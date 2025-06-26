terraform {
  source = "${dirname(find_in_parent_folders("terragrunt_base.hcl"))}/../layers/${basename(get_terragrunt_dir())}///"
}

dependency "networking" {
  config_path = "../networking"

  mock_outputs = {
    vpc = {
      vpc_id          = "dummy"
      private_subnets = ["dummy", "dummy"]
    }
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  vpc_id             = dependency.networking.outputs.vpc.vpc_id
  subnet_ids         = dependency.networking.outputs.vpc.private_subnets
}

