# Build necessary IAM roles & users
module "hydra-users" {
  source = "iam-users"
}

# Set up Kinesis Streams 
module "hydra-collector-good" {
  source = "kinesis-stream"
  name   = "Hydra-Collector-Good"
}

module "hydra-collector-bad" {
  source = "kinesis-stream"
  name   = "Hydra-Collector-Bad"
}

module "hydra-enrich-good" {
  source = "kinesis-stream"
  name   = "Hydra-Enrich-Good"
}

module "hydra-enrich-bad" {
  source = "kinesis-stream"
  name   = "Hydra-Enrich-Bad"
}

# Set up kinesis consumer state table
module "hydra-collector-good-enrich-checkpoint" {
  source = "dynamodb-table"
  name = "Hydra-Collector-Good-Enrich-Checkpoint"
}

# Get local machine's IP
data "http" "my-ip" {
  url = "http://icanhazip.com"
}

module "collector" {
  source                = "1-collector"
  aws_region            = "${var.aws_region}"
  machine_ip            = "${data.http.my-ip.body}"
  key_pair_name         = "${var.key_pair_name}"
  key_pair_loc          = "${var.key_pair_location}"
  operator_access_key   = "${module.hydra-users.operator-access-key}"
  operator_secret_key   = "${module.hydra-users.operator-secret-key}"

  good_stream_out       = "${module.hydra-collector-good.stream-name}"
  bad_stream_out        = "${module.hydra-collector-bad.stream-name}"
  ssl_acm_arn           = "${var.ssl_acm_arn}"
}

module "enrich" {
  source                = "2-enrich"
  machine_ip            = "${data.http.my-ip.body}"
  aws_region            = "${var.aws_region}"
  key_pair_name         = "${var.key_pair_name}"
  key_pair_loc          = "${var.key_pair_location}"
  operator_access_key   = "${module.hydra-users.operator-access-key}"
  operator_secret_key   = "${module.hydra-users.operator-secret-key}"

  stream_in             = "${module.hydra-collector-good.stream-name}"
  stream_in_checkpoint  = "${module.hydra-collector-good-enrich-checkpoint.id}"
  good_stream_out       = "${module.hydra-enrich-good.stream-name}"
  bad_stream_out        = "${module.hydra-enrich-bad.stream-name}"
}
