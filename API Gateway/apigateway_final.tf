provider "aws" {
  region = "us-east-1"
}
# create an IAM Role lambdarole v1 for lambda function
resource "aws_iam_role" "lambdaRolev1" {
  name = "lambdaRolev1"
  
  assume_role_policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"Service": [
					"s3.amazonaws.com",
					"apigateway.amazonaws.com",
					"lambda.amazonaws.com"
				]
			},
			"Action": "sts:AssumeRole"
		}
	]
})
}

# create a policy for the role lambdaRolev1 - s3 full access
resource "aws_iam_role_policy_attachment" "lambdaRolev1_policy_s3" {
  role      =  aws_iam_role.lambdaRolev1.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# create a policy for role lambdaRolev1 - CloudWatchFullAccess
resource "aws_iam_role_policy_attachment" "lambdaRolev1_policy_cloudwatch" {
  role      =  aws_iam_role.lambdaRolev1.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

# create an IAM Role apiwayRolev1 for lambda function
resource "aws_iam_role" "apiwayRolev1" {
  name = "apiwayRolev1"
  
  assume_role_policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"Service": [
					"s3.amazonaws.com",
					"apigateway.amazonaws.com",
					"lambda.amazonaws.com"
				]
			},
			"Action": "sts:AssumeRole"
		},
        {
            "Effect": "Allow",
            "Principal": {
            "Service": "logs.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
	]
})
}

# create a policy for the role apiwayRolev1 - s3 full access
resource "aws_iam_role_policy_attachment" "apiwayRolev1_s3" {
  role      =  aws_iam_role.apiwayRolev1.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# create a policy for the role apiwayRolev1 - lambda full access
resource "aws_iam_role_policy_attachment" "apiwayRolev1_lambda" {
  role      =  aws_iam_role.apiwayRolev1.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

# create a policy for the role apiwayRolev1 - cloudwatch full access
resource "aws_iam_role_policy" "apiwayRolev1_cloudwatch" {
  name   = "APIGatewayCloudWatch"
  role   = aws_iam_role.apiwayRolev1.id

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}


# create lambda function for api gateway
resource "aws_lambda_function" "lambdaRolev1" {
  function_name = "TFlambdaRolev1"
  handler       = "lambdaRolev1.lambda_handler"
  runtime       = "python3.9"
  filename      = "lambdaRolev1_payload.zip"  # Path to Lambda function code ZIP file
  source_code_hash = data.archive_file.lambdaRolev1_zip.output_base64sha256  
  role          = aws_iam_role.lambdaRolev1.arn

  # updating time out to 14 mins 59 secs
  timeout       = 899

  environment {
    variables = {
      # TODO: Refer to the created user images bucket
      USER_INFO_BUCKET = "ali-final-user-images-team5facecollection"
    }
  }
}

data "archive_file" "lambdaRolev1_zip" {
  type        = "zip"
  source_file = "lambdaRolev1.py"
  output_path = "lambdaRolev1_payload.zip"
}


# create api gateway
resource "aws_api_gateway_rest_api" "celebrity_terraform_apigateway" {
    name          = "TFcelebrity_apigateway"
    description   = "An API to upload user image to s3 bucket and to get email from lambda."

    endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# create the resource - upload the image into s3 bucket
resource "aws_api_gateway_resource" "upload" {
    path_part     = "upload"
    parent_id     = aws_api_gateway_rest_api.celebrity_terraform_apigateway.root_resource_id
    rest_api_id   = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
}

# enable options in first child
resource "aws_api_gateway_method" "upload_options_method_request" {
    rest_api_id   = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
    resource_id   = aws_api_gateway_resource.upload.id
    http_method   = "OPTIONS"
    authorization = "NONE"
}

# upload options integration request
resource "aws_api_gateway_integration" "upload_options_integration_request" {
  rest_api_id = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.upload_options_method_request.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }

  timeout_milliseconds = 29000  # Timeout in milliseconds (29 seconds)
}

# upload options method response
resource "aws_api_gateway_method_response" "upload_options_method_response" {
  rest_api_id = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.upload_options_method_request.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

#upload option integration response
resource "aws_api_gateway_integration_response" "upload_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.upload_options_method_request.http_method
  status_code = aws_api_gateway_method_response.upload_options_method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}


# create post method for upload resource
resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
  resource_id   = aws_api_gateway_resource.upload.id
  http_method   = "POST"
  authorization = "NONE"

}

# integration request for POST Method
resource "aws_api_gateway_integration" "upload_post_integration_request" {
  rest_api_id = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.post_method.http_method
  type        = "AWS"

  integration_http_method = "POST"  

  uri = aws_lambda_function.lambdaRolev1.invoke_arn # URI pointing to your Lambda function ARN


  request_templates = {
    "application/json" = file("${path.module}/mapping_template.json.tpl")
  }

  timeout_milliseconds = 29000  # Timeout in milliseconds (29 seconds)
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambdaRolev1.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.celebrity_terraform_apigateway.execution_arn}/*/${aws_api_gateway_method.post_method.http_method}${aws_api_gateway_resource.upload.path}"
}

# method response for POST
resource "aws_api_gateway_method_response" "upload_post_method_response" {
  rest_api_id = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = aws_api_gateway_method_response.upload_post_method_response.status_code

    response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'*'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  response_templates = {
    "application/json" = file("${path.module}/mapping_template.json.tpl")
  }

  depends_on = [aws_api_gateway_integration.upload_post_integration_request]
}

##########################################################################
#########ALI'S Method to get the email ID#################################

#Lambda
resource "aws_lambda_function" "get_results_lambda" {
  function_name = "TFget_results_lambda"
  handler       = "get_results.lambda_handler"
  runtime       = "python3.9"
  filename      = "get_results_payload.zip"  # Path to Lambda function code ZIP file
  source_code_hash = data.archive_file.get_results_lambda_zip.output_base64sha256  
  role          = aws_iam_role.get_results_lambda_role.arn


  environment {
    variables = {
      APIG_PATH_PARAMETER = "email", # Taken from the API Gateway
      DYNAMO_ACCESS_FIELD = "celebrityImageMatchesInfo",  # Taken from Dynamo table
      DYNAMO_TABLE_KEY = "Email",
      DYNAMO_TABLE_NAME = "TF_user_info"
    }
  }
}

resource "aws_iam_role" "get_results_lambda_role" {
  name = "TFget_results_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid = ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "get_results_lambda_policy" {
  name = "TFget_results_lambda_policy"
  role = aws_iam_role.get_results_lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["dynamodb:GetItem"]
        Resource = "arn:aws:dynamodb:*"    
      },
      {
        Effect = "Allow"
        Action = "s3:*"
        Resource = "arn:aws:s3:::*"     
      }
    ]
  })
}

data "archive_file" "get_results_lambda_zip" {
  type        = "zip"
  source_file = "get_results.py"
  output_path = "get_results_payload.zip"
}

# create the resource - upload the image into s3 bucket
resource "aws_api_gateway_resource" "email" {
    path_part     = "{email}"
    parent_id     = aws_api_gateway_rest_api.celebrity_terraform_apigateway.root_resource_id
    rest_api_id   = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
}

# enable options in second child
resource "aws_api_gateway_method" "get_options_method_request" {
    rest_api_id   = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
    resource_id   = aws_api_gateway_resource.email.id
    http_method   = "OPTIONS"
    authorization = "NONE"
}

# #GET mail options integration request
resource "aws_api_gateway_integration" "get_options_integration_request" {
  rest_api_id = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
  resource_id = aws_api_gateway_resource.email.id
  http_method = aws_api_gateway_method.get_options_method_request.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }

  timeout_milliseconds = 29000  # Timeout in milliseconds (29 seconds)
}

# Get options method response
resource "aws_api_gateway_method_response" "get_options_method_response" {
  rest_api_id = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
  resource_id = aws_api_gateway_resource.email.id
  http_method = aws_api_gateway_method.get_options_method_request.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "get_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
  resource_id = aws_api_gateway_resource.email.id
  http_method = aws_api_gateway_method.get_options_method_request.http_method
  status_code = aws_api_gateway_method_response.get_options_method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# create get method for get mail
resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
  resource_id   = aws_api_gateway_resource.email.id
  http_method   = "GET"
  authorization = "NONE"

}

# integration request for GET Method
resource "aws_api_gateway_integration" "get_integration_request" {
  rest_api_id = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
  resource_id = aws_api_gateway_resource.email.id
  http_method = aws_api_gateway_method.get_method.http_method
  type        = "AWS_PROXY"

  # Has to be POST since PROXY is enabled
  integration_http_method = "POST"

  uri = aws_lambda_function.get_results_lambda.invoke_arn


  request_templates = {
    "application/json" = file("${path.module}/mapping_template.json.tpl")
  }

  timeout_milliseconds = 29000  # Timeout in milliseconds (29 seconds)
}

resource "aws_lambda_permission" "apigw_lambda1" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_results_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.celebrity_terraform_apigateway.execution_arn}/*/${aws_api_gateway_method.get_method.http_method}${aws_api_gateway_resource.email.path}"
}

