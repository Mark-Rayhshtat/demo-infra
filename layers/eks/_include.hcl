terraform {
  source = "${get_repo_root()}/layers/${basename(get_terragrunt_dir())}///"
}

dependencies {
  paths = ["../networking", "../storage"]
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

dependency "acm" {
  config_path = "../acm"

  mock_outputs = {
    acm = {
      acm_certificate_arn = "dummy"
    }
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "git_pipeline" {
  config_path = "../git_pipeline"

  mock_outputs = {
    codebuild_role_arn = "dummy"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "storage" {
  config_path = "../storage"

  mock_outputs = {
    secret_arn = "dummy"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  vpc_id                             = dependency.networking.outputs.vpc.vpc_id
  subnet_ids                         = dependency.networking.outputs.vpc.private_subnets
  acm_certificate_arn                = dependency.acm.outputs.acm.acm_certificate_arn
  codebuild_role_arn                 = dependency.git_pipeline.outputs.codebuild_role_arn
  security_group_codebuild           = dependency.git_pipeline.outputs.security_group.security_group_id
  db_instance_secret_arn             = dependency.storage.outputs.secret_arn
}


