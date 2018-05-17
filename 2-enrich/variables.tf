variable "stream_in" { type = "string" }
variable "stream_in_checkpoint" { type = "string" }
variable "good_stream_out" { type = "string" }
variable "bad_stream_out" { type = "string" }

variable "enrich_version" { default = "0.13.0" }

variable "machine_ip" { type = "string" }
variable "key_pair_name" { type = "string" }
variable "key_pair_loc" { type = "string" }
variable "aws_region" { type = "string" }

variable "operator_access_key" { type = "string" }
variable "operator_secret_key" { type = "string" }
