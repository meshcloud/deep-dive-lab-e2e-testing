# Chapter 01 — the `tofu test` loop

**Time: ~10 min. Credentials needed: none.**

One module, one test file, one loop: run it red, make it green, add the next assertion. That
loop is the whole chapter — everything later in this workshop is the same loop with slower
`run` blocks.

[`main.tf`](main.tf) turns a meshStack workspace identifier and project identifier into an
object storage bucket name, and creates a `terraform_data` resource under that name. It declares
no providers — `terraform_data` is built into OpenTofu — so this suite really creates and
destroys a resource, with no credentials and in under a second.

There is nothing to configure either: the test file carries its own inputs. Every chapter after
this one needs to know something about *your* meshStack, and gets it from a `.auto.tfvars` file
sitting in the chapter directory — chapter 02 sets the first one up.

## Red

```bash
tofu -chdir=01-tofu-test init
```

```bash
tofu -chdir=01-tofu-test test
```

```
tests/bucket_name.tftest.hcl... fail
  run "builds_a_name_the_service_accepts"... fail

  on tests/bucket_name.tftest.hcl line 16, in run "builds_a_name_the_service_accepts":
  16:     condition     = length(terraform_data.bucket.output) <= 24
    ├────────────────
    │ terraform_data.bucket.output is "likvid-datascience-loan-scoring"

bucket name must be at most 24 characters, got 31:
'likvid-datascience-loan-scoring'

Failure! 0 passed, 1 failed.
```

OpenTofu prints the value that broke the assertion, so you already know what to fix.

## Green

Truncate `local.bucket_name` in [`main.tf`](main.tf) to the 24 characters the service accepts,
then re-run.

<details>
<summary>Solution</summary>

```hcl
bucket_name = substr(lower("${var.workspace_identifier}-${var.project_identifier}"), 0, 24)
```

</details>

```
Success! 1 passed, 0 failed.
```

## Add a second assertion

Green does not mean correct — it means correct about the one thing you asserted. Truncating at
a fixed offset can cut the name on a hyphen, and the object storage service rejects a name that
ends in a separator. Add a second `run` block to
[`tests/bucket_name.tftest.hcl`](tests/bucket_name.tftest.hcl):

```hcl
run "never_ends_in_a_separator" {
  command = apply

  assert {
    condition     = !endswith(terraform_data.bucket.output, "-")
    error_message = "bucket name must not end in '-', got '${terraform_data.bucket.output}'"
  }
}
```

Re-run: red again, on the name you just made "correct".

```
  │ terraform_data.bucket.output is "likvid-datascience-loan-"
```

Make it green a second time.

<details>
<summary>Solution</summary>

```hcl
bucket_name = trimsuffix(substr(lower("${var.workspace_identifier}-${var.project_identifier}"), 0, 24), "-")
```

</details>

## Try it: `command = plan`

Change the first `run` to `command = plan` and watch it break in a completely different way:

```
Error: Unknown condition run

  16:     condition     = length(terraform_data.bucket.output) <= 24
    ├────────────────
    │ terraform_data.bucket.output is a string

Condition expression could not be evaluated at this time.
```

Not a failed assertion — an assertion that could not be *evaluated*. `plan` never creates the
resource, so its `output` attribute is still unknown. Anything you want to assert about a
resource that exists needs `command = apply`. Put it back before moving on.

## What to take away

**`apply` is the default, and for a reason.** `tofu test` creates the resources, runs your
assertions against what actually came into existence, then destroys them again on the way out.
`command = plan` is the cheap variant for modules that only compute values — it needs no state
and no credentials, but it can only see what is knowable before anything exists.

**Assert on the resource, not on the local.** `terraform_data.bucket.output` is what the bucket
got; `local.bucket_name` is only what the module intended. The e2e chapters follow the same
rule against `meshstack_building_block.this`, and it is what lets one test file cover several
deployment modes.

**File-level `variables` are your fixture.** Declared once at the top of the `.tftest.hcl` file,
they apply to every `run`, and a `run` can override just what makes it different. That works here
because the inputs are made up. From chapter 02 on they describe a real meshStack, so they move out
of the test file and into a var-file — same idea, one indirection further out.

**Every `error_message` prints the value it asserted on.** `got '${terraform_data.bucket.output}'`
is the difference between a five-second fix and a debugging session.

**A green suite is a statement about your assertions, not about your module.** The second
assertion was the interesting one, and it only existed because someone thought of it.

## Going further (not covered live)

- `expect_failures = [var.environment]` inverts a run, so it passes *because* an input was
  rejected. That is how you test variable validation.
- `mock_provider` unit-tests modules that *do* declare providers, with canned resource
  attributes instead of credentials.
- `run` blocks can chain: a later run can reference `run.<earlier>.<output>`.

---

Next: [Chapter 02 — deploy a building block definition from the hub](../02-building-block-definition/README.md)
