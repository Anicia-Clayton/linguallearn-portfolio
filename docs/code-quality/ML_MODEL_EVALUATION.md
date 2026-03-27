# ML Model Evaluation

This document describes the machine learning evaluation strategy used in LinguaLearn AI's forgetting curve model, including lessons learned from a code quality review.

## Overview

The forgetting curve model predicts the probability that a user will successfully recall a vocabulary item based on:
- Days since last review
- Number of previous reviews  
- Item difficulty rating

The model outputs a probability used to schedule optimal review times, implementing a spaced repetition system.

## Model Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Input Features                        │
│  ┌─────────────────┐  ┌─────────────┐  ┌────────────────┐  │
│  │ days_since_review│  │ review_count │  │ difficulty_score│  │
│  │      (int)       │  │    (int)     │  │     (1-5)      │  │
│  └────────┬─────────┘  └──────┬──────┘  └───────┬────────┘  │
│           │                   │                  │           │
│           └───────────────────┼──────────────────┘           │
│                               │                              │
│                    ┌──────────▼──────────┐                  │
│                    │  LogisticRegression │                  │
│                    │   (scikit-learn)    │                  │
│                    └──────────┬──────────┘                  │
│                               │                              │
│                    ┌──────────▼──────────┐                  │
│                    │  predict_proba()    │                  │
│                    │   P(recall=1)       │                  │
│                    └──────────┬──────────┘                  │
│                               │                              │
│                    ┌──────────▼──────────┐                  │
│                    │  Probability [0,1]  │                  │
│                    └─────────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

## Why Logistic Regression?

The target variable is binary: the user either recalled the item (1) or forgot it (0).

| Model | Output | Appropriate For |
|-------|--------|-----------------|
| LinearRegression | Unbounded continuous value | Predicting continuous targets (prices, temperatures) |
| LogisticRegression | Probability in [0, 1] | Binary classification (yes/no, success/failure) |

Using `predict_proba()` gives native probability outputs without manual clipping:

```python
# LogisticRegression outputs probabilities natively
prob = model.predict_proba(features)[0][1]  # P(class=1)
# Result: 0.73 (73% recall probability)
```

## Evaluation Strategy

### Train/Test Split

Data is split before training to evaluate on unseen examples:

```python
X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size=0.2,
    random_state=42,
    stratify=y  # Maintain class balance
)
```

**Why stratify?** With imbalanced classes, random splits might put all minority class examples in one set. Stratification ensures both sets have the same class proportions.

### Metrics

| Metric | What It Measures | Why It Matters |
|--------|------------------|----------------|
| **AUC-ROC** | Discrimination ability across all thresholds | Primary metric — measures ranking quality |
| Accuracy | Correct predictions / total | Can be misleading with imbalanced classes |
| Precision | True positives / predicted positives | How reliable are "will remember" predictions? |
| Recall | True positives / actual positives | How many "remembers" do we catch? |
| F1 | Harmonic mean of precision/recall | Single balanced metric |

**AUC-ROC as primary metric:** A model with AUC=0.85 means that 85% of the time, a randomly chosen positive example ranks higher than a randomly chosen negative example. This is threshold-independent, making it ideal for probability models.

### Quality Gate

Models must meet a minimum AUC threshold to be promoted:

```python
MINIMUM_AUC = 0.65

if auc < MINIMUM_AUC:
    print("Model will NOT be promoted to production")
    return model, auc, False
```

This prevents:
- Silent model degradation if training data quality drops
- Accidental promotion of broken models
- Regressions during code changes

## Optimal Review Time Calculation

The model predicts when recall probability drops below a threshold:

```python
def get_optimal_review_time(
    self,
    review_count: int,
    difficulty_score: int,
    target_recall_prob: float = 0.8,
    max_days: int = 60
) -> int:
    """
    Binary search for the day when probability crosses threshold.
    """
    low, high = 0, max_days
    
    while low < high:
        mid = (low + high) // 2
        prob = self.predict_recall_probability(mid, review_count, difficulty_score)
        
        if prob > target_recall_prob:
            low = mid + 1  # Can wait longer
        else:
            high = mid     # Found crossing point
    
    return low
```

