from fastapi import APIRouter, Request, status
from fastapi.responses import HTMLResponse
from src.models import RegisterRequest, RegisterResponse, Client
from src.errors import ClientConflictException, APIException
from src.admin_html import ADMIN_HTML
from datetime import datetime, timezone
from typing import List
from uuid import UUID

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


@router.get("/v1/registrations", response_model=List[Client])
async def list_registrations(request: Request):
    state = request.app.state.app_state
    return list(state.clients.values())


@router.delete("/v1/registrations/{client_id}", status_code=status.HTTP_200_OK)
async def delete_registration(client_id: UUID, request: Request):
    state = request.app.state.app_state
    if client_id not in state.clients:
        raise APIException(status.HTTP_404_NOT_FOUND, "Client not found")
    del state.clients[client_id]
    return {"message": "Client deregistered successfully"}


@router.get("/admin", response_class=HTMLResponse)
@router.get("/", response_class=HTMLResponse)
async def get_admin_portal():
    return HTMLResponse(content=ADMIN_HTML)
