output "ecr_repositories" {
  description = "The URLs of the ECR repositories."
  value = [for ecr_repo in aws_ecr_repository.ecr_repo: ecr_repo.repository_url]
}

# output "helm_repositories" {
#   description = "The URLs of the Helm repositories."
#   value = [for helm_repo in aws_ecr_repository.helm_repo: helm_repo.repository_url]
# }

