variable "env" {}
variable "env_type" {}
variable "vpc_id" {}
variable "cidr" {}
variable "acm_certificate_arn" {}
variable "subnet_ids" { type = list(string) }
variable "eks_mng_settings" { type = any }
variable "zone_id" {}
variable "domain_name" {}
variable "eks_version" {
  type    = string
  default = "1.33"
}
# variable "secrets" {
#   type = any
# }
variable "blueprints_addons" {
  type = any
}
variable "codebuild_role_arn" {}
variable "security_group_codebuild" {}
variable "db_instance_secret_arn" {}