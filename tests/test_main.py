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


def test_list_registrations_empty():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    response = client.get("/v1/registrations")
    assert response.status_code == 200
    assert response.json() == []


def test_list_registrations_non_empty():
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

    # Register first
    response = client.post("/v1/register", json=payload)
    assert response.status_code == 201

    # List registrations
    response = client.get("/v1/registrations")
    assert response.status_code == 200
    body = response.json()
    assert len(body) == 1
    assert body[0]["client_id"] == client_id


def test_delete_registration_success():
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

    client.post("/v1/register", json=payload)

    # Delete client
    response = client.delete(f"/v1/registrations/{client_id}")
    assert response.status_code == 200
    assert response.json() == {"message": "Client deregistered successfully"}

    # Ensure it is gone from registrations
    response = client.get("/v1/registrations")
    assert response.status_code == 200
    assert response.json() == []


def test_delete_registration_not_found():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    response = client.delete("/v1/registrations/8f3b2024-9b2f-4f76-8041-b0e7d56653df")
    assert response.status_code == 404
    assert response.json() == {"error": "Client not found"}


def test_admin_portal_get():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    response = client.get("/admin")
    assert response.status_code == 200
    assert "text/html" in response.headers["content-type"]
    assert "Provme Admin" in response.text


def test_admin_portal_root_get():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    response = client.get("/")
    assert response.status_code == 200
    assert "text/html" in response.headers["content-type"]
    assert "Provme Admin" in response.text


def test_static_elm_js_get():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    response = client.get("/static/elm.js")
    assert response.status_code == 200
    # Starlette might return application/javascript or text/javascript depending on MIME db, both are fine
    assert "javascript" in response.headers["content-type"]
