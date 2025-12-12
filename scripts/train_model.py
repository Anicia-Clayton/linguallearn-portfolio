import numpy as np
import pandas as pd
import sys
import os

# Add parent directory to path to import api modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from api.models.forgetting_curve import ForgettingCurveModel

def generate_synthetic_data(n_samples=1000):
    """
    Generate synthetic learning session data for training.

    Simulates realistic spaced repetition patterns:
    - More reviews = better retention
    - More time = worse retention
    - Higher difficulty = worse retention
    """
    print(f"Generating {n_samples} synthetic training samples...")

    np.random.seed(42)  # Reproducible results

    # Simulate review patterns
    # Days since last review: 0-30 days
    days_since_review = np.random.randint(0, 31, n_samples)

    # Review count: 1-15 previous reviews
    review_count = np.random.randint(1, 16, n_samples)

    # Difficulty score: 0.3 (easy) to 1.0 (hard)
    difficulty_score = np.random.uniform(0.3, 1.0, n_samples)

    # Simulate recall success based on forgetting curve principles:
    # 1. Success probability decreases exponentially with time
    # 2. Success probability increases with review count
    # 3. Success probability decreases with difficulty

    # Base forgetting curve: e^(-0.3 * days)
    time_decay = np.exp(-0.3 * days_since_review / (review_count + 1))

    # Difficulty adjustment: harder items are forgotten faster
    difficulty_adjustment = 1.0 - (difficulty_score * 0.3)

    # Review count bonus: more reviews = better retention
    review_bonus = np.log(review_count + 1) * 0.1

    # Combine factors
    recall_probability = time_decay * difficulty_adjustment + review_bonus

    # Add realistic noise (learning isn't perfectly predictable)
    recall_probability += np.random.normal(0, 0.1, n_samples)

    # Clip to valid probability range [0, 1]
    recall_probability = np.clip(recall_probability, 0, 1)

    # Convert to binary success/failure (simulate actual reviews)
    # If probability > 0.5, more likely to succeed
    successful_recall = (recall_probability > 0.5).astype(int)

    # Create DataFrame
    df = pd.DataFrame({
        'days_since_last_review': days_since_review,
        'review_count': review_count,
        'difficulty_score': difficulty_score,
        'successful_recall': successful_recall
    })

    return df

def train_and_save_model():
    """Train the forgetting curve model and save to disk"""

    # Generate synthetic training data
    print("\n" + "="*60)
    print("STEP 1: Generating Synthetic Training Data")
    print("="*60)
    data = generate_synthetic_data(n_samples=1000)

    print(f"\nGenerated {len(data)} training samples")
    print("\nSample data:")
    print(data.head(10))

    print("\nData statistics:")
    print(data.describe())

    # Train model
    print("\n" + "="*60)
    print("STEP 2: Training Forgetting Curve Model")
    print("="*60)
    model = ForgettingCurveModel()
    r2_score = model.train(data)

    print(f"\n✅ Model trained successfully!")
    print(f"   R² score: {r2_score:.4f}")

    if r2_score < 0.5:
        print("   ⚠️  Warning: Low R² score. Model may not predict well.")
    elif r2_score < 0.7:
        print("   ⚠️  Moderate R² score. Predictions will be approximate.")
    else:
        print("   ✅ Good R² score. Model should predict well.")

    # Save model
    print("\n" + "="*60)
    print("STEP 3: Saving Model to Disk")
    print("="*60)
    model_filename = 'forgetting_curve_v1.pkl'
    model.save(model_filename)
    print(f"✅ Model saved to: {model_filename}")

    # Test predictions
    print("\n" + "="*60)
    print("STEP 4: Testing Model Predictions")
    print("="*60)

    test_cases = [
        {"days": 1, "reviews": 1, "difficulty": 0.5, "description": "New card, 1 day ago"},
        {"days": 7, "reviews": 3, "difficulty": 0.6, "description": "Moderate card, 1 week ago"},
        {"days": 14, "reviews": 5, "difficulty": 0.7, "description": "Hard card, 2 weeks ago"},
        {"days": 30, "reviews": 2, "difficulty": 0.8, "description": "Very hard card, 1 month ago"},
    ]

    print("\nTest predictions:")
    for test in test_cases:
        prob = model.predict_recall_probability(
            days_since_review=test["days"],
            review_count=test["reviews"],
            difficulty_score=test["difficulty"]
        )
        optimal_days = model.get_optimal_review_time(prob)

        print(f"\n{test['description']}:")
        print(f"  Days since review: {test['days']}")
        print(f"  Review count: {test['reviews']}")
        print(f"  Difficulty: {test['difficulty']}")
        print(f"  → Recall probability: {prob:.2%}")
        print(f"  → Optimal review timing: {'Today!' if optimal_days == 0 else 'Tomorrow'}")

    print("\n" + "="*60)
    print("✅ Training Complete!")
    print("="*60)
    print(f"\nNext steps:")
    print(f"1. Upload model to S3:")
    print(f"   aws s3 cp {model_filename} s3://<DATA_LAKE_BUCKET>/models/")
    print(f"2. Continue to Lambda ML Inference")

    return model, r2_score

if __name__ == "__main__":
    model, score = train_and_save_model()
