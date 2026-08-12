terraform {
  required_version = ">= 1.12.0"

  required_providers {
    github = {
      source = "integrations/github"

      # >= 6.13: earlier versions have no `value` on github_actions_environment_secret, only the
      # now-deprecated `plaintext_value`.
      version = ">= 6.13.0"
    }
  }
}
