include "base" {
  path = find_in_parent_folders("terragrunt_base.hcl")
}

include "layer" {
  path = "${get_repo_root()}/layers/${basename(get_terragrunt_dir())}/_include.hcl"
}