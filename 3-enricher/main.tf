# Configuration files
data "template_file" "enrich-config" {
  template = "${file("${path.module}/config.yml.tpl")}"

  vars {
    aws-region        = "${var.aws_region}"
    key-pair-name     = "${var.key_pair_name}"
    access-key        = "${var.operator_access_key}"
    secret-key        = "${var.operator_secret_key}"
    raw-bucket        = "${var.raw_bucket}"
    processing-bucket = "${var.processing_bucket}"
    enriched-bucket   = "${var.enriched_bucket}"
    shredded-bucket   = "${var.shredded_bucket}"
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
resource "aws_instance" "enricher" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "m1.small"
  key_name      = "${var.key_pair_name}"

  lifecycle {
    ignore_changes = ["ami"]
  }
  security_groups = [
    "${aws_security_group.enricher.name}",
  ]
  tags {
    Name = "hydra-enricher"
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
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("${var.key_pair_loc}")}"
    }
  }
  provisioner "remote-exec" {
    inline = [
      "cat <<FILEXXX > /home/ubuntu/config.yml",
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
      "wget http://dl.bintray.com/snowplow/snowplow-generic/snowplow_emr_${var.enrich_version}.zip",
      "unzip snowplow_emr_${var.enrich_version}.zip",
      "sudo chown ubuntu /etc/supervisor/conf.d/",
      "cat <<FILEXXX > /etc/supervisor/conf.d/enrich.conf",
      "${data.template_file.supervisord.rendered}",
      "FILEXXX",
      "sudo supervisorctl reread && sudo supervisorctl update",
      "sleep 1",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("${var.key_pair_loc}")}"
    }
  }
}
