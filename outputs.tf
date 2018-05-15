output "collector-elb-cname" { value = "${module.collector.elb_dns}" }
output "loader-ip" { value = "${module.loader.loader-ip}" }
output "enricher-ip" { value = "${module.enricher.enricher-ip}" }
