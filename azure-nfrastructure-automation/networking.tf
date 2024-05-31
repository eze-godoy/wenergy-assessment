resource "azurerm_resource_group" "assessment" {
  name     = local.resource_group
  location = local.location
}

# terraform import azurerm_resource_group.example /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/group1

resource "azurerm_virtual_network" "assessment" {
  name                = "assessment-vnet"
  address_space       = [local.vnet_cidr]
  location            = azurerm_resource_group.assessment.location
  resource_group_name = azurerm_resource_group.assessment.name
}

#region Web Subnet

resource "azurerm_subnet" "web" {
  name                 = "assessment-web"
  resource_group_name  = azurerm_resource_group.assessment.name
  virtual_network_name = azurerm_virtual_network.assessment.name
  address_prefixes     = [cidrsubnet(local.vnet_cidr, 4, 0)]
}

resource "azurerm_network_security_group" "web" {
  name                = "web-subnet-sg"
  location            = azurerm_resource_group.assessment.location
  resource_group_name = azurerm_resource_group.assessment.name
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_network_security_rule" "allow_http" {
  resource_group_name         = azurerm_resource_group.assessment.name
  name                        = "Allow-HTTP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.web.name
}

resource "azurerm_network_security_rule" "allow_https" {
  resource_group_name         = azurerm_resource_group.assessment.name
  name                        = "Allow-HTTPS"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.web.name
}

resource "azurerm_network_security_rule" "allow_ssh_web" {
  resource_group_name         = azurerm_resource_group.assessment.name
  name                        = "Allow-SSH"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = local.admin_ips
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.web.name
}

resource "azurerm_network_security_rule" "allow_outbound_web" {
  resource_group_name         = azurerm_resource_group.assessment.name
  name                        = "Allow-Outbound"
  priority                    = 400
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.web.name
}

#endregion

#region Application Subnet

resource "azurerm_subnet" "application" {
  name                 = "assessment-application"
  resource_group_name  = azurerm_resource_group.assessment.name
  virtual_network_name = azurerm_virtual_network.assessment.name
  address_prefixes     = [cidrsubnet(local.vnet_cidr, 4, 1)]
}

resource "azurerm_network_security_group" "application" {
  name                = "application-subnet-sg"
  location            = azurerm_resource_group.assessment.location
  resource_group_name = azurerm_resource_group.assessment.name
}

resource "azurerm_subnet_network_security_group_association" "application" {
  subnet_id                 = azurerm_subnet.application.id
  network_security_group_id = azurerm_network_security_group.application.id
}

resource "azurerm_network_security_rule" "allow_web_subnet" {
  resource_group_name         = azurerm_resource_group.assessment.name
  name                        = "Allow-web-Subnet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = azurerm_subnet.web.address_prefixes
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.application.name
}

resource "azurerm_network_security_rule" "allow_outbound_application" {
  resource_group_name         = azurerm_resource_group.assessment.name
  name                        = "Allow-Outbound"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.application.name
}

#endrgion

#region Database Subnet

resource "azurerm_subnet" "database" {
  name                 = "assessment-database"
  resource_group_name  = azurerm_resource_group.assessment.name
  virtual_network_name = azurerm_virtual_network.assessment.name
  address_prefixes     = [cidrsubnet(local.vnet_cidr, 4, 2)]
  service_endpoints    = ["Microsoft.Sql"]
}

resource "azurerm_network_security_group" "database" {
  name                = "database-subnet-sg"
  location            = azurerm_resource_group.assessment.location
  resource_group_name = azurerm_resource_group.assessment.name
}

resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.database.id
}

resource "azurerm_network_security_rule" "allow_application_subnet" {
  resource_group_name         = azurerm_resource_group.assessment.name
  name                        = "Allow-Application-Subnet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = azurerm_subnet.application.address_prefixes
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.database.name
}

resource "azurerm_network_security_rule" "allow_outbound_database" {
  resource_group_name         = azurerm_resource_group.assessment.name
  name                        = "Allow-Outbound"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.database.name
}

#endregion