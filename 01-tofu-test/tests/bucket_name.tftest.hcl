# Variables declared at file level apply to every `run` block below, so each run only has to
# say what is different about it. Right now there is exactly one run.
variables {
  workspace_identifier = "likvid-datascience"
  project_identifier   = "loan-scoring"
}

run "builds_a_name_the_service_accepts" {
  # `apply` really creates the resource and destroys it again on the way out. It is also
  # OpenTofu's default, so this line is here to be read, not because it is needed.
  command = apply

  # Assert on the resource, not on `local.bucket_name`: what matters is the name the bucket
  # actually got. This is the same rule the e2e chapters follow.
  assert {
    condition     = length(terraform_data.bucket.output) <= 24
    error_message = "bucket name must be at most 24 characters, got ${length(terraform_data.bucket.output)}: '${terraform_data.bucket.output}'"
  }
}

run "never_ends_in_a_separator" {
  command = apply

  assert {
    condition     = !endswith(terraform_data.bucket.output, "-")
    error_message = "bucket name must not end in '-', got '${terraform_data.bucket.output}'"
  }
}