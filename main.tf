resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "ama-rg"
}

# Create virtual network
resource "azurerm_virtual_network" "deploy" {
  name                = "ama-vnet"
  address_space       = ["10.23.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "deploy" {
  name                 = "ama-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.deploy.name
  address_prefixes     = ["10.23.0.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "server" {
  name                = "ama-public-ip-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "deploy" {
  name                = "ama-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "server" {
  name                = "ama-nic-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my_nic_configuration_01"
    subnet_id                     = azurerm_subnet.deploy.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_addr
    public_ip_address_id          = azurerm_public_ip.server.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.server.id
  network_security_group_id = azurerm_network_security_group.deploy.id
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "server" {
  name                     = "amastorage01"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "server" {
  name                  = "ama-dc-ca"
  admin_username        = "ama-admin"
  admin_password        = var.dc-password
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.server.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "ama-dc-ca-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.server.primary_blob_endpoint
  }
}

# # Install DC DNS and CA to the virtual machine -------------------------------------------
# resource "azurerm_virtual_machine_extension" "dc_ca_install" {
#   name                       = "ama-dc"
#   virtual_machine_id         = azurerm_windows_virtual_machine.dc.id
#   publisher                  = "Microsoft.Compute"
#   type                       = "CustomScriptExtension"
#   type_handler_version       = "1.8"
#   auto_upgrade_minor_version = true

#   settings = <<SETTINGS
#     {
#       "commandToExecute": "powershell -Command \"${local.powershell}\""
#     }
#   SETTINGS
# }

# locals {
#   // Install DC
#   cmd1 = "Import-Module ServerManager"
#   cmd2 = "Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools"

#   cmd3 = "Import-Module ADDSDeployment"
#   cmd4 = "Install-ADDSForest -DomainName ${var.domain_name}" #-Force:$true" -SafeModeAdministratorPassword (ConvertTo-SecureString ${var.safemode_password} -AsPlainText -Force)"

#   shut_down = "shutdown -r -t 10"
#   exit_code = "exit 0"

#   // Install CA
#   #   cmd3 = "Install-WindowsFeature -name ADCS-Cert-Authority -IncludeManagementTools"
#   #   cmd4 = "Install-AdcsCertificationAuthority -CAType EnterpriseCA -CryptoProviderName ${var.crypto_provider} -KeyLength 256 -HashAlgorithmName SHA256"

#   powershell = "${local.cmd1} ; ${local.cmd2} ; ${local.cmd3} ; ${local.cmd4} ; ${local.shut_down} ; ${local.exit_code}"
# }
# ----------------------------------------------------------------------------------------

# Create public IPs
resource "azurerm_public_ip" "client" {
  name                = "ama-public-ip-02"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create network interface
resource "azurerm_network_interface" "client" {
  name                = "ama-nic-02"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my_nic_configuration_02"
    subnet_id                     = azurerm_subnet.deploy.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.client.id
  }
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "client" {
  name                     = "amastorage02"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "client" {
  name                  = "ama-win11"
  admin_username        = "ama-user"
  admin_password        = var.user-password
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.client.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "ama-win11-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-24h2-ent"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.client.primary_blob_endpoint
  }
}