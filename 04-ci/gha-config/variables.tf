variable "repository" {
  description = "Name of the GitHub repository the nightly workflow lives in, without the owner."
  type        = string
  nullable    = false
}

variable "environment" {
  description = <<-EOT
  Name of the GitHub Environment to create and configure. The workflow's `environment:` key must
  match this exactly — a typo there gets you an empty `vars` context, not an error.
  EOT
  type        = string
  default     = "meshstack"
  nullable    = false
}

variable "variables" {
  description = <<-EOT
  Actions *variables* to set on the environment, as name => value.

  Deliberately not `sensitive`: variables print in run logs, which is the point — this is where
  everything you might have to debug from a failed nightly run belongs.

  The module does not know what any of these names mean. `terragrunt.hcl` decides that.
  EOT
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "secrets" {
  description = <<-EOT
  Actions *secrets* to set on the environment, as name => value. Same deal as `variables`, minus
  the visibility.

  To leave a secret unset, leave its key out of the map rather than passing an empty string: a
  step gated on `env.SOME_SECRET != ''` treats absent and empty alike, but an empty secret is
  still a resource this module then has to own.
  EOT
  type        = map(string)
  default     = {}
  nullable    = false
  sensitive   = true
}
