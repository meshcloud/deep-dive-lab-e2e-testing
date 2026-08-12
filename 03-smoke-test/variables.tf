variable "test_context" {
  description = <<-EOT
  Everything the test needs to know about the world it runs in, as ONE structured variable.

  Why one grab-bag instead of a handful of flat variables: whatever renders this value — a shell
  script here, a terragrunt `generate` block in a foundation repo, a job step in CI — stays
  completely module-agnostic. It dumps the same JSON for every test module, and each module
  declares only the fields it actually reads. Object type conversion silently drops the rest.
  EOT

  type = object({
    # meshStack workspace the ephemeral building block is ordered into.
    workspace = string

    # Unique per run, so concurrent or repeated runs never collide on a display name.
    name_suffix = string

    # The already-deployed definition version to order against.
    bbd_version_ref = object({
      uuid = string
    })
  })

  nullable = false
}
