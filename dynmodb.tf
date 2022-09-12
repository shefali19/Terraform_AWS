resource "aws_dynamodb_table" "tf_s3_db" {
  name           = "Files"
  billing_mode   = "PROVISIONED"
  read_capacity  = 30
  write_capacity = 30
  hash_key       = "Filename"

  attribute {
    name = "Filename"
    type = "S"
  }
}

resource "aws_iam_role_policy" "dynamoDB-put-object" {
  name        = "tf-dynamoDB-put-object-role"
  role   = aws_iam_role.lambda_iam_role.id
  policy = jsonencode(
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "dynamoDB:putItem"
        ],
        "Effect": "Allow",
        "Resource": "${aws_dynamodb_table.tf_s3_db.arn}"
      }
    ]
  })
}