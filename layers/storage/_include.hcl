terraform {
  source = "${get_repo_root()}/layers/${basename(get_terragrunt_dir())}///"
}


dependency "networking" {
  config_path = "../networking"

  mock_outputs = {
    vpc = {
      vpc_id                = "dummy"
      database_subnet_group = "dummy"
      database_subnets   = ["dummy", "dummy"]
    }
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  vpc_id                    = dependency.networking.outputs.vpc.vpc_id
  database_subnet_group     = dependency.networking.outputs.vpc.database_subnet_group
  database_subnet_ids       = dependency.networking.outputs.vpc.database_subnets
}
