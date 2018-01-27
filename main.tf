# Build necessary IAM roles
module "snowplow-users" { source = "iam-users" }

# Set up Kinesis Streams
module "analytics-good" {
  source = "kinesis-stream"
  name = "AnalyticsCollector-Good"
}

module "analytics-bad" {
  source = "kinesis-stream"
  name = "AnalyticsCollector-Bad"
}

module "analytics-enrich-good" {
  source = "kinesis-stream"
  name = "AnalyticsEnriched-Good"
}

module "analytics-enrich-bad" {
  source = "kinesis-stream"
  name = "AnalyticsEnriched-Bad"
}

# Get local machine's IP
data "http" "my-ip" {
  url = "http://icanhazip.com"
}

module "snowplow-collector" {
  source            =  "snowplow-collector"
  aws_region          = "${var.aws_region}"
  machine_ip          = "${data.http.my-ip.body}"
  key_pair_name       = "${var.key_pair_name}"
  key_pair_loc        = "${var.key_pair_location}"
  operator_access_key = "${module.snowplow-users.operator-access-key}"
  operator_secret_key = "${module.snowplow-users.operator-secret-key}"

  good_stream_name    = "${module.analytics-good.stream-name}"
  bad_stream_name     = "${module.analytics-bad.stream-name}"
  ssl_acm_arn         = "${var.ssl_acm_arn}"
}

module "snowplow-enrich" {
  source            =  "snowplow-enrich"
  aws_region          = "${var.aws_region}"
  machine_ip          = "${data.http.my-ip.body}"
  key_pair_name       = "${var.key_pair_name}"
  key_pair_loc        = "${var.key_pair_location}"
  operator_access_key = "${module.snowplow-users.operator-access-key}"
  operator_secret_key = "${module.snowplow-users.operator-secret-key}"

  stream_in           = "${module.analytics-good.stream-name}"
  good_stream_out     = "${module.analytics-enrich-good.stream-name}"
  bad_stream_out      = "${module.analytics-enrich-bad.stream-name}"
}
