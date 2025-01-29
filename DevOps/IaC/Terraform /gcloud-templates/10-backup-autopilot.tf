resource "google_container_cluster" "primary" {
  name               = "autopilot-cluster"
  location           = ""
  enable_autopilot = true
  ip_allocation_policy {
  }
  release_channel {
    channel = "RAPID"
  }
  addons_config {
    gke_backup_agent_config {
      enabled = true
    }
  }
  deletion_protection  = true
  network       = "default"
  subnetwork    = "default"
}

resource "google_gke_backup_backup_plan" "autopilot" {
  name = "autopilot-plan"
  cluster = google_container_cluster.primary.id
  location = ""
  backup_config {
    include_volume_data = true
    include_secrets = true
    all_namespaces = true
  }
}