# deploy.tf - EKS module kubernetes/helm components deployment for JARVICE

module "common" {
    source = "../common"

    global = var.global
    cluster = var.cluster

    system_nodes_type_upstream = lookup(var.cluster.meta, "arch", "") == "arm64" ? "m6g.4xlarge" : "m5.4xlarge"
    system_nodes_type_downstream = lookup(var.cluster.meta, "arch", "") == "arm64" ? "m6g.xlarge" : "m5.xlarge"
    storage_class_provisioner = "kubernetes.io/aws-ebs"
}

locals {
    charts = {
        "cluster-autoscaler" = {
            "values" = <<EOF
autoDiscovery:
  clusterName: ${var.cluster.meta["cluster_name"]}
  enabled: true

awsRegion: "${var.cluster.location["region"]}"

cloudProvider: aws

image:
  repository: gcr.io/jarvice/cluster-autoscaler
  tag: v1.17.4
  pullPolicy: IfNotPresent

tolerations:
  - key: node-role.jarvice.io/jarvice-system
    effect: NoSchedule
    operator: Exists
  - key: node-role.kubernetes.io/jarvice-system
    effect: NoSchedule
    operator: Exists

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-role.jarvice.io/jarvice-system
          operator: Exists
      - matchExpressions:
        - key: node-role.kubernetes.io/jarvice-system
          operator: Exists

rbac:
  create: true
  serviceAccountAnnotations:
    eks.amazonaws.com/role-arn: "${module.iam_assumable_role_admin.this_iam_role_arn}"
EOF
        },
        "metrics-server" = {
            "values" = <<EOF
image:
  repository: gcr.io/k8s-staging-metrics-server/metrics-server
  tag: v0.4.1
  pullPolicy: IfNotPresent

tolerations:
  - key: node-role.jarvice.io/jarvice-system
    effect: NoSchedule
    operator: Exists
  - key: node-role.kubernetes.io/jarvice-system
    effect: NoSchedule
    operator: Exists

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-role.jarvice.io/jarvice-system
          operator: Exists
      - matchExpressions:
        - key: node-role.kubernetes.io/jarvice-system
          operator: Exists

priorityClassName: system-node-critical

args:
  - --kubelet-preferred-address-types=InternalIP
  - --kubelet-insecure-tls

service:
  labels:
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "Metrics-server"
EOF
        },
        "cert-manager" = {
            "values" = <<EOF
installCRDs: true

#ingressShim:
#  defaultIssuerName: letsencrypt-prod
#  defaultIssuerKind: ClusterIssuer
#  defaultIssuerGroup: cert-manager.io

prometheus:
  enabled: false

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-role.jarvice.io/jarvice-system
          operator: Exists
      - matchExpressions:
        - key: node-role.kubernetes.io/jarvice-system
          operator: Exists

tolerations:
  - key: node-role.jarvice.io/jarvice-system
    effect: NoSchedule
    operator: Exists
  - key: node-role.kubernetes.io/jarvice-system
    effect: NoSchedule
    operator: Exists

webhook:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: node-role.jarvice.io/jarvice-system
            operator: Exists
        - matchExpressions:
          - key: node-role.kubernetes.io/jarvice-system
            operator: Exists

  tolerations:
    - key: node-role.jarvice.io/jarvice-system
      effect: NoSchedule
      operator: Exists
    - key: node-role.kubernetes.io/jarvice-system
      effect: NoSchedule
      operator: Exists

cainjector:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: node-role.jarvice.io/jarvice-system
            operator: Exists
        - matchExpressions:
          - key: node-role.kubernetes.io/jarvice-system
            operator: Exists

  tolerations:
    - key: node-role.jarvice.io/jarvice-system
      effect: NoSchedule
      operator: Exists
    - key: node-role.kubernetes.io/jarvice-system
      effect: NoSchedule
      operator: Exists
EOF
        },
        "traefik" =  {
            "values" = <<EOF
# TODO: use eip allocations with NLB
#loadBalancerIP: {aws_eip.nat[0].public_ip}
replicas: 2
memoryRequest: 1Gi
memoryLimit: 1Gi
cpuRequest: 1
cpuLimit: 1

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-role.jarvice.io/jarvice-system
          operator: Exists
      - matchExpressions:
        - key: node-role.kubernetes.io/jarvice-system
          operator: Exists

tolerations:
  - key: node-role.jarvice.io/jarvice-system
    effect: NoSchedule
    operator: Exists
  - key: node-role.kubernetes.io/jarvice-system
    effect: NoSchedule
    operator: Exists

ssl:
  enabled: true
  enforced: true
  permanentRedirect: true
  insecureSkipVerify: true
  generateTLS: true

dashboard:
  enabled: false

# TODO: use eip allocations with NLB
#service:
#  annotations:
#    service.beta.kubernetes.io/aws-load-balancer-type: nlb
#    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
#    service.beta.kubernetes.io/aws-load-balancer-eip-allocations: "{aws_eip.nat[0].id}"
#    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
#    service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "60"

rbac:
  enabled: true
EOF
        }
    }
}

module "helm" {
    source = "../helm"

    charts = local.charts

    # JARVICE settings
    jarvice = merge(var.cluster.helm.jarvice, {"values_file"=module.common.jarvice_values_file})
    global = var.global.helm.jarvice
    common_values_yaml = <<EOF
${module.common.cluster_values_yaml}
EOF
    cluster_values_yaml = <<EOF
# EKS cluster override values
${local.jarvice_ingress}
EOF

    depends_on = [module.eks, module.vpc]
}

