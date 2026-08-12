output "building_block_definition" {
  description = <<-EOT
  UUID and version ref of the definition we just created. Chapter 03 reads this output to smoke
  test the definition; in a real foundation repo, the deployment unit exposes exactly this so its
  sibling e2e unit can consume it.
  EOT
  value       = module.noop.building_block_definition
}
