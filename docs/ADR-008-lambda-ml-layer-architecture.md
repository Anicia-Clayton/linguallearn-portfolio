# ADR-007: Lambda Layer Architecture for ML Model Inference

**Status:** Accepted  
**Date:** December 12, 2024  
**Deciders:** Ace (Cloud Data Engineer / AI Engineer)  
**Context:** Week 4, Day 2 - Deploying forgetting curve ML model for serverless inference

---

## Context

LinguaLearn AI requires real-time ML predictions for the forgetting curve model to optimize spaced repetition schedules. The system needs to predict recall probability for vocabulary cards based on:
- Days since last review
- Review count  
- Difficulty score

The prediction service must:
- Handle variable traffic (low volume initially, potential spikes)
- Minimize infrastructure costs (portfolio project budget)
- Respond within 1 second for acceptable UX
- Be production-ready and scalable

## Decision

We will deploy the scikit-learn forgetting curve model using **AWS Lambda with a Lambda Layer architecture**:

- **Lambda Function:** Minimal deployment package (~2KB) containing only `handler.py`
- **Lambda Layer:** Shared dependency layer (218MB unzipped) containing scikit-learn, pandas, numpy, scipy
- **Model Storage:** ML model stored in S3, loaded on Lambda cold start and cached for warm starts
- **Deployment Method:** S3-based deployment (packages >50MB)
- **Runtime:** Python 3.11, 512MB memory, 60s timeout

## Alternatives Considered

### Alternative 1: EC2 with Flask API
**Pros:**
- No size limits on dependencies
- Full control over environment
- Can use any library versions

**Cons:**
- Always-on cost (~$30-50/month minimum)
- Requires OS patching and maintenance
- Overkill for low-traffic inference
- Need to manage scaling manually

**Decision:** Rejected due to unnecessary ongoing costs for portfolio project with low initial traffic.

---

### Alternative 2: SageMaker Inference Endpoint
**Pros:**
- Built for ML inference workloads
- Auto-scaling capabilities
- Integrated monitoring and A/B testing

**Cons:**
- Minimum cost: ~$50-100/month for smallest instance
- Overkill for simple scikit-learn model
- More complex than needed for this use case
- Portfolio project doesn't justify enterprise ML platform

**Decision:** Rejected due to cost (10x more expensive than Lambda for low traffic) and unnecessary complexity.

---

### Alternative 3: Lambda with Dependencies in Deployment Package
**Pros:**
- Simpler deployment (no layer management)
- Single artifact to version control

**Cons:**
- Hit 50MB direct upload limit immediately
- Would need S3 deployment anyway
- Harder to share dependencies across multiple functions
- Slower deployments (upload full package every time)

**Decision:** Rejected because scikit-learn + pandas already exceeds 50MB, forcing S3 deployment. Layer architecture allows dependency reuse.

---

### Alternative 4: Lambda Container Image
**Pros:**
- No 250MB unzipped limit
- Can use Docker-based workflows
- More flexibility in dependency management

**Cons:**
- Larger cold start time (image pull + initialization)
- More complex deployment pipeline
- Overkill for this size model
- Less familiar tooling than pip/layers

**Decision:** Rejected because Lambda Layer optimization (218MB) successfully fits within limits. Container adds complexity without clear benefit for this use case.

---

## Decision Rationale

**Lambda with Layer architecture chosen because:**

1. **Cost Efficiency (Primary Driver)**
   - $0.20 per million requests
   - Only pay for actual execution time
   - 80%+ cost savings vs EC2 for low traffic
   - Critical for portfolio project budget

2. **Scalability**
   - Auto-scales from 0 to thousands of concurrent invocations
   - No manual scaling configuration needed
   - Handles traffic spikes automatically

3. **Operational Simplicity**
   - No OS patching or maintenance
   - AWS manages all infrastructure
   - Focus on code, not servers

4. **Size Constraints Are Manageable**
   - With aggressive dependency stripping: 218MB unzipped (within 250MB limit)
   - Layer architecture allows dependency sharing
   - S3-based deployment supports packages >50MB

5. **Performance Acceptable**
   - Cold start: <500ms (acceptable for this use case)
   - Warm start: <100ms (excellent)
   - Model caching strategy reduces cold start impact

## Implementation Details

### Lambda Layer Optimization Strategy

**Original dependency size:** 300MB+ unzipped  
**Optimized size:** 218MB unzipped, 78MB zipped

**Optimization techniques applied:**
```bash
# 1. Platform-specific binaries (WSL on Windows host)
pip install --platform manylinux2014_x86_64 --python-version 3.11 \
    --target lambda/ml_layer_minimal/python \
    --only-binary=:all: \
    scikit-learn==1.3.2 pandas numpy scipy

# 2. Aggressive file stripping
find lambda/ml_layer_minimal/python -type d -name "*.dist-info" -exec rm -rf {} +
find lambda/ml_layer_minimal/python -type d -name "tests" -exec rm -rf {} +
find lambda/ml_layer_minimal/python -type d -name "docs" -exec rm -rf {} +
find lambda/ml_layer_minimal/python -type d -name "benchmarks" -exec rm -rf {} +

# 3. Version pinning for consistency
# Training environment: scikit-learn==1.3.2
# Deployment environment: scikit-learn==1.3.2
# Mismatch causes runtime warnings
```

