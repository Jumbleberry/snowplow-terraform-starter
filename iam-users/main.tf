resource "aws_iam_user" "operator" {
  name = "hydra-operator"
  path = "/system/"
}

resource "aws_iam_access_key" "operator" {
  user = "${aws_iam_user.operator.name}"
}

resource "aws_iam_user_policy" "operator" {
  name = "hydra-operator-policy"
  user = "${aws_iam_user.operator.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "kinesis:*",
        "dynamodb:*",
        "cloudwatch:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
