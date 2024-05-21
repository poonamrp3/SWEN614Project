### Rekognition - Face Matching Lambda
This lambda code completes the analysis of the user's image in an S3 bucket and places the results in a DynamoDB. 

## Terraform
The FaceMatcher.tf file currently creates: 
- S3 bucket for user Images
- Lambda that executes the code
- S3 and DynamoDB for Amazon Rekognition
- DynamoDB table for the results of the analysis

## Usage
# Pre-requisite:
1. Change the S3 bucket names in Terraform to make it fully unique - replace YOURNAME with your username. 

# Testing:
To test the lambda upload an image to the user info S3 bucket. This should create a record in DynamoDB with the results of the analysis.

## TODO: 
1. Switch the email from dummy to the name of the S3 image(the API uploads the image)
2. Make S3 bucket names unique in an easier way. Use variables?
3. Fix permissions to make them least access based.
4. Change the policy names from iam.for.lambda to avoid permission clashes later
