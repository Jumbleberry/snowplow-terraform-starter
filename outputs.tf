output "collector-elb-cname" { value = "${module.snowplow-collector.elb_dns}" }
output "kibana-endpoint" { value = "${module.snowplow-loader.kibana-endpoint}" }
