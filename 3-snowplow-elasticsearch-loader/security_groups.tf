resource "aws_security_group" "snowplow-loader" {
  name        = "snowplow-loader"
  description = "Our SSH inbound, and all outbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(var.machine_ip)}/32"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "snowplow-elasticsearch" {
  name        = "snowplow-elasticsearch"
  description = "Loader inbound, and all outbound traffic"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = ["${aws_security_group.snowplow-loader.id}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