This returns actual days (e.g., "review in 7 days"), not just binary flags.

## Fallback Behavior

When no trained model is available, the system uses the Ebbinghaus forgetting curve:

```python
if self.model is None:
    # P(recall) = e^(-decay * days)
    adjusted_decay = 0.3 / (1 + 0.1 * review_count)
    return float(np.exp(-adjusted_decay * days_since_review))
```

This ensures the API returns reasonable values even before the first model is trained.

## Lessons Learned

### Issue: Wrong Model Class

**Symptom:** Code included `max(0.0, min(1.0, prediction))` to clip outputs.

**Root Cause:** LinearRegression outputs unbounded values for a binary target. Clipping was a workaround for the fundamental mismatch.

**Fix:** Replaced with LogisticRegression which outputs probabilities natively via `predict_proba()`.

**Insight:** Manual clipping or normalization of model outputs is often a signal that the model class is wrong for the problem.

### Issue: No Train/Test Split

**Symptom:** R² metric was used without held-out data.

**Root Cause:** Evaluation on training data measures memorization, not generalization.

**Fix:** 
1. Implemented train_test_split with stratification
2. Replaced R² with AUC-ROC
3. Added quality gate to prevent bad models from promoting

**Insight:** Always evaluate on data the model hasn't seen. High training accuracy with poor test accuracy indicates overfitting.

### Issue: Binary Search Returned Boolean

**Symptom:** `get_optimal_review_time()` returned 0 or 1 instead of actual days.

**Root Cause:** The function was incomplete—just checking if review was needed today.

**Fix:** Implemented proper binary search to find the day when recall probability crosses the threshold.

**Insight:** Review function outputs end-to-end. A function named `get_optimal_review_time` should return a time, not a boolean.

## Model Versioning

Trained models are saved with timestamps:

```
models/
├── forgetting_curve_20260326_143052.pkl  # Versioned artifact
├── forgetting_curve_20260325_091015.pkl  # Previous version
└── forgetting_curve_latest.pkl           # Symlink to production
```

This enables:
- Rollback to previous versions
- A/B testing between model versions
- Audit trail of model changes

## MLflow Integration

Training runs are tracked in MLflow:

```python
with mlflow.start_run(run_name=run_name):
    mlflow.log_param("n_samples", n_samples)
    mlflow.log_param("test_size", test_size)
    mlflow.log_metric("auc_roc", auc)
    mlflow.sklearn.log_model(model, "model")
```

This enables:
- Comparing experiments with different parameters
- Visualizing metric trends over time
- Reproducing past training runs

## Best Practices

1. **Match model to target type** — Binary targets need classification, not regression
2. **Always use held-out data** — Never evaluate on training data
3. **Choose appropriate metrics** — AUC-ROC for probability models, not R²
4. **Implement quality gates** — Prevent bad models from reaching production
5. **Version models** — Enable rollback and audit
6. **Test fallback behavior** — Ensure system works before first model is trained
7. **Document model limitations** — This model is intentionally simple; see rationale

## Model Limitations

The current model is intentionally simple:

| Limitation | Rationale |
|------------|-----------|
| Three features only | Focus is on MLOps infrastructure, not model sophistication |
| No user embeddings | Would require more training data |
| No item-specific learning | Treats all vocabulary items the same |
| Synthetic training data | Real user data will be integrated in future phases |

These are documented design decisions, not oversights. The project demonstrates MLOps practices (versioning, evaluation, deployment) rather than state-of-the-art NLP.

## References

- [Ebbinghaus Forgetting Curve](https://en.wikipedia.org/wiki/Forgetting_curve)
- [Spaced Repetition Research](https://www.gwern.net/Spaced-repetition)
- [scikit-learn LogisticRegression](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LogisticRegression.html)
- [AUC-ROC Explained](https://developers.google.com/machine-learning/crash-course/classification/roc-and-auc)
