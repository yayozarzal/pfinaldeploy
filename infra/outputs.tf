output "public_ip" {
  value       = oci_core_instance.vm[0].public_ip
  description = "IP pública VM"
}
