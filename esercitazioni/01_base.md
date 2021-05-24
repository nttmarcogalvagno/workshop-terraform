# Lab description

In this lab we will explore the basic concepts you need to get started with Terraform and GCP integration.  
After this lab you should be able to:
- install Terraform and configure it to work with GCP resources
- execute the Terraform lifecycle
- work with the basic GCP resources in the Terraform way

We will proceed through the following step:
- Install Terraform
- Configure Terraform GCP provider
- Create the infrastructure on GCP
    - create a VPC network
    - create and attach a VM to the VPC network
    - create a static IP address and assign to the VM
- Explore how Terraform manages resource dependencies during infrastructure creation.
- Learn how organize your Terraform project in a structured way 

## Install Terraform

Download Terraform archive in a directory, unzip and add binary to the PATH env variable.  
You can get the installation instructions for your platform **[here](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/gcp-get-started)**.

```
cd ~/terraform-labs
wget https://releases.hashicorp.com/terraform/0.14.9/terraform_0.14.9_linux_amd64.zip
unzip terraform_0.14.9_linux_amd64.zip
export PATH="~/terraform-labs:$PATH"
terraform -help
```


## GCP Provider configuration

Terraform implements IaC paradigm: your infrastructure is described in a configuration file that you can store in your repo.
By default Terraform binary looks for your configuration file in the current directory.  

Create a 'main.tf' file, add the following code and save it. **Pay attention to replace credentials file path and project id with your data.**
```
## List of provider needed
terraform {
  required_providers {
    ## Local name of the provider
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
  }
}


## Configuration of Google provider referencing its name
provider "google" {

  credentials = file("<PATH_TO_YOUR_CREDENTIAL_FILE">)
  project = "<YOUR_PROJECT_ID>"
  region  = "us-central1"
  zone    = "us-central1-c"
}

## Defining a VPC network resource
## Every resource has a type and name
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
```

Init your Terraform workspace, running `terraform init` from the same directory of main.tf file.  
Provider will be downloaded and configured in a subdirectory of your workspace.

Build your infrastructure running `terraform apply`. When asked, confirm with "yes".

Verify resources has been created on GCP console or by typing the `terraform show` command.

Explore your workspace: Terraform keeps trace of the status of your infrastructure in a file 'terraform.tfstate'.

## Create a VM and attach to the network

Add to the 'main.tf' file the following content:

```
## Defining a VM resource
## Every resource has a type and name
resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  ##Referencing another resource via dot notation
  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
}
```

Apply changes with `terraform apply`.  

Verify resources has been created on GCP console or by typing `terraform show`.

## Apply changes to your infrastructure

When you make changes to your infrastructure, Terraform can act in two ways:
- if the change can be applied on the fly, Terraform will perform a simple update of the resource
- if the change is desruptive, Terraform will delete the resource and will create a new one with the updated configuration.

Let's see some examples.

### No new reasources are created

We will add a tag to VM to give info that the VM will be used as development machine for the FE.

Add a *tags* field to your vm_instance resource block in 'main.tf'
```
resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"
  tags         = ["web", "dev"]
  # ...
}
```

Apply changes with `terraform apply`. 

Note the output: this change doesn't require new resource to be created and can be applied on the fly by Terraform.

### Creating new resources

Changing the disk image of a VM is one example of desruptive change.

Edit the boot_disk block inside the vm_instance resource in your 'main.tf'.
```
  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }
```

Apply changes with `terraform apply`.

Note the output: resource affected by the change is first destroyed and reacreated.


## Create an External IP and assign to the VM

Let's define a new type of GCP resource, an external static ip, and assign it to the VM.

Add to the 'main.tf' the following content:

```
resource "google_compute_address" "vm_static_ip" {
  name = "terraform-static-ip"
}
```

Verify what changes will be introduced with `terraform plan`.
This command performs a sort of dry-run. It tells Terraform to show the result of the apply command without changing the infrastructure. 

Assign the created ip resource to the VM changing the *network_interface* block in 'main.tf' as follows:

```
 network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
       nat_ip = google_compute_address.vm_static_ip.address
    }
  }
```

Review the plan again but this time save it to a file: `terraform plan -out static_ip`.  
In this file we can find all the changes to our infrastructure.

To apply these changes issue `terraform apply "static_ip"`

## Explore how Terraform manages dependencies

So far we created resources writing resource block in the configuration file, defining a type and a name for each one.
Relationship between resources is achieved by dot notation or declaring an explicit relation.

Resource relationship implies also that resource are created on the cloud in a well defined order.

When Terraform build the infrastructure, it creates a dependency graph based on dot notation and explicit relations.

If you want to see the terraform graph representation of the infrastructure, execute the command: `terraform graph > graph.digraph`.  
Now let's go to https://dreampuf.github.io/GraphvizOnline and paste the content of the *graph.digraph* file.

### Explicit dependency

As you have seen, the dependency between a VPC, a VM and an ExternalIP is defined in a implicit way using dot notation reference.
Sometimes there are dependencies between resources that are not visible to Terraform: image an application that will run in the VM and expects to use a specific Cloud Storage bucket, but this dependency is configured inside the application code.

Add the following resources to 'main.tf'.
```
## This resource assures to choose a globally unique bucket name.
## This resource requires the Random Terraform provider 
resource "random_string" "bucket" {
  length  = 8
  special = false
  upper   = false
}

## Create a Cloud Storage bucket resource
resource "google_storage_bucket" "example_bucket" {
  name     = "learn-gcp-${random_string.bucket.result}"
  location = "US"

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

## Create another VM resource
## Defining an explicit dependency with the store
resource "google_compute_instance" "another_instance" {
  depends_on = [google_storage_bucket.example_bucket]

  name         = "terraform-instance-2"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
}
```
Refresh your terraform workspace to download new providers with `terraform init`

Apply changes with `terraform apply`.

Note the resource creation order from Terraform output.

Clean your infrastructure with: `terraform destroy`

## Terraform Lifecycle Summary

*Download, Initialize and Configure Terraform project* 

```
terraform init
```
*View and Apply changes.*
```
terraform plan [-out <plan_file>]
terraform apply ["<plan_file>"]
```
*Cleaning infrastructure*
```
terraform destroy
```
## Best practices

In a real world project, your infrastructure could be composed by many resources of many different types.
Keeping all in your main.tf configuration file could be confusing: for this reason, Terraform allows to define resources in many files.

In addition, we could have to create different environments for the project (i.e. dev, test, qa). We would like to have the same infrastructure and tuning some parameters for every specific env. Terraform allows us to reuse our configuration for different enviroments using variables.

Next lab will teach you how to use these feature in a **[more real scenario](02_more_real_scenario.md)** 