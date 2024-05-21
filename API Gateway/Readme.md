### API Gateway
This terraform code builds the api_gateway_resource of the Celebrity Lookalike pipeline. 

## Terraform
This script creates:
- The API Gateway and all the relevant method resources
- The Get Results lambda that connects to the DynamoDB table of Rekognition
- The PostImage lambda that connects to the User Images S3 Bucket


NOTE: The CloudWatch logs are not created by terraform immediately. They are only available after an execution, either via a Test or an application.

## Usage
1. Change the S3 bucket name accordingly
2. ENSURE THAT THE GET_RESULTS IS AVAILABLE FROM THE GETRESULTSLAMBDA Folder. THIS IS WORK IN PROGRESS, NOT FINALIZED YET
Copy the Lambda over to this folder, from the GetResultsLambda folder.

## TODO:
1. Update the file name and terraform resource name convention to make the code more readable.
