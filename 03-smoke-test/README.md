# Chapter 03 — smoke test what you deployed (foundation mode)

**Time: ~10 min. Credentials needed: meshStack API key. Runtime: ~3 min per test run.**

You now have a building block definition living in your meshStack (chapter 02). This chapter turns
"I clicked around in meshPanel and it seemed fine" into a test you can run on a schedule.

**Foundation mode** means: the definition is a long-lived thing your platform pipeline owns, and
the test does not touch it. It orders one ephemeral building block against the deployed definition,
asserts the outputs, and deletes it again.

This is the mode you point at production. It answers the only question that matters at 3am: *can
an app team order this building block right now?* — against the real definition, the real runner,
the real meshStack.

## Capture what chapter 02 deployed

This chapter's inputs are the previous chapter's *outputs*. Its own `.auto.tfvars` is where you
park them — the workspace you already used, plus the version uuid of the definition chapter 02
created:

```bash
cp 03-smoke-test/auto.tfvars.example 03-smoke-test/.auto.tfvars
```

Set `workspace` to yours, and paste in the version uuid this prints:

```bash
tofu -chdir=02-building-block-definition output -json building_block_definition \
  | jq -r .version_ref.uuid
```

Or skip the copy-paste and let the shell do it — everything but the workspace comes out of chapter
02's state:

```bash
cat > 03-smoke-test/.auto.tfvars <<EOF
test_context = {
  workspace   = "your-workspace"
  name_suffix = "test"

  bbd_version_ref = {
    uuid = "$(tofu -chdir=02-building-block-definition output -json building_block_definition | jq -r .version_ref.uuid)"
  }
}
EOF
```

That hand-off — one deployment's output becoming its test's input — is the only interesting wiring
in this chapter, and it is what a foundation repo automates; see the terragrunt version at the
bottom of this page.

## Run it

```bash
tofu -chdir=03-smoke-test init
```

```bash
tofu -chdir=03-smoke-test test
```

No `-var-file`. The file ends in `.auto.tfvars`, so `tofu test` loads it exactly like `tofu apply`
does. (You will also find a committed [`smoke.tfvars`](smoke.tfvars) in this directory — that one is
for CI and is chapter 04's subject. It is *not* named `*.auto.tfvars`, so it stays out of the way
until something passes it explicitly.)

Watch the run appear in meshPanel while you wait. Then watch it disappear again — `tofu test`
tears down everything it created, on pass **and** on fail.

## Try breaking it

Change an assertion in [`tests/noop_smoke.tftest.hcl`](tests/noop_smoke.tftest.hcl) — e.g. expect
`num == 2` — and re-run. Two things to notice: the failure message tells you the actual value, and
the building block is still cleaned up afterwards.

## The three pieces

**[`main.tf`](main.tf)** — one `meshstack_building_block` resource. That is genuinely all the
"test fixture" there is. `wait_for_completion = true` makes a failed building block run fail the
apply, which is what turns this from a deployment into a test.

**[`variables.tf`](variables.tf)** — one structured `test_context` variable.

**[`tests/noop_smoke.tftest.hcl`](tests/noop_smoke.tftest.hcl)** — the assertions.

## What to take away

**Use a var-file for `test_context`, not `TF_VAR_test_context`.** `tofu test` does not type-decode
complex `TF_VAR_*` environment variables, so a structured variable passed that way arrives
mistyped in assertion scope. A var-file arrives correctly typed — whether you wrote it by hand, a
script rendered it, or `tofu test` auto-loaded it. This one costs everybody an hour the first time.

**One structured `test_context` variable, not a pile of flat ones.** Whatever produces it — a
heredoc here, a terragrunt `generate` block in a foundation repo, the committed `smoke.tfvars` in
chapter 04 — stays completely module-agnostic. It dumps the same shape for every test module, and
each module declares only the fields it reads; object type conversion silently drops the rest. In
the hub this is one renderer serving 50+ modules.

The flip side of one object: object variables do **not** merge. A second var-file replaces the
whole `test_context`, it does not patch a field of it — which is why overriding just `name_suffix`
in CI is not a one-liner. Chapter 04 walks into exactly that.

**Assert the status first, then the outputs.** Everything else is noise if the run did not succeed.

**Every building block output is a JSON string.** `jsondecode` once for a normal value, twice for a
`CODE`/JSON output. Getting this wrong produces assertion errors that look like type bugs in your
test.

**Assert things users would notice.** The `resource_url` assertion here is not busywork: that
output is the link meshPanel shows app teams, and a broken link is a defect nobody reports for six
months.

**Never reuse a display name across runs.** A failed run can leave a building block behind. With a
fixed name, the *next* run fails on a name collision instead of telling you what actually broke.
The `name_suffix = "test"` you just wrote is therefore a workshop shortcut, and the only reason it
survives is that you are one person running this by hand. Anything unattended stamps the suffix per
run — a timestamp, the CI run id, `run_cmd("date", …)` in the terragrunt block below. Chapter 04
makes it your exercise.

**Reference only the resource in assertions, never `var.test_context`.** It is what lets chapter 05
run the very same assertions in a different invocation mode, and chapter 04 run them from CI with a
different var-file.

## How this looks in a real foundation repo

You read the definition's version uuid out of chapter 02's local state by hand. A foundation repo
does the same thing across deployment units, and renders the file instead of asking you to. From
[likvid-bank/likvid-cloudfoundation](https://github.com/likvid-bank/likvid-cloudfoundation), the
`e2e` unit sitting next to the deployment unit that owns the BBD:

```hcl
dependency "deployment" {
  config_path = "../"
}

terraform {
  source = "git::https://github.com/meshcloud/meshstack-hub.git//modules/${include.hub.locals.module}/e2e?ref=${include.hub.locals.git_ref}"
}

generate "smoke_tfvars" {
  path      = "smoke.auto.tfvars.json"
  if_exists = "overwrite"
  contents = jsonencode({
    test_context = {
      workspace       = dependency.deployment.outputs.e2e.owning_workspace
      name_suffix     = run_cmd("--terragrunt-quiet", "date", "-u", "+%Y%m%d%H%M%S")
      hub_git_ref     = dependency.deployment.outputs.e2e.hub.git_ref
      bbd_version_ref = { uuid = dependency.deployment.outputs.e2e.building_block_definition.version_ref.uuid }
    }
  })
}
```

Same shape, same discriminator, and the test module it sources is the `e2e/` directory that ships
*inside the hub module itself* — so the platform team maintaining the building block also maintains
its test, and every foundation consuming that module gets the test for free.

---

Next: [Chapter 04 — put it on a schedule](../04-ci/README.md)
