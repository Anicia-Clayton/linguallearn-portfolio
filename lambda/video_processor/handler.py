import json
import boto3
import os
from urllib.parse import unquote_plus

# Initialize AWS clients
s3 = boto3.client('s3')

# Environment variables
CLOUDFRONT_DOMAIN = os.environ['CLOUDFRONT_DOMAIN']

# Lambda handler function - triggered when video uploaded to S3
def lambda_handler(event, context):
    """
    Processes uploaded ASL videos:
    - Extracts metadata (sign name, category)
    - Builds CloudFront URL
    - Logs video information for database insertion
    """

    # Extract S3 event details
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = unquote_plus(event['Records'][0]['s3']['object']['key'])

    # Parse video path: asl/pocketsign/greetings/hello.mp4
    # Extract: sign_name='hello', category='greetings'
    parts = key.split('/')
    sign_name = parts[-1].replace('.mp4', '')
    category = parts[-2] if len(parts) > 2 else 'unknown'

    # Build CloudFront URL for video delivery
    video_url = f"https://{CLOUDFRONT_DOMAIN}/{key}"

    # Get video metadata from S3
    response = s3.head_object(Bucket=bucket, Key=key)
    file_size = response['ContentLength']
    content_type = response['ContentType']

    return {
        'statusCode': 200,
        'body': json.dumps({
            'sign_name': sign_name,
            'video_url': video_url,
            'category': category,
            'file_size': file_size,
            'content_type': content_type
        })
    }
