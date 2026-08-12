locals {
  # The entire "provisioning" this building block performs.
  c = var.a + var.b
}

# An addition has nothing to create, but a building block that manages no resource at all produces
# an empty plan — and an empty plan makes "ran and computed this" indistinguishable from "never
# ran". Parking the result in state means changing an input shows up as a real resource change in
# the run log, and lets the `c` output be read back off the applied resource rather than recomputed.
resource "terraform_data" "sum" {
  input = local.c
}
