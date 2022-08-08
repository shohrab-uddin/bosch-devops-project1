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
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  tags = var.tag_name
}

# Create virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/22"]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags = var.tag_name
}

# Create subnet
resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create public ip
resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  
  tags = var.tag_name
}

# Create load balancer
resource "azurerm_lb" "lb" {
  name                = "${var.prefix}-load-balancer"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  
  frontend_ip_configuration {
    name                 = "public-ip-address"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
  
  tags = var.tag_name
}

# Create load balancer backend pool
resource "azurerm_lb_backend_address_pool" "bap" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "scalesetpool"
}

resource "azurerm_lb_nat_rule" "main" {
  resource_group_name            = data.azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "HTTPSAccess"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                          = var.node_count 
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bap.id
  ip_configuration_name          = "internal" # this is should be same is in in_cofiguration in azurerm_network_interface
  network_interface_id           = element(azurerm_network_interface.main.*.id, count.index)
}

resource "azurerm_availability_set" "avlset" {
  name                         = "${var.prefix}-aset"
  location                     = data.azurerm_resource_group.main.location
  resource_group_name          = data.azurerm_resource_group.main.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  
  tags = var.tag_name
}

# Create network interface
resource "azurerm_network_interface" "main" {
  count               = var.node_count
  name                = "${var.prefix}-${count.index}-nic"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
  
  tags = var.tag_name
}

# Create virtual machine from packer image
resource "azurerm_linux_virtual_machine" "main" {
  count                           = var.node_count
  name                            = "${var.prefix}-${count.index}-vm"
  resource_group_name             = data.azurerm_resource_group.main.name
  location                        = data.azurerm_resource_group.main.location
  size                            = "Standard_D2s_v3"
  admin_username                  = "${var.azure_username}"
  admin_password                  = "${var.azure_password}"
  disable_password_authentication = false
  availability_set_id              = azurerm_availability_set.avlset.id
  network_interface_ids = [
    azurerm_network_interface.main[count.index].id,
  ]
  
  source_image_id = data.azurerm_image.main.id

  os_disk {
    name                 = "${var.prefix}-OS-${count.index}"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  
  tags = var.tag_name
}
