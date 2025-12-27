# Lessons Learned: Lambda Layer Size Optimization for ML Model Deployment

**Date:** December 12, 2024  
**Phase:** Week 4, Day 2 - ML Integration  
**Context:** Deploying scikit-learn forgetting curve model to AWS Lambda for serverless inference

---

## Challenge

Deploying a machine learning model to AWS Lambda with scikit-learn and its dependencies exceeded Lambda's 250MB unzipped layer limit significantly. Initial packaging attempts resulted in layers over 300MB, making deployment impossible.

## The Journey: 7 Errors Resolved

The deployment process revealed a series of cascading issues that required systematic debugging:

1. **Lambda package too large (>70MB)** → Required S3-based deployment strategy
2. **Layer exceeded 250MB unzipped** → Needed aggressive file stripping
3. **Windows vs Linux binaries incompatibility** → Used WSL with `--platform manylinux2014_x86_64`
4. **Python version mismatch (3.12 vs 3.11)** → Added `--python-version 3.11` flag to pip install
5. **Missing pandas dependency** → Added to layer requirements
6. **Layer still over 250MB with pandas** → Removed `.dist-info`, tests, docs, benchmarks directories
7. **Model dictionary structure mismatch** → Updated handler to extract `sklearn_model` key from dictionary

## Solution Implemented

### Final Working Architecture

**Lambda Layer (78MB zipped, 218MB unzipped):**
- scikit-learn 1.3.2 (pinned version)
- pandas, numpy, scipy, joblib, threadpoolctl
- Aggressively stripped unnecessary files:
  - All `.dist-info` directories
  - All `tests/` directories  
  - All `docs/` directories
  - All `benchmarks/` directories

**Lambda Function:**
- Slim package with `handler.py` only (~2KB)
- Deployed via S3 (supports packages >50MB)
- Python 3.11 runtime
- 512MB memory, 60s timeout

**Deployment Commands:**
```bash
# In WSL - Build Lambda layer with Linux binaries
pip install --platform manylinux2014_x86_64 --python-version 3.11 \
    --target lambda/ml_layer_minimal/python \
    --only-binary=:all: \
    scikit-learn==1.3.2 pandas numpy scipy joblib threadpoolctl

# Strip unnecessary files to reduce size
find lambda/ml_layer_minimal/python -type d -name "*.dist-info" -exec rm -rf {} +
find lambda/ml_layer_minimal/python -type d -name "tests" -exec rm -rf {} +
find lambda/ml_layer_minimal/python -type d -name "docs" -exec rm -rf {} +
find lambda/ml_layer_minimal/python -type d -name "benchmarks" -exec rm -rf {} +

# In Windows CMD - Train model locally (platform-independent .pkl file)
python scripts/train_model.py  # Uses Windows scikit-learn 1.3.2

# Upload to S3 via Terraform
terraform apply
```

### Version Consistency Critical Discovery

**Key insight:** ML model `.pkl` files are platform-independent, but library code is not.

- **Lambda layer (library code):** MUST use WSL with Linux binaries (runs on AWS Lambda Linux servers)
- **Model training (local script):** Use CMD with Windows binaries (runs on Windows laptop)
- **Model `.pkl` file:** Platform-independent serialized Python objects (works on both Windows and Linux)

**Version pinning is mandatory:** Training environment scikit-learn version (1.3.2) must exactly match deployment environment. Mismatch causes runtime warnings and potential prediction errors.

## What I Learned

### 1. **AWS Lambda Has Hard Constraints**
The 250MB unzipped limit isn't negotiable. Production ML deployments require careful dependency management and aggressive optimization.

### 2. **Platform-Specific Binaries vs Platform-Independent Data**
Understanding the distinction between:
- Binary libraries (platform-specific, must match deployment OS)
- Serialized model files (platform-independent, portable)
- This prevents wasted time trying to "fix" issues with the wrong tool

### 3. **Version Consistency is Non-Negotiable**
Even minor version differences (1.7.2 vs 1.3.2) cause warnings. Production systems require:
- Explicit version pinning in requirements.txt
- Matching versions across training and inference environments
- Documentation of which versions were used

### 4. **File Stripping is an Art, Not a Science**
Not all directories are safe to remove:
- Safe: `.dist-info`, `tests`, `docs`, `benchmarks`
- Risky: Core library code, binary `.so` files
- Testing after each stripping iteration is essential

### 5. **S3-Based Deployment Enables Larger Packages**
Direct Lambda upload: 50MB limit  
S3-based deployment: 250MB unzipped limit (10MB zipped)  
Knowing when to switch deployment strategies saves hours of troubleshooting

### 6. **Troubleshooting ML Deployments is Non-Linear**
Each error revealed the next issue. The process required:
- Systematic debugging (fix one error, test, iterate)
- Understanding the full deployment pipeline
- Patience with cascading dependency issues

## Impact

**Deployment Success:**
- ✅ Lambda function operational with 218MB layer
- ✅ Model predictions working correctly (61% recall probability)
- ✅ CloudWatch logs showing no warnings or errors
- ✅ Inference latency <500ms (including cold start)

**Cost Optimization:**
- Serverless Lambda: $0.20 per million requests
- vs Always-on EC2: ~$30-50/month for small instance
- 80%+ cost savings for low-traffic ML inference

**Portfolio Value:**
- Demonstrates production ML deployment constraints
- Shows debugging methodology and problem-solving
- Proves understanding of cloud-native architecture patterns

## Key Takeaways for Future Projects

1. **Start with layer size in mind** - Check dependency sizes before committing to Lambda
2. **Version pin everything** - Training and deployment environments must match exactly
3. **Use WSL for Lambda layers** - Even on Windows machines, Linux binaries are required
4. **Strip aggressively** - Test files, docs, and metadata directories can often be removed
5. **Document the journey** - The troubleshooting process itself demonstrates technical depth

## Interview Talking Points

*"I deployed a scikit-learn model to AWS Lambda and had to optimize the layer size from 300MB+ down to 218MB through strategic dependency stripping and binary optimization. This required understanding the distinction between platform-specific binaries and platform-independent model files, as well as maintaining strict version consistency between training and deployment environments."*

This demonstrates:
- Production ML deployment experience
- Cloud platform constraints awareness  
- Cost optimization mindset
- Systematic debugging methodology
- Real-world problem-solving (not tutorial-following)

---

## References

- AWS Lambda Limits: https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html
- Lambda Layer Best Practices: https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html
- Scikit-learn Version Compatibility: https://scikit-learn.org/stable/install.html
