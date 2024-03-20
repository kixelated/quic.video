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

variable "commit" {
  type        = bool
  description = "use a one-year usage commit"
  default     = false
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
      machine = "t2d-standard-1",
      commit = var.commit ? {
        cpu    = 1,
        memory = 4,
      } : null,
    },
/*
    europe-west = { # Netherlands
      region  = "europe-west4",
      zone    = "europe-west4-b",
      machine = "t2d-standard-1",
      commit = var.commit ? {
        cpu    = 1,
        memory = 4,
      } : null,
    },
    asia-southeast = { # Singapore
      region  = "asia-southeast1",
      zone    = "asia-southeast1-c",
      machine = "t2d-standard-1",
      commit = var.commit ? {
        cpu    = 1,
        memory = 4,
      } : null,
    }
*/
  }
  pub = {
    region  = "us-central1"
    zone    = "us-central1-f",
    machine = "t2d-standard-1",
    commit = var.commit ? {
      cpu    = 1,
      memory = 4,
    } : null,
  }
}
