variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "shohrab"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default     = "East US"
}

variable "username" {
  description = "The azure user name from Udacity Cloud Lab"
}

variable "password" {
  description = "Password for Udacity Cloud Lab"
}

variable "node_count" {
	type = number
}