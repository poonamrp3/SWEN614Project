import json
import boto3
import botocore
import os
from decimal import Decimal
import ast
import re
import base64


dynamodb = boto3.resource("dynamodb")
# Get the environment variables
apiPathParameter = os.environ['APIG_PATH_PARAMETER']
tableName = os.environ['DYNAMO_TABLE_NAME']
dynamoTableKey = os.environ['DYNAMO_TABLE_KEY']
dynamoAccessField = os.environ['DYNAMO_ACCESS_FIELD']

table = dynamodb.Table(tableName)

def get_image_base64(bucket_name, image_name):
    s3_client = boto3.client('s3')
    try:
        response = s3_client.get_object(Bucket=bucket_name, Key=image_name)
        image_data = response['Body'].read()
        image_base64 = base64.b64encode(image_data).decode('utf-8')

    except Exception as e:
        print('base 64 error')
        print(e)
        return None
    
    return image_base64

def lambda_handler(event, context):
    body = {}
    statusCode = 200
    headers = {
        "Content-Type": "application/json"
    }
    print('Lambda Event body')
    print(event['pathParameters'][apiPathParameter])
    images = dict()
    error = ''
    # DynamoDB access attempt
    if event['httpMethod'] == "GET":
        body = table.get_item(
            Key={dynamoTableKey: event['pathParameters'][apiPathParameter]}
            )

        if 'Item' in body:   # The record exists in DynamoDB
            body = body['Item'][dynamoAccessField]


            # print(body)
            # data = body[0]
            i = 0
            for i in range(len(body)):
                data = body[i]
                # Convert the string to a dictionary
                data = ast.literal_eval(data)
                # print('data',data)
                url = data['CelebrityImageLink'][0]
                # print('url',url)
                parts = url.split("/")

                # Extract the bucket name and object key
                bucket_name = parts[2]
                bucket_name = bucket_name.split(".s3.amazonaws.com")[0]
                image_name = parts[3]

                #print("Bucket name:", bucket_name)
                #print("Object key:", image_name)

                images[i] = get_image_base64(bucket_name, image_name)
                i+=1
            
        else:
            statusCode = 400
            error = 'The image for ' + event['pathParameters'][apiPathParameter] + ' was not processed yet, try again later'
        
    image_json = json.dumps(images)
    if statusCode == 400:
        image_json = json.dumps(error)
    res = {
        "statusCode": statusCode,
        'headers': {"Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
              "Access-Control-Allow-Methods": "GET,OPTIONS",
              "Access-Control-Allow-Origin": "*",
              "Content-Type": "application/json"},
        "body": image_json
    }
    
    return res
