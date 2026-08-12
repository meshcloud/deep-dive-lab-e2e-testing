# ─────────────────────────────────────────────────────────────────────────────────────────────
# Uncomment this file (select all → toggle comment) and `tofu apply` again to order a building
# block from the definition above — the same thing an app team does from meshPanel, expressed as
# code. This is the seed of every e2e test in this repo: chapters 03 and 04 do exactly this,
# they just wrap it in `tofu test` so it also gets torn down again.
#
# Note that `content_hash` is what makes a *draft* definition re-runnable: a draft keeps the same
# version uuid when you edit it, so without the hash OpenTofu would see no change and never
# re-run the block.
# ─────────────────────────────────────────────────────────────────────────────────────────────

# resource "meshstack_building_block" "demo" {
#   # Block until the run reaches a terminal state, so a failed run fails the apply.
#   wait_for_completion = true
#
#   spec = {
#     building_block_definition_version_ref = {
#       uuid         = module.noop.building_block_definition.version_ref.uuid
#       content_hash = module.noop.building_block_definition.version_ref.content_hash
#     }
#
#     display_name = "deep-dive-lab-noop"
#
#     # The noop definition is WORKSPACE_LEVEL, so the target is a workspace, not a tenant.
#     target_ref = {
#       kind = "meshWorkspace"
#       name = var.meshstack.owning_workspace_identifier
#     }
#
#     # One entry per USER_INPUT the definition declares. Every value is `jsonencode`d — including
#     # strings — because meshStack inputs are typed and carry their JSON representation.
#     inputs = {
#       flag              = { value = jsonencode(true) }
#       num               = { value = jsonencode(1) }
#       text              = { value = jsonencode("Hello, Deep Dive Lab!") }
#       single_select     = { value = jsonencode("single1") }
#       multi_select      = { value = jsonencode(["multi1", "multi2"]) }
#       multi_select_json = { value = jsonencode(["multi2", "multi1"]) }
#
#       # Sensitive inputs go under `sensitive` instead of `value`. They are encrypted to the
#       # runner's public key; only a sha256 hash of the value ends up in state.
#       sensitive_text = { sensitive = { secret_value = "Hidden value" } }
#     }
#   }
#
#   # The noop building block installs the AWS CLI in its pre-run script, so a run takes a couple
#   # of minutes. Tune these to your own runner's typical duration (default is 30m).
#   timeouts = {
#     create = "15m"
#     update = "15m"
#     delete = "15m"
#   }
# }
#
# output "building_block" {
#   value = {
#     uuid    = meshstack_building_block.demo.metadata.uuid
#     status  = meshstack_building_block.demo.status.status
#     summary = jsondecode(meshstack_building_block.demo.status.outputs["summary"].value)
#   }
# }
