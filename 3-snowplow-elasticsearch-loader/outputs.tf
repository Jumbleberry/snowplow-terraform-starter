output "kibana-endpoint" { value = "${aws_elasticsearch_domain.es.kibana_endpoint}" }
output "loader-ip" { value = "${aws_instance.loader.public_ip}" }
