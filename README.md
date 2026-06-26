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

Register a new user.

#### Request Body (`application/json`)
```json
{
  "username": "john_doe",
  "email": "john.doe@example.com",
  "password": "secure_password_123"
}
```

#### Response Body (`application/json` - `201 Created`)
```json
{
  "user_id": "8f3b2024-9b2f-4f76-8041-b0e7d56653df",
  "username": "john_doe",
  "email": "john.doe@example.com",
  "created_at": "2026-06-25T23:12:42Z"
}
```

#### Error Responses

- **400 Bad Request**: Invalid inputs (e.g., password too short, invalid email address).
  ```json
  {
    "error": "Password must be at least 6 characters"
  }
  ```
- **409 Conflict**: Username or email already exists.
  ```json
  {
    "error": "Username is already taken"
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
