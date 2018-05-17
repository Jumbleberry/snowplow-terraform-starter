# Configuration files
data "template_file" "enrich-config" {
    template = "${file("${path.module}/config.hocon.tpl")}"

    vars {
        stream-in             = "${var.stream_in}"
        stream-in-checkpoint  = "${var.stream_in_checkpoint}"
        good-stream-out       = "${var.good_stream_out}"
        bad-stream-out        = "${var.bad_stream_out}"
        aws-region            = "${var.aws_region}"
        access-key            = "${var.operator_access_key}"
        secret-key            = "${var.operator_secret_key}"
    }
}

data "template_file" "supervisord" {
    template = "${file("${path.module}/supervisord.tpl.conf")}"

    vars {
      enrich-version = "${var.enrich_version}"
    }
}

data "template_file" "resolver-config" {
    template = "${file("${path.module}/resolver.js.tpl")}"
}

data "template_file" "enrichment-referer-parser" {
    template = "${file("${path.module}/enrichments/referer_parser.json.tpl")}"
}

data "template_file" "enrichment-user-agent" {
    template = "${file("${path.module}/enrichments/user_agent_utils_config.json.tpl")}"
}

data "template_file" "enrichment-fingerprint" {
    template = "${file("${path.module}/enrichments/event_fingerprint_config.json.tpl")}"
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
    "${aws_security_group.hydra-enrich.name}",
  ]

  tags {
    Name = "hydra-enrich"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y unzip openjdk-8-jdk",
      "sudo apt-get install -y supervisor",
      "sudo service supervisor restart",
      "mkdir -p /home/ubuntu/logs",
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
      "mkdir /home/ubuntu/enrichments",
      "cat <<FILEXXX > /home/ubuntu/enrichments/referer_parser.json",
      "${data.template_file.enrichment-referer-parser.rendered}",
      "FILEXXX",
      "cat <<FILEXXX > /home/ubuntu/enrichments/user_agent_utils_config.json",
      "${data.template_file.enrichment-user-agent.rendered}",
      "FILEXXX",
      "cat <<FILEXXX > /home/ubuntu/enrichments/event_fingerprint_config.json",
      "${data.template_file.enrichment-fingerprint.rendered}",
      "FILEXXX",
      "wget https://bintray.com/snowplow/snowplow-generic/download_file?file_path=snowplow_stream_enrich_kinesis_${var.enrich_version}.zip",
      "unzip snowplow_stream_enrich_kinesis_${var.enrich_version}.zip",
      "sudo chown ubuntu /etc/supervisor/conf.d/",
      "cat <<FILEXXX > /etc/supervisor/conf.d/enrich.conf",
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
