from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, ConfigDict
import boto3
import json
import os
from api.utils.db_connection import db

router = APIRouter()

# Initialize Lambda client
lambda_client = boto3.client('lambda', region_name='us-east-1')
LAMBDA_FUNCTION_NAME = os.getenv('LAMBDA_FUNCTION_NAME', 'linguallearn-ml-inference-dev')

class PredictionRequest(BaseModel):
    """Request model for ML predictions"""
    card_id: int
    days_since_review: int
    review_count: int
    difficulty: float

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "card_id": 1,
                    "days_since_review": 7,
                    "review_count": 3,
                    "difficulty": 0.6
                }
            ]
        }
    )

@router.post("/predictions")
async def get_prediction(request: PredictionRequest):
    """
    Get ML prediction for optimal review timing

    This endpoint:
    1. Validates the request
    2. Invokes Lambda for ML inference
    3. Stores prediction in database
    4. Returns prediction result
    """
    try:
        # Map difficulty to difficulty_score for Lambda
        lambda_payload = {
            "card_id": request.card_id,
            "days_since_review": request.days_since_review,
            "review_count": request.review_count,
            "difficulty_score": request.difficulty
        }

        # Invoke Lambda function
        response = lambda_client.invoke(
            FunctionName=LAMBDA_FUNCTION_NAME,
            InvocationType='RequestResponse',
            Payload=json.dumps(lambda_payload)
        )

        # Parse Lambda response
        lambda_result = json.loads(response['Payload'].read())

        if lambda_result.get('statusCode') != 200:
            raise HTTPException(
                status_code=500,
                detail=f"Lambda error: {lambda_result.get('body', 'Unknown error')}"
            )

        body = json.loads(lambda_result['body'])

        recall_probability = body['recall_probability']
        optimal_review_days = body['optimal_review_days']
        recommendation = body['recommendation']
        model_version = body.get('model_version', 'v1')
        timestamp = body.get('timestamp')

        # Store prediction in database using shared db connection module
        conn = db.get_connection()
        cursor = conn.cursor()

        # Get user_id from vocabulary_cards
        cursor.execute("""
            SELECT user_id
            FROM vocabulary_cards
            WHERE card_id = %s
        """, (request.card_id,))

        card_result = cursor.fetchone()
        if not card_result:
            cursor.close()
            db.return_connection(conn)
            raise HTTPException(status_code=404, detail="Card not found")

        user_id = card_result[0]

        # Insert prediction into ml_predictions table
        cursor.execute("""
            INSERT INTO ml_predictions
            (user_id, card_id, prediction_type, confidence_score, model_version, prediction_result)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING prediction_id
        """, (
            user_id,
            request.card_id,
            'forgetting_curve',
            recall_probability,  # Use recall probability as confidence score
            model_version,
            json.dumps({
                'recall_probability': recall_probability,
                'optimal_review_days': optimal_review_days,
                'recommendation': recommendation,
                'days_since_review': request.days_since_review,
                'review_count': request.review_count,
                'difficulty': request.difficulty,
                'model_version': model_version,
                'timestamp': timestamp
            })
        ))

        prediction_id = cursor.fetchone()[0]
        conn.commit()
        cursor.close()
        db.return_connection(conn)

        return {
            "prediction_id": prediction_id,
            "card_id": request.card_id,
            "recall_probability": recall_probability,
            "optimal_review_days": optimal_review_days,
            "recommendation": recommendation,
            "model_version": model_version
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/predictions/card/{card_id}")
async def get_card_prediction(card_id: int):
    """
    Get ML prediction for a card using its historical data

    This endpoint:
    1. Fetches card metadata from database
    2. Calculates days_since_review
    3. Invokes Lambda for prediction
    4. Stores and returns result
    """
    try:
        # Get card data from database
        conn = db.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT
                card_id,
                user_id,
                COALESCE(EXTRACT(EPOCH FROM (NOW() - last_reviewed_at)) / 86400, 0) as days_since_review,
                COALESCE(times_reviewed, 0) as times_reviewed,
                COALESCE(difficulty_level, 3) as difficulty_level
            FROM vocabulary_cards
            WHERE card_id = %s
        """, (card_id,))

        card_data = cursor.fetchone()

        if not card_data:
            cursor.close()
            db.return_connection(conn)
            raise HTTPException(status_code=404, detail="Card not found")

        card_id_db, user_id, days_since_review, times_reviewed, difficulty_level = card_data

        # Map difficulty_level (1-5) to difficulty_score (0-1) for Lambda
        # difficulty_level 1 = easy = 0.2, level 5 = hard = 1.0
        difficulty_score = difficulty_level / 5.0

        # Invoke Lambda with card data
        lambda_payload = {
            "card_id": card_id_db,
            "days_since_review": int(days_since_review),
            "review_count": int(times_reviewed),  # Lambda expects review_count
            "difficulty_score": float(difficulty_score)
        }

        response = lambda_client.invoke(
            FunctionName=LAMBDA_FUNCTION_NAME,
            InvocationType='RequestResponse',
            Payload=json.dumps(lambda_payload)
        )

        # Parse Lambda response
        lambda_result = json.loads(response['Payload'].read())

        if lambda_result.get('statusCode') != 200:
            cursor.close()
            db.return_connection(conn)
            raise HTTPException(
                status_code=500,
                detail=f"Lambda error: {lambda_result.get('body', 'Unknown error')}"
            )

        body = json.loads(lambda_result['body'])

        recall_probability = body['recall_probability']
        optimal_review_days = body['optimal_review_days']
        recommendation = body['recommendation']
        model_version = body.get('model_version', 'v1')
        timestamp = body.get('timestamp')

        # Store prediction in database
        cursor.execute("""
            INSERT INTO ml_predictions
            (user_id, card_id, prediction_type, confidence_score, model_version, prediction_result)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING prediction_id
        """, (
            user_id,
            card_id_db,
            'forgetting_curve',
            recall_probability,
            model_version,
            json.dumps({
                'recall_probability': recall_probability,
                'optimal_review_days': optimal_review_days,
                'recommendation': recommendation,
                'days_since_review': int(days_since_review),
                'times_reviewed': int(times_reviewed),
                'difficulty_level': int(difficulty_level),
                'difficulty_score': float(difficulty_score),
                'model_version': model_version,
                'timestamp': timestamp
            })
        ))

        prediction_id = cursor.fetchone()[0]
        conn.commit()
        cursor.close()
        db.return_connection(conn)

        return {
            "prediction_id": prediction_id,
            "card_id": card_id_db,
            "user_id": user_id,
            "days_since_review": int(days_since_review),
            "times_reviewed": int(times_reviewed),
            "difficulty_level": int(difficulty_level),
            "difficulty_score": float(difficulty_score),
            "recall_probability": recall_probability,
            "optimal_review_days": optimal_review_days,
            "recommendation": recommendation,
            "model_version": model_version
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/predictions/recent")
async def get_recent_predictions(limit: int = 10):
    """
    Get recent predictions from database

    Query parameters:
    - limit: Number of predictions to return (default: 10, max: 100)
    """
    try:
        if limit > 100:
            limit = 100

        conn = db.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT
                prediction_id,
                user_id,
                card_id,
                prediction_type,
                confidence_score,
                model_version,
                prediction_result,
                predicted_at
            FROM ml_predictions
            WHERE prediction_type = 'forgetting_curve'
            ORDER BY predicted_at DESC
            LIMIT %s
        """, (limit,))

        results = cursor.fetchall()
        cursor.close()
        db.return_connection(conn)

        # Convert to JSON-serializable format
        predictions_list = []
        for row in results:
            predictions_list.append({
                "prediction_id": row[0],
                "user_id": row[1],
                "card_id": row[2],
                "prediction_type": row[3],
                "confidence_score": float(row[4]),
                "model_version": row[5],
                "prediction_result": row[6],
                "predicted_at": row[7].isoformat()
            })

        return {
            "count": len(predictions_list),
            "predictions": predictions_list
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
