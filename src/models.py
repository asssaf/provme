from pydantic import BaseModel, field_validator, field_serializer
from datetime import datetime
from uuid import UUID
from typing import Dict

class RegisterRequest(BaseModel):
    username: str
    email: str
    password: str

    @field_validator('username')
    @classmethod
    def validate_username(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Username cannot be empty")
        return v

    @field_validator('email')
    @classmethod
    def validate_email(cls, v: str) -> str:
        if not v.strip() or '@' not in v:
            raise ValueError("Invalid email address")
        return v

    @field_validator('password')
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters")
        return v

class RegisterResponse(BaseModel):
    user_id: UUID
    username: str
    email: str
    created_at: datetime

    @field_serializer('created_at')
    def serialize_datetime(self, dt: datetime, _info):
        # Format as ISO 8601 with Z suffix instead of +00:00 to match Rust's Utc serialization
        return dt.isoformat().replace("+00:00", "Z")

class User(BaseModel):
    id: UUID
    username: str
    email: str
    password_hash: str
    created_at: datetime

class AppState:
    def __init__(self):
        self.users: Dict[UUID, User] = {}
