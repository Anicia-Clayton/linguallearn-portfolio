from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr
from api.utils.db_connection import db
from typing import Optional
import hashlib
# import uuid

router = APIRouter()

class UserCreate(BaseModel):
    email: EmailStr
    username: str
    password: str
    role: str = "learner"  # learner, tutor, admin

class UserResponse(BaseModel):
    user_id: int
    email: str
    username: str
    role: str
    created_at: str

@router.post("/users", response_model=UserResponse)
async def create_user(user: UserCreate):
    """Create a new user"""
    try:
        conn = db.get_connection()
        cursor = conn.cursor()

        # Hash password (use proper hashing in production!)
        password_hash = hashlib.sha256(user.password.encode()).hexdigest()
        # user_id = str(uuid.uuid4())

        cursor.execute("""
            INSERT INTO users (email, username, password_hash, role)
            VALUES (%s, %s, %s, %s)
            RETURNING user_id, email, username, role, created_at
        """, (user.email, user.username, password_hash, user.role))

        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        db.return_connection(conn)

        return {
            "user_id": result[0],
            "email": result[1],
            "username": result[2],
            "role": result[3],
            "created_at": result[4].isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int):
    """Get user by ID"""
    try:
        conn = db.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT user_id, email, username, role, created_at
            FROM users WHERE user_id = %s
        """, (user_id,))

        result = cursor.fetchone()
        cursor.close()
        db.return_connection(conn)

        if not result:
            raise HTTPException(status_code=404, detail="User not found")

        return {
            "user_id": result[0],
            "email": result[1],
            "username": result[2],
            "role": result[3],
            "created_at": result[4].isoformat()
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
