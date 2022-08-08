# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
Policy Definition 
--------------------
PolicyDefinition.json file contains a policy rule to deny creating all indexed resources that do not have a tag. 

You can create the policy defintion with the following command

```
az policy definition create --name [policy_definition_name] --display-name "Deny creating indexed resources without a tag" 
--description "Deny creating any indexed resources that do not have a tag" --rules [/path/to/PolicyDefinition.json]
```

PolicyDefinition.json file contains a policy rule to deny creating all indexed resources that do not have a tag. 

You can assing the policy defintion to a subsription with the following command

```
az policy assignment create --name '[policy definition name]-assignment' --display-name "Deny creating indexed resources without a tag" 
--scope /subscriptions/<subscriptionId> --policy [policy defintion id]
```
** policy defintion id: open the policy defination page in azure portal, you can get the policy defintion id in that page


Packer
---------------------------
packer.json file contains IaC that creates a image of ubuntu 18.04LTS. You can use this image in terraform to provision any virtual machine.

packer.json has the following three varibale. Get the associated data for each of the variables from your azure Service Principal. 

```
"variables": {
	"client_id": "[]",
	"client_secret": "[]",
	"subscription_id": "[]"
} 
```

You can run the packer.json file with the following command

packer build [/path/to/packer.json]

terraform
--------------
terraform.tf file contains IaC that creates the following resources:
1. Create a Virtual network and a subnet on that virtual network.
2. Create a Network Security Group that allows access to other VMs on the subnet and deny direct access from the internet.
3. Creat a Network Interface.
4. Create a public IP
5. Crate a Load Balancer. The load balancer has a backend address pool and address pool association for the network interface and the load balancer.
6. Create a virtual machine availability set.
7. Create virtual machines from the image you deployed using Packer.
8. Create managed disks for your virtual machines.
9.  A variables file allows for customers to configure the number of virtual machines and the deployment at a minimum.

variables.tf file contains varibles like prefix, location, azure user id and password. User has to provide these information
when running terraform "terraform build" command.

Run the following command to initialize terraform

```
terraform init
```

Run the following command to ceate an execution plan

```
terraform plan -out solution.plan
```

Run the following command deploy your terraform infrastructure

```
terraform apply solution.plan
```

### Output
- a policy defintion and assignment should be created
- a pakcer image for Ubuntu18.04LTS should be created
- A virtual machine should be create from packer image

