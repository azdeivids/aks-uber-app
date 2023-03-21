resource "azurerm_resource_group" "tfrg01" {
  name     = "tfrg-{var.app_name}-001"
  location = var.location
}

# Azure services (ACR)

resource "azurerm_container_registry" "tfacr01" {
  name                = "{var.app_name}-acr-001"
  resource_group_name = azurerm_resource_group.tfrg01.name
  location            = azurerm_resource_group.tfrg01.location
  sku                 = "Standard"
  admin_enabled       = false
}

# Network resources

resource "azurerm_virtual_network" "tfvnet01" {
  name                = "{var.app_name}-vnet-001"
  resource_group_name = azurerm_resource_group.tfrg01.name
  location            = azurerm_resource_group.tfrg01.location
  address_space       = [var.address_space]
}

resource "azurerm_subnet" "aks_snet01" {
  name                 = "{var.aks_snet_name}-snet-001"
  resource_group_name  = azurerm_resource_group.tfrg01.name
  virtual_network_name = azurerm_virtual_network.tfvnet01.name
  address_prefixes     = [var.aks_snet_prefix]
}

resource "azurerm_subnet" "appgw_snet02" {
  name                 = "{var.snet_name}-snet-002"
  resource_group_name  = azurerm_resource_group.tfrg01.name
  virtual_network_name = azurerm_virtual_network.tfvnet01.name
  address_prefixes     = [var.snet_prefix]
}

# Azure Services (la)

resource "azurerm_log_analytics_workspace" "loga01" {
  name                = "{var.app_name}-la-001"
  resource_group_name = azurerm_resource_group.tfrg01.name
  location            = azurerm_resource_group.tfrg01.location
  sku                 = "PerGB2018"
}

resource "azurerm_log_analytics_solution" "loga_solution01" {
  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.loga01.location
  resource_group_name   = azurerm_resource_group.tfrg01.name
  workspace_resource_id = azurerm_log_analytics_workspace.loga01.id
  workspace_name        = azurerm_log_analytics_workspace.loga01.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

# Azure Services (k8s)

resource "azurerm_kubernetes_cluster" "k8s01" {
  name                = "{var.app_name}-aks-001"
  location            = azurerm_resource_group.tfrg01.location
  resource_group_name = azurerm_resource_group.tfrg01.name
  dns_prefix          = "{var.app_name}-dns"
  kubernetes_version  = var.k8s_ver

  node_resource_group = "tfrg-{var.app_name}-002"

  linux_profile {
    admin_username = "deivids"

    ssh_key {
      key_data = var.ssh_key
    }
  }

  default_node_pool {
    name                 = "agentpool"
    vm_size              = var.vm_size
    node_count           = var.k8s_agents
    vnet_subnet_id       = azurerm_virtual_network.tfvnet01.id
    type                 = "VirtualMachineScaleSets"
    orchestrator_version = var.k8s_ver
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.loga01.identity
  }

  ingress_application_gateway {
    subnet_id = data.azurerm_subnet.appgw_snet02.id
  }

  network_profile {
    load_balancer_sku = "Standard"
    network_plugin    = "azure"
  }

  role_based_access_control_enabled = var.k8s_cluster_rbac
  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = [var.sec_aks_admins_id]
  }
}

resource "azurerm_role_assignment" "infra_update_scale_set" {
  principal_id         = azurerm_kubernetes_cluster.k8s01.principal_id
  scope                = data.azurerm_resource_group.node_resource_group.id
  role_definition_name = "Virtual Machine Contributor"
  depends_on = [
    azurerm_kubernetes_cluster.k8s01
  ]
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.k8s01.principal_id
  scope                = data.azurerm_resource_group.node_resource_group.id
  role_definition_name = "acrpull"
  depends_on = [
    azurerm_kubernetes_cluster.k8s01
  ]
}