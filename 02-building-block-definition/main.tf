/*
 * This is the "platform engineering" side of a building block: the module below creates a
 * meshStack building block definition (BBD) that app teams can then order.
 *
 * We are not writing that definition ourselves. `modules/meshstack/noop` in the hub already
 * ships a `meshstack_integration.tf` — a ready-to-use Terraform root that wires the building
 * block into a meshStack instance. Sourcing it as a module is all the integration work there is.
 *
 * https://hub.meshcloud.io/platforms/meshstack/definitions/meshstack-noop
 */

module "noop" {
  # `?ref=${var.hub.git_ref}` is why `variable "hub"` is declared `const = true`: OpenTofu
  # resolves module sources during `init`, before any dynamic value exists. `const` marks the
  # variable for that early evaluation. Pin it to a hub tag or SHA for anything you care about.
  source = "github.com/meshcloud/meshstack-hub//modules/meshstack/noop?ref=${var.hub.git_ref}"

  hub       = var.hub
  meshstack = var.meshstack
}
