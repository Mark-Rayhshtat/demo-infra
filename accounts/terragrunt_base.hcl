locals {
  ## Environment Variables
  global_vars   = read_terragrunt_config(find_in_parent_folders("global.hcl")).locals
  account_vars  = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals
  region_vars   = read_terragrunt_config(find_in_parent_folders("region.hcl")).locals
  env        = local.region_vars.env
  region     = local.region_vars.aws_region
  layer      = basename(get_original_terragrunt_dir())
}

# terraform_version_constraint  = "~> 1.8.0"
# terragrunt_version_constraint = "~> 0.54.16"
# prevent_destroy = true

generate "versions" {
  path      = "_versions_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = file("${get_repo_root()}/accounts/_common/versions_override.tf")
}

generate "variables" {
  path      = "_variables.tf"
  if_exists = "overwrite_terragrunt"
  contents  = file("${get_repo_root()}/accounts/_common/variables.tf")
}

generate "providers" {
  path      = "_providers.tf"
  if_exists = "overwrite"
  contents  = file("${get_repo_root()}/accounts/_common/providers.tf")
}

remote_state {
  backend = "s3"  
  config = {
    encrypt        = true
    region         = local.region
    key            = format("%s/terraform.tfstate", path_relative_to_include())
    bucket         = format("terraform-states-%s-%s", get_aws_account_id(), local.region_vars.aws_region)
    dynamodb_table = format("terraform-states-%s-%s", get_aws_account_id(), local.region_vars.aws_region)
  }
  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite"
  }
}

download_dir = "${get_repo_root()}/.terragrunt-cache/${get_path_from_repo_root()}"

inputs = merge(
  local.global_vars,
  local.account_vars,
  local.region_vars,
  { 
    common_tags = {
      enviroment-name = local.region_vars.env
      enviroment-type = local.region_vars.env_type 
      created-by      = "terraform"
      managed-by      = "terraform"
      layer           = local.layer
    }
  }
)

