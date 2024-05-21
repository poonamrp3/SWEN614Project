import json
import boto3
import base64
import os

USER_INFO_BUCKET = os.environ['USER_INFO_BUCKET']

# Function to upload image to Amazon S3
def upload_image_to_s3(image_data, bucket_name, image_name):
    print('Function of s3 is called')
    s3 = boto3.client('s3')
    
    try:
        response = s3.put_object(Bucket=bucket_name, Key=image_name, Body=image_data)
        print("Upload successful:", response)
    except Exception as e:
        print("Upload failed:", e)

def lambda_handler(event, context):
    image_data = event['body-json']['image'].split(',')[1] 
    image_name = event['body-json']['imageName'] + '.jpg'

    # Upload image to Amazon S3
    # bucket_name = "imagerole"
    bucket_name = USER_INFO_BUCKET
    
    upload_image_to_s3(base64.b64decode(image_data), bucket_name, image_name)
    
    # Return a response
    response = {
        'statusCode': 200,
        'body': json.dumps({'message': 'Base64 file received and processed successfully'})
    }
    return response
