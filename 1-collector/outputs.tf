output "elb_dns" { value = "${aws_elb.collector.dns_name}" }
output "ip" { value = "${aws_instance.collector.public_ip}" }
