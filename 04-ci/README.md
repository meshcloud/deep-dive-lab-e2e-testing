# Chapter 04 — put the smoke test on a nightly cron

**Time: ~10 min. Mostly reading one workflow file. Applying the config module needs a GitHub login.**

A test is only worth writing if it runs without you. Chapter 03's smoke test takes three minutes
and needs no human, which makes it exactly the kind of thing a schedule should own.

Moving it to GitHub Actions means supplying the two things your laptop already had and a fresh
checkout does not:

| What CI is missing | Where this chapter puts it |
|---|---|
| the test's inputs — your `.auto.tfvars` is gitignored | a committed [`03-smoke-test/smoke.tfvars`](../03-smoke-test/smoke.tfvars) |
| credentials | a GitHub Environment, configured as code by [`gha-config/`](gha-config/) |

## The inputs: commit them

`.auto.tfvars` is gitignored, so a runner cloning this repo finds no `test_context` at all. The
non-secret half of that context — a workspace identifier and a definition version uuid — is not
something you need to hide, so commit it under a name CI passes explicitly:

```hcl
# 03-smoke-test/smoke.tfvars
test_context = {
  workspace   = "deepdivelab26081"
  name_suffix = "test"

  bbd_version_ref = {
    uuid = "b907ec36-a80e-4bac-9ec7-4e1058a03941"
  }
}
```

```yaml
- name: tofu test
  run: |
    tofu -chdir=03-smoke-test init -var-file=smoke.tfvars
    tofu -chdir=03-smoke-test test -var-file=smoke.tfvars
```

Two decisions are packed into that filename, and both are about staying out of your way:

**It is not called `*.auto.tfvars`.** So it never auto-loads. When you run chapter 03 locally your
own `.auto.tfvars` is what gets read, and the committed file changes nothing about your loop — even
though both files sit in the same directory declaring the same variable.

**CI passes it explicitly, and an explicit `-var-file` outranks an auto-loaded one.** That is also
how you reproduce a red nightly run on your laptop: same flag, same inputs, your `.auto.tfvars`
ignored for that one command.

```bash
tofu -chdir=03-smoke-test test -var-file=smoke.tfvars
```

Committing test inputs sounds like a shortcut and is actually the feature: the definition version
the nightly suite tests against is now a reviewable line of code. Bumping it is a pull request, and
`git log` answers "since when has it been testing *that*?".

> `init` takes `-var-file` too, which looks redundant here — chapter 03 has no `const` variable, so
> nothing is needed at init time. It is in the workflow so the pair of lines stays copy-pasteable to
> chapter 05, where `var.hub.git_ref` is interpolated into a module `source` and `init` genuinely
> cannot resolve it without the file.

## The credentials: configure the environment as code

The workflow reads them from a GitHub Environment called `meshstack`:

| Kind | Name | Value |
|---|---|---|
| variable | `MESHSTACK_ENDPOINT` | e.g. `https://federation.my.meshcloud.io` |
| variable | `MESHSTACK_API_KEY` | API key uuid |
| secret | `MESHSTACK_API_SECRET` | the API key secret |

Clicking those into the GitHub UI works once and is forgotten by the time you need a second repo.
[`gha-config/`](gha-config/) is the same thing as code: a small module that writes variables and
secrets to an environment, and a [`terragrunt.hcl`](gha-config/terragrunt.hcl) that takes their
values from the shell you already have loaded.

```bash
source bin/env.sh
```

```bash
cd 04-ci/gha-config && terragrunt apply
```

The GitHub provider authenticates through the `gh` CLI, so `gh auth login` is the only extra
prerequisite. Note the split of responsibilities: the module knows "write these names to this
environment" and nothing about meshStack; `terragrunt.hcl` is where the knowledge that the nightly
workflow wants `MESHSTACK_API_KEY` lives. Adding an input to the nightly run is one line there and
one line in the workflow yaml.

**Endpoint and key are variables, not secrets, on purpose.** Variables print in run logs, which is
what you want at 8am in front of a failed nightly run. Only the secret is secret.

This is also the one directory in the repo that reads no var-file. What it configures *is* the
environment, so taking its values from anywhere but the environment would be a second source of
truth.

## Read the workflow

[`nightly-e2e-tests.yml`](../.github/workflows/nightly-e2e-tests.yml) is short. The parts that are
there for a reason:

```yaml
on:
  # Commented out for the workshop: we only run this by hand. Uncomment to get the nightly run.
  # schedule:
  #   - cron: "17 4 * * 1-5"
  workflow_dispatch:
```

The schedule is commented out here so a room full of forks does not order a building block into the
same shared workspace every morning. Uncomment it and the reasoning below is what you get:

**Off-peak, not on the hour, on weekdays.** `:17` because the top of the hour is when everyone
else's cron fires and GitHub queues you. Weekdays because a red build nobody reads until Monday is a
red build that stays red. `workflow_dispatch` because a nightly test you cannot trigger by hand is a
nightly test you cannot debug.

```yaml
concurrency:
  group: smoke-tests
  cancel-in-progress: false
```

**Serialise anything that touches shared state.** These runs create real objects in a real
workspace under a fixed display name. Without this, a manual dispatch races the scheduled run into a
name collision that looks like a product bug and isn't. `cancel-in-progress: false` because
cancelling a run mid-apply is how you leak a building block.

```yaml
env:
  MESHSTACK_API_SECRET: ${{ secrets.MESHSTACK_API_SECRET }}
```

