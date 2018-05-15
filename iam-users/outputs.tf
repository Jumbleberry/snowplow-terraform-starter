output "operator-access-key" {
  value = "${aws_iam_access_key.operator.id}"
}

output "operator-secret-key" {
  value = "${aws_iam_access_key.operator.secret}"
}
