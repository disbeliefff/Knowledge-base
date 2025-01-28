## Worker nodes example

resource "google_service_account" "gke" {
  account_id = "demo-gke"
}

resource "google_container_node_pool" "general" {
  name = "general"
  cluster = google_container_cluster.gke.id

  autoscaling {
    total_min_node_count = 1
    total_max_node_count = 3
  }

  management {
    auto_repair = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = false
    machine_type = "machine-type"

    labels = {
      role = "general"
    }

    service_account = google_service_account.gke.email
    oauth_scopes = [
      "www.googleapis.com/blablabla"
    ]
  }
}

## Useless when use own logging and monitoring system

# resource "google_project_iam_member" "gke_logging" {
#   project = local.project_id
#   role    = "roles/logging.logeWriter"
#   member  = "serviceAccount:${google_service_account.gke.email}"
# }


# resource "google_project_iam_member" "gke_metrics" {
#   project = local.project_id
#   role    = "roles/logging.metricsWriter"
#   member  = "serviceAccount:${google_service_account.gke.email}"
# }

