output "c" {
  description = "The sum, a + b."

  # Read off the applied resource, not off `local.c`. A local would render even if the apply never
  # happened; `terraform_data.sum.output` only has a value once the resource actually exists.
  value = terraform_data.sum.output
}

output "resource_url" {
  description = "Where an app team goes to find out what this building block is. meshPanel links it."
  value       = "https://github.com/meshcloud/deep-dive-lab-e2e-testing/tree/main/06-ai-assisted/buildingblock"
}

output "summary" {
  description = "Markdown rendered in meshPanel like a README for this instance of the building block."
  value       = <<-MARKDOWN
    # Sum Building Block — Deployment Summary

    Your numbers were added up.

    | Input | Value |
    |---|---|
    | `a` | `${var.a}` |
    | `b` | `${var.b}` |
    | **`c`** | **`${terraform_data.sum.output}`** |

    > **Note**: this building block provisions no infrastructure. It exists so that chapter 06 has
    > something small enough to read in one sitting and real enough to fail.
  MARKDOWN
}
