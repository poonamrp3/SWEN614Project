import boto3
import os
from urllib.parse import unquote_plus
import shutil

# TODO : Change to your aws keys
AWS_ACCESS_KEY_ID = 'AWS_ACCESS_KEY_ID'
AWS_SECRET_ACCESS_KEY = 'AWS_SECRET_ACCESS_KEY'
REGION = 'us-east-1'

def create_collection(collection_id):
    rekognition_client = boto3.client('rekognition', region_name=REGION,
                                      aws_access_key_id=AWS_ACCESS_KEY_ID,
                                      aws_secret_access_key=AWS_SECRET_ACCESS_KEY,)
    response = rekognition_client.create_collection(CollectionId=collection_id)
    print("Collection ID:", response['CollectionArn'])
    return response['CollectionArn']

def index_faces(collection_id, s3_bucket_name, dynamodb_table_name):
    # Initialize AWS clients
    rekognition_client = boto3.client('rekognition', region_name=REGION,
                                      aws_access_key_id=AWS_ACCESS_KEY_ID,
                                      aws_secret_access_key=AWS_SECRET_ACCESS_KEY)
    s3_client = boto3.client('s3', region_name=REGION,
                             aws_access_key_id=AWS_ACCESS_KEY_ID,
                             aws_secret_access_key=AWS_SECRET_ACCESS_KEY)
    dynamodb_resource = boto3.resource('dynamodb', region_name=REGION,
                                       aws_access_key_id=AWS_ACCESS_KEY_ID,
                                       aws_secret_access_key=AWS_SECRET_ACCESS_KEY)


    table = dynamodb_resource.Table(dynamodb_table_name)
    c= 0

    # List objects in the S3 bucket
    response = s3_client.list_objects_v2(Bucket=s3_bucket_name)
    if 'Contents' in response:
        temp_dir = '../Data'  # Specify your desired temporary directory
        if not os.path.exists(temp_dir):
            os.makedirs(temp_dir)
        for obj in response['Contents']:
            # Extract image key (filename) and decode URL encoding
            image_key = obj['Key']
            image_name = unquote_plus(os.path.basename(image_key))

            # Download image from S3 bucket
            temp_image_path = os.path.join(temp_dir, image_name)
            s3_client.download_file(s3_bucket_name, image_key, temp_image_path)

            # Index faces using Amazon Rekognition
            with open(temp_image_path, 'rb') as image_file:
                image_bytes = image_file.read()
                response = rekognition_client.index_faces(
                    CollectionId=collection_id,
                    Image={'Bytes': image_bytes}
                )
                print("Faces indexed for:", image_name)
                for face_record in response['FaceRecords']:
                    face_id = face_record['Face']['FaceId']

                    # Store face_id, S3 bucket link, and image name in DynamoDB
                    table.put_item(
                        Item={
                            'FaceId': face_id,
                            'S3ObjectUrl': f"https://{s3_bucket_name}.s3.amazonaws.com/{image_key}",
                            'ImageName': image_name
                        }
                    )
                    c+=1
            os.remove(temp_image_path)

        print('Faces uploaded:', c)
        shutil.rmtree(temp_dir)


def main():
    collection_id = 'team5facecollection'
    create_collection(collection_id)

    s3_bucket_name = 'team5celebritycataset'
    dynamodb_table_name = 'celebrity_info'
    index_faces(collection_id, s3_bucket_name, dynamodb_table_name)

if __name__ == '__main__':
    main()

