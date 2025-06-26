module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.0.0"

  domain_name = var.domain_name
  zone_id     = var.zone_id
  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  validation_method = "DNS"

  wait_for_validation = true
}