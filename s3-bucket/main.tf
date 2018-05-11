resource "aws_s3_bucket" "b" {
  bucket = "${var.bucket}"
  acl    = "${var.acl}"

  tags {
    Name = "${var.name}"
  }
}
