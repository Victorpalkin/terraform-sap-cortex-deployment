# terraform {
#   required_providers {
#     google = {
#       source  = "hashicorp/google"
#       version = "4.27.0"
#     }
#   }
# }

locals {
  build_default_sa = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

provider "google" {
  project = var.gcp_project_id
}

data "google_project" "project" {}

module "cortex" {
  source = "./cortex-module"

  cortex_source_project = var.gcp_project_id
  cortex_target_project = var.gcp_project_id

  service_account_key_file = var.service_account_key_file
}

module "ai_challenge" {
  source = "./ai-challenge-module"

}