# method response for GET
resource "aws_api_gateway_method_response" "get_method_response" {
  rest_api_id = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
  resource_id = aws_api_gateway_resource.email.id
  http_method = aws_api_gateway_method.get_method.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}


#### STAGING AND DEPLOYMENT#####
resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.celebrity_terraform_apigateway.body))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [ aws_api_gateway_method.get_method, 
  aws_api_gateway_method.post_method,
  aws_api_gateway_integration.get_integration_request, 
  aws_api_gateway_integration.upload_post_integration_request,
  aws_api_gateway_integration_response.post_integration_response]
}

resource "aws_api_gateway_stage" "v1" {
  deployment_id = aws_api_gateway_deployment.deploy.id
  rest_api_id   = aws_api_gateway_rest_api.celebrity_terraform_apigateway.id
  stage_name    = "v1"
}


#################################################################################
##################### POONAM's AMPLIFY UI #######################################
resource "aws_amplify_app" "UIapp" {
  name       =  "TokenCheck"
  repository =  "https://github.com/km7872/SWEN614Team5Project"
  access_token = "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"

  build_spec = <<-EOF
    version: 1
    frontend:
      phases:
        preBuild:
          commands:     
            - npm ci --cache .npm --prefer-offline    
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: dist
        files:
          - '**/*'
      cache:
        paths:
          - .npm/**/*
    appRoot: celebui

  EOF

#TODO: Provide the API URLs from the API Terraform and access them in Vue.js
  environment_variables = {
    VUE_APP_API_UPLOAD_URL = "https://${aws_api_gateway_rest_api.celebrity_terraform_apigateway.id}.execute-api.us-east-1.amazonaws.com/v1/upload" 
    VUE_APP_API_GET_URL = "https://${aws_api_gateway_rest_api.celebrity_terraform_apigateway.id}.execute-api.us-east-1.amazonaws.com/v1"
  }
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.UIapp.id
  branch_name = "main"

  framework = "Vue"
  stage     = "PRODUCTION"
}

