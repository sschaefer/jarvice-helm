# outputs.tf - AKS module outputs

resource "local_file" "kube_config" {
    filename = pathexpand(local.kube_config["config_path"])
    file_permission = "0600" 
    directory_permission = "0775"
    content = azurerm_kubernetes_cluster.jarvice.kube_config_raw
}

output "kube_config" {
    value = local.kube_config
}

output "cluster_info" {
    value = <<EOF
===============================================================================

    AKS cluster name: ${var.cluster.meta["cluster_name"]}
AKS cluster location: ${var.cluster.location["region"]}

       JARVICE chart: ${module.helm.jarvice_chart["version"]}
   JARVICE namespace: ${module.helm.metadata["jarvice"]["namespace"]}

Execute the following to begin using kubectl/helm with the new cluster:

export KUBECONFIG=${local.kube_config["config_path"]}

${module.common.cluster_output_message}:

https://${azurerm_public_ip.jarvice.fqdn}/

===============================================================================
EOF
}

