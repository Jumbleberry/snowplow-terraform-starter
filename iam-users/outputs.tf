output "operator-access-key" {
  value = "${aws_iam_access_key.snowplow-operator.id}"
}

output "operator-secret-key" {
  value = "${aws_iam_access_key.snowplow-operator.secret}"
}
