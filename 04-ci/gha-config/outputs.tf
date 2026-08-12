output "environment" {
  description = "Name of the configured GitHub Environment. Must match the workflow's `environment:` key."
  value       = github_repository_environment.this.environment
}

output "configured" {
  description = <<-EOT
  Names of what was configured, so a plan/apply log tells you what the nightly run can see. Values
  are deliberately not exposed — the secrets are write-only as far as this module is concerned.
  EOT
  value = {
    variables = sort(keys(var.variables))
    secrets   = sort(tolist(local.secret_names))
  }
}
