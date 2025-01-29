resource "google_container_cluster" "autopilot_cluster" {
  name     = "dev-autopilot-cluster"
  location = local.region

  enable_autopilot = true

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {}

  resource_labels = {
    environment = "dev"
    managed_by  = "terraform"
  }
}


resource "google_cloud_scheduler_job" "scale_down" {
  name      = "scale-down-workloads"
  schedule  = "0 18 * * 1-5"
  time_zone = "UTC"

  http_target {
    http_method = "POST"
    uri         = "https://container.googleapis.com/v1/projects/${local.project_id}/locations/${local.region}/clusters/${google_container_cluster.autopilot_cluster.name}/workloads:scale"


    body = base64encode(jsonencode({
      "deployments": ["*"],
      "replicas": 0
    }))
  }
}

resource "google_cloud_scheduler_job" "scale_up" {
  name      = "scale-up-workloads"
  schedule  = "0 8 * * 1-5"
  time_zone = "UTC"

  http_target {
    http_method = "POST"
    uri         = "https://container.googleapis.com/v1/projects/${local.project_id}/locations/${local.region}/clusters/${google_container_cluster.autopilot_cluster.name}/workloads:scale"



    body = base64encode(jsonencode({
      "deployments": ["*"],
      "replicas": 1
    }))
  }
}