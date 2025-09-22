"""
Application settings and configuration management.
"""
import os
from typing import List, Optional
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class Settings:
    """Application settings from environment variables."""

    # FastAPI settings
    APP_NAME: str = "Info Class API"
    VERSION: str = "1.0.0"
    DEBUG: bool = os.getenv("DEBUG", "False").lower() == "true"

    # Server settings
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))

    # Security settings
    SECRET_KEY: str = os.getenv("SECRET_KEY", "")
    if not SECRET_KEY:
        raise ValueError("SECRET_KEY environment variable is required")

    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_HOURS: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_HOURS", "24"))

    # Firebase settings
    FIREBASE_PROJECT_ID: str = os.getenv("FIREBASE_PROJECT_ID", "info-class-7398a")
    FIREBASE_SERVICE_ACCOUNT_PATH: str = os.getenv(
        "FIREBASE_SERVICE_ACCOUNT_PATH",
        "/path/to/service-account-key.json"
    )

    # CORS settings - allow all origins in development mode
    ALLOWED_ORIGINS: List[str] = ["*"] if os.getenv("DEBUG", "False").lower() == "true" else [
        "https://info.pocheonil.hs.kr",  # Production domain
    ]

    # Domain restrictions
    ALLOWED_EMAIL_DOMAIN: str = "@pocheonil.hs.kr"

    # Admin email list (for role determination)
    ADMIN_EMAILS: List[str] = [
        "admin@pocheonil.hs.kr",
        # Add more admin emails as needed
    ]

    # API settings
    API_V1_PREFIX: str = "/api"

    # Rate limiting
    RATE_LIMIT_PER_MINUTE: int = int(os.getenv("RATE_LIMIT_PER_MINUTE", "60"))

    def is_admin_email(self, email: str) -> bool:
        """Check if email is in admin list."""
        return email.lower() in [admin.lower() for admin in self.ADMIN_EMAILS]

    def is_allowed_domain(self, email: str) -> bool:
        """Check if email is from allowed domain."""
        return email.lower().endswith(self.ALLOWED_EMAIL_DOMAIN.lower())

# Global settings instance
settings = Settings()