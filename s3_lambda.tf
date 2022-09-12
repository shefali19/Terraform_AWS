resource "aws_s3_bucket" "bucket_assignment" {
  bucket = "tf-assignment-bucket"
  tags = {
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.bucket_assignment.id
  acl    = "private"
}

resource "aws_iam_role" "lambda_iam_role" {
  name = "s3_event_notifier_iam_role"
  assume_role_policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Effect": "Allow"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        = aws_iam_role.lambda_iam_role.name
 policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}


resource "aws_iam_policy" "iam_policy_for_lambda" {
  name = "s3_event_notifier_lambda_role_policy"
  policy = jsonencode(
    { 
      "Version": "2012-10-17",
      "Statement": [
       {
        "Action": [
          "s3:*",
          "logs:*"
          ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "states:StartExecution"
          ],
        "Resource" : "*"
       }
      ]
    }
  )
}

data "archive_file" "zip_lambda_code"{
    type = "zip"
    source_file = "${path.module}/lambda/index.py"
    output_path = "${path.module}/lambda/index.zip"
}

resource "aws_lambda_permission" "allow_bucket" {
    statement_id  = "AllowS3Exceution"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.lambdafunc.arn
    principal     = "s3.amazonaws.com"
    source_arn    = aws_s3_bucket.bucket_assignment.arn
}

resource "aws_lambda_function" "lambdafunc" {
  filename      = "${path.module}/lambda/index.zip"
  function_name = "fetchIntoDynamoDB"
  role          = aws_iam_role.lambda_iam_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.8"
  timeout       = "900"
  depends_on = [
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role,
    data.archive_file.zip_lambda_code
  ]
  source_code_hash = "${base64sha256("${path.module}/lambda/index.zip")}"
  environment {
   variables = {
    SFN_ARN = aws_sfn_state_machine.workflow-engine.arn
   }
  }
}

resource "aws_s3_bucket_notification" "lambda_trigger" {
 bucket = aws_s3_bucket.bucket_assignment.id
    lambda_function {
        lambda_function_arn = aws_lambda_function.lambdafunc.arn    
        events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}

output "terraform_aws_role_output" {
  value = aws_iam_role.lambda_iam_role.name
}
output "terraform_aws_role_arn"{
    value = aws_iam_role.lambda_iam_role.arn
}