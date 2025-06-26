locals {
  cidrs = [for cidr_block in cidrsubnets(var.cidr, var.private_subnets_newbits, var.public_subnets_newbits, var.database_subnets_newbits) : cidrsubnets(cidr_block, 1, 1)]
  vpc_endpoints = merge({
    for vpce in var.vpce_list: replace(vpce, ".", "-") => {
      service             = vpce
      private_dns_enabled = vpce != "dynamodb" ? true: false
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "vpce-interface-${var.env}-${replace(vpce, ".", "-")}" }
    }},
    {
      s3 = {
        service         = "s3"
        service_type    = "Gateway"
        route_table_ids = flatten([
          module.vpc.private_route_table_ids, module.vpc.database_route_table_ids
        ])
        tags = { Name = "vpce-gateway-${var.env}-s3" }
      }
    }
  )
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"
  name                 = var.env
  cidr                 = var.cidr
  azs                  = slice(data.aws_availability_zones.available.names, 0, var.az_number)
  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway

  private_subnets  = local.cidrs[0]
  public_subnets   = local.cidrs[1]
  database_subnets = local.cidrs[2]

  create_database_subnet_route_table = true

  public_subnet_tags  = { "kubernetes.io/cluster/eks-${var.env}" = "shared", "kubernetes.io/role/elb" = "1" }
  private_subnet_tags = { "kubernetes.io/cluster/eks-${var.env}" = "shared", "kubernetes.io/role/internal-elb" = "1", "karpenter.sh/discovery" = "eks-${var.env}" }

  private_subnet_names  = ["net-${var.env}-private-az1", "net-${var.env}-private-az2"]
  public_subnet_names   = ["net-${var.env}-public-az1", "net-${var.env}-public-az2"]
  database_subnet_names = ["net-${var.env}-data-az1", "net-${var.env}-data-az2"]

  manage_default_network_acl = var.manage_default_network_acl
  manage_default_route_table = var.manage_default_route_table

  vpc_tags = {
    Name = "vpc-${var.env}"
  }
  igw_tags = {
    Name = "igw-${var.env}"
  }

  default_route_table_tags = {
    Name = "rtb-${var.env}-default"
  } 
  public_route_table_tags = {
    Name = "rtb-${var.env}-public"
  } 
  private_route_table_tags = {
    Name = "rtb-${var.env}-private"
  } 
  database_route_table_tags = {
    Name = "rtb-${var.env}-data"
  } 

}


#endpoints
module "sg-vpc-endpoint" {
 source  = "terraform-aws-modules/security-group/aws"
 version = "5.1.0"
 count = var.enable_vpc_endpoint ? 1 : 0
 name = "sgr-${var.env}-vpc-endpoints"

 description     = "Security group for VPC endpoints"
 vpc_id          = module.vpc.vpc_id
 use_name_prefix = false

 ingress_cidr_blocks     = [var.cidr]
 ingress_rules           = ["all-all"]
 egress_cidr_blocks      = ["0.0.0.0/0"]
 egress_ipv6_cidr_blocks = []
 egress_rules            = ["all-all"]

 tags = {
   Name           = "sgr-${var.env}-vpc-endpoints"
 }
}

module "vpc-endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.1.2"
  count = var.enable_vpc_endpoint ? 1 : 0
  vpc_id             = module.vpc.vpc_id
  security_group_ids = module.sg-vpc-endpoint[*].security_group_id
  endpoints          = local.vpc_endpoints
}

