terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_service_account" "vm_sa" {
  account_id   = "vm-sa-wiki"
  display_name = "VM Instance Service Account"
  project      = var.project
}

resource "google_compute_disk" "balanced_disk" {
  name  = "balanced-persistent-disk"
  type  = "pd-balanced"
  zone  = var.zone
  size  = 10
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "e2-small"
  tags         = ["web", "dev"]
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
     
    }
  }

  attached_disk {
    source      = google_compute_disk.balanced_disk.id
    device_name = "extra-disk"
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_firewall" "allow_web_traffic" {
  name    = "terraform-firewall-allow-web"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web" , "dev"]
}

output "ip" {
  value = google_compute_instance.vm_instance.network_interface.0.network_ip
}

output "external_ip" {
  value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}
