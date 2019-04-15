variable "circle_token" {
  type = "string"
}

variable "circle_project" {
  type = "string"
}

variable "circle_org" {
  type = "string"
}

variable "aws_user" {
  type = "string"
}

variable "cloudwatch_expression" {
  type = "string"
  default = "rate(1 hour)"
}