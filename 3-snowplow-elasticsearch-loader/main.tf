# Configuration file
data "template_file" "initialize-elasticsearch" {
    template = "${file("${path.module}/initialize_elasticsearch.sh.tpl")}"

    vars {
      elasticsearch-endpoint = "${aws_elasticsearch_domain.es.endpoint}"
    }
}

data "template_file" "loader-config" {
    template = "${file("${path.module}/config.hocon.tpl")}"

    vars {
        stream-in             = "${var.stream_in}"
        bad-stream-out        = "${var.bad_stream_out}"
        elasticsearch-url     = "${aws_elasticsearch_domain.es.endpoint}"
        aws-region            = "${var.aws_region}"
        access-key            = "${var.operator_access_key}"
        secret-key            = "${var.operator_secret_key}"
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
    "${aws_security_group.snowplow-loader.name}",
  ]

  tags {
    Name = "snowplow-loader"
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
      "cat <<FILEXXX > /home/ubuntu/initialize_elasticsearch.sh",
      "${data.template_file.initialize-elasticsearch.rendered}",
      "FILEXXX",
      "bash /home/ubuntu/initialize_elasticsearch.sh",
      "sleep 1"
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
      "wget http://dl.bintray.com/snowplow/snowplow-generic/snowplow_elasticsearch_loader_http_${var.loader_version}.zip",
      "unzip snowplow_elasticsearch_loader_http_${var.loader_version}.zip",
      "echo \"@reboot  java -jar /home/ubuntu/snowplow_elasticsearch_loader_http_${var.loader_version}.jar --config /home/ubuntu/config.hocon &> /home/ubuntu/loader.log\" | crontab -",
      "nohup java -jar /home/ubuntu/snowplow_elasticsearch_loader_http_${var.loader_version}.jar --config /home/ubuntu/config.hocon &> /home/ubuntu/loader.log &",
      "sleep 1"
    ]

    connection {
      type          = "ssh"
      user          = "ubuntu"
      private_key   = "${file("${var.key_pair_loc}")}"
    }
  }
}
