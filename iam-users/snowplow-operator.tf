resource "aws_iam_user" "snowplow-operator" {
  name = "snowplow-operator-datapipeline"
  path = "/system/"
}

resource "aws_iam_access_key" "snowplow-operator" {
  user = "${aws_iam_user.snowplow-operator.name}"
}

resource "aws_iam_user_policy" "snowplow-operator" {
  name = "snowplow-policy-operator"
  user = "${aws_iam_user.snowplow-operator.name}"

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "s3:*",
          "kinesis:*",
          "dynamodb:*",
          "elasticmapreduce:*",
          "redshift:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}
