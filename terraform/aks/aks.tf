data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.name}-aks"
  location            = var.location
  resource_group_name = var.rg-name
  dns_prefix          = "passwordapp"

  default_node_pool {
    name                 = "default"
    vm_size              = "Standard_DS2_v2"
    vnet_subnet_id       = var.subnet-id
    auto_scaling_enabled = true
    min_count            = 1
    max_count            = 2
  }

 azure_active_directory_role_based_access_control {
   tenant_id          = data.azurerm_client_config.current.tenant_id
   azure_rbac_enabled = true
} 

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin  = "azure"
    network_policy  = "calico"

  service_cidr   = "10.2.0.0/16"
  dns_service_ip = "10.2.0.10"
 }

 lifecycle {
   ignore_changes = all
 }
}