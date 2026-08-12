terraform {
  required_version = ">= 1.12.0"

  required_providers {
    meshstack = {
      source  = "meshcloud/meshstack"
      version = ">= 0.21.0"
    }
  }
}

# No `provider "meshstack"` block anywhere in this repo — the provider reads its configuration
# from MESHSTACK_ENDPOINT / MESHSTACK_API_KEY / MESHSTACK_API_SECRET. That keeps credentials out
# of the code and lets the exact same directory run locally and in CI. See ../bin/env.sh.example.
