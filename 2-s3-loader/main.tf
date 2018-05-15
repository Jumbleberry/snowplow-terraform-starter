# Configuration file
data "template_file" "loader-config" {
    template = "${file("${path.module}/config.hocon.tpl")}"

    vars {
        stream-in             = "${var.stream_in}"
        s3-bucket-out         = "${var.s3_bucket_out}"
        bad-stream-out        = "${var.bad_stream_out}"
        aws-region            = "${var.aws_region}"
        access-key            = "${var.operator_access_key}"
        secret-key            = "${var.operator_secret_key}"
    }
}

data "template_file" "supervisord" {
    template = "${file("${path.module}/supervisord.tpl.conf")}"

    vars {
      loader-version             = "${var.loader_version}"
    }
}

# EC2 Server
resource "aws_instance" "loader" {
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "t2.micro"
  key_name        = "${var.key_pair_name}"

  lifecycle {
    ignore_changes = ["ami"]
  }

  security_groups = [
    "${aws_security_group.loader.name}",
  ]

  tags {
    Name = "hydra-loader"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y unzip openjdk-8-jdk",
      "sudo apt-get install -y supervisor",
      "sudo service supervisor restart",
      "mkdir -p /home/ubuntu/logs",
      "sudo apt-get install -y lzop liblzo2-dev"
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
      "${data.template_file.loader-config.rendered}",
      "FILEXXX",
      "wget http://dl.bintray.com/snowplow/snowplow-generic/snowplow_s3_loader_${var.loader_version}.zip",
      "unzip snowplow_s3_loader_${var.loader_version}.zip",
      "sudo chown ubuntu /etc/supervisor/conf.d/",
      "cat <<FILEXXX > /etc/supervisor/conf.d/loader.conf",
      "${data.template_file.supervisord.rendered}",
      "FILEXXX",
      "sudo supervisorctl reread && sudo supervisorctl update",
      "sleep 1"
    ]

    connection {
      type          = "ssh"
      user          = "ubuntu"
      private_key   = "${file("${var.key_pair_loc}")}"
    }
  }
}
