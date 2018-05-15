# Build necessary IAM roles & users
module "snowplow-users" {
  source = "iam-users"
}

Set up Kinesis Streams module "analytics-collector-good" {
  source = "kinesis-stream"
  name   = "Analytics-Collector-Good"
}

module "analytics-collector-bad" {
  source = "kinesis-stream"
  name   = "Analytics-Collector-Bad"
}

module "analytics-load-bad" {
  source = "kinesis-stream"
  name   = "Analytics-Load-Bad"
}

# Set up S3 bucket
module "analytics-raw-data" {
  source = "s3-bucket"
  bucket = "khanh-analytics-raw-data"
  name   = "JB-Analytics-Raw-Data"
}

module "analytics-processing-data" {
  source = "s3-bucket"
  bucket = "analytics-processing-data"
  name   = "JB-Analytics-Processing-Data"
}

module "analytics-enriched-data" {
  source = "s3-bucket"
  bucket = "analytics-enriched-data"
  name   = "JB-Analytics-Enriched-Data"
}

module "analytics-shredded-data" {
  source = "s3-bucket"
  bucket = "analytics-shredded-data"
  name   = "JB-Analytics-Shredded-Data"
}

# Get local machine's IP
data "http" "my-ip" {
  url = "http://icanhazip.com"
}

module "snowplow-collector" {
  source              = "1-snowplow-collector"
  aws_region          = "${var.aws_region}"
  machine_ip          = "${data.http.my-ip.body}"
  key_pair_name       = "${var.key_pair_name}"
  key_pair_loc        = "${var.key_pair_location}"
  operator_access_key = "${module.snowplow-users.operator-access-key}"
  operator_secret_key = "${module.snowplow-users.operator-secret-key}"

  good_stream_name = "${module.analytics-collector-good.stream-name}"
  bad_stream_name  = "${module.analytics-collector-bad.stream-name}"
  ssl_acm_arn      = "${var.ssl_acm_arn}"
}

module "snowplow-loader" {
  source              = "2-snowplow-s3-loader"
  aws_region          = "${var.aws_region}"
  machine_ip          = "${data.http.my-ip.body}"
  key_pair_name       = "${var.key_pair_name}"
  key_pair_loc        = "${var.key_pair_location}"
  operator_access_key = "${module.snowplow-users.operator-access-key}"
  operator_secret_key = "${module.snowplow-users.operator-secret-key}"

  stream_in      = "${module.analytics-collector-good.stream-name}"
  s3_bucket_out  = "${module.analytics-raw-data.bucket}"
  bad_stream_out = "${module.analytics-load-bad.stream-name}"
}

module "snowplow-enrich" {
  source              = "3-snowplow-enrich"
  machine_ip          = "${data.http.my-ip.body}"
  aws_region          = "${var.aws_region}"
  key_pair_name       = "${var.key_pair_name}"
  key_pair_loc        = "${var.key_pair_location}"
  operator_access_key = "${module.snowplow-users.operator-access-key}"
  operator_secret_key = "${module.snowplow-users.operator-secret-key}"

  raw_bucket        = "${module.analytics-raw-data.bucket}"
  processing_bucket = "${module.analytics-processing-data.bucket}"
  enriched_bucket   = "${module.analytics-enriched-data.bucket}"
  shredded_bucket   = "${module.analytics-shredded-data.bucket}"
}
