/*
 * meshStack hands you a workspace identifier and a project identifier; the object storage
 * service wants a single lowercase bucket name of at most 24 characters.
 *
 * `terraform_data` stands in for the bucket. It is OpenTofu's built-in managed resource: no
 * provider, no credentials, no network — but it does have to be *created*, so this module has
 * a real create/destroy lifecycle to test against.
 */

locals {
  bucket_name = lower("${var.workspace_identifier}-${var.project_identifier}")
}

resource "terraform_data" "bucket" {
  input = local.bucket_name
}
