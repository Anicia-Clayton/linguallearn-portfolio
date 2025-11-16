from fastapi import APIRouter, HTTPException
from api.utils.db_connection import db
import datetime

router = APIRouter()

@router.get("/health")
async def health_check():
    """Health check endpoint with RDS connectivity test"""
    try:
        conn = db.get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.close()
        db.return_connection(conn)

        return {
            "status": "healthy",
            "timestamp": datetime.datetime.utcnow().isoformat(),
            "database": "connected"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
