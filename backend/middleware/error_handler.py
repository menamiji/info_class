"""
Global error handling middleware for FastAPI.
"""
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
import traceback
from typing import Dict, Any

from config.settings import settings


def add_error_handlers(app: FastAPI) -> None:
    """
    Add global error handlers to FastAPI application.

    Args:
        app (FastAPI): FastAPI application instance
    """

    @app.exception_handler(HTTPException)
    async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
        """Handle HTTP exceptions with consistent error format."""

        # If detail is already in our error format, return as-is
        if isinstance(exc.detail, dict) and "ok" in exc.detail:
            return JSONResponse(
                status_code=exc.status_code,
                content=exc.detail
            )

        # Otherwise, format the error
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "ok": False,
                "error": {
                    "code": f"HTTP_{exc.status_code}",
                    "message": str(exc.detail),
                    "status_code": exc.status_code
                }
            }
        )

    @app.exception_handler(StarletteHTTPException)
    async def starlette_http_exception_handler(request: Request, exc: StarletteHTTPException) -> JSONResponse:
        """Handle Starlette HTTP exceptions."""
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "ok": False,
                "error": {
                    "code": f"HTTP_{exc.status_code}",
                    "message": str(exc.detail),
                    "status_code": exc.status_code
                }
            }
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
        """Handle request validation errors."""

        # Extract validation error details
        errors = []
        for error in exc.errors():
            field = " -> ".join(str(loc) for loc in error["loc"])
            message = error["msg"]
            errors.append(f"{field}: {message}")

        return JSONResponse(
            status_code=422,
            content={
                "ok": False,
                "error": {
                    "code": "VALIDATION_ERROR",
                    "message": "요청 데이터가 유효하지 않습니다.",
                    "details": {
                        "validation_errors": errors,
                        "body": str(exc.body) if hasattr(exc, 'body') else None
                    }
                }
            }
        )

    @app.exception_handler(ValueError)
    async def value_error_handler(request: Request, exc: ValueError) -> JSONResponse:
        """Handle ValueError exceptions."""
        error_message = str(exc)

        # Log the error for debugging
        print(f"❌ ValueError in {request.url.path}: {error_message}")

        return JSONResponse(
            status_code=400,
            content={
                "ok": False,
                "error": {
                    "code": "VALUE_ERROR",
                    "message": error_message
                }
            }
        )

    @app.exception_handler(Exception)
    async def general_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        """Handle all other unexpected exceptions."""

        # Log the full error with traceback
        error_traceback = traceback.format_exc()
        print(f"🚨 Unhandled exception in {request.url.path}:")
        print(error_traceback)

        # Don't expose internal error details in production
        if settings.DEBUG:
            error_details = {
                "exception_type": type(exc).__name__,
                "exception_message": str(exc),
                "traceback": error_traceback
            }
        else:
            error_details = None

        return JSONResponse(
            status_code=500,
            content={
                "ok": False,
                "error": {
                    "code": "INTERNAL_SERVER_ERROR",
                    "message": "서버에서 예상치 못한 오류가 발생했습니다. 잠시 후 다시 시도해주세요.",
                    "details": error_details
                }
            }
        )

    print("✅ Global error handlers configured")