locals {
  cluster_context = "kind-otel-demo-kind"
  kubeconfig_path = pathexpand("~/.kube/config")
}

provider "kubernetes" {
  config_path    = local.kubeconfig_path
  config_context = local.cluster_context
}
