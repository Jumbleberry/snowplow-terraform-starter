# Configuration files
data "template_file" "enrich-config" {
    template = "${file("${path.module}/config.hocon.tpl")}"

    vars {
        stream-in         = "${var.stream_in}"
        good-stream-out   = "${var.good_stream_out}"
        bad-stream-out    = "${var.bad_stream_out}"
        aws-region        = "${var.aws_region}"
        access-key        = "${var.operator_access_key}"
        secret-key        = "${var.operator_secret_key}"
    }
}

data "template_file" "resolver-config" {
    template = "${file("${path.module}/resolver.js.tpl")}"
}

# EC2 Server
resource "aws_instance" "enrich" {
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "t2.micro"
  key_name        = "${var.key_pair_name}"

  lifecycle {
    ignore_changes = ["ami"]
  }

  security_groups = [
    "${aws_security_group.snowplow-enrich.name}",
  ]

  tags {
    Name = "snowplow-enrich"
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
      "${data.template_file.enrich-config.rendered}",
      "FILEXXX",
      "cat <<FILEXXX > /home/ubuntu/resolver.js",
      "${data.template_file.resolver-config.rendered}",
      "FILEXXX",
      "wget http://dl.bintray.com/snowplow/snowplow-generic/snowplow_stream_enrich_${var.enrich_version}.zip",
      "unzip snowplow_stream_enrich_${var.enrich_version}.zip",
      "echo \"@reboot  java -jar /home/ubuntu/snowplow-stream-enrich-${var.enrich_version}.jar --config /home/ubuntu/config.hocon --resolver file:/home/ubuntu/resolver.js &> /home/ubuntu/enrich.log\" | crontab -",
      "nohup java -jar /home/ubuntu/snowplow-stream-enrich-${var.enrich_version}.jar --config /home/ubuntu/config.hocon --resolver file:/home/ubuntu/resolver.js &> /home/ubuntu/enrich.log &",
      "sleep 1"
    ]

    connection {
      type          = "ssh"
      user          = "ubuntu"
      private_key   = "${file("${var.key_pair_loc}")}"
    }
  }
}
