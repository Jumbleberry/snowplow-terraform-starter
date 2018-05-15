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

module "hydra-load-bad" {
  source = "kinesis-stream"
  name   = "Hydra-Load-Bad"
}

# Set up kinesis consumer state dynamoDB table
module "kinesis-consumer-state-table" {
  source = "dynamodb-table"
  name = "kinesis_consumer_s3_loader_state"
}

# Set up S3 bucket
module "hydra-raw-data" {
  source = "s3-bucket"
  bucket = "jb-hydra-raw-data"
  name   = "JB-Hydra-Raw-Data"
}

module "hydra-processing-data" {
  source = "s3-bucket"
  bucket = "jb-hydra-processing-data"
  name   = "JB-Hydra-Processing-Data"
}

module "hydra-enriched-data" {
  source = "s3-bucket"
  bucket = "jb-hydra-enriched-data"
  name   = "JB-Hydra-Enriched-Data"
}

module "hydra-shredded-data" {
  source = "s3-bucket"
  bucket = "jb-hydra-shredded-data"
  name   = "JB-Hydra-Shredded-Data"
}

# Get local machine's IP
data "http" "my-ip" {
  url = "http://icanhazip.com"
}

module "collector" {
  source              = "1-collector"
  aws_region          = "${var.aws_region}"
  machine_ip          = "${data.http.my-ip.body}"
  key_pair_name       = "${var.key_pair_name}"
  key_pair_loc        = "${var.key_pair_location}"
  operator_access_key = "${module.hydra-users.operator-access-key}"
  operator_secret_key = "${module.hydra-users.operator-secret-key}"

  good_stream_name    = "${module.hydra-collector-good.stream-name}"
  bad_stream_name     = "${module.hydra-collector-bad.stream-name}"
  ssl_acm_arn         = "${var.ssl_acm_arn}"
}

module "loader" {
  source              = "2-s3-loader"
  aws_region          = "${var.aws_region}"
  machine_ip          = "${data.http.my-ip.body}"
  key_pair_name       = "${var.key_pair_name}"
  key_pair_loc        = "${var.key_pair_location}"
  operator_access_key = "${module.hydra-users.operator-access-key}"
  operator_secret_key = "${module.hydra-users.operator-secret-key}"

  stream_in           = "${module.hydra-collector-good.stream-name}"
  s3_bucket_out       = "${module.hydra-raw-data.bucket}"
  bad_stream_out      = "${module.hydra-load-bad.stream-name}"
  consumer_name       = "${module.kinesis-consumer-state-table.id}"
}

module "enricher" {
  source              = "3-enricher"
  machine_ip          = "${data.http.my-ip.body}"
  aws_region          = "${var.aws_region}"
  key_pair_name       = "${var.key_pair_name}"
  key_pair_loc        = "${var.key_pair_location}"
  operator_access_key = "${module.hydra-users.operator-access-key}"
  operator_secret_key = "${module.hydra-users.operator-secret-key}"

  raw_bucket          = "${module.hydra-raw-data.bucket}"
  processing_bucket   = "${module.hydra-processing-data.bucket}"
  enriched_bucket     = "${module.hydra-enriched-data.bucket}"
  shredded_bucket     = "${module.hydra-shredded-data.bucket}"
}
