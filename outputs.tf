output "collector-elb-cname" { value = "${module.collector.elb_dns}" }
output "enrich-ip" { value = "${module.enrich.enrich-ip}" }
