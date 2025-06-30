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

variable "docker_relay" {
  description = "Docker image for moq-relay"
  default     = "docker.io/kixelated/moq-relay:0.7.6"
}

variable "docker_hang" {
  description = "Docker image for hang"
  default     = "docker.io/kixelated/hang:0.1.8"
}

# cargo run --bin moq-token -- --key root.jwk generate
variable "root_key" {
  description = "root key"
  sensitive   = true
}

# A token used to publish demo/bbb.hang
# This is very manual/crude, but I don't want someone to hijack the broadcast.
# cargo run --bin moq-token -- --key root.jwk sign --path "demo" --publish "" > demo.jwt
variable "demo_token" {
  description = "demo token"
  sensitive   = true
}

# cargo run --bin moq-token -- --key root.jwk sign --publish "" --publish-secondary --subscribe "" --subscribe-primary > cluster.jwt
variable "cluster_token" {
  description = "cluster token"
  sensitive   = true
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
