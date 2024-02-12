locals {
    cortex_deployer_roles = [
        "roles/iam.serviceAccountUser",
        "roles/iam.serviceAccountTokenCreator",
        "roles/composer.worker",
        "roles/composer.admin",
        "roles/storage.objectViewer",
        "roles/bigquery.dataEditor",
        "roles/bigquery.jobUser"
    ]
}

# Create a custom VPC
resource "google_compute_network" "composer_vpc" {
  project = var.cortex_source_project
  name                    = "cortex-composer"
  auto_create_subnetworks = false
}

# Create a custom subnet
resource "google_compute_subnetwork" "composer_subnet" {
  project = var.cortex_source_project
  name          = "cortex-composer-us-east1"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.composer_vpc.self_link
  region = "us-central1"
}

# Create a firewall rule that allows access from the internet
resource "google_compute_firewall" "allow_internet" {
  project = var.cortex_source_project

  name    = "allow-internet"
  network = google_compute_network.composer_vpc.name
    
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "all"
  }
}

# Create a firewall rule that allows all internal communication
resource "google_compute_firewall" "allow_internal" {
  project = var.cortex_source_project

  name    = "allow-internal"
  network = google_compute_network.composer_vpc.name

  source_ranges = ["10.0.0.0/16"]
  
  allow {
    protocol = "all"
  }
}

# resource "google_org_policy_policy" "os_login" {
#   name   = "projects/${var.cortex_source_project}/policies/compute.requireOsLogin"
#   parent = "projects/${var.cortex_source_project}"

#   spec {
#     rules {
#       enforce = "FALSE"
#     }
#   }
# }

# resource "google_org_policy_policy" "port_logging" {
#   name   = "projects/${var.cortex_source_project}/compute.disableSerialPortLogging"
#   parent = "projects/${var.cortex_source_project}"

#   spec {
#     rules {
#       enforce = "FALSE"
#     }
#   }
# }

# resource "google_org_policy_policy" "shielded_vm" {
#   name   = "projects/${var.cortex_source_project}/compute.requireShieldedVm"
#   parent = "projects/${var.cortex_source_project}"

#   spec {
#     rules {
#       enforce = "FALSE"
#     }
#   }
# }

# resource "google_org_policy_policy" "ip_forwarding" {
#   name   = "projects/${var.cortex_source_project}/compute.vmCanIpForward"
#   parent = "projects/${var.cortex_source_project}"

#   spec {
#     rules {
#       allow_all = "TRUE"
#     }
#   }
# }

# resource "google_org_policy_policy" "vmExternalIpAccess" {
#   name   = "projects/${var.cortex_source_project}/compute.vmExternalIpAccess"
#   parent = "projects/${var.cortex_source_project}"

#   spec {
#     rules {
#       allow_all = "TRUE"
#     }
#   }
# }

# resource "google_org_policy_policy" "external_ip" {
#   name   = "projects/${var.cortex_source_project}/compute.vmExternalIpAccess"
#   parent = "projects/${var.cortex_source_project}"

#   spec {
#     rules {
#       allow_all = "TRUE"
#     }
#   }
# }

# resource "google_org_policy_policy" "restrict_vpc_peering" {
#   name   = "projects/${var.cortex_source_project}/compute.restrictVpcPeering"
#   parent = "projects/${var.cortex_source_project}"

#   spec { 

#     rules {
#       allow_all = "TRUE"

#     }
#   }
# }

# resource "google_org_policy_policy" "account_key_creation" {
#   name   = "projects/${var.cortex_source_project}/iam.disableServiceAccountKeyCreation"
#   parent = "projects/${var.cortex_source_project}"

#   spec {
#     inherit_from_parent = false
#     rules {
#       enforce = "FALSE"
#     }
#   }
# }

resource "google_service_account" "deployment_account" {
  project = var.cortex_source_project

  account_id   = "cortex-deployer"
  display_name = "cortex-deployer"
  description = "User Managed Service Account for Cortex Deployment"
}

resource "google_project_iam_member" "cortex_deployer_binding" {
  for_each = toset(local.cortex_deployer_roles)

  project = var.cortex_source_project
  role    = each.value

  member = "serviceAccount:${google_service_account.deployment_account.email}"
}

# resource "google_composer_environment" "cortex" {
#   name   = "cortex"
#   region = "us-central1"
#   config {
#     software_config {
#       image_version = "composer-2-airflow-2"
#     }


#     node_config {
#       network    = google_compute_network.composer_vpc.id
#       subnetwork = google_compute_subnetwork.composer_subnet.id

#       service_account = google_service_account.deployment_account.name
#       }
#     }
# }
