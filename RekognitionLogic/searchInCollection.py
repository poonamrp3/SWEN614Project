#
# Method 2: Store dataset in a collection and use search_faces_by_image do find
# similarity
#

import boto3

# TODO Change this to your keys
AWS_ACCESS_KEY_ID = 'AWS_ACCESS_KEY_ID'
AWS_SECRET_ACCESS_KEY = 'AWS_SECRET_ACCESS_KEY'
REGION = 'us-east-1'


def query_dynamodb_for_image_links(table_name, face_id):
    # Initialize AWS DynamoDB client
    dynamodb_resource = boto3.resource('dynamodb', region_name=REGION,
                                       aws_access_key_id=AWS_ACCESS_KEY_ID,
                                       aws_secret_access_key=AWS_SECRET_ACCESS_KEY)

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

def search_faces_by_image(collection_id,threshold, bucket, key):
    rekognition_client = boto3.client('rekognition', region_name=REGION,
                                      aws_access_key_id=AWS_ACCESS_KEY_ID,
                                      aws_secret_access_key=AWS_SECRET_ACCESS_KEY,)
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

if __name__ == "__main__":
    # Replace 'your-collection-id' with your collection ID
    # collection_id = 'kate-celebrity-dataset'
    collection_id = 'team5facecollection'

    # Search for faces similar to the provided image within the collection
    face_matches = search_faces_by_image(collection_id,0, 'userimageuploaded','profd.JPG' )


    if face_matches:
        print("Found similar faces:")
        for match in face_matches:
            print("Face ID:", match['Face']['FaceId'])
            print("Confidence:", match['Face']['Confidence'])
            print("Similarity:", match['Similarity'])
            print('Img link S3:', query_dynamodb_for_image_links('celebrity_info',match['Face']['FaceId']))
    else:
        print("No similar faces found.")
