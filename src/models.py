from pydantic import BaseModel, Field, ConfigDict, field_validator, field_serializer
from datetime import datetime
from uuid import UUID
from typing import Dict


class SSHConfig(BaseModel):
    user: str
    port: int
    host_key: str = Field(..., alias="host-key")

    model_config = ConfigDict(populate_by_name=True, populate_by_alias=True)

    @field_validator("user")
    @classmethod
    def validate_user(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("SSH user cannot be empty")
        return v

    @field_validator("port")
    @classmethod
    def validate_port(cls, v: int) -> int:
        if not (1 <= v <= 65535):
            raise ValueError("SSH port must be between 1 and 65535")
        return v

    @field_validator("host_key")
    @classmethod
    def validate_host_key(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("SSH host-key cannot be empty")
        return v


class RegisterRequest(BaseModel):
    client_id: UUID
    ip: str
    ssh: SSHConfig

    @field_validator("ip")
    @classmethod
    def validate_ip(cls, v: str) -> str:
        import ipaddress

        try:
            ipaddress.ip_address(v)
        except ValueError:
            raise ValueError("Invalid IP address")
        return v


class RegisterResponse(BaseModel):
    client_id: UUID
    ip: str
    ssh: SSHConfig
    created_at: datetime

    model_config = ConfigDict(populate_by_name=True, populate_by_alias=True)

    @field_serializer("created_at")
    def serialize_datetime(self, dt: datetime, _info):
        # Format as ISO 8601 with Z suffix instead of +00:00 for Utc serialization
        return dt.isoformat().replace("+00:00", "Z")


class Client(BaseModel):
    client_id: UUID
    ip: str
    ssh: SSHConfig
    created_at: datetime


class AppState:
    def __init__(self):
        self.clients: Dict[UUID, Client] = {}
