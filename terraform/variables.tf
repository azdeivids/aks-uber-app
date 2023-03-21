variable "prefix" {
  description = "Prefix used for all resources."
  type        = string
}

variable "location" {
  description = "Location where the resources will be stored"
  type        = string
}

# Network resource variables

variable "address_space" {
  description = "Address space used for the virtual network."
  type        = string
}

variable "aks_snet_name" {
  description = "Subnet where the kubernetes cluster will be deployed."
  type        = string
}

variable "aks_snet_prefix" {
  description = "Kubernetes cluster subnet address space."
  type        = string
}

variable "snet_name" {
  description = "Subnet address space name."
  type        = string
}

variable "snet_prefix" {
  description = "Subnet address space."
  type        = string
}

# Azure Services (k8s)

variable "k8s_cluster_rbac" {
  default = "true"
}

variable "k8s_ver" {

}

variable "k8s_agents" {

}

variable "vm_size" {

}

variable "ssh_key" {

}

variable "sec_aks_admins_id" {

}