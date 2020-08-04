# deploy.tf - GKE module kubernetes/helm components deployment for JARVICE

module "helm" {
    source = "../helm"

    # Traefik settings
    traefik_values = <<EOF
replicas: 2
memoryRequest: 1Gi
memoryLimit: 1Gi
cpuRequest: 1
cpuLimit: 1

nodeSelector:
  kubernetes.io/arch: "amd64"
  #node-role.kubernetes.io/jarvice-system: "true"
  node-role.jarvice.io/jarvice-system: "true"
tolerations:
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

rbac:
  enabled: true
EOF

    # JARVICE settings
    jarvice = merge(var.cluster.helm.jarvice, {"override_yaml_file"="${local.jarvice_override_yaml_file}"})
    global = var.global.helm.jarvice
    cluster_override_yaml_values = local.cluster_override_yaml_values
}
