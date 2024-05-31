resource "random_password" "vms" {
  length  = 16
  special = true
}

#region Web App

resource "azurerm_public_ip" "web_tier" {
  name                = "web-tier-pip"
  location            = azurerm_resource_group.assessment.location
  resource_group_name = azurerm_resource_group.assessment.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "web_tier" {
  name                = "web-tier-lb"
  location            = azurerm_resource_group.assessment.location
  resource_group_name = azurerm_resource_group.assessment.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "web-tier-frontend"
    public_ip_address_id = azurerm_public_ip.web_tier.id
  }
}

resource "azurerm_lb_backend_address_pool" "web_tier" {
  name            = "web-tier-bap"
  loadbalancer_id = azurerm_lb.web_tier.id
}

resource "azurerm_lb_probe" "web_tier" {
  name            = "web-tier-probe"
  loadbalancer_id = azurerm_lb.web_tier.id
  protocol        = "Tcp"
  port            = 80
}

resource "azurerm_lb_rule" "web_tier" {
  name                           = "web-tier-rule"
  loadbalancer_id                = azurerm_lb.web_tier.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "web-tier-frontend"
  probe_id                       = azurerm_lb_probe.web_tier.id
}

resource "azurerm_network_interface" "web_tier" {
  count = local.web_tier_vm_count

  name                = "web-tier-nic-${count.index}"
  location            = azurerm_resource_group.assessment.location
  resource_group_name = azurerm_resource_group.assessment.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "web_tier" {
  count = local.web_tier_vm_count

  network_interface_id    = azurerm_network_interface.web_tier[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web_tier.id
}

resource "azurerm_linux_virtual_machine" "web_tier" {
  count = local.web_tier_vm_count

  name                = "web-tier-vm-${count.index}"
  location            = azurerm_resource_group.assessment.location
  resource_group_name = azurerm_resource_group.assessment.name
  size                = "Standard_B1s"

  admin_username                  = "adminuser"
  admin_password                  = random_password.vms.result
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.web_tier[count.index].id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  custom_data = base64encode(<<-EOF
                #!/bin/bash
                apt-get update
                apt-get install -y nginx
                systemctl start nginx
                systemctl enable nginx
                EOF
  )
}

#endregion

#region Application

resource "azurerm_network_interface" "application_tier" {
  count = local.application_tier_vm_count

  name                = "application-tier-nic-${count.index}"
  location            = azurerm_resource_group.assessment.location
  resource_group_name = azurerm_resource_group.assessment.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.application.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "application_tier" {
  count = local.application_tier_vm_count

  name                = "application-tier-vm-${count.index}"
  location            = azurerm_resource_group.assessment.location
  resource_group_name = azurerm_resource_group.assessment.name
  size                = "Standard_B1s"

  admin_username                  = "adminuser"
  admin_password                  = random_password.vms.result
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.application_tier[count.index].id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }
}

#endregion