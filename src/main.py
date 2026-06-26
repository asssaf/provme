from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
import uvicorn
import logging
import os

from src.models import AppState
from src.handlers import router
from src.errors import APIException, api_exception_handler, validation_exception_handler

logger = logging.getLogger("provme")


def create_app(state: AppState) -> FastAPI:
    app = FastAPI(title="Provme REST API Server")
    app.state.app_state = state
    app.include_router(router)

    # Exception handlers
    app.add_exception_handler(APIException, api_exception_handler)
    app.add_exception_handler(RequestValidationError, validation_exception_handler)

    return app


def setup_logging():
    log_level = os.getenv("LOG_LEVEL", "INFO").upper()
    logging.basicConfig(
        level=getattr(logging, log_level, logging.INFO),
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )


def main():
    setup_logging()

    state = AppState()
    app = create_app(state)

    port = int(os.getenv("PORT", 3000))
    host = os.getenv("HOST", "0.0.0.0")

    logger.info(f"Server listening on {host}:{port}")
    uvicorn.run(app, host=host, port=port)


if __name__ == "__main__":
    main()
