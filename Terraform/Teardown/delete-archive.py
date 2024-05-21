import json
import sys
import boto3

# TODO-Change this to your keys & account id
AWS_ACCESS_KEY_ID = 'AWS_ACCESS_KEY_ID'
AWS_SECRET_ACCESS_KEY = 'AWS_SECRET_ACCESS_KEY'
REGION = 'us-east-1'
ACCOUNT_ID ='ACCOUNT_ID'

def delete_archive(archive_ids):
    # Initialize Glacier client
    glacier = boto3.client('glacier',region_name=REGION,
                                       aws_access_key_id=AWS_ACCESS_KEY_ID,
                                       aws_secret_access_key=AWS_SECRET_ACCESS_KEY)

    # Loop through each ArchiveId
    for archive_id in archive_ids:
        # Delete archive from Glacier vault
        res = glacier.delete_archive(accountId=ACCOUNT_ID, vaultName='frequently_matched_celebs_vault', archiveId=archive_id)
        print(res)

def main():
    # Load the JSON file
    with open(sys.argv[1], 'r') as file:
        data = json.load(file)
    archive_ids = [item['ArchiveId'] for item in data['ArchiveList']]

    delete_archive(archive_ids)
    print('Archives sent for deletion. Please check back after a day, then delete archive')

if __name__ == '__main__':
    main()
