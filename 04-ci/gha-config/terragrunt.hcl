# Terragrunt wrapper for this module: takes its inputs from the environment you already have
# loaded, so `source bin/env.sh && terragrunt apply` is the whole invocation. This is the one
# directory in the repo with no `.auto.tfvars` next to it — what it configures in GitHub *is* the
# environment, so reading it from anywhere else would be a second source of truth.
#
# This file is the meshStack-aware half of the chapter. The module next to it only knows "write
# these variables and these secrets to this environment"; everything about *which* names the
# nightly workflow reads, and where their values come from, lives here. Adding an input to the
# nightly run is one line below and one line in the workflow yaml.
#
# There is no `terraform { source = ... }` block on purpose — the .tf files live right here, so
# Terragrunt runs them in place.
#
# The GitHub provider uses github cli authentication, which we assume you have installed

locals {
  # No env var carries the repo name, and hardcoding it would defeat the point of this file.
  # Override with GITHUB_REPOSITORY_NAME if your fork is named differently from the checkout dir.
  repository = get_env("GITHUB_REPOSITORY_NAME", basename(get_repo_root()))
}

inputs = {
  repository = local.repository

  variables = {
    MESHSTACK_ENDPOINT    = get_env("MESHSTACK_ENDPOINT")
    MESHSTACK_API_KEY     = get_env("MESHSTACK_API_KEY")
  }

  secrets = {
    MESHSTACK_API_SECRET = get_env("MESHSTACK_API_SECRET")
  }
}
