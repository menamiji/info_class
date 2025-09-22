"""
FastAPI main application for Info Class backend.

This module sets up the FastAPI application with:
- Firebase authentication integration
- JWT token management
- Role-based access control
- CORS and error handling middleware
"""

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import uvicorn
from datetime import datetime

from config.settings import settings
from config.firebase_config import firebase_config
from middleware.cors import add_cors_middleware
from middleware.error_handler import add_error_handlers
from api.auth_routes import router as auth_router

# Initialize FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.VERSION,
    description="""
    Backend API for Info Class - Educational file management system

    ## Features
    * Firebase authentication integration
    * JWT token-based authorization
    * Role-based access control (Admin/Student)
    * File upload and download management
    * User session management

    ## Authentication
    1. Login with Google via Firebase Auth on frontend
    2. Exchange Firebase ID token for custom JWT via `/auth/exchange`
    3. Use JWT token for subsequent API calls with `Authorization: Bearer <token>`

    ## Roles
    * **Admin**: Teachers with full access to manage files and users
    * **Student**: Students with limited access to download and submit files
    """,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
)


@app.on_event("startup")
async def startup_event():
    """Initialize services on application startup."""
    print(f"🚀 Starting {settings.APP_NAME} v{settings.VERSION}")
    print(f"🌍 Environment: {'Development' if settings.DEBUG else 'Production'}")

    try:
        # Initialize Firebase Admin SDK
        firebase_config.initialize_firebase()
        print("✅ Firebase Admin SDK initialized successfully")

    except Exception as e:
        print(f"❌ Failed to initialize Firebase: {str(e)}")
        print("⚠️  Application may not function properly without Firebase")

    print(f"🎯 Server ready at http://{settings.HOST}:{settings.PORT}")


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on application shutdown."""
    print("👋 Shutting down Info Class API")


# Add middleware
add_cors_middleware(app)
add_error_handlers(app)


# Root endpoint
@app.get(
    "/",
    tags=["Health"],
    summary="API Health Check",
    description="Simple health check endpoint to verify the API is running."
)
async def root():
    """API health check endpoint."""
    return {
        "ok": True,
        "message": f"Welcome to {settings.APP_NAME}",
        "version": settings.VERSION,
        "timestamp": datetime.now().isoformat(),
        "environment": "development" if settings.DEBUG else "production"
    }


# Health check endpoint
@app.get(
    "/healthz",
    tags=["Health"],
    summary="Detailed Health Check",
    description="Detailed health check with service status information."
)
async def health_check():
    """Detailed health check endpoint."""

    # Check Firebase connection
    firebase_status = "healthy"
    try:
        # Try to get Firebase app info
        firebase_app = firebase_config._app
        if firebase_app is None:
            firebase_status = "not_initialized"
        else:
            firebase_status = "healthy"
    except Exception as e:
        firebase_status = f"error: {str(e)}"

    return {
        "ok": True,
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": settings.VERSION,
        "services": {
            "api": "healthy",
            "firebase": firebase_status
        },
        "configuration": {
            "debug_mode": settings.DEBUG,
            "allowed_domain": settings.ALLOWED_EMAIL_DOMAIN,
            "token_expire_hours": settings.ACCESS_TOKEN_EXPIRE_HOURS
        }
    }


# Include API routers
app.include_router(
    auth_router,
    prefix="/auth",
    tags=["Authentication"],
    responses={
        401: {"description": "Unauthorized"},
        403: {"description": "Forbidden"},
        500: {"description": "Internal Server Error"}
    }
)


# Add any additional middleware or routes here
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all incoming requests (optional)."""

    if settings.DEBUG:
        start_time = datetime.now()
        print(f"📥 {request.method} {request.url.path}")

        response = await call_next(request)

        process_time = (datetime.now() - start_time).total_seconds()
        print(f"📤 {request.method} {request.url.path} - {response.status_code} ({process_time:.3f}s)")

        return response
    else:
        return await call_next(request)


# Run the application
if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level="info" if settings.DEBUG else "warning"
    )