/*
 * One `run` block, because there is one thing under test: ordering a Sum building block end to
 * end against a definition built from this repo's source.
 *
 * As in chapter 03, every assertion references `meshstack_building_block.this` only — never
 * `var.test_context`, never `module.sum`. That is what would let this same file also serve as a
 * foundation-mode smoke test against an already-deployed definition.
 */

run "sum_building_block_adds_two_numbers" {
  # Status first. Everything below is noise if the run did not succeed.
  assert {
    condition     = meshstack_building_block.this.status.status == "SUCCEEDED"
    error_message = "expected SUCCEEDED, got ${meshstack_building_block.this.status.status} — check the building block run logs in meshPanel"
  }

  # The point of the whole chapter: 2 + 3 = 5. Every building block output arrives as a
  # JSON-encoded string whatever its declared type, so `jsondecode` once.
  assert {
    condition     = jsondecode(meshstack_building_block.this.status.outputs["c"].value) == 5
    error_message = "expected output c == 5 for a = 2, b = 3, got ${jsondecode(meshstack_building_block.this.status.outputs["c"].value)}"
  }

  # RESOURCE_URL is the link meshPanel shows app teams. A broken one is a real defect, and exactly
  # the kind nobody reports for six months.
  assert {
    condition     = jsondecode(meshstack_building_block.this.status.outputs["resource_url"].value) == "https://github.com/meshcloud/deep-dive-lab-e2e-testing/tree/main/06-ai-assisted/buildingblock"
    error_message = "expected resource_url to point at the buildingblock directory on GitHub, got '${jsondecode(meshstack_building_block.this.status.outputs["resource_url"].value)}'"
  }

  # The summary interpolates the inputs, so asserting on it proves the values reached the runner —
  # not just that the module computed something.
  assert {
    condition     = strcontains(jsondecode(meshstack_building_block.this.status.outputs["summary"].value), "| **`c`** | **`5`** |")
    error_message = "expected the summary output to report c = 5, got '${jsondecode(meshstack_building_block.this.status.outputs["summary"].value)}'"
  }
}
