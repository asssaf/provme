from fastapi import APIRouter, Request, status
from src.models import RegisterRequest, RegisterResponse, User
from src.errors import UsernameConflictException, EmailConflictException
from datetime import datetime, timezone
import uuid

router = APIRouter()

@router.post("/v1/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
async def register(payload: RegisterRequest, request: Request):
    state = request.app.state.app_state

    # Check for duplicate username/email (case-insensitive)
    for user in state.users.values():
        if user.username.lower() == payload.username.lower():
            raise UsernameConflictException()
        if user.email.lower() == payload.email.lower():
            raise EmailConflictException()

    # Create new user
    user_id = uuid.uuid4()
    created_at = datetime.now(timezone.utc)

    new_user = User(
        id=user_id,
        username=payload.username,
        email=payload.email,
        password_hash=payload.password,  # Mocking hashing just like Rust did
        created_at=created_at
    )

    state.users[user_id] = new_user

    return RegisterResponse(
        user_id=user_id,
        username=payload.username,
        email=payload.email,
        created_at=created_at
    )
