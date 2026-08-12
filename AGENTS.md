# Agent instructions for this repository

This is a workshop repo teaching end-to-end testing for meshStack building blocks. Each numbered
directory is one chapter; each chapter's `README.md` states what it teaches.

Read this file before making changes. It exists so a coding agent can be useful here without
being told the same five things every session — which is the actual point of chapter 06.

## How to verify your work

Never hand back building block code you have not run. In this repo you can always run something:

```bash
tofu -chdir=01-tofu-test test          # no credentials, seconds
```

```bash
tofu fmt -check -recursive             # must pass; CI enforces it
```

```bash
tofu -chdir=<chapter> validate         # type-checks chapters that need credentials, without them
```

The e2e chapters need a live meshStack (`source bin/env.sh`) and take minutes per run. Their
non-credential inputs come from one var-file at the repo root, passed explicitly:

```bash
tofu -chdir=03-smoke-test test -var-file=../demo.tfvars            # foundation mode
```

Or render the test context with the script instead, which is what CI does and the only way to get
build-from-source mode:

```bash
./bin/test-context.sh 03-smoke-test 02-building-block-definition   # foundation mode
```

```bash
./bin/test-context.sh 05-e2e-test                                  # build-from-source mode
```

Prefer `tofu apply` over `tofu test` while iterating on a failing e2e test — `tofu test` destroys
the evidence on the way out. Always `tofu destroy` afterwards.

## Conventions in this repo

- **Never add a `provider "meshstack"` block.** The provider is configured from
  `MESHSTACK_ENDPOINT` / `MESHSTACK_API_KEY` / `MESHSTACK_API_SECRET` so the same directory runs
  locally and in CI.
- **`test_context` is one structured variable**, passed via a var-file — `../demo.tfvars` or a
  rendered `*.auto.tfvars.json` — never via `TF_VAR_test_context`, because `tofu test` does not
  type-decode complex `TF_VAR_*` values.
- **One var-file for the whole repo**: `/demo.tfvars` (gitignored, `demo.tfvars.example` committed),
  appended to chapter by chapter. Chapters declare only what they read, so undeclared-variable
  warnings from it are expected. Do not add per-chapter `demo.tfvars` files back. Note an explicit
  `-var-file` outranks an auto-loaded `*.auto.tfvars.json`, so never pass both.
- **`bbd_version_ref` is the only mode discriminator.** Set → foundation mode; null →
  build-from-source mode. Do not infer the mode from any other field.
- **`variable "hub"` is `const = true`** so `var.hub.git_ref` can be interpolated into a module
  `source`. Its value must come from a default, a `.tfvars` file or `TF_VAR_hub`.
- **Assertions reference the resource only** (`meshstack_building_block.this`), never
  `var.test_context` and never `module.*` — that is what lets one test file serve both modes.
- **Every `error_message` interpolates the value it asserted on.** A failure that does not print
  the actual value costs the reader a debugging session.
- **Assert `status.status == "SUCCEEDED"` first.** Every building block output is a JSON string:
  `jsondecode` once, twice for a `CODE` output.
- Comments explain *why*, not what. The READMEs carry the teaching; code comments carry the
  non-obvious constraint (e.g. why `depends_on` is needed, why `count = 0` still needs a valid
  `git_ref`).

## Upstream sources of truth

Building block modules themselves live in
[meshcloud/meshstack-hub](https://github.com/meshcloud/meshstack-hub). Its `e2e-test` skill is the
authoritative reference for the e2e invocation protocol; this repo is a stripped-down teaching
version of it. When the two disagree, the hub is right.
