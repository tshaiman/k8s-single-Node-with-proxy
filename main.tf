terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.58.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "common" {
  name     = var.prefix
  location = "East US"
}

resource "azurerm_virtual_network" "common" {
  name                = join("-", [var.prefix, "vnet"])
  address_space       = ["172.10.0.0/16"]
  location            = azurerm_resource_group.common.location
  resource_group_name = azurerm_resource_group.common.name
}

resource "azurerm_subnet" "common" {
  name                 =  join("-", [var.prefix, "subnet"])
  resource_group_name  = azurerm_resource_group.common.name
  virtual_network_name = azurerm_virtual_network.common.name
  address_prefixes     = ["172.10.1.0/24"]
}

resource "azurerm_network_security_group" "common" {
  name                =  join("-", [var.prefix, "nsg"])
  location            = azurerm_resource_group.common.location
  resource_group_name = azurerm_resource_group.common.name

  security_rule {
    name                       = "SSH_Allow"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP_Allow"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTPS_Allow"
    priority                   = 1011
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "NodePort_Allow"
    priority                   = 1012
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-40000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "common" {
  subnet_id                 = azurerm_subnet.common.id
  network_security_group_id = azurerm_network_security_group.common.id
}

resource "azurerm_public_ip" "proxynoauth" {
  name                = join("-", [var.prefix, "proxynoauthpip"])
  resource_group_name = azurerm_resource_group.common.name
  location            = azurerm_resource_group.common.location
  allocation_method   = "Dynamic"
}


resource "azurerm_public_ip" "cluster" {
  name                = join("-", [var.prefix, "clusterpip"])
  resource_group_name = azurerm_resource_group.common.name
  location            = azurerm_resource_group.common.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "proxynoauth" {
  name                = join("-", [var.prefix, "proxnoauthnic"])
  location            = azurerm_resource_group.common.location
  resource_group_name = azurerm_resource_group.common.name

  ip_configuration {
    name                          = "configuration1"
    subnet_id                     = azurerm_subnet.common.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.proxynoauth.id
  }
}

resource "azurerm_network_interface_security_group_association" "proxynoauth" {
  network_interface_id      = azurerm_network_interface.proxynoauth.id
  network_security_group_id = azurerm_network_security_group.common.id
}

resource "azurerm_network_interface" "cluster" {
  name                = join("-", [var.prefix, "clusternic"])
  location            = azurerm_resource_group.common.location
  resource_group_name = azurerm_resource_group.common.name

  ip_configuration {
    name                          = "configuration3"
    subnet_id                     = azurerm_subnet.common.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.cluster.id
  }
}

resource "azurerm_network_interface_security_group_association" "cluster" {
  network_interface_id      = azurerm_network_interface.cluster.id
  network_security_group_id = azurerm_network_security_group.common.id
}

resource "azurerm_virtual_machine" "proxynoauth" {
  name                  = join("-", [var.prefix, "proxynoauthvm"])
  location              = azurerm_resource_group.common.location
  resource_group_name   = azurerm_resource_group.common.name
  network_interface_ids = [azurerm_network_interface.proxynoauth.id]
  vm_size               = "Standard_B2ms"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "noauthdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "proxynoauth"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data  = file(var.publickeypath)
      path      = "/home/azureuser/.ssh/authorized_keys"
    }
  }
}

resource "azurerm_virtual_machine_extension" "proxynoauth" {
  name                 = join("-", [var.prefix, "noauthextension"])
  virtual_machine_id   = azurerm_virtual_machine.proxynoauth.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = jsonencode({
    "fileUris": [
      "https://raw.githubusercontent.com/tshaiman/proxy-simulation/main/scripts/squid/noauth.sh",
      "https://raw.githubusercontent.com/tshaiman/proxy-simulation/main/scripts/squid/squid-noauth.conf"
    ],
    "commandToExecute": "sudo bash ./noauth.sh"
  })
}

resource "azurerm_virtual_machine" "cluster" {
  name                  = join("-", [var.prefix, "clustervm"])
  location              = azurerm_resource_group.common.location
  resource_group_name   = azurerm_resource_group.common.name
  network_interface_ids = [azurerm_network_interface.cluster.id]
  vm_size               = "Standard_D8as_v4"

  storage_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"

  }

  storage_os_disk {
    name              = "clusterdisk"
    caching           = "ReadWrite"
    disk_size_gb      =  300
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }
  
  os_profile {
    computer_name  = "cluster"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data  = file(var.publickeypath)
      path      = "/home/azureuser/.ssh/authorized_keys"
    }
  }
}

resource "azurerm_virtual_machine_extension" "cluster" {
  name                 = join("-", [var.prefix, "clusterextension"])
  virtual_machine_id   = azurerm_virtual_machine.cluster.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = jsonencode({
    "fileUris": [
      "https://raw.githubusercontent.com/tshaiman/proxy-simulation/main/scripts/cluster/main.sh"
    ],
    "commandToExecute": join(" ", ["sudo bash ./main.sh", azurerm_network_interface.proxynoauth.private_ip_address ])
  })
}