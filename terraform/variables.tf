variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "s-uddin"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default     = "East US"
}

variable "azure_username" {
  description = "The azure user name from Udacity Cloud Lab"
  default     = "odl_user_203688@udacityhol.onmicrosoft.com"
}

variable "azure_password" {
  description = "Password for Udacity Cloud Lab"
  default     =  "djpp10ZGQ*0J"
}

variable "node_count" {
	type = number
	default = 2
}

variable "tag_name" {
	type = map(string)
	default = {
		 ProjectName = "Assignment1"
		 }
}		 