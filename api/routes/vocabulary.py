from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from api.utils.db_connection import db
from typing import Optional

router = APIRouter()

class VocabularyCreate(BaseModel):
    user_id: int
    language_code: str
    word_native: str
    word_target: str
    context_sentence: Optional[str] = None
    difficulty_level: Optional[int] = None
    category: Optional[str] = None

class VocabularyResponse(BaseModel):
    card_id: int
    user_id: int
    language_code: str
    word_native: str
    word_target: str
    context_sentence: Optional[str] = None
    difficulty_level: Optional[int] = None
    category: Optional[str] = None
    created_at: str

@router.post("/vocabulary", response_model=VocabularyResponse)
async def create_vocabulary_card(vocab: VocabularyCreate):
    """Create a new vocabulary card"""
    try:
        conn = db.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO vocabulary_cards
            (user_id, language_code, word_native, word_target, context_sentence,
             difficulty_level, category)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING card_id, user_id, language_code, word_native, word_target,
                      context_sentence, difficulty_level, category, created_at
        """, (vocab.user_id, vocab.language_code, vocab.word_native,
              vocab.word_target, vocab.context_sentence, vocab.difficulty_level,
              vocab.category))

        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        db.return_connection(conn)

        return {
            "card_id": result[0],
            "user_id": result[1],
            "language_code": result[2],
            "word_native": result[3],
            "word_target": result[4],
            "context_sentence": result[5],
            "difficulty_level": result[6],
            "category": result[7],
            "created_at": result[8].isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/vocabulary/user/{user_id}")
async def get_user_vocabulary(user_id: int, limit: int = 50):
    """Get vocabulary cards for a user"""
    try:
        conn = db.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT card_id, language_code, word_native, word_target,
                   context_sentence, difficulty_level, category, created_at
            FROM vocabulary_cards
            WHERE user_id = %s
            ORDER BY created_at DESC
            LIMIT %s
        """, (user_id, limit))

        results = cursor.fetchall()
        cursor.close()
        db.return_connection(conn)

        return {
            "user_id": user_id,
            "count": len(results),
            "cards": [
                {
                    "card_id": row[0],
                    "language_code": row[1],
                    "word_native": row[2],
                    "word_target": row[3],
                    "context_sentence": row[4],
                    "difficulty_level": row[5],
                    "category": row[6],
                    "created_at": row[7].isoformat()
                } for row in results
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
