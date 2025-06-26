module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.19.0"


  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  create_delay_dependencies = [for v in module.eks.eks_managed_node_groups : v.node_group_arn]

  # LOAD BALANCER CONTROLLER
  enable_aws_load_balancer_controller = lookup(var.blueprints_addons, "enable_aws_load_balancer_controller", false)
  aws_load_balancer_controller = {
    chart_version = "1.11.0"
    values = [
      yamlencode({
        tolerations = local.default_system_tolerations
        affinity    = local.default_system_affinity
      })
    ]
  }

  ## METRICS SERVER
  enable_metrics_server = lookup(var.blueprints_addons, "enable_aws_load_balancer_controller", false)
  metrics_server = {
    chart_version = "3.10.0"
    values = [
      yamlencode({
        tolerations = local.default_system_tolerations
        affinity    = local.default_system_affinity
      })
    ]
  }

  ## KARPENTER
  enable_karpenter = lookup(var.blueprints_addons, "enable_aws_load_balancer_controller", false)
  karpenter = {
    chart_version = "1.0.7"
    values = [
      yamlencode({
        tolerations = local.default_system_tolerations
      })
    ]
  }
  karpenter_enable_spot_termination          = true
  karpenter_enable_instance_profile_creation = true
  karpenter_node = {
    iam_role_use_name_prefix = false
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      #   AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      #   AmazonEKSWorkerNodePolicy = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
      #   AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    }
  }

  ## EXTERNAL-SECRET
  enable_external_secrets = lookup(var.blueprints_addons, "enable_external_secrets", false)
  external_secrets = {
    values = [
      yamlencode({
        tolerations = local.default_system_tolerations
        affinity    = local.default_system_affinity
        global = {
          tolerations = local.default_system_tolerations
          affinity    = local.default_system_affinity
        }
        webhook = {
          tolerations = local.default_system_tolerations
          affinity    = local.default_system_affinity
        }
        certController = {
          tolerations = local.default_system_tolerations
          affinity    = local.default_system_affinity
        }
      })
    ]
  }

  # External DNS
  enable_external_dns = lookup(var.blueprints_addons, "enable_external_dns", false)
  external_dns = {
    chart_version = "1.15.2"
    values = [
      yamlencode({
        tolerations = local.default_system_tolerations
        affinity    = local.default_system_affinity
      })
    ]
  }
  external_dns_route53_zone_arns = ["arn:aws:route53:::hostedzone/${var.zone_id}"]

}

resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = "karpenter"
  }
  depends_on = [module.eks]
}