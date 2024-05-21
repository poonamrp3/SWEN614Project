### Get Records Lambda
This lambda code pulls the data from a DynamoDB table when a GET API call is issued to it. 

## Terraform
The GetResultsLambda.tf file currently creates the lambda(with the required IAM policies) and a DynamoDB table that will be used to 
store the analyzed user image S3 link and the celebrity image S3 link.

NOTE: The CloudWatch logs are not created by terraform immediately. They are only available after an execution, either via a Test or an application.

## Usage
To test the lambda use the APIGEventExample as a custom test event. If the Dynamo is empty, you will see a KeyError saying "CelebrityImageLinks0" is not recognized as a Key. If you upload the DynamoItemExample into the DynamoDB Table, and then run the test, it should return "someS3Links". 

The connected API must have Proxy Integration Enabled for the lambda to function, and use {email} as API path parameter in the resource that connects to the Lambda.

## TODO: 
1. Change the permission resource to refer to a dynamo table
2. Add SNS notification logic(and the relevant policies)
3. Update the Test APIGEvent to have a different email, not a classic one. 
4. Add error handling for initial tests
