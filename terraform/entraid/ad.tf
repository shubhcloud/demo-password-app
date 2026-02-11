data "azurerm_client_config" "current" {}

#==========================================================
#WORKFLOW 1 – TERRAFORM PLAN (Reader, terraform-update branch)
#==========================================================

resource "azuread_application" "tf_plan" {
  display_name = "gha-terraform-plan"
}

resource "azuread_service_principal" "tf_plan" {
  client_id = azuread_application.tf_plan.client_id
}

resource "azurerm_role_assignment" "tf_plan_reader" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.rg_name}"
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.tf_plan.object_id
}

resource "azuread_application_federated_identity_credential" "tf_plan" {
  application_id = azuread_application.tf_plan.id
  display_name          = "tf-plan-any-branch"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"

  subject = "repo:${var.repo-name}:workflow:terraform-plan.yml:ref:refs/heads/terraform-update"
}

#==========================================================
#WORKFLOW 2 – TERRAFORM APPLY (Contributor, MAIN ONLY)
#==========================================================

resource "azuread_application" "tf_apply" {
  display_name = "gha-terraform-apply"
}

resource "azuread_service_principal" "tf_apply" {
  client_id = azuread_application.tf_apply.client_id
}

resource "azurerm_role_assignment" "tf_apply_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.rg_name}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.tf_apply.object_id
}

resource "azuread_application_federated_identity_credential" "tf_apply" {
  application_id = azuread_application.tf_apply.id
  display_name          = "tf-apply-main-only"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"

  subject = "repo:${var.repo-name}:workflow:terraform-apply.yml:ref:refs/heads/main"
}

#==========================================================
#WORKFLOW 3 – DOCKER CI (ACR PUSH)
#==========================================================

resource "azuread_application" "docker_ci" {
  display_name = "gha-docker-ci"
}

resource "azuread_service_principal" "docker_ci" {
  client_id = azuread_application.docker_ci.client_id
}

resource "azurerm_role_assignment" "docker_acr_push" {
  scope = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.rg_name}/providers/Microsoft.ContainerRegistry/registries/${var.acr_name}"

  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.docker_ci.object_id
}

resource "azuread_application_federated_identity_credential" "docker_ci" {
  application_id = azuread_application.docker_ci.id
  display_name          = "docker-ci-main-only"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"

  subject = "repo:${var.repo-name}:workflow:docker-ci.yml:ref:refs/heads/main"
}

#==========================================================
#WORKFLOW 4 – ARGOCD BOOTSTRAP (AKS ACCESS)
#==========================================================

resource "azuread_application" "argocd" {
  display_name = "gha-argocd-bootstrap"
}

resource "azuread_service_principal" "argocd" {
  client_id = azuread_application.argocd.client_id
}

resource "azurerm_role_assignment" "argocd_aks_user" {
  scope = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.rg_name}/providers/Microsoft.ContainerService/managedClusters/${var.aks-name}"

  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azuread_service_principal.argocd.object_id
}

resource "azuread_application_federated_identity_credential" "argocd" {
  application_id = azuread_application.argocd.id
  display_name          = "argocd-bootstrap-main-only"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"

  subject = "repo:${var.repo-name}:workflow:argocd-bootstrap.yml:ref:refs/heads/main"
}