### Model Loading Strategy

```python
# Global variable for warm start optimization
model = None

def load_model():
    """Load model from S3 on cold start, cache for warm starts"""
    global model
    if model is None:
        response = s3.get_object(Bucket=MODEL_BUCKET, Key=MODEL_KEY)
        model_bytes = response['Body'].read()
        model = pickle.loads(model_bytes)
    return model
```

**Cold start:** Downloads model from S3 (~200ms) + unpickles (~100ms)  
**Warm start:** Returns cached model (~0ms)

### Terraform Deployment Configuration

```hcl
resource "aws_lambda_function" "ml_inference" {
  filename         = "ml_inference.zip"
  function_name    = "linguallearn-ml-inference-dev"
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 60
  memory_size      = 512
  
  layers = [aws_lambda_layer_version.ml_dependencies.arn]
  
  environment {
    variables = {
      MODEL_BUCKET = aws_s3_bucket.data_lake.bucket
    }
  }
}

resource "aws_lambda_layer_version" "ml_dependencies" {
  filename            = "ml_layer.zip"
  layer_name          = "ml-dependencies"
  compatible_runtimes = ["python3.11"]
}
```

## Consequences

### Positive

✅ **Cost Savings:** $0.20/million requests vs $30-50/month for EC2  
✅ **Auto-scaling:** Handles traffic spikes without manual intervention  
✅ **Zero Maintenance:** No OS patching or infrastructure management  
✅ **Fast Warm Start:** <100ms response time for cached invocations  
✅ **Production-Ready:** Demonstrates understanding of serverless best practices

### Negative

❌ **Size Constraints:** Required significant time to optimize dependencies (7 errors resolved)  
❌ **Cold Start Latency:** ~500ms for first invocation (acceptable for this use case)  
❌ **Version Pinning Required:** Training and deployment environments must match exactly  
❌ **Platform-Specific Builds:** Must use WSL on Windows for Linux binary compatibility  
❌ **Debugging Complexity:** Harder to debug than local Flask API

### Neutral

⚖️ **Model Retraining:** Must upload new `.pkl` to S3 and redeploy (acceptable for infrequent updates)  
⚖️ **Monitoring:** Requires CloudWatch for observability (standard AWS practice)  
⚖️ **Lambda Limits:** 15-minute execution timeout, 10GB memory max (not constraints for this model)

## Risks and Mitigations

### Risk 1: Lambda Cold Start Impact on UX
**Mitigation:** 
- Keep Lambda warm with scheduled EventBridge pings (if needed)
- Acceptable 500ms latency for background prediction jobs
- User-facing predictions could be pre-computed daily

### Risk 2: Model Size Growth Over Time
**Mitigation:**
- Monitor model size with each version
- If exceeds 250MB: migrate to Lambda Container Image
- Document size optimization techniques for future models

### Risk 3: Version Mismatch Between Training and Deployment
**Mitigation:**
- Pin scikit-learn version in both environments (1.3.2)
- CI/CD checks to verify version consistency
- Document training environment requirements

## Success Metrics

**Deployment successful if:**
- ✅ Lambda layer <250MB unzipped (achieved: 218MB)
- ✅ Model predictions accurate (achieved: 61% recall probability)
- ✅ Cold start <1 second (achieved: ~500ms)
- ✅ Warm start <200ms (achieved: <100ms)
- ✅ No runtime warnings (achieved: clean CloudWatch logs)

**Cost target:**
- Initial traffic: ~1,000 requests/month = $0.20/month
- Growth to 100K requests/month = $2.00/month
- Still 90%+ cheaper than EC2 at scale

## Future Considerations

**When to revisit this decision:**

1. **Model grows beyond 250MB:** Migrate to Lambda Container Image
2. **Cold start becomes UX issue:** Consider keeping Lambda warm or migrate to Fargate
3. **Complex model ensemble needed:** Evaluate SageMaker or ECS
4. **Real-time inference critical (<100ms):** Consider EC2 with GPU or SageMaker Real-Time Inference

**Evolution path:**
1. Lambda Layer (current)
2. Lambda Container Image (if size constraints hit)
3. Fargate/ECS (if cold start becomes issue)
4. SageMaker (if enterprise ML features needed)

## References

- AWS Lambda Limits: https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html
- Lambda Layer Best Practices: https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html
- Scikit-learn Deployment Guide: https://scikit-learn.org/stable/model_persistence.html
- Lambda Cold Start Optimization: https://aws.amazon.com/blogs/compute/operating-lambda-performance-optimization-part-1/

---

**Decision logged by:** Ace (Cloud Data Engineer)  
**Review date:** End of Week 6 (evaluate performance and cost metrics)
