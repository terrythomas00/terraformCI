terraform {
  required_version = "1.12.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.35.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "azure-terraform-group"
    storage_account_name = "storeasttest899"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}

}

resource "azurerm_resource_group" "dev_group" {
  name     = "azure-terraform-group"
  location = "eastus"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_storage_account" "storage" {
  name                     = "storeasttest899"
  location                 = azurerm_resource_group.dev_group.location
  resource_group_name      = azurerm_resource_group.dev_group.name
  account_tier             = "Standard"
  account_replication_type = "LRS"

}


resource "azurerm_virtual_network" "terraform-vnet1" {
  name                = "terraform-networkv1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.dev_group.location
  resource_group_name = azurerm_resource_group.dev_group.name
}

resource "azurerm_subnet" "terraform-subnet1" {
  name                 = "tf-internal-subnet"
  resource_group_name  = azurerm_resource_group.dev_group.name
  virtual_network_name = azurerm_virtual_network.terraform-vnet1.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "terraform-nic" {
  name                = "terraform1-nic"
  location            = azurerm_resource_group.dev_group.location
  resource_group_name = azurerm_resource_group.dev_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.terraform-subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/id_rsa"
  file_permission = "0600"
}



resource "azurerm_linux_virtual_machine" "vm-example" {
  name                = "terraform-machine"
  resource_group_name = azurerm_resource_group.dev_group.name
  location            = azurerm_resource_group.dev_group.location
  size                = "Standard_A2_v2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.terraform-nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
