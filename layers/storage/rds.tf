module "security_group" {
  for_each = var.rds_settings_postgres

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "sgr-${var.env}-rds"
  description = "PostgreSQL security group"
  vpc_id      = var.vpc_id

  # ingress
  ingress_cidr_blocks      = [var.cidr]
  ingress_rules            = ["postgresql-tcp"]

}


resource "random_string" "this" {
  for_each = var.rds_settings_postgres

  length           = 8
  special          = false
  upper            = false
  lower            = true
  numeric          = true
}

resource "random_password" "postgres"{
  for_each = var.rds_settings_postgres

	length           = 16
  special          = true
  override_special = "_!%^"
}


resource "aws_secretsmanager_secret" "postgres" {
  for_each = var.rds_settings_postgres

  name = "sm-${var.env}-db-password-postgres-${random_string.this[each.key].result}"
}

resource "aws_secretsmanager_secret_version" "postgres" {
  for_each = var.rds_settings_postgres
  secret_id 		= aws_secretsmanager_secret.postgres[each.key].id
	secret_string = <<EOF
{
  "username": "${each.value.username}",
  "password": "${random_password.postgres[each.key].result}",
  "endpoint": "${module.rds_postgres[each.key].db_instance_address}"
}
EOF
}


module "rds_postgres" {
  source = "terraform-aws-modules/rds/aws"
  version = "6.10.0"

  # create_db_instance = false #length(var.rds_settings_postgres) > 1

  for_each = var.rds_settings_postgres

  identifier = "rds-${var.env}-${each.key}"
  engine                                = each.value.engine
  engine_version                        = each.value.engine_version
  family                                = each.value.family
  major_engine_version                  = each.value.major_engine_version
  instance_class                        = each.value.instance_class

  storage_type                          = each.value.storage_type
  allocated_storage                     = each.value.allocated_storage
  max_allocated_storage                 = each.value.max_allocated_storage


  username                              = each.value.username
  password 									            = random_password.postgres[each.key].result
  port                                  = each.value.port
  db_name                               = each.value.db_name

  manage_master_user_password_rotation  = each.value.manage_master_user_password_rotation
  manage_master_user_password           = each.value.manage_master_user_password

  multi_az                              = each.value.multi_az
  db_subnet_group_name                  = var.database_subnet_group
  vpc_security_group_ids                = [module.security_group[each.key].security_group_id]
  iam_database_authentication_enabled   = each.value.iam_database_authentication_enabled

  backup_window                         = each.value.backup_window
  backup_retention_period               = each.value.backup_retention_period
  maintenance_window                    = each.value.maintenance_window
  enabled_cloudwatch_logs_exports       = each.value.enabled_cloudwatch_logs_exports
  create_cloudwatch_log_group           = true

  skip_final_snapshot                   = true
  deletion_protection                   = true

  performance_insights_enabled          = each.value.performance_insights_enabled
  performance_insights_retention_period = each.value.performance_insights_retention_period
  create_monitoring_role                = each.value.create_monitoring_role
  monitoring_interval                   = each.value.create_monitoring_role ? 60 : 0
  monitoring_role_name                  = "role-${var.env}-rds-monitoring"
  monitoring_role_use_name_prefix       = false
  monitoring_role_description           = "RDS monitoring role"

  create_db_parameter_group             = true
  parameter_group_name                  = "pgr-${var.env}-${each.value.engine}-${each.key}"
  parameters                            = each.value.parameters

}