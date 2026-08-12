/*
 * Build-from-source mode, the same shape every hub module's `e2e/` directory has: create the
 * definition from the source in this repo, order one building block against it, assert, destroy
 * both. It answers "does my code still work?" — chapter 05's question, now about code we own.
 *
 * The definition this creates is ephemeral. `tofu test` destroys it along with the building block,
 * which is why this is safe to point at a dev meshStack and not at production.
 */

variable "test_context" {
  description = <<-EOT
  Everything the test needs to know about the world it runs in, as ONE structured variable — same
  contract as chapter 03, so the same renderer feeds both.

  `git_ref` is the interesting field. The definition tells the meshStack runner which git ref to
  clone the implementation from, so testing a change to ./buildingblock means pointing this at the
  branch that change is on. Testing your working tree is not possible, and no amount of local
  `tofu apply` will tell you otherwise.
  EOT

  type = object({
    # meshStack workspace that owns the ephemeral definition and building block.
    workspace = string

    # Unique per run, so concurrent or repeated runs never collide on a display name.
    name_suffix = string

    # Git ref of THIS repository that the runner clones ../buildingblock from.
    git_ref = string
  })

  nullable = false
}

module "sum" {
  source = "../"

  meshstack = {
    owning_workspace_identifier = var.test_context.workspace
    tags                        = {}
  }

  repo = {
    git_ref = var.test_context.git_ref

    # Draft, so a test run never publishes a definition version anybody could order by accident.
    bbd_draft = true
  }
}

resource "meshstack_building_block" "this" {
  # Block until the run reaches a terminal state, so a failed run fails the test rather than
  # leaving the assertions to read a half-finished status.
  wait_for_completion = true

  spec = {
    # Both uuid and content_hash: a draft definition keeps its version uuid across edits, so
    # without the hash OpenTofu would see no change and never re-run the block.
    building_block_definition_version_ref = module.sum.building_block_definition.version_ref

    display_name = "e2e-test-sum-${var.test_context.name_suffix}"

    target_ref = {
      kind = "meshWorkspace"
      name = var.test_context.workspace
    }

    # Every value is `jsonencode`d — including numbers and strings — because meshStack inputs are
    # typed and carry their JSON representation.
    inputs = {
      a = { value = jsonencode(2) }
      b = { value = jsonencode(3) }
    }
  }

  timeouts = {
    create = "15m"
    delete = "15m"
  }
}
