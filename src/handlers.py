from fastapi import APIRouter, Request, status
from src.models import RegisterRequest, RegisterResponse, Client
from src.errors import ClientConflictException
from datetime import datetime, timezone

router = APIRouter()


@router.post(
    "/v1/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED
)
async def register(payload: RegisterRequest, request: Request):
    state = request.app.state.app_state

    # Check if client_id is already registered
    if payload.client_id in state.clients:
        raise ClientConflictException()

    # Create new client
    created_at = datetime.now(timezone.utc)

    new_client = Client(
        client_id=payload.client_id,
        ip=payload.ip,
        ssh=payload.ssh,
        created_at=created_at,
    )

    state.clients[payload.client_id] = new_client

    return RegisterResponse(
        client_id=payload.client_id,
        ip=payload.ip,
        ssh=payload.ssh,
        created_at=created_at,
    )
