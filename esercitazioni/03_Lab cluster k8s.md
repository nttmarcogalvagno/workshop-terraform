Lab cluster k8s with nginx service

## Creazione del clusetr k8s

Il seguente Lab deve essere eseguito sulla shell fornita da google cloud.

![7710f279b65d00291e9d691fe6d4645f.png](../_resources/68e52b5d3b2e47d68387f6302aca7c3d.png)

Per il lab occorre la versione 0.14 di terraform. Sulla shell di google è invece installata la 0.12.  Per prima cosa quindi scarichiamo la versione più recente direttamente dal sito.

```curl -L "https://releases.hashicorp.com/terraform/0.14.10/terraform_0.14.10_linux_amd64.zip" -o terraform_0.14.10_linux_amd64.zip```

ed estraiamo il file

```unzip terraform_0.14.10_linux_amd64.zip```

Per avere nel path l’eseguibile lo si deve andare a sostituire nella cartella */usr/local/bin*

```sudo cp terraform  /usr/local/bin```

Scarichiamo in locale i file sorgenti per la creazione del cluster:

```git clone https://github.com/edoardopelli/terraform-gke.git```

ed entriamo nella directory del progetto

```cd terraform-provision-gke-cluster```

All'interno di questa directory troviamo i seguentii file

**versions.tf** (contiene le info sui provider utilizzati)

```
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.52.0"
    }
  }

  required_version = "~> 0.14"
}
```

**terraform.tfvars** (definizione variabili)

```
project_id = "terraform-gcp-labs-310013"
region     = "us-central1"
```

**outputs.tf** (output di terraform con i valori delle variabili)

```output "region" {
  value       = var.region
  description = "GCloud Region"
}

output "project_id" {
  value       = var.project_id
  description = "GCloud Project ID"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Host"
}
```

**vpc.tf** (creazione della virtual network)

```
variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}
```

**gke.tf** (contiene la configurazione del cluster)

```
variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}

variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes"
}

# GKE cluster
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-gke"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  master_auth {
    username = var.gke_username
    password = var.gke_password

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }

    # preemptible  = true
    machine_type = "n1-standard-1"
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}


# # Kubernetes provider
# # The Terraform Kubernetes Provider configuration below is used as a learning reference only.
# # It references the variables and resources provisioned in this file.
# # We recommend you put this in another file -- so you can have a more modular configuration.
# # https://learn.hashicorp.com/terraform/kubernetes/provision-gke-cluster#optional-configure-terraform-kubernetes-provider
# # To learn how to schedule deployments and services using the provider, go here: https://learn.hashicorp.com/tutorials/terraform/kubernetes-provider.

# provider "kubernetes" {
#   load_config_file = "false"

#   host     = google_container_cluster.primary.endpoint
#   username = var.gke_username
#   password = var.gke_password

#   client_certificate     = google_container_cluster.primary.master_auth.0.client_certificate
#   client_key             = google_container_cluster.primary.master_auth.0.client_key
#   cluster_ca_certificate = google_container_cluster.primary.master_auth.0.cluster_ca_certificate
# }
```

In questo lab avendo lavorato su un account con attivo il periodo di prova di 3 mesi, verrà creato un solo nodo. Nel caso si fosse in possesso di un account attivo, cambiare il valore gke_num_nodes a 2.


**Creazione del cluster k8s**

Apriamo il file terraform.tfvars e cambiamomo il project id, che si trova nella dashboard di progetto sotto “Project Info”.

![1b265f94649efbb1dbd00b2ec83e0999.png](../_resources/0feb15d596854441bf17bb7d63ee1e10.png)



Per verificare se l’id di progetto è corretto eseguire questo comando:

```
gcloud config get-value project
```

A questo punto eseguire nella directory del lab

`terraform init`

L’output dovrebbe essere simile al seguente:

