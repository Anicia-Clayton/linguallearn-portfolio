from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from api.utils.db_connection import db

router = APIRouter()

# Pydantic models for ASL vocabulary
class ASLVocabularyCreate(BaseModel):
    user_id: int
    sign_name: str
    video_url: str
    thumbnail_url: Optional[str] = None
    difficulty_level: Optional[int] = None  # INTEGER 1-5
    category: Optional[str] = None
    description: Optional[str] = None

class ASLVocabularyResponse(BaseModel):
    asl_card_id: int  # SERIAL - auto-generated
    user_id: int
    sign_name: str
    video_url: str
    category: Optional[str]
    times_practiced: int
    created_at: str

# Creates a new ASL vocabulary card with video reference
@router.post("/asl/vocabulary", response_model=ASLVocabularyResponse)
async def create_asl_vocabulary(vocab: ASLVocabularyCreate):
    """Create a new ASL vocabulary card"""
    try:
        conn = db.get_connection()
        cursor = conn.cursor()

        # Insert into asl_vocabulary table
        cursor.execute("""
            INSERT INTO asl_vocabulary
            (user_id, sign_name, video_url, thumbnail_url,
             difficulty_level, category, description)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING asl_card_id, user_id, sign_name, video_url,
                     category, times_practiced, created_at
        """, (
            vocab.user_id,
            vocab.sign_name,
            vocab.video_url,
            vocab.thumbnail_url,
            vocab.difficulty_level,
            vocab.category,
            vocab.description
        ))

        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        db.return_connection(conn)

        return {
            "asl_card_id": result[0],
            "user_id": result[1],
            "sign_name": result[2],
            "video_url": result[3],
            "category": result[4],
            "times_practiced": result[5],
            "created_at": result[6].isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# Retrieves all ASL vocabulary cards for a user
@router.get("/asl/vocabulary/user/{user_id}")
async def get_user_asl_vocabulary(
    user_id: int,
    category: Optional[str] = None
):
    """Get ASL vocabulary for a user, optionally filtered by category"""
    try:
        conn = db.get_connection()
        cursor = conn.cursor()

        # Build query with optional category filter
        query = """
            SELECT asl_card_id, sign_name, video_url, thumbnail_url,
                   category, difficulty_level, times_practiced, created_at
            FROM asl_vocabulary
            WHERE user_id = %s
        """
        params = [user_id]

        if category:
            query += " AND category = %s"
            params.append(category)

        query += " ORDER BY created_at DESC"

        cursor.execute(query, params)
        results = cursor.fetchall()
        cursor.close()
        db.return_connection(conn)

        return {
            "user_id": user_id,
            "count": len(results),
            "vocabulary": [
                {
                    "asl_card_id": row[0],
                    "sign_name": row[1],
                    "video_url": row[2],
                    "thumbnail_url": row[3],
                    "category": row[4],
                    "difficulty_level": row[5],
                    "times_practiced": row[6],
                    "created_at": row[7].isoformat()
                } for row in results
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Increments practice count for an ASL card
@router.put("/asl/vocabulary/{asl_card_id}/practice")
async def record_asl_practice(asl_card_id: int):
    """Record that user practiced this ASL sign"""
    try:
        conn = db.get_connection()
        cursor = conn.cursor()

        # Update practice count and timestamp
        cursor.execute("""
            UPDATE asl_vocabulary
            SET times_practiced = times_practiced + 1,
                last_practiced_at = NOW()
            WHERE asl_card_id = %s
            RETURNING asl_card_id, times_practiced, last_practiced_at
        """, (asl_card_id,))

        result = cursor.fetchone()

        if not result:
            raise HTTPException(status_code=404, detail="ASL card not found")

        conn.commit()
        cursor.close()
        db.return_connection(conn)

        return {
            "asl_card_id": result[0],
            "times_practiced": result[1],
            "last_practiced_at": result[2].isoformat()
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
