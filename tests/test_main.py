from fastapi.testclient import TestClient
from src.main import create_app
from src.models import AppState


def test_register_success():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    client_id = "8f3b2024-9b2f-4f76-8041-b0e7d56653df"
    payload = {
        "client_id": client_id,
        "ip": "192.168.1.100",
        "ssh": {
            "user": "ubuntu",
            "port": 22,
            "host-key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL...",
        },
    }

    response = client.post("/v1/register", json=payload)

    assert response.status_code == 201
    body = response.json()
    assert body["client_id"] == client_id
    assert body["ip"] == "192.168.1.100"
    assert body["ssh"]["user"] == "ubuntu"
    assert body["ssh"]["port"] == 22
    assert body["ssh"]["host-key"] == "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL..."
    assert isinstance(body["created_at"], str)
    assert body["created_at"].endswith("Z")


def test_register_duplicate_client_id():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    payload = {
        "client_id": "8f3b2024-9b2f-4f76-8041-b0e7d56653df",
        "ip": "192.168.1.100",
        "ssh": {
            "user": "ubuntu",
            "port": 22,
            "host-key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL...",
        },
    }

    # Register first time
    response = client.post("/v1/register", json=payload)
    assert response.status_code == 201

    # Register with same client_id but different IP/SSH details
    payload2 = {
        "client_id": "8f3b2024-9b2f-4f76-8041-b0e7d56653df",
        "ip": "10.0.0.1",
        "ssh": {
            "user": "root",
            "port": 2222,
            "host-key": "ssh-rsa AAAAB3NzaC1yc2E...",
        },
    }
    response = client.post("/v1/register", json=payload2)
    assert response.status_code == 409
    body = response.json()
    assert body["error"] == "Client is already registered"


def test_register_invalid_client_id():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    payload = {
        "client_id": "invalid-uuid",
        "ip": "192.168.1.100",
        "ssh": {
            "user": "ubuntu",
            "port": 22,
            "host-key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL...",
        },
    }

    response = client.post("/v1/register", json=payload)
    assert response.status_code == 400


def test_register_invalid_ip():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    payload = {
        "client_id": "8f3b2024-9b2f-4f76-8041-b0e7d56653df",
        "ip": "999.999.999.999",
        "ssh": {
            "user": "ubuntu",
            "port": 22,
            "host-key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL...",
        },
    }

    response = client.post("/v1/register", json=payload)
    assert response.status_code == 400
    body = response.json()
    assert body["error"] == "Invalid IP address"


def test_register_invalid_ssh_user():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    payload = {
        "client_id": "8f3b2024-9b2f-4f76-8041-b0e7d56653df",
        "ip": "192.168.1.100",
        "ssh": {
            "user": "  ",
            "port": 22,
            "host-key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL...",
        },
    }

    response = client.post("/v1/register", json=payload)
    assert response.status_code == 400
    body = response.json()
    assert body["error"] == "SSH user cannot be empty"


def test_register_invalid_ssh_port():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    payload = {
        "client_id": "8f3b2024-9b2f-4f76-8041-b0e7d56653df",
        "ip": "192.168.1.100",
        "ssh": {
            "user": "ubuntu",
            "port": 0,
            "host-key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL...",
        },
    }

    response = client.post("/v1/register", json=payload)
    assert response.status_code == 400
    body = response.json()
    assert body["error"] == "SSH port must be between 1 and 65535"


def test_register_invalid_ssh_host_key():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    payload = {
        "client_id": "8f3b2024-9b2f-4f76-8041-b0e7d56653df",
        "ip": "192.168.1.100",
        "ssh": {
            "user": "ubuntu",
            "port": 22,
            "host-key": "   ",
        },
    }

    response = client.post("/v1/register", json=payload)
    assert response.status_code == 400
    body = response.json()
    assert body["error"] == "SSH host-key cannot be empty"


def test_register_missing_ssh_fields():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    payload = {
        "client_id": "8f3b2024-9b2f-4f76-8041-b0e7d56653df",
        "ip": "192.168.1.100",
        "ssh": {
            "user": "ubuntu",
            "port": 22,
            # host-key is missing
        },
    }

    response = client.post("/v1/register", json=payload)
    assert response.status_code == 400
    body = response.json()
    assert body["error"] == "host-key is required"
