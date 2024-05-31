resource "random_password" "database" {
  length  = 16
  special = true
}

resource "azurerm_mssql_server" "server" {
  name                         = "server-wea-01"
  resource_group_name          = azurerm_resource_group.assessment.name
  location                     = azurerm_resource_group.assessment.location
  version                      = "12.0"
  administrator_login          = "sqladminuser"
  administrator_login_password = random_password.database.result
}

resource "azurerm_mssql_database" "database" {
  name                 = "database-01"
  server_id            = azurerm_mssql_server.server.id
  collation            = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb          = 10
  read_scale           = false
  sku_name             = "GP_S_Gen5_2"
  zone_redundant       = false
  storage_account_type = "Local"

  min_capacity                = 0.5
  auto_pause_delay_in_minutes = 60

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_mssql_virtual_network_rule" "database" {
  name      = "sql-vnet-rule"
  server_id = azurerm_mssql_server.server.id
  subnet_id = azurerm_subnet.database.id
}