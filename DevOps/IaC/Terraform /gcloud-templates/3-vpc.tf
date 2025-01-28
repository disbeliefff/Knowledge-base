resource "google_compute_network" "vpc" {
  name                            = "main"
  routing_mode                    = "REGIONAL"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true

  depends_on = [google_project_service.api]
}

# full private VPC
# need for NAT gateway
resource "google_compute_route" "default_route" {
  name             = "default_route"
  dest_range       = "0.0.0.0/0"
  network          = "google_compute_network.vpc.name"
  next_hop_gateway = "default-internet-gatewaty"
}