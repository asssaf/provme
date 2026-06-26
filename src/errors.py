from fastapi import Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError


class APIException(Exception):
    def __init__(self, status_code: int, detail: str):
        self.status_code = status_code
        self.detail = detail


class UsernameConflictException(APIException):
    def __init__(self):
        super().__init__(status.HTTP_409_CONFLICT, "Username is already taken")


class EmailConflictException(APIException):
    def __init__(self):
        super().__init__(status.HTTP_409_CONFLICT, "Email is already registered")


class InvalidInputException(APIException):
    def __init__(self, message: str):
        super().__init__(status.HTTP_400_BAD_REQUEST, message)


async def api_exception_handler(request: Request, exc: APIException):
    return JSONResponse(status_code=exc.status_code, content={"error": exc.detail})


async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = exc.errors()
    if errors:
        error = errors[0]
        msg = error.get("msg", "Invalid input")
        if msg.startswith("Value error, "):
            msg = msg[len("Value error, ") :]

        loc = error.get("loc", [])
        field_name = loc[-1] if loc else None
        if msg == "Field required" and field_name:
            msg = f"{field_name} is required"
    else:
        msg = "Invalid input"

    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={"error": msg},
    )
