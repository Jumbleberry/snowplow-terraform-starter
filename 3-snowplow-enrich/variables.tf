variable "enrich_version" {
  default = "0.13.0"
}

variable "machine_ip" {
  type = "string"
}

variable "raw_bucket" {
  type = "string"
}

variable "processing_bucket" {
  type = "string"
}

variable "enriched_bucket" {
  type = "string"
}

variable "shredded_bucket" {
  type = "string"
}

variable "key_pair_name" {
  type = "string"
}

variable "key_pair_loc" {
  type = "string"
}

variable "aws_region" {
  type = "string"
}

variable "operator_access_key" {
  type = "string"
}

variable "operator_secret_key" {
  type = "string"
}
