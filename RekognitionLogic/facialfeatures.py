
#
# Method 1: Compare faces one at a time
#

import boto3

# TODO Change this to your keys
AWS_ACCESS_KEY_ID = 'AWS_ACCESS_KEY_ID'
AWS_SECRET_ACCESS_KEY = 'AWS_SECRET_ACCESS_KEY'
REGION = 'us-east-1'

def comparefaces(image_path):
    rekognition_client = boto3.client('rekognition', region_name=REGION,
                                      aws_access_key_id=AWS_ACCESS_KEY_ID,
                                      aws_secret_access_key=AWS_SECRET_ACCESS_KEY,)
    src = '../'
    image_paths = [src + 'A.JPG',src + 'AdamSamberg.jfif', src + 'AS.JPG',
                   src + 'JT.JPG', src + 'one1.jpg', src + 'one2.jpg']
    highest_simalirity_score = 0.0
    highest_similarity_img_path = ''
    with open(image_path, 'rb') as image_file:
        image_bytes = image_file.read()
    for image in image_paths:
        with (open(image, 'rb') as source):
            src_image_bytes = source.read()
            response = rekognition_client.compare_faces(
                SourceImage={'Bytes': image_bytes},
                TargetImage={'Bytes': src_image_bytes},
                SimilarityThreshold=0)
            if ('FaceMatches' in response and len(response['FaceMatches'])> 0
                and response['FaceMatches'][0]['Similarity'] > highest_simalirity_score):
                highest_simalirity_score = response['FaceMatches'][0]['Similarity']
                highest_similarity_img_path = source

    return highest_simalirity_score, highest_similarity_img_path

if __name__ == "__main__":
    # Replace 'your-collection-id' with your collection ID
    collection_id = 'kate-celebrity-dataset'

    src = '../'
    # Replace 'image.jpg' with the path to the image you want to search for
    image_path = src + 'Ali.JPG'

    # Search for faces similar to the provided image within the collection
    highest_simalirity_score, highest_similarity_img_path = comparefaces(image_path)
    print(highest_simalirity_score, highest_similarity_img_path)


