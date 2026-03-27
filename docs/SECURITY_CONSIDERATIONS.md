# Security Considerations

This document outlines the security posture of LinguaLearn AI, including implemented controls and known limitations with documented solutions.

## Implemented Security Controls

### Infrastructure Security

| Control | Implementation | Status |
|---------|----------------|--------|
| Network Isolation | Private subnets for EC2 and RDS | ✅ Implemented |
| TLS Encryption | HTTPS via ALB with ACM certificate | ✅ Implemented |
| Encryption at Rest | S3 SSE-AES256, RDS encryption | ✅ Implemented |
| IAM Least Privilege | Scoped policies, function-specific Lambda roles | ✅ Implemented |
| S3 Public Access Blocks | All buckets protected | ✅ Implemented |
| Secrets Management | AWS Secrets Manager for credentials | ✅ Implemented |
| VPC Flow Logs | Network traffic monitoring | ✅ Implemented |
| Shell Access | SSM Session Manager (no SSH) | ✅ Implemented |

### Application Security

| Control | Implementation | Status |
|---------|----------------|--------|
| Input Validation | Pydantic models with constraints | ✅ Implemented |
| Error Handling | Correlation IDs, no information leakage | ✅ Implemented |
| Query Bounds | Pagination limits enforced | ✅ Implemented |
| Connection Pool Safety | Context manager with cleanup | ✅ Implemented |
| Rate Limiting | slowapi with tiered limits | ✅ Implemented |

## Known Limitations

The following security features are not implemented in this portfolio project. These are documented with solutions that would be applied in a production environment.

### Authentication & Authorization

**Current State:** The API does not implement authentication middleware. User IDs are accepted from request bodies without ownership verification.

**Why Not Implemented:**
- This is a portfolio project demonstrating MLOps and data engineering skills
- Authentication is a specialized domain typically handled by security teams
- In a real organization, these changes would go through security review and change control

**Production Solution:**

1. **JWT-based Authentication**
   ```python
   from fastapi import Depends, HTTPException
   from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
   import jwt

   security = HTTPBearer()

   async def get_current_user(
       credentials: HTTPAuthorizationCredentials = Depends(security)
   ) -> dict:
       try:
           payload = jwt.decode(
               credentials.credentials,
               settings.JWT_SECRET,
               algorithms=["HS256"]
           )
           return payload
       except jwt.InvalidTokenError:
           raise HTTPException(status_code=401, detail="Invalid token")
   ```

2. **Resource Ownership Verification**
   ```python
   @router.get("/vocabulary/user/{user_id}")
   async def get_vocabulary(
       user_id: int,
       current_user: dict = Depends(get_current_user)
   ):
       if current_user["user_id"] != user_id:
           raise HTTPException(status_code=403, detail="Forbidden")
       # ... proceed with request
   ```

3. **Alternative: AWS Cognito Integration**
   - User pools for authentication
   - Identity pools for AWS resource access
   - ALB integration for token validation

### Password Storage

**Current State:** If password storage were implemented, the security review noted SHA-256 would be insufficient.

**Production Solution:**
```python
import bcrypt

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

def verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode(), hashed.encode())
```

**Why bcrypt:**
- Work factor (cost) makes brute force expensive
- Built-in salt prevents rainbow table attacks
- Industry standard for password hashing

### API Security Headers

**Production Addition:**
```python
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.gzip import GZipMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://app.linguallearn.example.com"],
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

@app.middleware("http")
async def add_security_headers(request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Content-Security-Policy"] = "default-src 'self'"
    return response
```

### Session Management

**Production Solution:**
- Short-lived access tokens (15 minutes)
- Refresh token rotation
- Secure, HttpOnly cookies
- Session invalidation on logout

## Security Review Process

This project underwent a collaborative code review with a security engineer colleague. Findings were categorized as:

1. **Implemented:** Code quality fixes (connection pooling, error handling, ML evaluation, Terraform security)
2. **Documented:** Authentication-related items documented here with solutions

This approach reflects real-world practice where:
- Not every finding is immediately fixable
- Some changes require organizational process (security review boards)
- Documentation enables future implementation

## Threat Model Summary

| Threat | Mitigation |
|--------|------------|
| SQL Injection | Parameterized queries via psycopg2 |
| Information Leakage | Structured error handling with correlation IDs |
| Connection Exhaustion | Context manager with guaranteed cleanup |
| Unauthorized Access | [Future: Authentication middleware] |
| Data Exfiltration | VPC isolation, S3 public access blocks |
| Credential Exposure | Secrets Manager, no hardcoded credentials |

## Compliance Considerations

For production deployment handling PII (user vocabulary, learning patterns):

| Requirement | Consideration |
|-------------|---------------|
| Data Encryption | ✅ At rest and in transit |
| Access Logging | ✅ CloudWatch, VPC Flow Logs |
| Data Retention | Configurable log retention policies |
| Right to Deletion | Would require API endpoint for user data deletion |
| Data Location | Single-region deployment, specify in privacy policy |

## Incident Response

See [OPERATIONAL_RUNBOOK.md](./OPERATIONAL_RUNBOOK.md) for:
- Alert response procedures
- Security incident investigation steps
- Contact escalation paths

## References

- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [AWS Security Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [FastAPI Security Documentation](https://fastapi.tiangolo.com/tutorial/security/)
