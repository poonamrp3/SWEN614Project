import boto3
import numpy as np
from scipy.spatial.distance import cosine


# TODO : Change to your aws keys
AWS_ACCESS_KEY_ID = 'AWS_ACCESS_KEY_ID'
AWS_SECRET_ACCESS_KEY = 'AWS_SECRET_ACCESS_KEY'
REGION = 'us-east-1'

def extract_face_features(image_bytes):
    rekognition = boto3.client('rekognition', region_name=REGION,
                                      aws_access_key_id=AWS_ACCESS_KEY_ID,
                                      aws_secret_access_key=AWS_SECRET_ACCESS_KEY,)
    response = rekognition.detect_faces(Image={'Bytes': image_bytes}, Attributes=['ALL'])
    if 'FaceDetails' in response and len(response['FaceDetails']) > 0:
        face_details = response['FaceDetails'][0]
        return face_details['Landmarks']
    else:
        return None


def cosine_similarity(feature_vector1, feature_vector2):
    vector1 = np.array([(lm['X'], lm['Y']) for lm in feature_vector1])
    vector2 = np.array([(lm['X'], lm['Y']) for lm in feature_vector2])
    return 1 - cosine(vector1.flatten(), vector2.flatten())


def find_closest_match(test_image_features, database_features):
    best_match_index = -1
    best_similarity = -1
    for i, database_image_features in enumerate(database_features):
        similarity = cosine_similarity(test_image_features, database_image_features)
        if similarity > best_similarity:
            best_similarity = similarity
            best_match_index = i
    return best_match_index, best_similarity


def main():
    s3 = boto3.client('s3', region_name=REGION,
                                      aws_access_key_id=AWS_ACCESS_KEY_ID,
                                      aws_secret_access_key=AWS_SECRET_ACCESS_KEY,)
    test_image_bucket = 'userimageuploaded'
    test_image_key = 'profd.JPG'
    response = s3.get_object(Bucket=test_image_bucket, Key=test_image_key)
    image_bytes = response['Body'].read()
    # test_image_name = 'Ali'
    test_image_features = extract_face_features(image_bytes)

    if test_image_features:
        celebrity_image_bucket = 'team5celebritycataset'
        s3 = boto3.client('s3',region_name=REGION,
                                      aws_access_key_id=AWS_ACCESS_KEY_ID,
                                      aws_secret_access_key=AWS_SECRET_ACCESS_KEY,)
        list_response = s3.list_objects_v2(Bucket=celebrity_image_bucket)
        celebrity_image_keys = [obj['Key'] for obj in
                                list_response.get('Contents', [])]

        # Extract features for each image in the database
        database_features = []
        for celebrity_image_key in celebrity_image_keys:
            response = s3.get_object(Bucket=celebrity_image_bucket,
                                     Key=celebrity_image_key)
            image_bytes = response['Body'].read()
            features = extract_face_features(image_bytes)
            if features:
                database_features.append(features)

        # Find the closest match
        best_match_index, best_similarity = find_closest_match(
            test_image_features, database_features)
        print(best_similarity)

        if best_match_index != -1:
            closest_match_key = celebrity_image_keys[best_match_index]
            confidence_level = best_similarity
            print(
                f"Closest match found: {closest_match_key} with similarity score {best_similarity}")
        else:
            print("No match found in the database.")

if __name__ == '__main__':
    main()