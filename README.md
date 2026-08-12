# Deep Dive Lab: End-to-End Testing for Building Blocks

A hands-on companion repo for the meshcloud **Deep Dive Lab** — a relaxed, one-hour session where
we walk through a single feature step by step, with space to try it out, experiment and ask
questions as we go.

**Goal:** take away practical patterns for automating tests of your own building block definitions,
drawn from the engineering workflow behind [meshStack hub](https://hub.meshcloud.io).

Each directory is one chapter. Follow them in order, or jump to the one you came for.

| Chapter | What you do | Credentials | Runtime |
|---|---|---|---|
| [01 — `tofu test`](01-tofu-test/) | red, green, one more assertion, on a provider-free module | none | seconds |
| [02 — Building block definition](02-building-block-definition/) | deploy a hub BBD into your meshStack | meshStack | ~1 min |
| [03 — Smoke test](03-smoke-test/) | order an ephemeral building block against it, and assert | meshStack | ~3 min |
| [04 — CI](04-ci/) | put that test on a nightly cron in GitHub Actions, config included | GitHub | ~2 min |
| [05 — E2E test](05-e2e-test/) | build the definition from source too, and tear it all down | meshStack | ~4 min |
| [06 — AI-assisted](06-ai-assisted/) | write your own building block with an agent, hub layout and all | meshStack | ~2 min |

## The two modes, up front

The one idea worth having before you start. There are two useful ways to test a building block, and
they answer different questions:

```
                    ┌─────────────────────────────────────────────────────────┐
  build-from-source │  create BBD from hub source  →  order BB  →  destroy    │  chapter 05
   "does my code    │                                                          │
    still work?"    │  target: dev meshStack, nothing survives the run         │
                    └─────────────────────────────────────────────────────────┘

                    ┌─────────────────────────────────────────────────────────┐
        foundation  │  BBD already deployed  →  order BB  →  destroy BB        │  chapter 03
   "can an app team │                                                          │
    order this      │  target: production, the definition is left alone        │
    right now?"     └─────────────────────────────────────────────────────────┘
```

The same test file serves both. One field — `bbd_version_ref` — decides which mode you are in.

## Prerequisites

**OpenTofu ≥ 1.12** (or Terraform ≥ 1.15) — earlier versions lack `const` variables.

```bash
brew install opentofu
```

**`jq`**, for lifting a uuid out of a chapter's outputs.

**A meshStack workspace and API key** for chapters 02, 03 and 05. Chapter 01 needs nothing at all,
so you can follow that one on a plane.

```bash
cp bin/env.sh.example bin/env.sh   # fill in your values, then:
source bin/env.sh
```

`bin/env.sh` holds credentials only. Everything else — your workspace, the definition version the
tests order against — goes in a **`.auto.tfvars` file inside the chapter that reads it**, copied
from the `auto.tfvars.example` next to it and gitignored. OpenTofu auto-loads any file whose name
ends in `.auto.tfvars` for both `apply` and `test`, so there is no flag to pass and no shared
grab-bag file to keep in sync. Chapter 02 sets up the first one; chapter 03 fills its own from
chapter 02's outputs; chapter 04 commits a `smoke.tfvars` for CI to pass explicitly.

**`terragrunt` and a `gh auth login`** only if you want to apply chapter 04's config module against
a repo of your own. Reading that chapter needs nothing.

## What this repo is not

This is the **stripped-down version** of meshcloud's internal test infrastructure — the essentials,
laid out so you can read all of it in an hour. The real thing adds discovery across two repos,
Vault-sourced credentials, a provider built from source, cloud fixtures per platform, and a
scorecard over 50+ modules.

Everything here is reusable. But the point is the *pattern*, and the pattern fits in these six
directories.

## Where the real code lives

- [meshcloud/meshstack-hub](https://github.com/meshcloud/meshstack-hub) — the building block module
  registry. Every module ships its own `e2e/` test directory.
- [likvid-bank/likvid-cloudfoundation](https://github.com/likvid-bank/likvid-cloudfoundation) — a
  public foundation repo running foundation-mode tests for real.
- [meshcloud/terraform-provider-meshstack](https://github.com/meshcloud/terraform-provider-meshstack)
  — the provider that makes all of this expressible as Terraform.
