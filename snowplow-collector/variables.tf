variable "machine_ip" { type = "string" }
variable "key_pair_name" { type = "string" }
variable "key_pair_loc" { type = "string" }
variable "aws_region" { type = "string" }

variable "good_stream_name" { type = "string" }
variable "bad_stream_name" { type = "string" }
variable "collector_version" { default = "0.12.0"}

variable "operator_access_key" { type = "string" }
variable "operator_secret_key" { type = "string" }

variable "ssl_acm_arn" { type = "string" }
