"""
This script contains the Lambda function code for the final project.
author: Team 5
final_lambda_code.py
"""
from urllib.parse import urlparse

import boto3
import os

# Hardcoded values
REGION = 'us-east-1'
COLLECTION_ID = os.environ['COLLECTION_ID']
THRESHOLD = 0
CELEBRITY_IMAGES_BUCKET = os.environ['CELEBRITY_IMAGES_BUCKET']
CELEBRITY_INFO_TABLE = os.environ['CELEBRITY_INFO_TABLE']
USER_INFO_TABLE = os.environ['USER_INFO_TABLE']
GLACIER_BUCKET = os.environ['GLACIER_BUCKET']

def create_collection(collection_id):
    """
        Creates a collection in Amazon Rekognition.

        Args:
            collection_id (str): The ID of the collection to create.

        Returns:
            str: The ARN of the created collection.
    """
    rekognition_client = boto3.client('rekognition', REGION)
    response = rekognition_client.create_collection(CollectionId=collection_id)
    return response['CollectionArn']


def query_dynamodb_for_image_links(table_name, face_id):
    """
        Queries DynamoDB for image links associated with a given face ID.

        Args:
            table_name (str): The name of the DynamoDB table.
            face_id (str): The face ID to query for.

        Returns:
            list: A list of image links associated with the face ID.
    """
    # Initialize AWS DynamoDB client
    dynamodb_resource = boto3.resource('dynamodb', REGION)

    # Retrieve the DynamoDB table
    table = dynamodb_resource.Table(table_name)

    # Initialize an empty list to store image links
    image_links = []
    response = table.query(
        KeyConditionExpression='FaceId = :face_id',
        ExpressionAttributeValues={':face_id': face_id}
    )
    for item in response['Items']:
        image_link = item['S3ObjectUrl']
        image_links.append(image_link)

    return image_links


def search_faces_by_image(collection_id, threshold, bucket, key):
    """
        Searches for faces similar to the given image in a collection.

        Args:
            collection_id (str): The ID of the collection to search in.
            threshold (float): The confidence threshold for face matches.
            bucket (str): The name of the S3 bucket containing the image.
            key (str): The key of the image in the S3 bucket.

        Returns:
            list: A list of face matches found in the collection.
    """
    rekognition_client = boto3.client('rekognition', REGION)
    response = rekognition_client.search_faces_by_image(
        CollectionId=collection_id,
        Image={
            'S3Object': {
                'Bucket': bucket,
                'Name': key
            }
        },
        FaceMatchThreshold=threshold,
        MaxFaces=5
    )
    return response['FaceMatches'] if 'FaceMatches' in response else []


def is_table_empty(table):
    """
        Checks if a DynamoDB table is empty.

        Args:
            table: The DynamoDB table object.

        Returns:
            bool: True if the table is empty, False otherwise.
    """
    response = table.scan(Select='COUNT')
    return response['Count'] == 0


def index_faces(image_bucket, image_key, collection_id):
    """
        Indexes faces in an image and returns face records.

        Args:
            image_bucket (str): The name of the S3 bucket containing the image.
            image_key (str): The key of the image in the S3 bucket.
            collection_id (str): The ID of the collection to index faces into.

        Returns:
            list: A list of face records indexed in the collection.
    """
    rekognition_client = boto3.client('rekognition', region_name=REGION)

    # Generate S3 object reference
    s3_object = {
        'S3Object': {
            'Bucket': image_bucket,
            'Name': image_key
        }
    }

    # Index faces in the image
    response = rekognition_client.index_faces(
        CollectionId=collection_id,
        Image=s3_object,
    )

    # Extract and return the face IDs
    return response['FaceRecords']


def store_celebrity_images_to_dynamodb(s3_bucket, table_name, collection_id):
    """
        Stores celebrity images to DynamoDB along with face metadata.

        Args:
            s3_bucket (str): The name of the S3 bucket containing celebrity images.
            table_name (str): The name of the DynamoDB table to store data into.
            collection_id (str): The ID of the collection containing celebrity faces.
    """
    # Initialize AWS clients
    s3_client = boto3.client('s3', REGION)
    dynamodb_resource = boto3.resource('dynamodb', REGION)

    # Retrieve the DynamoDB table
    table = dynamodb_resource.Table(table_name)

    # List objects in the S3 bucket
    response = s3_client.list_objects_v2(Bucket=s3_bucket)
    if 'Contents' in response:
        for obj in response['Contents']:
            # Extract image key (filename) and decode URL encoding
            image_key = obj['Key']
            image_name = image_key.split('/')[-1]

            # Index faces in the image and get face IDs
            face_records = index_faces(s3_bucket, image_key, collection_id)

            # Store face IDs, S3 bucket link, and image name in DynamoDB
            for face_record in face_records:
                face_id = face_record['Face']['FaceId']
                table.put_item(
                    Item={
                        'FaceId': face_id,
                        'S3ObjectUrl': f"https://{s3_bucket}.s3.amazonaws.com/{image_key}",
                        'ImageName': image_name
                    }
                )
                print("Celebrity image stored:", image_name)


