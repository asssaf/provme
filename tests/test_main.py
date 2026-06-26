from fastapi.testclient import TestClient
from src.main import create_app
from src.models import AppState

def test_register_success():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    response = client.post(
        "/v1/register",
        json={
            "username": "alice",
            "email": "alice@example.com",
            "password": "supersecurepassword"
        }
    )

    assert response.status_code == 201
    body = response.json()
    assert body["username"] == "alice"
    assert body["email"] == "alice@example.com"
    assert isinstance(body["user_id"], str)
    assert isinstance(body["created_at"], str)
    assert body["created_at"].endswith("Z")

def test_register_duplicate_username():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    # Register first time
    response = client.post(
        "/v1/register",
        json={
            "username": "alice",
            "email": "alice@example.com",
            "password": "supersecurepassword"
        }
    )
    assert response.status_code == 201

    # Register with same username but different email (case-insensitive check)
    response = client.post(
        "/v1/register",
        json={
            "username": "ALICE",
            "email": "another@example.com",
            "password": "supersecurepassword"
        }
    )
    assert response.status_code == 409
    body = response.json()
    assert body["error"] == "Username is already taken"

def test_register_duplicate_email():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    # Register first time
    response = client.post(
        "/v1/register",
        json={
            "username": "alice",
            "email": "alice@example.com",
            "password": "supersecurepassword"
        }
    )
    assert response.status_code == 201

    # Register with different username but same email (case-insensitive check)
    response = client.post(
        "/v1/register",
        json={
            "username": "bob",
            "email": "ALICE@example.com",
            "password": "supersecurepassword"
        }
    )
    assert response.status_code == 409
    body = response.json()
    assert body["error"] == "Email is already registered"

def test_register_invalid_email():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    response = client.post(
        "/v1/register",
        json={
            "username": "alice",
            "email": "invalid-email",
            "password": "supersecurepassword"
        }
    )
    assert response.status_code == 400
    body = response.json()
    assert body["error"] == "Invalid email address"

def test_register_invalid_username():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    response = client.post(
        "/v1/register",
        json={
            "username": "   ",
            "email": "alice@example.com",
            "password": "supersecurepassword"
        }
    )
    assert response.status_code == 400
    body = response.json()
    assert body["error"] == "Username cannot be empty"

def test_register_short_password():
    state = AppState()
    app = create_app(state)
    client = TestClient(app)

    response = client.post(
        "/v1/register",
        json={
            "username": "alice",
            "email": "alice@example.com",
            "password": "12345"
        }
    )
    assert response.status_code == 400
    body = response.json()
    assert body["error"] == "Password must be at least 6 characters"
