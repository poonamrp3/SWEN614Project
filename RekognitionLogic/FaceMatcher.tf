terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


#TODO: Make the bucket creation automatic for all accounts:

resource "aws_s3_bucket" "user_images_bucket" {
  bucket = "ali-final-user-images-team5facecollection" # Bucket for user images
}

resource "aws_s3_bucket_public_access_block" "user_images_bucket" {
  bucket = aws_s3_bucket.user_images_bucket.id

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_policy" "user_images_bucket_policy" {
  bucket = aws_s3_bucket.user_images_bucket.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal": "*",
        "Action"   : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        "Resource" : "${aws_s3_bucket.user_images_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket" "celebrity_images_bucket" {
  bucket = "ali-final-celebrity-images-team5facecollection" # Bucket for celebrity images
}

resource "aws_glacier_vault" "frequently_matched_celebs_vault" {
  name        = "frequently_matched_celebs_vault"
}

resource "aws_s3_bucket_public_access_block" "celebrity_images_bucket" {
  bucket = aws_s3_bucket.celebrity_images_bucket.id

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_policy" "celebrity_images_bucket_policy" {
  bucket = aws_s3_bucket.celebrity_images_bucket.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal": "*",
        "Action"   : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        "Resource" : "${aws_s3_bucket.celebrity_images_bucket.arn}/*"
      }
    ]
  })
}


locals {
  images_folder_path = "./images" # Local directory path for images
}

# Load images from the local directory into the S3 bucket
resource "aws_s3_bucket_object" "images" {
  for_each = fileset(local.images_folder_path, "**/*")

  bucket = aws_s3_bucket.celebrity_images_bucket.id # Bucket for celebrity images
  key    = each.value
  source = "${local.images_folder_path}/${each.value}" # Local directory path for images
}

# DynamoDB tables
resource "aws_dynamodb_table" "celebrity_info_table" {
  name           = "TF_celebrity_info" # Table for celebrity information
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "FaceId" # Primary key for the table

  attribute {
    name = "FaceId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "user_info_table" {
  name           = "TF_user_info" # Table for user information
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "Email" # Primary key for the table

  attribute {
    name = "Email"
    type = "S"
  }
}

# Lambda function
resource "aws_lambda_function" "face_matching_lambda" {
  function_name = "TFface-matching-lambda"
  handler       = "face_matching_lambda.lambda_handler"
  runtime       = "python3.8"
  filename      = "face_matching_lambda_payload.zip"  # Path to Lambda function code ZIP file
  source_code_hash = data.archive_file.face_matching_lambda_zip.output_base64sha256  # Compute the source code hash
  role          = aws_iam_role.iam_for_lambda.arn # IAM role for the Lambda function

  timeout = 300
  environment {
    variables = {
      COLLECTION_ID = "Face_Matching_Collection"
      CELEBRITY_IMAGES_BUCKET = aws_s3_bucket.celebrity_images_bucket.bucket
      CELEBRITY_INFO_TABLE = aws_dynamodb_table.celebrity_info_table.name
      USER_INFO_TABLE = aws_dynamodb_table.user_info_table.name
      GLACIER_BUCKET = aws_glacier_vault.frequently_matched_celebs_vault.name
    }
  }
}

# zips the lambda code
data "archive_file" "face_matching_lambda_zip" {
  type        = "zip"
  source_file = "face_matching_lambda.py"
  output_path = "face_matching_lambda_payload.zip"
}

# Lambda permission
resource "aws_lambda_permission" "with_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.face_matching_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.user_images_bucket.arn
}

# S3 bucket notification
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.user_images_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.face_matching_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_permission.with_s3]
}

# IAM role for Lambda
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"
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

# IAM role policies
resource "aws_iam_role_policy" "iam_for_lambda" {
  name = "iam_for_lambda"
  role = aws_iam_role.iam_for_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject"]
        Resource = "arn:aws:s3:::*"
      },
      {
        Effect: "Allow"
        Action: ["s3:ListBucket"]
        Resource: aws_s3_bucket.celebrity_images_bucket.arn
      },
      {
        Effect: "Allow"
        Action: ["rekognition:SearchFacesByImage", "rekognition:IndexFaces"]
        Resource: "arn:aws:rekognition:*"  #TODO: make this a locals in the format arn:aws:rekognition:us-east-1:ACCOUNTNUMBER:collection/Face_Matching_Collection
      },
      {
        Effect: "Allow"
        Action: ["rekognition:CreateCollection", "rekognition:ListCollections"]
        Resource: "*"
      },
      {
        Effect: "Allow",
        Action: ["dynamodb:Query", "dynamodb:Scan", "dynamodb:PutItem"],
        Resource: aws_dynamodb_table.celebrity_info_table.arn
      },
      {
        Effect: "Allow",
        Action: ["dynamodb:PutItem"]
        Resource: aws_dynamodb_table.user_info_table.arn
      },
      {
        Effect = "Allow"
        Action = ["glacier:ListJobs","glacier:UploadArchive"]
        Resource = "arn:aws:glacier:*:*:vaults/frequently_matched_celebs_vault"  # Replace with the ARN of your Glacier vault
      }
#    ,
#      {
#        Effect   = "Allow"
#        Action   = ["iam:ListInstanceProfilesForRole"]
#        Resource = "*"
#      }
    ]
  })
}

