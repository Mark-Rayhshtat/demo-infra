terraform {
  source = "${get_repo_root()}/layers/${basename(get_terragrunt_dir())}///"
}
