variable "ssh_public_key" {}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "example-vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.example.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

output "vm_public_ip" {
  value = azurerm_linux_virtual_machine.example.public_ip_address
}

output "ssh_connection_command" {
  value = "ssh azureuser@${azurerm_linux_virtual_machine.example.public_ip_address}"
}