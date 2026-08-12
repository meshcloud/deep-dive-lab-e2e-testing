variable "meshstack" {
  type = object({
    owning_workspace_identifier = string
    tags                        = optional(map(list(string)), {})
  })
  description = "Shared meshStack context: which workspace owns the building block definition."
}

variable "hub" {
  type = object({
    git_ref   = optional(string, "main")
    bbd_draft = optional(bool, true)
  })

  # Required so `var.hub.git_ref` can be interpolated into a module `source` (see main.tf).
  # A `const` variable's value must come from a default, a .tfvars file or TF_VAR_*, and it may
  # not be `sensitive` or `ephemeral`.
  const = true

  default = {
    git_ref   = "main"
    bbd_draft = true
  }

  description = <<-EOT
  `git_ref`: hub release reference — a tag (e.g. 'v1.2.3'), branch or commit SHA of meshstack-hub.
  `bbd_draft`: if true, the building block definition version stays in draft mode.
  EOT
}
