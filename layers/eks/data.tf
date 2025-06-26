data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_roles" "ps-global-admin" {
  name_regex  = "AWSReservedSSO_ps-global-admin_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}