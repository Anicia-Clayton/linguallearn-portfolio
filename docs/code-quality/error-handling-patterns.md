# Error Handling Patterns

This document describes the error handling strategy used in LinguaLearn AI's API layer, including the rationale for each pattern and lessons learned from a security review.

## Overview

The API uses a centralized error handling approach that:
- Logs complete error details for debugging
- Returns safe, correlation-ID-based responses to clients
- Provides consistent error formats across all endpoints
- Prevents information leakage

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      API Request                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Route Handler                            │
│                                                             │
│  try:                                                       │
│      # Business logic                                       │
│      with db.get_db_cursor() as (conn, cursor):            │
│          cursor.execute(...)                                │
│          if not result:                                     │
│              handle_not_found("user", user_id)             │
│          return response                                    │
│  except HTTPException:                                      │
│      raise  # Re-raise as-is                               │
│  except Exception as e:                                     │
│      handle_exception(e, context="operation")              │
└─────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┴───────────────────┐
          │                                       │
          ▼                                       ▼
┌─────────────────────┐               ┌─────────────────────┐
│   CloudWatch Logs   │               │   Client Response   │
│                     │               │                     │
│ error_id=abc123     │               │ {"detail":          │
│ context=creating... │               │  "An error occurred │
│ error_type=psycopg2 │               │  during operation.  │
│ detail=relation...  │               │  Reference: abc123"}│
│ [full stack trace]  │               │                     │
└─────────────────────┘               └─────────────────────┘
```

## Implementation

### Error Handling Utility

```python
# api/utils/error_handling.py

def handle_exception(e: Exception, context: str = "operation") -> None:
    """
    Handle an exception by logging details and raising a safe HTTPException.
    """
    error_id = str(uuid.uuid4())
    
    # Full details for operators (CloudWatch)
    logger.error(
        f"error_id={error_id} context={context} "
        f"error_type={type(e).__name__} detail={str(e)}",
        exc_info=True
    )
    
    # Safe message for clients
    raise HTTPException(
        status_code=500,
        detail=f"An unexpected error occurred during {context}. Reference: {error_id}"
    )


def handle_not_found(resource: str, identifier: any) -> None:
    """Handle a not found condition with consistent messaging."""
    logger.warning(f"Resource not found: {resource} with id={identifier}")
    raise HTTPException(
        status_code=404,
        detail=f"{resource.title()} not found"
    )
```

### Usage Pattern

```python
@router.get("/users/{user_id}")
async def get_user(user_id: int):
    try:
        with db.get_db_cursor() as (conn, cursor):
            cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
            result = cursor.fetchone()
            
            if not result:
                handle_not_found("user", user_id)
                
        return UserResponse(**result)
    except HTTPException:
        raise  # Re-raise HTTP exceptions as-is
    except Exception as e:
        handle_exception(e, context="retrieving user")
```

## Why This Matters

### Information Leakage Prevention

Raw exception messages often contain sensitive information:

| Exception Type | Raw Message Contains |
|---------------|---------------------|
| `psycopg2.errors.UndefinedTable` | Table names, schema |
| `psycopg2.errors.SyntaxError` | SQL query fragments |
| `boto3` exceptions | AWS ARNs, account IDs |
| `KeyError` | Internal variable names |

Example of a problematic response:
```json
{
  "detail": "relation \"users_backup\" does not exist\nLINE 1: SELECT password_hash FROM users_backup..."
}
```

This reveals:
- A backup table exists
- The password storage column name
- Part of the SQL query

### Debuggability

The correlation ID enables operators to find the full error:

```bash
aws logs filter-log-events \
  --log-group-name /aws/ec2/linguallearn-api-dev \
  --filter-pattern "error_id=abc123-def456-..."
```

## Error Types and Responses

| Scenario | Status Code | Response Format |
|----------|-------------|-----------------|
| Resource not found | 404 | `{"detail": "User not found"}` |
| Validation error | 422 | Pydantic's standard format |
| Business rule violation | 400 | `{"detail": "Specific message"}` |
| Unexpected error | 500 | `{"detail": "...Reference: {error_id}"}` |

## Input Validation

Beyond error handling, input validation prevents common issues:

### Query Parameter Bounds

```python
@router.get("/vocabulary/user/{user_id}")
async def get_vocabulary(
    user_id: int,
    limit: int = Query(default=50, le=200, ge=1),
    offset: int = Query(default=0, ge=0)
):
    ...
```

This prevents:
- Unbounded queries (`limit=999999`)
- Negative offsets
- DoS through expensive queries

### Enum Validation

```python
class ActivityType(str, Enum):
    journal = "journal"
    music = "music"
    conversation = "conversation"
    # ... other valid types

class PracticeActivityCreate(BaseModel):
    activity_type: ActivityType
```

Invalid values return 422 with:
```json
{
  "detail": [{
    "type": "enum",
    "loc": ["body", "activity_type"],
    "msg": "Input should be 'journal', 'music' or 'conversation'",
    "input": "invalid_type"
  }]
}
```

### URL Validation

```python
class ASLVocabularyCreate(BaseModel):
    video_url: HttpUrl  # Must be valid URL format
```

## Lessons Learned

### Issue: SQL Query Exposure

**Symptom:** Error responses included fragments of SQL queries and table names.

**Root Cause:** Using `str(e)` directly in HTTPException detail for database errors.

**Fix:** Implemented correlation-ID-based error handling that logs full details internally while returning only the reference ID to clients.

**Prevention:** All unexpected exceptions must go through `handle_exception()`, never `detail=str(e)`.

### Issue: Inconsistent Error Formats

**Symptom:** Different endpoints returned errors in different formats, complicating client error handling.

**Root Cause:** Each route implemented its own error handling logic.

**Fix:** Centralized error handling utilities with consistent response formats.

**Prevention:** Use `handle_not_found()` and `handle_exception()` everywhere; don't create custom HTTPException instances with arbitrary messages.

## Best Practices

1. **Never expose raw exceptions** — Always use the error handling utilities
2. **Include context** — The `context` parameter helps operators understand what failed
3. **Re-raise HTTPExceptions** — Let FastAPI's built-in exceptions pass through unchanged
4. **Validate at the boundary** — Use Pydantic models and Query constraints
5. **Log at appropriate levels** — `error` for unexpected exceptions, `warning` for business rule violations
6. **Test error paths** — Include tests that verify error responses don't leak information

## Testing Error Handling

```python
def test_error_handling_does_not_leak_information():
    """Verify error responses contain correlation ID, not raw details."""
    response = client.get("/api/users/99999999")
    
    assert response.status_code == 404
    assert "User not found" in response.json()["detail"]
    
    # These should NOT appear
    assert "SELECT" not in response.json()["detail"]
    assert "psycopg2" not in response.json()["detail"]
    assert "arn:aws" not in response.json()["detail"]
```

## References

- [OWASP Error Handling](https://owasp.org/www-community/Improper_Error_Handling)
- [FastAPI Exception Handling](https://fastapi.tiangolo.com/tutorial/handling-errors/)
- [Pydantic Validation](https://docs.pydantic.dev/latest/concepts/validation/)
