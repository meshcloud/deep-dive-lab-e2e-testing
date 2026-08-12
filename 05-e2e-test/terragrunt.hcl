terraform {
  source = "git::https://github.com/meshcloud/meshstack-hub.git//modules/meshstack/noop/e2e?ref=main"
}


# `tofu test` does not type-decode complex TF_VAR_* env vars — use auto.tfvars.json so the
# structured `test_context` variable arrives correctly typed in test assertion scope.
generate "smoke_tfvars" {
  path              = "smoke.auto.tfvars.json"
  if_exists         = "overwrite"
  disable_signature = true
  contents = jsonencode({
    test_context = {
      workspace       = "deepdivelab26081"
      name_suffix     = run_cmd("--terragrunt-quiet", "date", "-u", "+%Y%m%d%H%M%S")
      hub_git_ref     = "main"
      project         = "ignored"
    }
  })
}