provider "aws" {
  region = var.aws_region

  allowed_account_ids = [
    var.account_id
  ]

  default_tags {
    tags = var.common_tags
  }
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"

  allowed_account_ids = [
    var.account_id
  ]

  default_tags {
    tags = var.common_tags
  }
}
