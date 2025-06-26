variable "aws_region" {
  description = "AWS region to create infrastructure in"
  type        = string
}

variable "account_id" {
  description = "Allowed AWS account id to create infrastructure in"
  type        = string
}



variable "common_tags" { type = map(string) }
