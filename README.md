# Provme REST API Server (Python version)

A lightweight, asynchronous Python HTTP server built using **FastAPI** and **Uvicorn**. It exposes a registration REST API endpoint with JSON validation and in-memory storage.

## Features

- **FastAPI Framework**: Modern, high-performance, asynchronous routing and request/response handling.
- **Pydantic Validation**: Automatic schema parsing and request body validation.
- **In-Memory Store**: Dict-based database simulation (`state.users`).
- **Validation**: Basic validation for username (non-empty), email (valid structure), and password (minimum length of 6 characters).
- **Error Handling**: Custom exception handlers for clean JSON errors and proper HTTP status codes (`400 Bad Request`, `409 Conflict`).
- **Logging**: Integrated structured logging with standard `logging` library.

---

## API Documentation

### POST `/v1/register`

Register a new client.

#### Request Body (`application/json`)
```json
{
  "client_id": "8f3b2024-9b2f-4f76-8041-b0e7d56653df",
  "ip": "192.168.1.100",
  "ssh": {
    "user": "ubuntu",
    "port": 22,
    "host-key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL..."
  }
}
```

#### Response Body (`application/json` - `201 Created`)
```json
{
  "client_id": "8f3b2024-9b2f-4f76-8041-b0e7d56653df",
  "ip": "192.168.1.100",
  "ssh": {
    "user": "ubuntu",
    "port": 22,
    "host-key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL..."
  },
  "created_at": "2026-06-25T23:12:42Z"
}
```

#### Error Responses

- **400 Bad Request**: Invalid inputs (e.g., invalid IP address, missing fields, or empty ssh user).
  ```json
  {
    "error": "Invalid IP address"
  }
  ```
- **409 Conflict**: Client is already registered.
  ```json
  {
    "error": "Client is already registered"
  }
  ```

---

## Setup and Installation

### 1. Prerequisites (Setup environment)
Run the automated developer setup script to install Python and configure the virtual environment:
```bash
./scripts/dev-setup.sh
```

### 2. Activate Virtual Environment
```bash
source .venv/bin/activate
```

---

## Commands

### Run the Server
Starts the FastAPI server listening on `0.0.0.0:3000`.
```bash
python -m src.main
```

### Run Tests
Executes the test suite with `pytest`.
```bash
python -m pytest
```

### Format and Lint
Runs linter checks and verifies formatting with `ruff`.
```bash
python -m ruff check .
python -m ruff format --check .
```

To auto-format files:
```bash
python -m ruff format .
```

