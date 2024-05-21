# zips the lambda code
data "archive_file" "get_results_lambda_zip" {
  type        = "zip"
  source_file = "get_results.py"
  output_path = "get_results_payload.zip"
}

data "archive_file" "post_images_lambda_zip" {
  type        = "zip"
  source_file = "post_images.py"
  output_path = "post_images_lambda_payload.zip"
}

data "archive_file" "face_matching_lambda_zip" {
  type        = "zip"
  source_file = "face_matching_lambda.py"
  output_path = "face_matching_lambda_payload.zip"
}