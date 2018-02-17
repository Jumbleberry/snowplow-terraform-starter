data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
}

resource "aws_elasticsearch_domain" "es" {
  domain_name           = "snowplow-elasticsearch"
  elasticsearch_version = "1.5"

  cluster_config {
    instance_type   = "t2.micro.elasticsearch"
    instance_count  = 1
  }

  vpc_options {
    security_group_ids = ["${aws_security_group.snowplow-elasticsearch.id}"]
    subnet_ids         = ["${data.aws_subnet_ids.default.ids[0]}"]
  }

  advanced_options {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 20
  }
}
