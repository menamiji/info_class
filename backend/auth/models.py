"""
Pydantic models for authentication-related data structures.
"""
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, EmailStr, Field


class FirebaseTokenRequest(BaseModel):
    """Request model for Firebase token exchange."""

    firebase_token: str = Field(
        ...,
        description="Firebase ID token to be exchanged for custom JWT",
        min_length=1
    )


class UserRole(str):
    """User role enumeration."""
    ADMIN = "admin"
    STUDENT = "student"
    GUEST = "guest"


class UserInfo(BaseModel):
    """User information extracted from Firebase token."""

    uid: str = Field(..., description="Firebase user ID")
    email: EmailStr = Field(..., description="User email address")
    name: Optional[str] = Field(None, description="User display name")
    picture: Optional[str] = Field(None, description="User profile picture URL")
    email_verified: bool = Field(True, description="Whether email is verified")


class UserWithRole(UserInfo):
    """User information with role and permissions."""

    role: str = Field(..., description="User role (admin/student)")
    permissions: List[str] = Field(
        default_factory=list,
        description="List of permissions for this user"
    )


class JWTPayload(BaseModel):
    """Custom JWT token payload."""

    sub: str = Field(..., description="Subject (user ID)")
    email: EmailStr = Field(..., description="User email")
    name: Optional[str] = Field(None, description="User display name")
    role: str = Field(..., description="User role")
    permissions: List[str] = Field(default_factory=list, description="User permissions")
    iat: int = Field(..., description="Issued at timestamp")
    exp: int = Field(..., description="Expiration timestamp")
    iss: str = Field(default="info-class-api", description="Issuer")


class TokenExchangeResponse(BaseModel):
    """Response model for successful token exchange."""

    ok: bool = Field(True, description="Success indicator")
    data: 'TokenData' = Field(..., description="Token and user data")


class TokenData(BaseModel):
    """Token and user data in successful response."""

    jwt_token: str = Field(..., description="Custom JWT token")
    user: UserWithRole = Field(..., description="User information with role")
    expires_at: datetime = Field(..., description="Token expiration time")


class ErrorResponse(BaseModel):
    """Error response model."""

    ok: bool = Field(False, description="Success indicator")
    error: 'ErrorDetail' = Field(..., description="Error information")


class ErrorDetail(BaseModel):
    """Error detail information."""

    code: str = Field(..., description="Error code")
    message: str = Field(..., description="Human-readable error message")
    details: Optional[dict] = Field(None, description="Additional error details")


# Forward reference resolution
TokenExchangeResponse.model_rebuild()
ErrorResponse.model_rebuild()