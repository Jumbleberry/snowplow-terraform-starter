resource "aws_dynamodb_table" "kinesis_consumer_state" {
  name           = "${var.name}"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "leaseKey"

  attribute {
    name = "checkpoint"
    type = "S"
  }

  attribute {
    name = "checkpointSubSequenceNumber"
    type = "S"
  }

  attribute {
    name = "leaseCounter"
    type = "S"
  }

  attribute {
    name = "leaseKey"
    type = "S"
  }

  attribute {
    name = "leaseOwner"
    type = "S"
  }

  attribute {
    name = "ownerSwitchesSinceCheckpoint"
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
