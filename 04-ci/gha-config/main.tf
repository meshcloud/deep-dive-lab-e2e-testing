/*
 * Configure the GitHub Environment the nightly workflow reads from.
 */
resource "github_repository_environment" "this" {
  repository  = var.repository
  environment = var.environment

}

resource "github_actions_environment_variable" "this" {
  for_each = var.variables

  repository    = var.repository
  environment   = github_repository_environment.this.environment
  variable_name = each.key
  value         = each.value
}

locals {
  secret_names = nonsensitive(toset(keys(var.secrets)))
}

resource "github_actions_environment_secret" "this" {
  for_each = local.secret_names

  repository  = var.repository
  environment = github_repository_environment.this.environment
  secret_name = each.key

  value = var.secrets[each.key]
}
