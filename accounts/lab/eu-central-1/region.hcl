locals {
  env           = "lab"
  env_type      = "non-prod"
  aws_region    = "eu-central-1"
  az_number     = 2

  # DNS
  zone_id         = "Z01507761KS9322GYDINY"
  domain_name     = "demo.rayhshtat.com"

  # VPC
  cidr                     = "10.250.48.0/20"
  enable_nat_gateway       = true
  single_nat_gateway       = true
  one_nat_gateway_per_az   = false
  private_subnets_newbits  = 1
  public_subnets_newbits   = 3
  database_subnets_newbits = 3
  vpce_list                = ["logs", "ecr.api", "ecr.dkr"]


  # RDS
  rds_settings_postgres = {
    demo = {
      engine                                = "postgres"
      engine_version                        = "17.4"
      family                                = "postgres17"
      major_engine_version                  = "17"
      instance_class                        = "db.t4g.micro"
      storage_type                          = "gp3"
      allocated_storage                     = 30
      max_allocated_storage                 = 100
      manage_master_user_password_rotation  = false
      manage_master_user_password           = false
      username                              = "postgres"
      port                                  = 5432
      db_name                               = "demo"
      multi_az                              = false
      iam_database_authentication_enabled   = false
      backup_window                         = "02:58-03:28"
      backup_retention_period               = 7
      maintenance_window                    = "Sun:01:38-Sun:02:08"
      enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
      performance_insights_enabled          = false
      performance_insights_retention_period = 7
      create_monitoring_role                = false
      parameters                            = []
    }
  }

  # EKS
  eks_mng_settings = {
    infra = {
      per_az          = "false"
      az_qty          = 2
      # capacity_type   = "ON_DEMAND"
      capacity_type   = "SPOT"
      max_unavailable = 1
      min_size        = 0
      max_size        = 4
      desired_size    = 2
      ami_type        = "AL2023_x86_64_STANDARD"
      use_ami_id      = true
      instance_types  = ["t4g.medium"]
      volume_size     = 200
      iops            = 3000
      taints = [
        {
          key    = "dedicated"
          value  = "system"
          effect = "NO_EXECUTE"
        }
      ]
    }
  }

  blueprints_addons = {
    enable_aws_load_balancer_controller = true
    enable_metrics_server = true
    enable_karpenter = true
    enable_external_secrets = true
    enable_external_dns = true
  }

  ecr_repository_names = ["demo"]

  github_organization_name = "Mark-Rayhshtat"

}
