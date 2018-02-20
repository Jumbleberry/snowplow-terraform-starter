data "aws_vpc" "default" {
  default = true
}

resource "aws_elasticsearch_domain" "es" {
  domain_name           = "snowplow-elasticsearch"
  elasticsearch_version = "5.5"

  cluster_config {
    instance_type   = "t2.small.elasticsearch"
    instance_count  = 2
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

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Condition": {
                "IpAddress": {"aws:SourceIp": ["${chomp(var.machine_ip)}/32", "${data.aws_vpc.default.cidr_block}"]}
            }
        }
    ]
}
CONFIG
}
