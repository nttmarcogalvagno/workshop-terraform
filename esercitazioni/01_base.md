# Agenda
## Installazione TF -> Rivedere documentazione Marco

Download Terraform archive in a directory, unzip and add binary to the PATH env variable:

```
cd ~/terraform-labs
wget https://releases.hashicorp.com/terraform/0.14.9/terraform_0.14.9_linux_amd64.zip
unzip terraform_0.14.9_linux_amd64.zip
export PATH="~/terraform-labs:$PATH"
terraform -help
```


## Configurazione provider

Create a 'main.tf', add the following code and save it. Pay attention to replace credentials file path and project id with yours data.
```
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {

  credentials = file("<PATH_TO_YOUR_CREDENTIAL_FILE">)

  project = "<YOUR_PROJECT_ID>"
  region  = "us-central1"
  zone    = "us-central1-c"
}

## CreazioneVPC
Configuring Google provider and create a VPC Network

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
```

Init your Terraform workspace:
```
terraform init
terraform apply
```

Verify resources has been created on GCP console or by typing the following command:

terraform show

## CreazioneVM
Be sure to complete the labs 01-Build in the Getting Started learning path before continuing.

Add to the 'main.tf' the following content:

```
resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
}
```
### Apply changes to your infrastructure (no new reasources are created)

```
terraform apply
```
Verify resources has been created on GCP console or by typing the following command:
```
terraform show
```

Add a *tags* argument to your vm_instance resource block in 'main.tf'
```
resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"
  tags         = ["web", "dev"]
  # ...
}
```

### Creating new resources

Making destructive changes

Changing the disk image of our instance is one example of a destructive change.

Edit the boot_disk block inside the vm_instance resource in your 'main.tf'.
```
  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }
```
Apply changes. You will see that resource affected by the change is first destroyed and reacreated.
```
terraform apply
```
Verify resources has been created on GCP console or by typing the following command:

terraform show



## Gestione dipendenze

Add to the 'main.tf' the following content:
```
resource "google_compute_address" "vm_static_ip" {
  name = "terraform-static-ip"
}
```
Verify what changes will be introduced:

terraform plan

Assign the created ip resource to the VM changing the *network_interface* block in 'main.tf' as follows:

```
 network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
       nat_ip = google_compute_address.vm_static_ip.address
    }
  }
```
Review the plan and save it to a file:
```
terraform plan -out static_ip
```
In this file we can find all the changes to our infrastructure.

To apply these changes issue
```
terraform apply "static_ip"
```


If we want to see the terraform graph representation of our infrastructure, issue the command:
```
terraform graph > graph.digraph
```

Now let's go to https://dreampuf.github.io/GraphvizOnline and paste the content of the *graph.digraph* file.

### Explicit dependency

Create a VM that depends on a bucket
Add the following resources to 'main.tf'
```
resource "random_string" "bucket" {
  length  = 8
  special = false
  upper   = false
}

resource "google_storage_bucket" "example_bucket" {
  name     = "learn-gcp-${random_string.bucket.result}"
  location = "US"

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

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
Refresh your terraform workspace to download new providers.
```
terraform init
```
Apply changes.
```
terraform apply
```

## Applicazione ciclo di vita

*Download, Initialize and Configure Terraform project* 

```
terraform init
```
*View and Apply changes.*
```
(terraform plan -out static_ip)
terraform apply
```
*Cleaning infrastructure*
```
terraform destroy
```
## Best practices (organizzazione sorgenti) 

- ### Multi file code organization
- ### Variables utilisation
- ### https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html

 