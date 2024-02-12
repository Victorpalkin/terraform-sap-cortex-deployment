locals {
    services = [
        "bigquery.googleapis.com",
        "cloudbuild.googleapis.com",
        "composer.googleapis.com",
        "storage-component.googleapis.com",
        "cloudresourcemanager.googleapis.com",
        "orgpolicy.googleapis.com",
        "compute.googleapis.com",
        "monitoring.googleapis.com",
        "cloudtrace.googleapis.com",
        "clouddebugger.googleapis.com"
    ]
    project_number = data.google_project.project.number
}

data "google_project" "project" {
    project_id = var.cortex_source_project
}


# resource "google_project_service" "required_api" {
#   for_each = toset( local.services )
  
#   project = var.cortex_source_project
#   service = each.key

#   timeouts {
#     create = "30m"
#     update = "40m"
#   }

#   disable_dependent_services = true
#   lifecycle {
    
#   }
# }

resource "google_bigquery_dataset" "sap_raw" {
  project = var.cortex_source_project
  
  dataset_id                  = var.sap_raw_landing_dataset
  friendly_name               = var.sap_raw_landing_dataset
  description                 = var.sap_raw_landing_dataset
  location                    = var.location
}

resource "google_bigquery_dataset" "sap_cdc_processed" {
  project = var.cortex_source_project
  
  dataset_id                  = var.sap_cdc_processed_dataset
  friendly_name               = var.sap_cdc_processed_dataset
  description                 = var.sap_cdc_processed_dataset
  location                    = var.location
}

resource "google_bigquery_dataset" "sap_reporting" {
  project = var.cortex_target_project
  
  dataset_id                  = var.reporting_dataset
  friendly_name               = var.reporting_dataset
  description                 = var.reporting_dataset
  location                    = var.location
}

resource "google_bigquery_dataset" "sap_ml_dataset" {
  project = var.cortex_source_project
  
  dataset_id                  = var.ml_models_dataset
  friendly_name               = var.ml_models_dataset
  description                 = var.ml_models_dataset
  location                    = var.location
}

resource "google_storage_bucket" "dags" {
  project = var.cortex_source_project


  name          = "${var.cortex_source_project}-dags"
  location      = var.location
  force_destroy = true

  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "logs" {
  project = var.cortex_source_project

  name          = "${var.cortex_source_project}-logs"
  location      = var.location
  force_destroy = true

  uniform_bucket_level_access = true


}


resource "google_storage_bucket_iam_member" "dags_policy" {
  bucket = google_storage_bucket.dags.name
  role = "roles/storage.admin"
  member = "serviceAccount:${local.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_storage_bucket_iam_member" "logs_policy" {
  bucket = google_storage_bucket.logs.name
  role = "roles/storage.admin"
  member = "serviceAccount:${local.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloud_build_bq_editor" {
  project = var.cortex_source_project
  role    = "roles/bigquery.dataEditor"

  member = "serviceAccount:${local.project_number}@cloudbuild.gserviceaccount.com"
  
}

resource "google_project_iam_member" "cloud_build_bq_user" {
  project = var.cortex_source_project
  role    = "roles/bigquery.jobUser"

  member = "serviceAccount:${local.project_number}@cloudbuild.gserviceaccount.com"
}


resource "local_file" "deploy_script" {
    content  = templatefile("${path.module}/template_script.sh", {
        cortex_source_project = var.cortex_source_project,
        cortex_target_project = var.cortex_target_project,
        bq_processed_dataset = var.sap_cdc_processed_dataset,
        bq_raw_dataset = var.sap_raw_landing_dataset,
        bq_reporting_dataset = var.reporting_dataset,
        bq_ml_dataset = var.ml_models_dataset,
        logs_bucket = google_storage_bucket.logs.name,
        dags_bucket = google_storage_bucket.dags.name,
        if_test_data = "true",
        if_cdc_data = "true",
        sap_client = "100",
        location = var.location
        if_sap = "true"
        if_sfdc = "true"
        if_ext = "true"
    })
    filename = "./deploy_script.sh"
    depends_on = [
      google_project_iam_member.cloud_build_bq_editor,
      google_storage_bucket_iam_member.logs_policy, 
      google_project_iam_member.cloud_build_bq_user, 
      google_storage_bucket_iam_member.dags_policy 
    ]
}


module "gcloud" {
  source = "terraform-google-modules/gcloud/google"
  version = "~> 3.1.0"

  platform = "linux"
  additional_components = []

  create_cmd_entrypoint = "gcloud"
  create_cmd_body = "builds submit --config ${path.module}/cloudbuild.yaml --project ${var.cortex_source_project} --timeout=7200"

  skip_download = false
  upgrade = false
  module_depends_on = [ local_file.deploy_script ]
  gcloud_sdk_version = "399.0.0"
  service_account_key_file = var.service_account_key_file
}



