// main lambda function
resource "aws_lambda_function" "lambda_function" {
  filename         = "${path.module}/function.zip"
  function_name    = "${var.circle_project}-circleci-rotator"
  role             = "${aws_iam_role.lambda_iam.arn}"
  handler          = "main"
  source_code_hash = "${base64sha256(file("${path.module}/function.zip"))}"
  runtime          = "go1.x"

  environment {
    variables = {
      CIRCLE_TOKEN = "${var.circle_token}",
      CIRCLE_PROJECT = "${var.circle_project}",
      CIRCLE_ORG = "${var.circle_org}",
      AWS_USER = "${var.aws_user}",
    }
  }
}

data "aws_iam_policy" "lambda_basic" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = "${aws_iam_role.lambda_iam.name}"
  policy_arn = "${data.aws_iam_policy.lambda_basic.arn}"
}


resource "aws_iam_role" "lambda_iam" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_user" "aws_user" {
  user_name = "${var.aws_user}"
}

data "aws_iam_policy_document" "iam" {
  statement {
    sid = "circleIAM"

    actions = [
      "iam:GetUser",
      "iam:CreateAccessKey",
      "iam:ListAccessKeys",
      "iam:DeleteAccessKey",
    ]

    resources = [
      "${data.aws_iam_user.aws_user.arn}"
    ]
  }

}

resource "aws_iam_policy" "iam" {
  name        = "iamPermissions"
  path        = "/"

  policy = "${data.aws_iam_policy_document.iam.json}"
}

resource "aws_iam_role_policy_attachment" "iam" {
  role       = "${aws_iam_role.lambda_iam.name}"
  policy_arn = "${aws_iam_policy.iam.arn}"
}

// cloud watch resources
resource "aws_cloudwatch_event_rule" "lambda_rule" {
    name = "${var.circle_project}-circleci-rotator-rule"
    schedule_expression = "${var.cloudwatch_expression}"
}

resource "aws_cloudwatch_event_target" "event_target" {
    rule = "${aws_cloudwatch_event_rule.lambda_rule.name}"
    arn = "${aws_lambda_function.lambda_function.arn}"
}

resource "aws_lambda_permission" "cloudwatch_lambda_permission" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.lambda_function.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.lambda_rule.arn}"
}