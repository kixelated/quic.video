variable "region" {
  description = "GCloud Region"
}

variable "zone" {
  description = "GCloud Zone"
}

variable "dns_zone" {
  description = "The name of the GCloud DNS zone"
}

variable "domain" {
  description = "The relay domain"
}

variable "instances" {
  type        = number
  description = "Instance count"
}

variable "image" {
  type = string
}

variable "email" {
  description = "Your email address"
}

variable "crt" {
  description = "The PEM certificate for *.domain"
}

variable "key" {
  description = "The PEM key for *.domain"
}
