variable "env" {}

variable "ecr_repository_names" {
  description = "A list of the ECR repository names."
  type        = list(string)
}

variable "create_helm_app_repositories" {
  description = "Automatically create Helm repositories as well as ECR repos for applications"
  type        = bool
  default     = false
}

variable "helm_group_repository_names" {
  description = "Helm repositories for Application Groups"
  type        = list(string)
  default     = []
}

variable "encryption_type" {
  description = "The encryption type to use for the repository (KMS or AES256)."
  type        = string
  default     = "AES256"
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to encrypt the repository when the encryption type is KMS."
  type        = string
  default     = ""
}

variable "force_delete" {
  description = "If true, will delete the repository even if it contains images."
  type        = bool
  default     = true
}

variable "image_tag_mutability" {
  description = "Tag immutability to prevent image tags from being overwritten by subsequent image pushes using the same tag."
  type        = string
  default     = "MUTABLE"
}

# The ScanOnPush configuration at the repository level has been deprecated in favour of registry-level scan filters.
variable "scan_on_push" {
  description = "Have each image automatically scanned after being pushed to a repository."
  type        = bool
  default     = false
}

