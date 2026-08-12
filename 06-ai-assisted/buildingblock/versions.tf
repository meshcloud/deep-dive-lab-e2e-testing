# Deliberately lower than the >= 1.12.0 the rest of this repo requires. This directory is not run
# by you — it is cloned and run by the meshStack building block runner, whose Terraform version is
# pinned in the definition (`terraform_version` in ../meshstack_integration.tf). Requiring a
# version the runner does not have is a failure you only discover in a real run.
terraform {
  required_version = ">= 1.5.0"
}
