variable "create_github_runners_codebuild" {
    type = bool
    default = true
}
variable "github_organization_name" {default = null}
variable "env" {}
variable "env_type" {}
variable "vpc_id" {}
variable "subnet_ids" { type = list(string) }
variable "build_timeout" {
    type = number
    default = 120
}
variable "queued_timeout" {
    type = number
    default = 30
}

variable "compute_type" {
    type = string
    default = "BUILD_GENERAL1_SMALL"
}

variable "image" {
    type = string
    default = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
}

variable "type" {
    type = string
    default = "LINUX_CONTAINER"
}

variable "privileged_mode" {
    type = bool
    default = true
}
