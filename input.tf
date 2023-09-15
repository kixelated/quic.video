variable "project" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "zone" {
  description = "zone"
}

variable "domain" {
  description = "domain name"
}

variable "relay_image" {
  description = "name of the relay docker image"
  default     = "moq-rs:latest"
}
