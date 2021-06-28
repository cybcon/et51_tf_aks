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
    # Terrafrom internal key for the Azure BuildAgent installation
    ssh_keys {
      key_data = tls_private_key.ssh_key.public_key_openssh
      path     = "/home/tfuser/.ssh/authorized_keys"
    }
    # Azure Build Agent in Virtual Edge environment
    # Michael Oberdorf
    ssh_keys {
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAl2lOkmPD7/WEV8hgc4vm6NVuVRrsqhRFSOWrJkgtV9j+Cfeya3c/NGubesvbr64fhIrbDMt9K+qGKo/kv90J5OXV+ayrbz0vm+y6y/IyfYw//msJijUsdYaTNOnZ12hGkD2cs1/xMxgszhHDa2rA3MgCa6UWkxl5j6RqleY/iw75BUTKPh2K1DYTxyufBd/9dY7kgMbenKxzHNStd1KR1X0VsZLRaO/RLxU0TF1jrzyve+qryvvneedvHxch/ueRT2qO3F7IqVgZufevom3RSlTGYdyDQenZxPR2aQAEkVg/ZXc9E/eV7iV/SmEDMcoRRkT5y70LCvFayjZARfscpQ== michael.oberdorf@bridging-it.de\n"
      path     = "/home/tfuser/.ssh/authorized_keys"
    }
    ssh_keys {
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCnXZxppk0GhIVcg+CZbgx6wjWH71oy4+Z6E0eBGmdTkbFfd8H2BBbYqsL+SmuLecYFbOjP/Lu6lzjFI3GJZVZZNfUP55JnyR7THme5E9kWhlMH0wPCSgYoi3rEo3Z/CuEG3xJ4lxR8NzmhHRcEbhyVJJrCJjjZRhhDq/Hddv7uZ7OZMQy1tjm0JyCz5jCVh1rFAZA5O8OUk5/cDxVMn3LUNF0/2BbFd+jiais6R5Ez96kjwa5pipwJudiaBjnlCDmkG7sXjNxIZQ4VvySn1KSONczPm7dmFu9/uVjfeSx0md9WqC0Fo4LB3L4H8Dfcf95+rdXsGWc+JAcBZ7OXwIKKIgYdc2MWXrPUV9xqeG7aXzMF8UH3hmb2MYeNeNr7xo6NLyLGlI0Hurokc6ZUwsUKtBIAXeTLJNtKPEfdoAj/ESqM5Ds3n37onJG1n+3OkmYijnbX5PvnflXHyu5EvPNJ5zSvb+CxORTcBJfugnIg7AKeITi+Yd0q9xJ55DqQIBs= patrick.wasik@bridging-it.de\n"
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
