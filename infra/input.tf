variable "project" {
  description = "project id"
  default     = "quic-video"
}

variable "region" {
  description = "region"
  default     = "us-central1"
}

variable "zone" {
  description = "zone"
  default     = "us-central1-a"
}

variable "email" {
  description = "Your email address, used for LetsEncrypt"
  default     = "kixelated@gmail.com"
}

variable "domain" {
  description = "domain name"
  default     = "quic.video"
}

variable "docker_relay" {
  description = "Docker image for moq-relay"
  default     = "docker.io/kixelated/moq-relay:0.8.0"
}

variable "docker_hang" {
  description = "Docker image for hang"
  default     = "docker.io/kixelated/hang:0.2.0"
}

# Too complicated to specify via flags, so do it here.
locals {
  relays = {
    us-central = { # Iowa
      region  = "us-central1"
      zone    = "us-central1-a",
      machine = "t2d-standard-1",
      image   = "cos-cloud/cos-stable",
    },
    europe-west = { # Netherlands
      region  = "europe-west4",
      zone    = "europe-west4-b",
      machine = "t2d-standard-1",
      image   = "cos-cloud/cos-stable",
    },
    asia-southeast = { # Singapore
      region  = "asia-southeast1",
      zone    = "asia-southeast1-c",
      machine = "t2d-standard-1",
      image   = "cos-cloud/cos-stable",
    },
  }
  pub = {
    region  = "us-central1"
    zone    = "us-central1-a",
    machine = "t2d-standard-1",
    image   = "cos-cloud/cos-stable",
  }
  # To save an instance, we use a relay as a root
  # In the future we should have a dedicated instance/cluster for this.
  root = "relay-us-central.us-central1-a"
}
