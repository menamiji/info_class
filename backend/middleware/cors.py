"""
CORS middleware configuration for FastAPI.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from config.settings import settings


def add_cors_middleware(app: FastAPI) -> None:
    """
    Add CORS middleware to FastAPI application.

    Args:
        app (FastAPI): FastAPI application instance
    """
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=[
            "Accept",
            "Accept-Language",
            "Content-Language",
            "Content-Type",
            "Authorization",
            "X-Requested-With",
            "X-CSRFToken",
        ],
        expose_headers=[
            "Content-Length",
            "Content-Type",
            "Authorization",
        ]
    )

    print(f"✅ CORS middleware configured with origins: {settings.ALLOWED_ORIGINS}")