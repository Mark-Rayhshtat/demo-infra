output "rds_postgres" {
  value = module.rds_postgres
}

output "secret_arn" {
  value = aws_secretsmanager_secret.postgres["demo"].arn
}