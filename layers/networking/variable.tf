variable "env" {}
variable "az_number" {}
variable "cidr" {}
variable "env_type" {}
variable "enable_nat_gateway" {}
variable "single_nat_gateway" {default = true}
variable "one_nat_gateway_per_az" {default = false}
variable "enable_vpc_endpoint" {
  type    = bool
  default = true
}
variable "private_subnets_newbits" {type = number}
variable "public_subnets_newbits" {type = number}
variable "database_subnets_newbits" {type = number}
variable "vpce_list" {
  type = list(string)
  default = []  
}
variable "manage_default_network_acl" {
  default = true
}
variable "manage_default_route_table" {
  default = true
}

