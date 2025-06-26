resource "kubectl_manifest" "karpenter_default_ec2_node_class" {
  yaml_body = <<YAML
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  kubelet:
    maxPods: 98
  amiFamily: AL2023
  amiSelectorTerms:
    - alias: al2023@latest
  role: "${module.eks_blueprints_addons.karpenter.node_iam_role_name}"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "eks-${var.env}"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "eks-${var.env}"
  tags:
    karpenter-node-pool-name: default
    intent: default
    karpenter.sh/discovery: "eks-${var.env}"
    Name: "i-${var.env}-eks-karpenter-default"



YAML
  depends_on = [
    module.eks.cluster,
    module.eks_blueprints_addons.karpenter,
  ]
}

resource "kubectl_manifest" "karpenter_default_node_pool" {
  yaml_body = <<YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    metadata:
      labels:
        intent: default
    spec:
      expireAfter: 720h
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key : karpenter.k8s.aws/instance-cpu
          operator : Gt
          values : ["1"]
        - key: karpenter.k8s.aws/instance-cpu
          operator: Lt
          values: ["20"]
        - key : karpenter.k8s.aws/instance-hypervisor
          operator : In
          values : ["nitro"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: node.kubernetes.io/instance-type
          operator: NotIn
          values: ["t4g.nano", "t3.nano", "t3a.nano", "t3.micro", "t4g.micro", "t3a.micro"]
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 3m

YAML
  depends_on = [
    module.eks.cluster,
    module.eks_blueprints_addons.karpenter,
    kubectl_manifest.karpenter_default_node_pool,
  ]
}

