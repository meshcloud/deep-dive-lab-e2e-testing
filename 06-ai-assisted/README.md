# Chapter 06 — write your own building block, with an agent

**Time: ~10 min. Credentials needed: meshStack API key. Runtime: ~2 min per test run.**

Chapters 02–05 tested somebody else's building block. This one is ours, written from scratch, and
it mirrors the hub layout exactly — because the layout is the interface, and an agent that knows
the layout can be handed "add a building block that does X" and produce something reviewable.

The building block adds two numbers. `a + b = c`. That is not a joke about scope: it is the
smallest thing that still exercises every part of the contract — an input binding, an output
binding, a `RESOURCE_URL`, a `SUMMARY`, a definition, a runner, and a test that can go red.

## The layout

Straight out of [meshstack-hub](https://github.com/meshcloud/meshstack-hub), minus the `backplane/`
tier, which exists for cloud-side setup and an addition has none:

```
06-ai-assisted/
├── meshstack_integration.tf   # the definition — what meshStack knows about the block
├── buildingblock/             # the implementation — what the runner clones and applies
│   ├── main.tf
│   ├── variables.tf           # a, b
│   ├── outputs.tf             # c, resource_url, summary
│   ├── versions.tf
│   └── README.md
└── e2e/                       # the test — build from source, order, assert, destroy
    ├── main.tf
    ├── terraform.tf
    └── tests/sum.tftest.hcl
```

Three directories, three audiences. `buildingblock/` is run by meshStack, never by you.
`meshstack_integration.tf` is applied by a platform pipeline. `e2e/` is run by CI and by you.

## The thing that catches everyone once

The definition does not contain your code. It contains **coordinates to your code**:

```hcl
implementation = {
  terraform = {
    repository_url  = var.repo.url
    ref_name        = var.repo.git_ref
    repository_path = "06-ai-assisted/buildingblock"
  }
}
```

The runner clones that repository at that ref. Your working tree does not exist as far as it is
concerned. **An unpushed change to `buildingblock/` changes nothing about a building block run** —
you will edit a file, re-run the test, watch it fail identically, and lose twenty minutes.

Which is why `git_ref` is an input to the test and not a constant. Testing a change to the
implementation means pushing the branch and pointing the test at it:

```hcl
test_context = {
  workspace   = "your-workspace"
  name_suffix = "test"
  git_ref     = "feat/my-change"      # ← the branch you just pushed
}
```

This is the same discipline as pinning `hub.git_ref` in chapters 02 and 05, seen from the other
side: there you pin someone else's code so it cannot move under you; here you move your own code
deliberately, one ref at a time.

## Run it

```bash
source bin/env.sh
```

```bash
cp 06-ai-assisted/e2e/auto.tfvars.example 06-ai-assisted/e2e/.auto.tfvars   # then edit it
```

```bash
tofu -chdir=06-ai-assisted/e2e init
```

```bash
tofu -chdir=06-ai-assisted/e2e test
```

The test creates a **draft** definition, orders one building block with `a = 2`, `b = 3`, asserts
`c == 5`, and destroys both. Nothing survives the run — that is build-from-source mode, and it is
why this is safe against a dev meshStack and not something you point at production.

## Try breaking it

Three failures, each teaching something different:

**Break the arithmetic.** Change `outputs.tf` to `var.a + var.b + 1`, push, re-run. Red, with the
actual value in the message. This is the failure a unit test would also have caught.

**Break the binding.** Rename `variable "b"` to `variable "second"` in `buildingblock/` but leave
`b` in the definition's `inputs`. Push, re-run. The definition still deploys fine; the *run* fails
with `No value for required variable`. Nothing checks the two lists against each other but a real
run — this is the failure only an e2e test catches.

**Forget to push.** Make any change and re-run without pushing. Green, and meaningless. Sit with
that one for a second; it is the failure mode that costs the most time in practice.

## What to take away

**The hub layout is a contract, not a filing preference.** `buildingblock/` + optional
`backplane/` + `e2e/` + `meshstack_integration.tf` is what lets one renderer, one CI matrix and one
test-context shape serve 50+ modules. Following it for your own inline blocks means the tooling in
chapters 03–05 works on them unmodified.

**The definition and the implementation are two artifacts that drift.** Inputs bind by name and
nothing validates the pair. Every building block therefore needs at least one real run in CI, and
that run is cheaper than the outage.

**`e2e/` ships with the module.** In the hub, the team that maintains a building block maintains
its test, and every foundation that consumes the module gets the test for free — as a smoke test in
foundation mode, against their own deployed definition. Writing the test in the same PR as the
building block is what makes that possible.

**Ship the agent instructions with the repo.** [`AGENTS.md`](../AGENTS.md) at the root is why the
files in this chapter came out in the right shape: it states the layout, the conventions
(`jsonencode` every input, assert status first, interpolate the actual value into every
`error_message`) and — most importantly — how to verify the work. An agent that can run
`tofu -chdir=06-ai-assisted/e2e test` checks its own answer instead of handing you a plausible one.

---

Back to the [start](../README.md).
