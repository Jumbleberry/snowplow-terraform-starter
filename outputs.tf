output "collector-elb-cname" { value = "${module.snowplow-collector.elb_dns}" }
output "kibana-endpoint" { value = "${module.snowplow-loader.kibana-endpoint}" }
output "enrich-ip" { value = "${module.snowplow-enrich.enrich-ip}" }
output "loader-ip" { value = "${module.snowplow-loader.loader-ip}" }
