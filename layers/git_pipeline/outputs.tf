output "codebuild_role_arn" {
    value = try(aws_iam_role.codebuild[0].arn, "")
}
output "security_group" {
  value = module.codebuild_security_group
}