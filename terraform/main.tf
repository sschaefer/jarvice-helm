
module "aks" {
    source = "./aks"

    # count feature will be available in terraform v0.13.0
    #count = length(var.aks)
    #aks = var.aks[count.index]

    aks = var.aks[0]
}

