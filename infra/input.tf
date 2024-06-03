variable "project" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "zone" {
  description = "zone"
}

variable "email" {
  description = "Your email address, used for LetsEncrypt"
}

variable "domain" {
  description = "domain name"
}

variable "image_pub" {
  description = "moq-pub image"
  default     = "docker.io/kixelated/moq-pub"
}

variable "image_relay" {
  description = "moq-relay image"
  default     = "docker.io/kixelated/moq-rs"
}

# Too complicated to specify via flags, so do it here.
locals {
  relays = {
    us-central = { # Iowa
      region  = "us-central1"
      zone    = "us-central1-a",
      machine = "t2a-standard-1",
      image   = "cos-cloud/cos-arm64-stable",
    },
    europe-west = { # Netherlands
      region  = "europe-west4",
      zone    = "europe-west4-b",
      machine = "t2a-standard-1",
      image   = "cos-cloud/cos-arm64-stable",
    },
    asia-southeast = { # Singapore
      region  = "asia-southeast1",
      zone    = "asia-southeast1-c",
      machine = "t2a-standard-1",
      image   = "cos-cloud/cos-arm64-stable",
    }
  }
  pub = {
    region  = "us-central1"
    zone    = "us-central1-f",
    machine = "t2a-standard-1",
    image   = "cos-cloud/cos-arm64-stable",
  }
}