```
Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/google from the dependency lock file
- Installing hashicorp/google v3.52.0...
- Installed hashicorp/google v3.52.0 (signed by HashiCorp)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Dopo l’init possiamo lanciare il commando

`terraform plan`

per vedere il piano di esecuzione. Al fondo del piano vengono indicate cosa verrà creato e l'output:

```
[.....]
Plan: 4 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + kubernetes_cluster_host = (known after apply)
  + kubernetes_cluster_name = "terraform-gcp-labs-310013-gke"
  + project_id              = "terraform-gcp-labs-310013"
  + region                  = "us-central1"
```

Infine per creare l'infrastruttura eseguire l'apply.

`terraform apply`

e come output avremo questo

```
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

kubernetes_cluster_host = "35.184.230.14"
kubernetes_cluster_name = "terraform-gcp-labs-310013-gke"
project_id = "terraform-gcp-labs-310013"
region = "us-central1"
```

Attenzione che la creazione dell'infrastruttura può durare tra i 10 ed i 15 minuti.


**Creazione di un servizio nginx**

Entrare nella directory learn-terraform-deploy-nginx-kubernetes

`cd learn-terraform-deploy-nginx-kubernetes`

All'interno abbiamo il file kubernetes.tf

**kubernetes.tf**

```
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.52.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }
  }
}

data "terraform_remote_state" "gke" {
  backend = "local"

  config = {
    path = "../learn-terraform-provision-gke-cluster/terraform.tfstate"
  }
}

# Retrieve GKE cluster information
provider "google" {
  project = data.terraform_remote_state.gke.outputs.project_id
  region  = data.terraform_remote_state.gke.outputs.region
}

# Configure kubernetes provider with Oauth2 access token.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config
# This fetches a new token, which will expire in 1 hour.
data "google_client_config" "default" {}

data "google_container_cluster" "my_cluster" {
  name     = data.terraform_remote_state.gke.outputs.kubernetes_cluster_name
  location = data.terraform_remote_state.gke.outputs.region
}

provider "kubernetes" {
  host = data.terraform_remote_state.gke.outputs.kubernetes_cluster_host

  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)
}


resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "scalable-nginx-example"
    labels = {
      App = "ScalableNginxExample"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = "ScalableNginxExample"
      }
    }
    template {
      metadata {
        labels = {
          App = "ScalableNginxExample"
        }
      }
      spec {
        container {
          image = "nginx:1.7.8"
          name  = "example"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name      = "nginx-service"

  }
  spec {
    selector = {
      app = "ScalableNginxExample"
    }
    session_affinity = "ClientIP"
    type = "LoadBalancer"
    port {
      port        = 80
      target_port = 80
    }
  }
}
```

Eseguire quindi in sequenza:

```
terraform init

terraform plan

terraform apply
```

con questo output

`Apply complete! Resources: 2 added, 0 changed, 0 destroyed.`

Per verificare se il servizio è correttamente deploiato colleghiamoci al cluster:

```
gcloud container clusters get-credentials <PROJECT_ID>-gke --zone <location>
```

Eseguire quindi

```
kubectl get deployments
```

Con questo output

```
NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
scalable-nginx-example   2/2     2            2           15s
```

Verifichiamo che il servizio sia esposto all’esterno. Dovremmo ottenere una risposta simile.

`kubectl get service nginx-service`

e ottenere come output

```
NAME            TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)        AGE
nginx-service   LoadBalancer   10.251.253.124   34.72.181.111   80:31861/TCP   9m52s
```

L'external-ip ovviamente sarà diverso da quello visualizzato qui.

A questo punto collegandosi ad http://34.72.181.111:80 si deve visualizzare la pagina di nginx.

![1cbdaafc8bfc20220a0073834df4b50a.png](../_resources/8f7040878e5e423287a33ca7cf4c51a0.png)


Bibliografia:

[https://learn.hashicorp.com/tutorials/terraform/gke?in=terraform/kubernetes](https://learn.hashicorp.com/tutorials/terraform/gke?in=terraform/kubernetes)
[https://learn.hashicorp.com/tutorials/terraform/kubernetes-provider?in=terraform/kubernetes](https://learn.hashicorp.com/tutorials/terraform/kubernetes-provider?in=terraform/kubernetes)

Link utili:

[Qui](https://cloud.google.com/about/locations#europe) si trovano le regioni disponibili per google cloud
