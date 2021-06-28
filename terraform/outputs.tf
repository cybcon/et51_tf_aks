# Output the public IP address of our adminhost
output "adminhost_ip_address" {
  value = azurerm_public_ip.adminhost-pupip.ip_address
}
