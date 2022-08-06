provider "azurerm" {
  features {}
}

# Locate the existing resource group
data "azurerm_resource_group" "main" {
  name = "Azuredevops"
}

# Locate the existing custom image
data "azurerm_image" "main" {
  name                = "shohrabPackerImage"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Create virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/22"]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

# Create subnet
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public ip
resource "azurerm_public_ip" "pip" {
  count = var.node_count
  name                = "${var.prefix}-${format("%02d", count.index)}-pip"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Dynamic"
  
  tags = {
    ProjectName = "Assignment1"
  }
}

# Create load balancer
resource "azurerm_lb" "lb" {
  count               = var.node_count
  name                = "${var.prefix}-load-balancer"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku="Standard"
  sku_tier = "Regional"
  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = element(azurerm_public_ip.pip.*.id, count.index)
  }

  depends_on=[
    azurerm_public_ip.pip
  ]
}

# Create backend pool
resource "azurerm_lb_backend_address_pool" "scalesetpool" {
  count               = var.node_count
  loadbalancer_id = azurerm_lb.lb[count.index].id
  name            = "scalesetpool"
  depends_on=[
    azurerm_lb.lb
  ]
}

# Create network security group
resource "azurerm_network_security_group" "example" {
  name                = "${var.prefix}-nsg"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "${var.prefix}-allowSubnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "VirtualNetwork"
  }
  
  security_rule {
    name                       = "${var.prefix}-disallowInternet"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = {
    ProjectName = "Assignment1"
  }
}

# Create network interface
resource "azurerm_network_interface" "main" {
  count               = var.node_count
  name                = "${var.prefix}-${format("%02d", count.index)}-nic"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
	public_ip_address_id          = element(azurerm_public_ip.pip.*.id, count.index)
    # azurerm_public_ip.pip.id
  }
}

# Create virtual machine from packer image
resource "azurerm_linux_virtual_machine" "main" {
  count                           = var.node_count
  name                            = "${var.prefix}-${format("%02d", count.index)}-vm"
  resource_group_name             = data.azurerm_resource_group.main.name
  location                        = data.azurerm_resource_group.main.location
  size                            = "Standard_D2s_v3"
  admin_username                  = "${var.username}"
  admin_password                  = "${var.password}"
  disable_password_authentication = false
  network_interface_ids = [element(azurerm_network_interface.main.*.id, count.index)]
  # [  azurerm_network_interface.main.id,]

  source_image_id = data.azurerm_image.main.id

  os_disk {
    name                 = "${var.prefix}-OS-${count.index}"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  
  tags = {
    ProjectName = "Assignment1"
  }
}

# Create managed disk
resource "azurerm_managed_disk" "example" {
  count                = var.node_count
  name                 = "${var.prefix}-${format("%02d", count.index)}-managedDisk"
  location             = data.azurerm_resource_group.main.location
  resource_group_name  = data.azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"

  tags = {
    ProjectName = "Assignment1"
  }
}
