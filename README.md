# CircleCI Rotator

## What is This?

This project is code (golang/terraform) that rotates AWS Keys for an IAM user on a CircleCI as environment variables.
The code that does the rotation is writen in golang and the easy way to deploy it is as a terraform module. 

## Why

CircleCI is a really cool CI\CD tool but, it hasn't solved this use case. AWS Keys should be rotated and this project makes that happen with little overhead. 

## What Gets Deployed?
* lambda function -- this contains the go code that does the key rotation
* lambda iam role -- this contains the lambda basic execution policy plus iam access to the specified aws_user
* cloudwatch event -- to trigger the lambda and do rotation with a cron expression

## Getting Started

```hcl
provider "aws" {
  region     = "us-east-1"
}

module "rotator" {
  source = "git@github.com:codingdiaz/circleci-rotater.git?ref=v0.0.1"

  circle_token = "<insert-token>"
  circle_org = "<github-user or org>"
  circle_project = "<some-project>"
  aws_user = "${aws_iam_user.circle_deploy.name}"
}

resource "aws_iam_user" "circle_deploy" {
  name = "circle_deploy"
  path = "/"
}

```

Pro Tip: Get a token for a specific project to reduce the scope of the token