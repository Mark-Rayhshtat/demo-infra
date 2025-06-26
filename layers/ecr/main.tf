data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

resource "aws_ecr_repository" "ecr_repo" {
  for_each = toset(var.ecr_repository_names)

  name = "ecr-${var.env}-${each.key}"
  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.kms_key_arn
  }
  force_delete         = var.force_delete
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

}

