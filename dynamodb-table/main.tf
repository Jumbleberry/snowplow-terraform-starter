resource "aws_dynamodb_table" "kinesis_consumer_state" {
  name           = "${var.name}"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "leaseKey"

  attribute {
    name = "leaseKey"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled = false
  }

  tags {
    Name = "${var.name}"
  }
}
