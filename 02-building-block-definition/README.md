# Chapter 02 — deploy a building block definition from the hub

**Time: ~10 min. Credentials needed: meshStack API key.**

Before you can e2e test a building block, something has to *be* there. This chapter deploys a
building block definition (BBD) into your meshStack, using a module straight out of
[meshstack-hub](https://github.com/meshcloud/meshstack-hub).

We use [`meshstack/noop`](https://hub.meshcloud.io/platforms/meshstack/definitions/meshstack-noop)
— the hub's reference building block. It exercises meshStack's complete Terraform interface
(every input type, file inputs, user permissions injection, pre-run scripts) and provisions no
real infrastructure. No cloud credentials, nothing to clean up, nothing to pay for. Perfect for a
workshop, and genuinely useful as the canary in your own meshStack.

## Set up your environment

```bash
cp bin/env.sh.example bin/env.sh   # then fill in your values
```

```bash
source bin/env.sh
```

Three variables, all of them credentials, all read directly by the meshStack provider:

| Variable | What it is |
|---|---|
| `MESHSTACK_ENDPOINT` | e.g. `https://federation.my.meshcloud.io` |
| `MESHSTACK_API_KEY` | API key of a service user with building block permissions |
| `MESHSTACK_API_SECRET` | its secret |

There is deliberately **no `provider "meshstack"` block** anywhere in this repo. Env-var
configuration is what lets chapters 03 and 04 run unchanged on your laptop and in GitHub Actions.

`bin/env.sh` holds credentials and nothing else. Everything that is *not* a credential lives in a
var-file **in the chapter that reads it**. This chapter needs one thing — which workspace owns the
definition:

```bash
cp 02-building-block-definition/auto.tfvars.example 02-building-block-definition/.auto.tfvars
```

```hcl
meshstack = {
  owning_workspace_identifier = "your-workspace"
}
```

The filename is doing real work. OpenTofu auto-loads every var-file whose name **ends in**
`.auto.tfvars`, for `apply` and `test` alike, so there is no `-var-file` flag to forget and no way
for two chapters to disagree about which file they read. `.auto.tfvars` is gitignored — your
workspace identifier stays yours — and the committed `auto.tfvars.example` next to it is the
template.

> **The trap in that sentence: *ends in*.** A file called `auto.tfvars`, without the leading dot,
> is not auto-loaded — OpenTofu matches the suffix `.auto.tfvars` and `auto.tfvars` does not have
> it. Nothing warns you. You get an interactive prompt for `var.meshstack`, or in CI a bare
> `No value for required variable`, while the file with the answer in it sits right there.

## Deploy it

```bash
tofu -chdir=02-building-block-definition init
```

```bash
tofu -chdir=02-building-block-definition apply
```

No `-var-file`: `-chdir` makes the chapter the working directory, and the `.auto.tfvars` you just
wrote is in it.

Then go look at it in meshPanel: your workspace now has a **meshStack NoOp Building Block**
definition, in draft. `tofu output` gives you its coordinates:

```bash
tofu -chdir=02-building-block-definition output building_block_definition
```

## The one line that does the work

```hcl
module "noop" {
  source = "github.com/meshcloud/meshstack-hub//modules/meshstack/noop?ref=${var.hub.git_ref}"

  hub       = var.hub
  meshstack = var.meshstack
}
```

Every hub module ships a `meshstack_integration.tf` at its root — a ready-to-use Terraform root
module that declares the `meshstack_building_block_definition`, its inputs, outputs, readme and
its implementation reference back into the hub. Your foundation repo doesn't reimplement any of
that; it sources the module and passes two variables.

## Your turn: order a building block

[`building_block.tf`](building_block.tf) is a complete, commented-out `meshstack_building_block`
resource. Uncomment it (select all → toggle comment in your editor) and apply again:

```bash
tofu -chdir=02-building-block-definition apply
```

`wait_for_completion = true` blocks until the run reaches a terminal state, so a failed building
block run fails your apply. Watch the run in meshPanel while it goes. It takes a couple of minutes
— the noop building block's pre-run script installs the AWS CLI to demonstrate that it can.

**This is the whole idea behind the next chapter.** You just asserted, in code, that the
definition you deployed can actually be ordered and runs successfully. Chapter 03 takes this exact
resource and puts it inside `tofu test`, which adds the two things `apply` doesn't give you:
assertions on the outputs, and automatic teardown. Chapter 04 then runs that nightly.

## What to take away

**Inputs live next to the code that reads them.** One `.auto.tfvars` per chapter, each declaring
only what that chapter uses. The alternative — one var-file for the whole repo — means every
chapter is handed values it does not declare, so every run is noisy with
`Value for undeclared variable` warnings and nobody can tell which input belongs to what. Chapter
03 goes one step further and fills its file from *this* chapter's outputs, which is the same
dependency a real foundation repo wires between deployment units.

**`const = true` on `variable "hub"` is not decoration.** Module `source` strings are resolved
during `init`, before any dynamic value exists. `const` marks a variable for that early
evaluation so `?ref=${var.hub.git_ref}` works. The payoff: one variable pins the building block
implementation, the integration module and (for hub modules that have one) the backplane, all to
the same hub revision.

**Pin `git_ref` for anything real.** `main` is right for a workshop and wrong for production. Use
a tag or SHA, and treat bumping it as a normal reviewed change — that is your building block's
release process.

**Draft vs released matters for re-runs.** `bbd_draft = true` keeps the definition in draft, which
means its version uuid stays stable while you edit it. Wire `content_hash` alongside `uuid` (see
[`building_block.tf`](building_block.tf)) so OpenTofu notices draft edits and re-runs the block.

---

Next: [Chapter 03 — smoke test what you deployed](../03-smoke-test/README.md)
