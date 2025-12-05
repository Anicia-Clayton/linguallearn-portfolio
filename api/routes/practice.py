from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from api.utils.db_connection import db

router = APIRouter()

# Pydantic models for request/response validation
# Schema: practice_activities table
class PracticeActivityCreate(BaseModel):
    user_id: int
    language_code: str
    activity_type: str  # journal, music, show, book, conversation, movie, podcast, other
    skill_focus: Optional[str] = None  # listening, speaking, reading, writing, input, mixed
    title: Optional[str] = None
    content: Optional[str] = None
    notes: Optional[str] = None
    duration_minutes: Optional[int] = None
    new_vocabulary_discovered: Optional[List[str]] = None

class PracticeActivityResponse(BaseModel):
    activity_id: int
    user_id: int
    language_code: str
    activity_type: str
    skill_focus: Optional[str]
    title: Optional[str]
    created_at: str
    duration_minutes: Optional[int]

# Endpoint: Creates a new practice activity record
@router.post("/practice", response_model=PracticeActivityResponse)
async def create_practice_activity(activity: PracticeActivityCreate):
    """Log a new practice activity"""
    try:
        conn = db.get_connection()
        cursor = conn.cursor()

        # Insert into practice_activities table
        cursor.execute("""
            INSERT INTO practice_activities
            (user_id, language_code, activity_type, skill_focus,
             title, content, notes, duration_minutes, new_vocabulary_discovered)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING activity_id, user_id, language_code, activity_type,
                     skill_focus, title, created_at, duration_minutes
        """, (
            activity.user_id,
            activity.language_code,
            activity.activity_type,
            activity.skill_focus,
            activity.title,
            activity.content,
            activity.notes,
            activity.duration_minutes,
            activity.new_vocabulary_discovered
        ))

        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        db.return_connection(conn)

        return {
            "activity_id": result[0],
            "user_id": result[1],
            "language_code": result[2],
            "activity_type": result[3],
            "skill_focus": result[4],
            "title": result[5],
            "created_at": result[6].isoformat(),
            "duration_minutes": result[7]
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# Endpoint: Retrieves practice activities for a specific user with optional filters
@router.get("/practice/user/{user_id}")
async def get_user_practice_activities(
    user_id: int,
    language_code: Optional[str] = None,
    activity_type: Optional[str] = None,
    limit: int = 50
):
    """Get practice activities for a user with optional filters"""
    try:
        conn = db.get_connection()
        cursor = conn.cursor()

        # Build dynamic query with filters
        query = """
            SELECT activity_id, language_code, activity_type, skill_focus,
                   title, content, notes, duration_minutes, created_at
            FROM practice_activities
            WHERE user_id = %s
        """
        params = [user_id]

        if language_code:
            query += " AND language_code = %s"
            params.append(language_code)

        if activity_type:
            query += " AND activity_type = %s"
            params.append(activity_type)

        query += " ORDER BY created_at DESC LIMIT %s"
        params.append(limit)

        cursor.execute(query, params)
        results = cursor.fetchall()
        cursor.close()
        db.return_connection(conn)

        return {
            "user_id": user_id,
            "count": len(results),
            "activities": [
                {
                    "activity_id": row[0],
                    "language_code": row[1],
                    "activity_type": row[2],
                    "skill_focus": row[3],
                    "title": row[4],
                    "content": row[5],
                    "notes": row[6],
                    "duration_minutes": row[7],
                    "created_at": row[8].isoformat()
                } for row in results
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Endpoint: Aggregates practice statistics by activity type
@router.get("/practice/stats/{user_id}")
async def get_practice_stats(user_id: int):
    """Get practice statistics for a user"""
    try:
        conn = db.get_connection()
        cursor = conn.cursor()

        # Aggregate statistics by activity type
        cursor.execute("""
            SELECT
                activity_type,
                COUNT(*) as count,
                SUM(COALESCE(duration_minutes, 0)) as total_minutes
            FROM practice_activities
            WHERE user_id = %s
            GROUP BY activity_type
        """, (user_id,))

        results = cursor.fetchall()
        cursor.close()
        db.return_connection(conn)

        stats = {
            "user_id": user_id,
            "by_activity_type": [
                {
                    "activity_type": row[0],
                    "count": row[1],
                    "total_minutes": row[2]
                } for row in results
            ]
        }

        return stats
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Endpoint: Retrieves a single practice activity by ID
@router.get("/practice/{activity_id}")
async def get_practice_activity(activity_id: int):
    """Get a specific practice activity by ID"""
    try:
        conn = db.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT activity_id, user_id, language_code, activity_type, skill_focus,
                   title, content, notes, duration_minutes, new_vocabulary_discovered,
                   created_at, reviewed_by_tutor, tutor_feedback
            FROM practice_activities
            WHERE activity_id = %s
        """, (activity_id,))

        result = cursor.fetchone()
        cursor.close()
        db.return_connection(conn)

        if not result:
            raise HTTPException(status_code=404, detail="Activity not found")

        return {
            "activity_id": result[0],
            "user_id": result[1],
            "language_code": result[2],
            "activity_type": result[3],
            "skill_focus": result[4],
            "title": result[5],
            "content": result[6],
            "notes": result[7],
            "duration_minutes": result[8],
            "new_vocabulary_discovered": result[9],
            "created_at": result[10].isoformat(),
            "reviewed_by_tutor": result[11],
            "tutor_feedback": result[12]
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
