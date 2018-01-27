# Configuration file
data "template_file" "collector-config" {
    template = "${file("${path.module}/config.hocon.tpl")}"

    vars {
        good-stream-name  = "${var.good_stream_name}"
        bad-stream-name   = "${var.bad_stream_name}"
        aws-region        = "${var.aws_region}"
        access-key        = "${var.operator_access_key}"
        secret-key        = "${var.operator_secret_key}"
    }
}

# EC2 Server
resource "aws_instance" "collector" {
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "t2.micro"
  key_name        = "${var.key_pair_name}"

  lifecycle {
    ignore_changes = ["ami"]
  }

  security_groups = [
    "${aws_security_group.snowplow-collector.name}",
  ]

  tags {
    Name = "snowplow-collector"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y unzip openjdk-8-jdk",
    ]

    connection {
      type          = "ssh"
      user          = "ubuntu"
      private_key   = "${file("${var.key_pair_loc}")}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "cat <<FILEXXX > /home/ubuntu/config.hocon",
      "${data.template_file.collector-config.rendered}",
      "FILEXXX",
      "wget http://dl.bintray.com/snowplow/snowplow-generic/snowplow_scala_stream_collector_${var.collector_version}.zip",
      "unzip snowplow_scala_stream_collector_${var.collector_version}.zip",
      "echo \"@reboot  java -jar /home/ubuntu/snowplow-stream-collector-${var.collector_version}.jar --config /home/ubuntu/config.hocon &> /home/ubuntu/collector.log\" | crontab -",
      "nohup java -jar /home/ubuntu/snowplow-stream-collector-${var.collector_version}.jar --config /home/ubuntu/config.hocon &> /home/ubuntu/collector.log &",
      "sleep 1"
    ]

    connection {
      type          = "ssh"
      user          = "ubuntu"
      private_key   = "${file("${var.key_pair_loc}")}"
    }
  }
}
