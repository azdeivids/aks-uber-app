data "azurerm_resource_group" "node_resource_group" {
  name = azurerm_kubernetes_cluster.k8s01.node_resource_group
  depends_on = [
    azurerm_kubernetes_cluster.k8s01
  ]
}

data "azurerm_container_registry" "tfacr01" {
  name                = "{var.app_name}-acr-001"
  resource_group_name = azurerm.resource_group_name.tfrg01.name
}