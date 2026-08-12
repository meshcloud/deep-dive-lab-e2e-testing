output "bucket_name" {
  description = "Name the object storage bucket was created under."
  value       = terraform_data.bucket.output
}
