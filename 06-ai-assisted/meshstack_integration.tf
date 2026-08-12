variable "meshstack" {
  type = object({
    owning_workspace_identifier = string
    tags                        = optional(map(list(string)), {})
  })
  description = "Shared meshStack context. Tags are optional and propagated to building block definition metadata."
}

variable "repo" {
  type = object({
    url       = optional(string, "https://github.com/meshcloud/deep-dive-lab-e2e-testing.git")
    git_ref   = optional(string, "main")
    bbd_draft = optional(bool, true)
  })
  default = {}

  description = <<-EOT
  Where the building block implementation lives, from the runner's point of view.

  This is the inline counterpart of `variable "hub"` in a hub module: same job — pin the
  implementation to one reviewable git reference — except the repository is this one. `url` is a
  variable rather than a constant so a fork can point the definition at its own remote without
  editing code, and `git_ref` is a variable so the e2e test can point it at the branch under
  review instead of `main`.

  Note there is no `const = true` here, unlike `variable "hub"` in chapters 02 and 05. `const` is
  only needed to interpolate a value into a module `source`, which OpenTofu resolves at `init`.
  Nothing here does that: `git_ref` is data handed to meshStack, not a module source.
  EOT
}

output "building_block_definition" {
  description = "BBD is consumed in building block compositions, and by the e2e test in ./e2e."
  value = {
    uuid        = meshstack_building_block_definition.this.metadata.uuid
    version_ref = var.repo.bbd_draft ? meshstack_building_block_definition.this.version_latest : meshstack_building_block_definition.this.version_latest_release
    git_ref     = var.repo.git_ref
  }
}

resource "meshstack_building_block_definition" "this" {
  metadata = {
    owned_by_workspace = var.meshstack.owning_workspace_identifier
    tags               = var.meshstack.tags
  }

  spec = {
    display_name = "Sum Building Block"
    description  = "Adds two numbers and returns the sum. The smallest building block that is still a real building block."
    target_type  = "WORKSPACE_LEVEL"
    readme = chomp(<<-EOT
      The **Sum Building Block** takes two numbers, `a` and `b`, and returns `c = a + b`.

      ## 🎯 When to use it

      - To check that ordering a building block works at all, in a workspace where you do not want
        anything real to be created.
      - As the smallest possible template for a building block of your own.

      ## 💡 Usage examples

      Order it with `a = 2` and `b = 3`, and the `c` output is `5`. There is no example 2.
      EOT
    )
  }

  version_spec = {
    draft         = var.repo.bbd_draft
    deletion_mode = "DELETE"

    implementation = {
      terraform = {
        # The runner clones this repository at this ref and runs ./buildingblock. It has no view of
        # your working tree, so an unpushed change here changes nothing about a run.
        repository_url  = var.repo.url
        ref_name        = var.repo.git_ref
        repository_path = "06-ai-assisted/buildingblock"

        # Pin the version the runner uses, so a runner upgrade is a decision and not a surprise.
        # ./buildingblock/versions.tf must stay satisfiable by whatever this says.
        terraform_version = "1.11.0"
      }
    }

    # One entry per `variable` in ./buildingblock. Bound by name — nothing checks the two lists
    # against each other except a real building block run.
    inputs = {
      a = {
        assignment_type = "USER_INPUT"
        display_name    = "A"
        type            = "INTEGER"
      }
      b = {
        assignment_type = "USER_INPUT"
        display_name    = "B"
        type            = "INTEGER"
      }
    }

    # One entry per `output` in ./buildingblock that meshStack should surface. The assignment_type
    # is what meshPanel does with it: NONE just displays it, RESOURCE_URL becomes the link on the
    # building block, SUMMARY is rendered as markdown.
    outputs = {
      c = {
        assignment_type = "NONE"
        display_name    = "C"
        type            = "INTEGER"
      }
      resource_url = {
        assignment_type = "RESOURCE_URL"
        display_name    = "Resource URL"
        type            = "STRING"
      }
      summary = {
        assignment_type = "SUMMARY"
        display_name    = "Summary"
        type            = "STRING"
      }
    }
  }
}

terraform {
  required_version = ">= 1.12.0"

  required_providers {
    meshstack = {
      source  = "meshcloud/meshstack"
      version = ">= 0.21.0"
    }
  }
}
