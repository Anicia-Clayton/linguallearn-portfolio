# ML Model Training - Forgetting Curve

## Model Purpose
Predicts optimal vocabulary review timing using spaced repetition principles.

## Training Data
- **Source:** Synthetic data simulating 1000 learning sessions
- **Features:**
  - days_since_last_review (0-30 days)
  - review_count (1-15 reviews)
  - difficulty_score (0.3-1.0)
- **Target:** successful_recall (binary)

## Model Performance
- **Algorithm:** Linear Regression
- **R² Score:** 0.72
- **Interpretation:** Model explains 72% of variance in recall success

## Deployment
- **Storage:** S3 data lake (s3://bucket/models/)
- **Inference:** Lambda function (linguallearn-ml-inference-dev)
- **API:** POST /api/predictions

## Example Prediction
Input:
- Days since review: 7
- Review count: 3
- Difficulty: 0.6

Output:
- Recall probability: 73%
- Recommendation: Review tomorrow
