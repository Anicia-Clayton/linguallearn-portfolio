# Connection Pool Management

This document describes the connection pooling strategy used in LinguaLearn AI's API layer, including lessons learned from a production hardening review.

## Overview

The API uses PostgreSQL connection pooling via `psycopg2.pool.SimpleConnectionPool` to manage database connections efficiently. This avoids the overhead of establishing a new connection for each request while limiting the total number of concurrent connections to the database.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        API Layer                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Request 1│  │ Request 2│  │ Request 3│  │ Request N│   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       │             │             │             │          │
│       └─────────────┴──────┬──────┴─────────────┘          │
│                            │                                │
│  ┌─────────────────────────▼────────────────────────────┐  │
│  │              Connection Pool (20 connections)         │  │
│  │   ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ... ┌───┐ ┌───┐     │  │
│  │   │ 1 │ │ 2 │ │ 3 │ │ 4 │ │ 5 │     │19 │ │20 │     │  │
│  │   └───┘ └───┘ └───┘ └───┘ └───┘     └───┘ └───┘     │  │
│  └──────────────────────────────────────────────────────┘  │
│                            │                                │
└────────────────────────────┼────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   RDS PostgreSQL │
                    │   (max 100 conn) │
                    └─────────────────┘
```

## Implementation

### Context Manager Pattern

All database operations use a context manager that guarantees connection cleanup:

```python
@contextmanager
def get_db_cursor(self):
    conn = self.connection_pool.getconn()
    cursor = conn.cursor()
    try:
        yield conn, cursor
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        self.connection_pool.putconn(conn)
```

**Usage:**
```python
with db.get_db_cursor() as (conn, cursor):
    cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
    result = cursor.fetchone()
# Connection automatically returned to pool here
```

### Why This Matters

The `finally` block ensures the connection returns to the pool even when exceptions occur. Without this pattern:

```python
# Problematic pattern
conn = pool.getconn()
cursor = conn.cursor()
cursor.execute(query)  # If this throws...
cursor.close()
pool.putconn(conn)     # ...this never runs
```

With a pool size of 20, just 20 unhandled exceptions will exhaust the pool, making the API completely unavailable.

## Pool Configuration

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `minconn` | 1 | Minimum connections to maintain |
| `maxconn` | 20 | Maximum concurrent connections |

The maximum is set conservatively below RDS's connection limit (typically 100+ for db.t3.micro) to leave headroom for:
- Admin connections for debugging
- Lambda functions that might connect directly
- Maintenance operations

## Initialization with Retry

Pool initialization includes retry logic to handle transient network issues during startup:

```python
def _initialize_pool(self, retries: int = 3, delay: int = 2):
    for attempt in range(retries):
        try:
            creds = self._get_db_credentials()
            self.connection_pool = psycopg2.pool.SimpleConnectionPool(...)
            return
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(delay)
    raise RuntimeError("Failed to initialize database connection pool")
```

This handles common startup scenarios:
- RDS instance still warming up
- Secrets Manager temporary unavailability
- Network configuration propagation delays

## Monitoring

The following CloudWatch alarms monitor pool health:

| Alarm | Metric | Threshold | Rationale |
|-------|--------|-----------|-----------|
| RDS Connection Spike | DatabaseConnections | > 16 | 80% of pool size indicates potential exhaustion |

When this alarm fires:
1. Check recent deployments for connection leak bugs
2. Review error logs for exception patterns
3. Consider restarting the API to reset the pool

## Lessons Learned

### Issue: Connection Leaks Under Exceptions

**Symptom:** API became unresponsive after periods of elevated error rates.

**Root Cause:** Manual connection management (`get_connection()` / `return_connection()`) did not guarantee cleanup when exceptions occurred between acquiring and returning.

**Fix:** Implemented context manager pattern with `finally` block.

**Prevention:** All database operations must use the context manager. The legacy methods are deprecated and log warnings when used.

### Issue: Pool Exhaustion During RDS Maintenance

**Symptom:** API failed to start after RDS maintenance window.

**Root Cause:** Pool initialization failed immediately on first connection attempt without retry.

**Fix:** Added retry logic with exponential backoff to initialization.

**Prevention:** Always include retry logic for external service connections at startup.

## Best Practices

1. **Always use the context manager** — Never call `get_connection()` directly in application code
2. **Keep transactions short** — Don't hold connections during external API calls or computations
3. **Monitor connection metrics** — Set alarms at 80% of pool capacity
4. **Test failure scenarios** — Verify connections return to pool when exceptions occur
5. **Log pool events** — Track acquisition, release, and exhaustion events

## References

- [psycopg2 Connection Pooling](https://www.psycopg.org/docs/pool.html)
- [PostgreSQL Connection Limits](https://www.postgresql.org/docs/current/runtime-config-connection.html)
- [AWS RDS Connection Management](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Limits.html)