**Job-level `env`, not workflow-level.** The `secrets` context is not available in top-level `env` —
the value arrives empty and nothing tells you. The same trap has a second half: `secrets` is not
available in a step's `if` at all, so a step gated on an optional secret must test
`env.SOME_SECRET != ''` after the secret has been promoted to job-level `env` like this.

```yaml
- name: Upload errored test state
  if: failure()
```

**Keep `errored_test.tfstate`.** When `tofu test` dies mid-apply it writes what it could not destroy
there. Without that file you are guessing at what leaked in a run you cannot reproduce — and you
cannot clean it up.

## Break it on purpose

A green pipeline proves nothing until you have watched it go red. Break the thing this test exists
to catch: a definition someone changed by hand.

In meshPanel, open your **meshStack NoOp Building Block** definition and delete the `flag` input.
Save. Nothing warns you — the definition is yours to edit, and the edit lands as a draft on the
version `smoke.tfvars` pins. Now dispatch the workflow:

```bash
gh workflow run nightly-e2e-tests.yml
```

```
run "noop_building_block_can_be_ordered"... fail

Error: Error creating building block

  with meshstack_building_block.this,
  on main.tf line 13, in resource "meshstack_building_block" "this":

http error 400, response '{"message":"Cannot determine input type for input 'flag':
valueType not provided and input key not found in BBD.","errorCode":"BadRequest",...}'
```

Three things in that output are worth more than the failure itself:

**It failed in thirteen seconds, not three minutes.** The API rejected the order outright — a `400`
before anything was created. Nothing leaked, nothing needs cleaning up, and no `errored_test.tfstate`
was written — which is why the upload step runs, finds no file and stays quiet instead of failing
the job. That is `if-no-files-found: ignore` earning its keep. Compare it to a building block that
*starts* and then fails: that one costs you three minutes and leaves a block behind.

**The error names the input.** `Cannot determine input type for input 'flag'` is the whole
diagnosis. You are not reading run logs in meshPanel to find out what broke; you are reading one
line and going straight to the definition.

**No assertion was involved.** The test never got as far as `status.status == "SUCCEEDED"`. This is
the failure mode the smoke test catches for free: not a wrong output, but an order that cannot be
placed at all — exactly what an app team would hit, and exactly what nothing else in your pipeline
is watching for.

Reproduce it on your laptop with the same inputs CI used:

```bash
tofu -chdir=03-smoke-test test -var-file=smoke.tfvars
```

Fix it by redeploying chapter 02. The definition is code; the meshPanel edit was drift, and `apply`
reverts it:

```bash
tofu -chdir=02-building-block-definition apply
```

Dispatch the workflow again and it is green. That loop — someone clicks, the nightly goes red, an
apply puts it back — is the entire argument for this chapter. Without a scheduled test the drift is
still there; you just find out when an app team does.

## Your turn: make `name_suffix` unique per run

`smoke.tfvars` has `name_suffix = "test"` in it, which chapter 03 already flagged as a shortcut. The
`concurrency` group stops two runs overlapping, but it does nothing about the other case: a run that
fails mid-apply leaves a building block called `smoke-test-noop-test` behind, and every night after
that fails on the collision instead of on whatever broke. The suffix wants to be per-run.

Try it, and notice what stops you: `test_context` is one object, and object variables do not merge.
A second `-var-file` carrying only `name_suffix` does not patch the committed one, it replaces the
whole variable — and then `workspace` and `bbd_version_ref` are missing. Your options are to render
the entire context in a workflow step (a heredoc like chapter 03's, or `-var` with a JSON object) or
to keep the committed file and pass a rendered one instead of it.

That constraint is not an accident of this workshop; it is why the real thing has a renderer rather
than a committed file. Chapter 03's terragrunt example shows the shape — `run_cmd("date", …)` into a
generated `smoke.auto.tfvars.json`, so the suffix is fresh and nothing is committed at all. The
trade is reproducibility for uniqueness, and which side you want depends on whether a human or a
robot is the one asking.

## What to take away

**Two tiers, not one.** Logic tests on every push, e2e tests on a schedule. If you put a
three-minute building block run on every commit you will start skipping CI; if e2e is all you have
you will stop running it at all. The cheap tier costs nothing to add — `tofu fmt -check -recursive`
plus chapter 01's suite needs no credentials, so it works on forks and outside pull requests too.

**Nightly, not hourly, for anything with a real-world quota.** The hub learned this the hard way: a
starterkit test provisioning an ingress needed a fresh Let's Encrypt certificate per run, and
hourly runs burned through the 50-certs-per-domain-per-week limit and turned the suite permanently
red. Rate limits, quotas and cost all argue for the slowest cadence that still catches regressions
before your users do.

**`fail-fast: false` the moment there is a matrix.** Chapter 05 adds the second test as a matrix
entry; without that flag the first red building block cancels the rest and you learn one thing per
night instead of all of them.

**Fail loudly.** A nightly test that goes red silently is worse than no test — it is a false sense
of safety. This repo's workflow stops at uploading the errored state; add a notification (Slack, an
issue, an email) and make sure a person owns it. In the hub a dedicated `report-failure` workflow
posts to the ops channel.

**Everything CI needs is in the repo or in an environment, never in someone's shell.** The whole
chapter is that sentence: inputs in `smoke.tfvars`, credentials in an environment written by
`gha-config`, and no step anywhere that only works on the laptop it was written on.

---

Next: [Chapter 05 — test the definition itself, built from source](../05-e2e-test/README.md)
