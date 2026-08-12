---
name: Sum Building Block
supportedPlatforms:
  - meshstack
description: |
  Adds two numbers and returns the sum. The smallest building block that is still a real building
  block — inputs, an output, a resource_url and a summary.
---

# Sum Building Block

Takes two numbers, `a` and `b`, and returns `c = a + b`.

That is the whole thing. It provisions no infrastructure and needs no credentials, which makes it
the cheapest possible subject for the two questions this workshop is about: *does the definition
still deploy?* and *can an app team still order it?*

## Inputs

| Input | Type | Assignment | Description |
|---|---|---|---|
| `a` | `INTEGER` | `USER_INPUT` | First summand |
| `b` | `INTEGER` | `USER_INPUT` | Second summand |

## Outputs

| Output | Type | Assignment | Description |
|---|---|---|---|
| `c` | `INTEGER` | `NONE` | The sum |
| `resource_url` | `STRING` | `RESOURCE_URL` | Link meshPanel shows app teams |
| `summary` | `STRING` | `SUMMARY` | Markdown rendered as this instance's README |

## How this directory is run

You never run it. meshStack's building block runner clones the repository named in the definition
(`repository_url` / `ref_name` in [`../meshstack_integration.tf`](../meshstack_integration.tf)),
changes into `repository_path`, and runs `init` + `apply` there with the inputs bound to the
`variable` blocks by name.

Two consequences worth internalising:

- **Your working tree is invisible to the runner.** Uncommitted, unpushed changes to this directory
  change nothing about a building block run. The `git_ref` in the definition is the source of
  truth, and that is exactly why [`../e2e/`](../e2e/) takes it as an input.
- **Inputs bind by name.** A `variable` here with no matching input in the definition is a
  `No value for required variable` at apply time; an input in the definition with no matching
  variable is silently ignored. Nothing checks the two against each other but a real run.
