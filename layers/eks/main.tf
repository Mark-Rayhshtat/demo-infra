locals {
  default_system_tolerations = [
    {
      key      = "dedicated"
      value    = "system"
      operator = "Equal"
      effect   = "NoExecute"
    }
  ]
  default_ds_system_tolerations = [
    {
      operator = "Exists"
    }
  ]
  default_system_nodeselector = {
    node-pool = "infra"
  }
  default_system_affinity = {
    nodeAffinity = {
      preferredDuringSchedulingIgnoredDuringExecution = [
        {
          weight = 1
          preference = {
            matchExpressions = [
              {
                key = "node-pool"
                operator = "In"
                values = ["infra"] 
              }
            ]
          }
        }
      ]
    }
  }


}
module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  description = "KMS for aws ebs csi driver"
  key_usage   = "ENCRYPT_DECRYPT"

  # Policy
  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/Mark"]
  key_users          = [module.ebs_csi_irsa_role.iam_role_arn]
  key_service_users  = [module.ebs_csi_irsa_role.iam_role_arn]
  key_service_roles_for_autoscaling = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]

  # Aliases
  aliases = ["eks"]
  aliases_use_name_prefix = true
}

module "eks" {
  # TODO: enable secrets encryption
  source  = "terraform-aws-modules/eks/aws"
  version = "20.36.0"

  cluster_name                    = "eks-${var.env}"
  cluster_version                 = var.eks_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  vpc_id                          = var.vpc_id
  subnet_ids                      = var.subnet_ids

  cluster_security_group_name             = "sgr-${var.env}-eks-cluster"
  cluster_security_group_use_name_prefix  = false
  cluster_security_group_description      = "EKS Cluster security group"
  cluster_security_group_additional_rules = {
    ingress = {
      description               = "Access from codebuild"
      protocol                  = "tcp"
      from_port                 = 443
      to_port                   = 443
      type                      = "ingress"
      source_security_group_id  = var.security_group_codebuild
    }
  }

  iam_role_name            = "role-${var.env}-eks-cluster"
  iam_role_use_name_prefix = false

  cluster_addons = {
    coredns                = {
      most_recent = true
      before_compute = true
      configuration_values = jsonencode({
        autoScaling = {
          enabled = true
        }
        tolerations = local.default_system_tolerations
        affinity = local.default_system_affinity
      })
    }
    aws-ebs-csi-driver = {
      most_recent = true
      before_compute = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
      configuration_values = jsonencode({
        controller = {
          tolerations = local.default_system_tolerations
          affinity = local.default_system_affinity
        }
      })
    }
    kube-proxy             = {
      most_recent = true
      before_compute = true
    }
    vpc-cni                = {
      most_recent = true
      before_compute = true
      service_account_role_arn = module.vpc_cni_ipv4_irsa_role.iam_role_arn
      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
        env = {
          ENABLE_PREFIX_DELEGATION           = "true"
          WARM_PREFIX_TARGET                 = "1"
          # AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
          # ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"
        }
      })
    }
  }

  enable_cluster_creator_admin_permissions = false

  access_entries = {
    codebuild_role = {
      kubernetes_groups = []
      principal_arn     = var.codebuild_role_arn

      policy_associations = {
        single = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
      }
    }  
    user = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/Mark"

      policy_associations = {
        single = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
      }
    } 
  }

  node_security_group_additional_rules = {
    egress_all = {
      description      = "!!Node all egress!!"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    ingress_all_vpc = {
      description = "!!Node all ingress from vpc!!"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = [var.cidr]
    }
    ingress_self_all = {
      description = "!!Node to node all ports/protocols!!"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }
  node_security_group_tags = {"karpenter.sh/discovery" = "eks-${var.env}"}
  eks_managed_node_group_defaults = {
    use_name_prefix                        = true
    create_launch_template                 = true
    launch_template_use_name_prefix        = true
    iam_role_use_name_prefix               = true
    update_launch_template_default_version = true
    iam_role_additional_policies           = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
    capacity_type           = "ON_DEMAND"
    cloudinit_pre_nodeadm = [
      {
        content_type = "application/node.eks.aws"
        content      = <<-EOT
          ---
          apiVersion: node.eks.aws/v1alpha1
          kind: NodeConfig
          spec:
            kubelet:
              config:
                maxPods: 98
        EOT
      }
    ]
  }
  eks_managed_node_groups = local.mng
}

resource "aws_eks_access_entry" "karpenter" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${module.eks_blueprints_addons.karpenter.node_iam_role_name}"
  type              = "EC2_LINUX"
  depends_on = [ module.eks.cluster ]
}
