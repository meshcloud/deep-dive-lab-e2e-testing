/*
 * Foundation mode: smoke test a building block definition that is ALREADY deployed.
 *
 * The definition is a long-lived thing your platform pipeline manages (chapter 02 deployed it).
 * This test does not touch it. It orders one ephemeral building block against it, asserts the
 * run succeeded and produced the right outputs, and deletes it again.
 *
 * That is the test you point at production. It answers the only question that matters at 3am:
 * "can an app team order this building block right now?" — and it answers it against the real
 * definition, the real runner and the real meshStack.
 */

resource "meshstack_building_block" "this" {
  # Block until the run reaches a terminal state, so a failed run fails the test.
  wait_for_completion = true

  spec = {
    building_block_definition_version_ref = {
      uuid = var.test_context.bbd_version_ref.uuid
    }

    # `name_suffix` makes every run's building block uniquely named. Do not be tempted to reuse a
    # fixed name: a failed run can leave a block behind, and the next run would then collide with
    # it instead of telling you what actually broke.
    display_name = "smoke-test-noop-${var.test_context.name_suffix}"

    target_ref = {
      kind = "meshWorkspace"
      name = var.test_context.workspace
    }

    inputs = {
      flag              = { value = jsonencode(true) }
      num               = { value = jsonencode(1) }
      text              = { value = jsonencode("Hello, Deep Dive Lab!") }
      single_select     = { value = jsonencode("single1") }
      multi_select      = { value = jsonencode(["multi1", "multi2"]) }
      multi_select_json = { value = jsonencode(["multi2", "multi1"]) }
      sensitive_text    = { sensitive = { secret_value = "Hidden value" } }
    }
  }

  timeouts = {
    create = "15m"
    delete = "15m"
  }
}
