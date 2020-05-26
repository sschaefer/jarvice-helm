
variable "aks" {
    description = "Azure AKS Settings"
    type = list(object({
        enabled = bool

        service_principal_client_id = string
        service_principal_client_secret = string

        cluster_name = string
        kubernetes_version = string

        location = string
        availability_zones = list(string)

        ssh_public_key = string

        system_node_pool = object({
            node_vm_size = string
            node_count = number
        })
        compute_node_pools = list(object({
            node_vm_size = string
            node_os_disk_size_gb = number
            node_count = number
            node_min_count = number
            node_max_count = number
        }))

        helm = map(string)
    }))
    default = [{
        enabled = false

        service_principal_client_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        service_principal_client_secret = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

        cluster_name = "jarvice"
        kubernetes_version = "1.15.10"

        location = "Central US"
        availability_zones = ["1"]

        ssh_public_key = "~/.ssh/id_rsa.pub"

        system_node_pool = {
            node_vm_size = "Standard_DS4_v2"
            node_count = 3
        }
        compute_node_pools = [
            {
                node_vm_size = "Standard_D32_v3"
                node_os_disk_size_gb = 100
                node_count = 2
                node_min_count = 1
                node_max_count = 16
            }
        ]

        helm = {
            override_yaml = "override.yaml"
            JARVICE_PVC_VAULT_SIZE = "10"
            JARVICE_PVC_VAULT_NAME = "persistent"
            JARVICE_PVC_VAULT_STORAGECLASS = "jarvice-user"
            JARVICE_PVC_VAULT_ACCESSMODES = "ReadWriteOnce"
        }
    }]
}

