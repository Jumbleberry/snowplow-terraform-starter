output "collector-elb-cname" { value = "${module.snowplow-collector.elb_dns}" }
output "loader-ip" { value = "${module.snowplow-loader.loader-ip}" }
