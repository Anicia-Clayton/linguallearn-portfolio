import json
import boto3
import pickle
import os
import numpy as np
from datetime import datetime
from sklearn.linear_model import LinearRegression

# Initialize S3 client for model loading
s3 = boto3.client('s3')
MODEL_BUCKET = os.environ['MODEL_BUCKET']
MODEL_KEY = 'models/forgetting_curve_v1.pkl'

# Global model variable for reuse across invocations
model_data = None

# Load ML model from S3 on cold start
def load_model():
    """Download and load model from S3"""
    global model_data
    if model_data is None:
        print(f"Loading model from s3://{MODEL_BUCKET}/{MODEL_KEY}")
        response = s3.get_object(Bucket=MODEL_BUCKET, Key=MODEL_KEY)
        model_bytes = response['Body'].read()
        model_data = pickle.loads(model_bytes)
        print("Model loaded successfully")
    return model_data

def predict_recall_probability(model_dict, days_since_review, review_count, difficulty_score):
    """Predict probability of successful recall"""
    sklearn_model = model_dict['sklearn_model']

    import pandas as pd
    features = pd.DataFrame({
        'days_since_last_review': [days_since_review],
        'review_count': [review_count],
        'difficulty_score': [difficulty_score]
    })

    prediction = sklearn_model.predict(features)[0]

    # Clip to valid probability range
    return max(0.0, min(1.0, prediction))

def get_optimal_review_time(recall_probability, threshold=0.7):
    """Calculate optimal review timing"""
    if recall_probability < threshold:
        return 0  # Review today
    else:
        return 1  # Review tomorrow

# Lambda handler
def lambda_handler(event, context):
    """
    Lambda handler for ML predictions
    Expected input:
    {
      "card_id": 123,
      "days_since_review": 5,
      "review_count": 3,
      "difficulty_score": 0.6
    }
    """
    try:
        # Parse input
        body = json.loads(event.get('body', '{}')) if isinstance(event.get('body'), str) else event

        # Extract card metadata
        card_id = body.get('card_id')
        days_since_review = body['days_since_review']
        review_count = body['review_count']
        difficulty_score = body['difficulty_score']

        print(f"Prediction request: card_id={card_id}, days={days_since_review}, reviews={review_count}, difficulty_score={difficulty_score}")

        # Load model and make prediction
        model_dict = load_model()
        recall_probability = predict_recall_probability(
            model_dict, days_since_review, review_count, difficulty_score
        )

        # Calculate optimal review time
        optimal_days = get_optimal_review_time(recall_probability)

        print(f"Prediction: recall_prob={recall_probability:.2f}, optimal_days={optimal_days}")

        # Return prediction results
        return {
            'statusCode': 200,
            'body': json.dumps({
                'card_id': card_id,
                'recall_probability': float(recall_probability),
                'optimal_review_days': int(optimal_days),
                'recommendation': 'Review today!' if optimal_days == 0 else 'Review tomorrow',
                'model_version': 'v1',
                'timestamp': str(datetime.now())
            })
        }

    except KeyError as e:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': f'Missing required field: {str(e)}'
            })
        }
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
