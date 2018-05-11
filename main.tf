# Build necessary IAM roles
module "snowplow-users" { 
  source = "iam-users" 
}

# Set up Kinesis Streams
module "analytics-collector-good" {
  source = "kinesis-stream"
  name = "Analytics-Collector-Good"
}

module "analytics-collector-bad" {
  source = "kinesis-stream"
  name = "Analytics-Collector-Bad"
}

module "analytics-load-bad" {
  source = "kinesis-stream"
  name = "Analytics-Load-Bad"
}

# Set up S3 bucket
module "analytics-raw-data" {
  source = "s3-bucket"
  bucket = "jb-analytics-raw-data"
  name = "JB-Analytics-Raw-Data"
}

# Get local machine's IP
data "http" "my-ip" {
  url = "http://icanhazip.com"
}

module "snowplow-collector" {
  source              =  "1-snowplow-collector"
  aws_region          = "${var.aws_region}"
  machine_ip          = "${data.http.my-ip.body}"
  key_pair_name       = "${var.key_pair_name}"
  key_pair_loc        = "${var.key_pair_location}"
  operator_access_key = "${module.snowplow-users.operator-access-key}"
  operator_secret_key = "${module.snowplow-users.operator-secret-key}"

  good_stream_name    = "${module.analytics-collector-good.stream-name}"
  bad_stream_name     = "${module.analytics-collector-bad.stream-name}"
  ssl_acm_arn         = "${var.ssl_acm_arn}"
}

module "snowplow-loader" {
  source              =  "2-snowplow-s3-loader"
  aws_region          = "${var.aws_region}"
  machine_ip          = "${data.http.my-ip.body}"
  key_pair_name       = "${var.key_pair_name}"
  key_pair_loc        = "${var.key_pair_location}"
  operator_access_key = "${module.snowplow-users.operator-access-key}"
  operator_secret_key = "${module.snowplow-users.operator-secret-key}"

  stream_in           = "${module.analytics-collector-good.stream-name}"
  s3_bucket_out       = "${module.analytics-raw-data.bucket}"
  bad_stream_out      = "${module.analytics-load-bad.stream-name}"
}
