provider "google" {
  credentials = file("/Users/abhaydeshpande/Downloads/pkey-gcloud/velvety-ground-414100-5d0dae2ed105.json")
  project     = var.project_id
  region      = var.region
}
