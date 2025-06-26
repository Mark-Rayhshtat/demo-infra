variable "env" {}
variable "az_number" {}
variable "cidr" {}
variable "vpc_id" {}
variable "database_subnet_group" {}
variable "rds_settings_postgres" { 
  type = any
  default = {}
}