def lambda_handler(event, context):
    """
        Lambda function handler.

        Args:
            event (dict): The Lambda event object.
            context (object): The Lambda context object.
    """
    for record in event['Records']:
        bucket_name = record['s3']['bucket']['name']
        object_key = record['s3']['object']['key']

        # Check if the collection already exists
        rekognition_client = boto3.client('rekognition', REGION)
        collections = rekognition_client.list_collections()['CollectionIds']

        if COLLECTION_ID not in collections:
            # Create the collection if it doesn't exist
            print("Creating collection:", COLLECTION_ID)
            create_collection(COLLECTION_ID)
        else:
            print("Collection already exists:", COLLECTION_ID)

        dynamodb_resource = boto3.resource('dynamodb', REGION)

        if is_table_empty(dynamodb_resource.Table(CELEBRITY_INFO_TABLE)):
            # If the table is empty, populate it
            store_celebrity_images_to_dynamodb(CELEBRITY_IMAGES_BUCKET, CELEBRITY_INFO_TABLE, COLLECTION_ID)

        # Search for faces similar to the newly added image
        face_matches = search_faces_by_image(COLLECTION_ID, THRESHOLD, bucket_name, object_key)

        if face_matches:
            print("Found similar faces:")
            #user_email = 'user1@gmail.com'  # TODO: Update dummy email for now
            image_link = f"https://{bucket_name}.s3.amazonaws.com/{object_key}"  # Link of the user's image
            face_matches_list = []
            user_email, _ = os.path.splitext(object_key)

            i = 0

            for match in face_matches:
                face_id = match['Face']['FaceId']
                confidence = match['Face']['Confidence']
                similarity = match['Similarity']

                matching_celebrity_image_link = query_dynamodb_for_image_links(CELEBRITY_INFO_TABLE, face_id)
                facematch_info = {'FaceId': face_id, 'Confidence': confidence, 'Similarity': similarity, 'CelebrityImageLink': matching_celebrity_image_link}
                face_matches_list.append(facematch_info)
                if i == 0:
                    s3_object_url = matching_celebrity_image_link[0]
                    glacier_vault_name = GLACIER_BUCKET
                    # Parse the S3 object URL to extract bucket name and key
                    parts = s3_object_url.split("/")
                    source_key = parts[-1]

                    # print("Bucket Name:", CELEBRITY_IMAGES_BUCKET)
                    print("Object Key:", source_key)
                    s3 = boto3.client('s3')
                    glacier = boto3.client('glacier')
                    # List all jobs for the vault
                    response = glacier.list_jobs(
                        vaultName=glacier_vault_name)
                    print(response)
                    found = False # since we canot check archives at run time, it's and async operation.

                    # Check if there are any inventory retrieval jobs in the response
                    # if response is not None and 'JobList' in response:
                    #     print(response['JobList'])
                    #     # Iterate over the list of jobs
                    #     for job in response['JobList']:
                    #         # Check if the job is an inventory retrieval job
                    #         if job['Action'] == 'InventoryRetrieval':
                    #             # Get the job details, including the list of archives
                    #             job_details = glacier.describe_job(
                    #                 vaultName=glacier_vault_name,
                    #                 jobId=job['JobId'])
                    #             archive_list = \
                    #                 job_details['InventoryRetrievalParameters'][
                    #                     'InventoryList']
                    #
                    #             # Iterate over the list of archives
                    #             for archive in archive_list:
                    #                 # Print the archive description
                    #                 if archive.get('ArchiveDescription',
                    #                                'No description provided') == source_key:
                    #                     print(source_key,'Img exists in glacier')
                    #                     found = True
                    if not found:
                        # Get the object from S3
                        response = s3.get_object(Bucket=CELEBRITY_IMAGES_BUCKET,
                                                 Key=source_key)
                        image_data = response['Body'].read()

                        # Upload the object to Glacier
                        res= glacier.upload_archive(vaultName=glacier_vault_name,
                                               body=image_data,
                                               archiveDescription=source_key)
                        print(source_key,'Img added in glacier')
                        print(res)
                i+=1

            # Update item in user_info table
            table = dynamodb_resource.Table(USER_INFO_TABLE)
            table.put_item(
                Item={
                    'Email': user_email,
                    'userImageLink': image_link,
                    'celebrityImageMatchesInfo': [str(match) for match in face_matches_list]
                }
            )

            print("Result added to user_info table:", face_matches_list)
        else:
            print("No similar faces found.")
