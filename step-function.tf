resource "aws_sfn_state_machine" "workflow-engine" {
  name     = "tf-worflow-engine"
  role_arn = "${aws_iam_role.StateMachineRole.arn}"
  definition = jsonencode(
{
  "Comment": "Assignment - HandsOn",
  "StartAt": "startingStepFunction",
  "States": {
    "startingStepFunction": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:::function:fetchIntoDynamoDB",
      "OutputPath": "$.TaskResult",
      "ResultPath": "$.TaskResult",
      "Next": "insertIntoDB"
    },
    "insertIntoDB": {
      "Type": "Task",
      "Resource": "arn:aws:states:::dynamodb:putItem",
      "Parameters":{
        "TableName": "Files",
        "Item":{
            "Filename": {
              "S.$": "$.Filename"
            }
          }
      }
      "Catch": [
            {
               "ErrorEquals": ["States.ALL"],
               "Next": "FailState"
            }
         ],
     "End":true,
     "ResultPath":"$.DynamoDB"
    },
    "FailState": {
      "Type": "Fail"
    }
  },
})
}


resource "aws_iam_role" "StateMachineRole" {
  assume_role_policy = jsonencode(
  {
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "states.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
   }
  )
}