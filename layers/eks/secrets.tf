# data "aws_region" "current" {}

locals {
  namespace                    = "external-secrets"
  cluster_secretstore_name     = "cluster-secretstore-sm"
  cluster_secretstore_sa       = "cluster-secretstore-sa"
  cluster_secretstore_ssm_name = "cluster-secretstore-ssm-sm"
}


module "cluster_secretstore_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.30.0"

  create_role = lookup(var.blueprints_addons, "enable_external_secrets", false)
  role_name = "role-${var.env}-external-secret-sm-irsa"

  role_policy_arns = {
    policy = module.cluster_secretstore_policy.arn # aws_iam_policy.cluster_secretstore[0].arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.namespace}:${local.cluster_secretstore_sa}"]
    }
  }

}

module "cluster_secretstore_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  create_policy = lookup(var.blueprints_addons, "enable_external_secrets", false)
  name        = "policy-${var.env}-secret-manager-permission"
  path        = "/"
  description = "Allows ECR read/write"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
            "secretsmanager:GetResourcePolicy",
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
            "secretsmanager:ListSecretVersionIds",
            "ssm:GetParameter*",
            "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}



resource "kubectl_manifest" "cluster_secretstore_sa" {
  count = lookup(var.blueprints_addons, "enable_external_secrets", false) ? 1 : 0
  yaml_body  = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    eks.amazonaws.com/role-arn: ${module.cluster_secretstore_role.iam_role_arn}
  name: ${local.cluster_secretstore_sa}
  namespace: ${local.namespace}
YAML
  depends_on = [module.eks_blueprints_addons]
}




resource "kubectl_manifest" "cluster_secretstore" {
  count = lookup(var.blueprints_addons, "enable_external_secrets", false) ? 1 : 0
  yaml_body  = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets-store
spec:
  provider:
    aws:
      service: SecretsManager
      region: ${data.aws_region.current.name}
      auth:
        jwt:
          serviceAccountRef:
            name: ${local.cluster_secretstore_sa}
            namespace: ${local.namespace}
YAML
  depends_on = [module.eks_blueprints_addons]
}


resource "kubectl_manifest" "cluster_secretstore_parameters" {
  count = lookup(var.blueprints_addons, "enable_external_secrets", false) ? 1 : 0
  yaml_body  = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets-store-ssm
spec:
  provider:
    aws:
      service: ParameterStore
      region: ${data.aws_region.current.name}
      auth:
        jwt:
          serviceAccountRef:
            name: ${local.cluster_secretstore_sa}
            namespace: ${local.namespace}
YAML
  depends_on = [module.eks_blueprints_addons]
}

resource "kubernetes_namespace" "demo" {
  metadata {
    name = "demo"
  }
  depends_on = [kubectl_manifest.cluster_secretstore]
}


resource "kubectl_manifest" "postgres_secret" {
  yaml_body  = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: postgres-sm
  namespace: "demo"
spec:
  refreshInterval: 24h
  secretStoreRef:
    name: aws-secrets-store
    kind: ClusterSecretStore
  dataFrom:
  - extract:
      key: ${var.db_instance_secret_arn}
YAML
  depends_on = [kubectl_manifest.cluster_secretstore, kubernetes_namespace.demo]
}