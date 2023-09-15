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
  description = "The root domain"
}

variable "instances" {
  type        = number
  description = "Instance count"
}

variable "image" {
  type = string
}
