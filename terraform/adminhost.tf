resource "azurerm_public_ip" "adminhost-pupip" {
  name                    = "adminhost-pupip"
  location                = azurerm_resource_group.et51-rg.location
  resource_group_name     = azurerm_resource_group.et51-rg.name
  sku                     = "Basic"
  allocation_method       = "Static"
  idle_timeout_in_minutes = 4
}

resource "azurerm_virtual_network" "et51-vnet" {
  name                = "et51-vnet"
  location            = azurerm_resource_group.et51-rg.location
  resource_group_name = azurerm_resource_group.et51-rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "et51-vnet-defalt-subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.et51-rg.name
  virtual_network_name = azurerm_virtual_network.et51-vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_security_group" "adminhost-nsg" {
  name                = "adminhost-nsg"
  location            = azurerm_resource_group.et51-rg.location
  resource_group_name = azurerm_resource_group.et51-rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "adminhost-nic" {
  name                = "adminhost-nic"
  location            = azurerm_resource_group.et51-rg.location
  resource_group_name = azurerm_resource_group.et51-rg.name

  ip_configuration {
    name                          = "adminhost-nic-ipconf"
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
    public_ip_address_id          = azurerm_public_ip.adminhost-pupip.id
    subnet_id                     = azurerm_subnet.et51-vnet-defalt-subnet.id
  }
}

resource "azurerm_network_interface_security_group_association" "adminhost-nsg-association" {
  network_interface_id      = azurerm_network_interface.adminhost-nic.id
  network_security_group_id = azurerm_network_security_group.adminhost-nsg.id
}

resource "azurerm_virtual_machine" "adminhost" {
  name                             = "adminhost"
  resource_group_name              = upper(azurerm_resource_group.et51-rg.name)
  location                         = azurerm_resource_group.et51-rg.location
  network_interface_ids            = [
    azurerm_network_interface.adminhost-nic.id
    ]
  primary_network_interface_id     = azurerm_network_interface.adminhost-nic.id
  vm_size                          = "Standard_B2s"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name                      = "adminhost-disk"
    managed_disk_type         = "Standard_LRS"
    caching                   = "ReadWrite"
    create_option             = "FromImage"
    disk_size_gb              = 30
    os_type                   = "Linux"
    write_accelerator_enabled = false
  }

  os_profile {
    computer_name  = "adminhost"
    admin_username = "tfuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    # Terraform internal key
    ssh_keys {
      key_data = tls_private_key.ssh_key.public_key_openssh
      path     = "/home/tfuser/.ssh/authorized_keys"
    }
    # Michael Oberdorf
    ssh_keys {
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAl2lOkmPD7/WEV8hgc4vm6NVuVRrsqhRFSOWrJkgtV9j+Cfeya3c/NGubesvbr64fhIrbDMt9K+qGKo/kv90J5OXV+ayrbz0vm+y6y/IyfYw//msJijUsdYaTNOnZ12hGkD2cs1/xMxgszhHDa2rA3MgCa6UWkxl5j6RqleY/iw75BUTKPh2K1DYTxyufBd/9dY7kgMbenKxzHNStd1KR1X0VsZLRaO/RLxU0TF1jrzyve+qryvvneedvHxch/ueRT2qO3F7IqVgZufevom3RSlTGYdyDQenZxPR2aQAEkVg/ZXc9E/eV7iV/SmEDMcoRRkT5y70LCvFayjZARfscpQ== michael.oberdorf@bridging-it.de\n"
      path     = "/home/tfuser/.ssh/authorized_keys"
    }
    # Patrick Wasik
    ssh_keys {
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAn3c779mUhIrABcjfb8V5BAbXPoUROvH+ix8/dYRkGqBs2Do+GLST7z/xsQRbsyWX4rToTLHTLtthAfP94v0XadieNXK5L9Dg50jkX9yHMbZTopULeRhOHJ7cJf0GUDpM8sV7YG3bgpZ82DpM+Wa2EfEa9iW/vQHSbkzLDsFVGnQfHaZf75BrbSVgKx2ZgYOqmAGzPguFEZ9V/tY0xAfi6L4e+gmJpAFpCA6j2EDng8e6VE1LC0hy3zhR7deMc+Y7qO7fRLm6YmUKPay0ew9YzBP62v2gX99H0Gn+TSBGiIeLWs0Z+5JL+eUI9n4itMdeJpFXfr3/PmJ9Qgw8tjwz3Q== patrick.wasik@bridging-it.de\n"
      path     = "/home/tfuser/.ssh/authorized_keys"
    }
  }
}

resource "null_resource" "adminhost-installation" {
  depends_on = [azurerm_virtual_machine.adminhost]

  triggers = {
    cluster_instance_ids = azurerm_virtual_machine.adminhost.id
  }

  connection {
    type = "ssh"
    user = "tfuser"
    private_key = tls_private_key.ssh_key.private_key_pem
    host = azurerm_public_ip.adminhost-pupip.ip_address
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg -y",
      "sudo curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -",
      "sudo apt-add-repository \"deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
      "sudo apt-get install terraform -y",
      "terraform version",
      "curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -",
      "sudo apt-add-repository \"deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main\"",
      "sudo apt-get install azure-cli -y",
      "git clone https://github.com/cybcon/et51_tf_aks.git"
    ]
  }
}
