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

### GET `/v1/registrations`

Retrieve a list of all registered clients.

#### Response Body (`application/json` - `200 OK`)
```json
[
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
]
```

### DELETE `/v1/registrations/{client_id}`

Deregister / delete a registered client by ID.

#### Response Body (`application/json` - `200 OK`)
```json
{
  "message": "Client deregistered successfully"
}
```

#### Error Responses
- **404 Not Found**: Client does not exist.
  ```json
  {
    "error": "Client not found"
  }
  ```

---

## Admin Portal

A premium admin dashboard is available at `/admin` (and also served at the root `/`). The frontend is written in **Elm** and compiles to a static JS bundle.

This interface provides:
- Live stats (total clients, unique IP count, last activity time).
- A search and filter bar for searching client registrations.
- Auto-refresh toggle.
- A **Simulate Registration** action to generate and register mock clients for easy testing.
- An interactive registrations list table with copy-to-clipboard buttons and deregistration (delete) controls.

---


## Setup and Installation

### 1. Prerequisites (Setup environment)
Run the automated developer setup script to install Python, configure the virtual environment, and download/install the Elm compiler:
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

### Build the Elm Frontend
Compiles the Elm source code ([src/elm/Main.elm](file:///home/user/work/src/elm/Main.elm)) to the static JavaScript asset ([src/static/elm.js](file:///home/user/work/src/static/elm.js)):
```bash
elm make src/elm/Main.elm --output=src/static/elm.js
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


