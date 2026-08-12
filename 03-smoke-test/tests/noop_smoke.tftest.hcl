/*
 * A single `run` block, because there is a single thing under test: ordering a building block
 * end to end. `command` defaults to `apply` here — unlike chapter 01, we very much want the
 * resource to really exist.
 *
 * `tofu test` destroys everything it created when the run finishes, pass OR fail. That is the
 * whole reason to use it instead of `apply` + a cleanup script you forget to run.
 *
 * Note that these assertions reference `meshstack_building_block.this` only — never
 * `var.test_context`. Keep it that way: it is what lets chapter 04 reuse this exact file in a
 * different invocation mode.
 */

run "noop_building_block_can_be_ordered" {
  # Always assert the status first. Everything below it is noise if the run did not succeed.
  assert {
    condition     = meshstack_building_block.this.status.status == "SUCCEEDED"
    error_message = "expected SUCCEEDED, got ${meshstack_building_block.this.status.status} — check the building block run logs in meshPanel"
  }

  # Every building block output arrives as a JSON-encoded string, whatever its declared type.
  # `jsondecode` once for a normal value; twice for a CODE/JSON output.
  assert {
    condition     = jsondecode(meshstack_building_block.this.status.outputs["num"].value) == 1
    error_message = "expected output num == 1, got ${jsondecode(meshstack_building_block.this.status.outputs["num"].value)}"
  }

  assert {
    condition     = jsondecode(meshstack_building_block.this.status.outputs["flag"].value) == true
    error_message = "expected output flag == true"
  }

  # The noop module echoes our `text` input back with the AWS CLI version its pre-run script
  # installed appended. Asserting the prefix proves two things at once: our input arrived, and the
  # pre-run script ran.
  assert {
    condition     = startswith(jsondecode(meshstack_building_block.this.status.outputs["text"].value), "Hello, Deep Dive Lab! aws-cli/2")
    error_message = "expected output text to start with 'Hello, Deep Dive Lab! aws-cli/2', got '${jsondecode(meshstack_building_block.this.status.outputs["text"].value)}'"
  }

  # RESOURCE_URL is what meshPanel links app teams to. A broken link is a real defect, and it is
  # exactly the kind that no one notices for six months.
  assert {
    condition     = jsondecode(meshstack_building_block.this.status.outputs["resource_url"].value) == "https://hub.meshcloud.io/modules/meshstack/noop"
    error_message = "expected the resource_url output to point at the hub module page, got '${jsondecode(meshstack_building_block.this.status.outputs["resource_url"].value)}'"
  }
}
