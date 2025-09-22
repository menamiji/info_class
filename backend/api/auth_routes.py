"""
Authentication API routes for token exchange and user management.
"""
from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Dict

from ..auth.models import (
    FirebaseTokenRequest,
    TokenExchangeResponse,
    TokenData,
    ErrorResponse,
    ErrorDetail,
    UserWithRole
)
from ..auth.firebase_validator import FirebaseTokenValidator
from ..auth.role_manager import RoleManager
from ..auth.jwt_manager import JWTManager

# Initialize router and security
router = APIRouter()
security = HTTPBearer()


@router.post(
    "/exchange",
    response_model=TokenExchangeResponse,
    responses={
        400: {"model": ErrorResponse, "description": "Invalid Firebase token"},
        401: {"model": ErrorResponse, "description": "Unauthorized - invalid domain or unverified email"},
        403: {"model": ErrorResponse, "description": "Forbidden - access denied"},
        500: {"model": ErrorResponse, "description": "Internal server error"}
    },
    summary="Exchange Firebase token for custom JWT",
    description="""
    Exchange a valid Firebase ID token for a custom JWT token with role-based permissions.

    This endpoint:
    1. Validates the Firebase ID token
    2. Checks if the user's email is from an allowed domain (@pocheonil.hs.kr)
    3. Determines the user's role (admin/student/guest)
    4. Generates a custom JWT token with role and permissions
    5. Returns the JWT token along with user information

    The returned JWT token should be used for subsequent API calls requiring authentication.
    """
)
async def exchange_firebase_token(request: FirebaseTokenRequest) -> TokenExchangeResponse:
    """
    Exchange Firebase ID token for custom JWT with role-based permissions.

    Args:
        request (FirebaseTokenRequest): Request containing Firebase ID token

    Returns:
        TokenExchangeResponse: Custom JWT token and user information

    Raises:
        HTTPException: If token is invalid or user is not authorized
    """
    try:
        # Step 1: Validate Firebase token and extract user info
        user_info = await FirebaseTokenValidator.validate_token(request.firebase_token)

        # Step 2: Determine user role and permissions
        user_with_role = RoleManager.create_user_with_role(user_info)

        # Step 3: Generate custom JWT token
        jwt_token, expires_at = JWTManager.create_access_token(user_with_role)

        # Step 4: Prepare response
        token_data = TokenData(
            jwt_token=jwt_token,
            user=user_with_role,
            expires_at=expires_at
        )

        response = TokenExchangeResponse(data=token_data)

        # Log successful authentication (optional)
        print(f"✅ Token exchange successful for user: {user_with_role.email} (role: {user_with_role.role})")

        return response

    except ValueError as e:
        error_message = str(e)

        # Determine appropriate HTTP status code based on error
        if any(phrase in error_message.lower() for phrase in ['invalid', 'expired', 'revoked', 'malformed']):
            status_code = status.HTTP_400_BAD_REQUEST
            error_code = "INVALID_TOKEN"
        elif any(phrase in error_message.lower() for phrase in ['domain not allowed', 'not verified']):
            status_code = status.HTTP_401_UNAUTHORIZED
            error_code = "UNAUTHORIZED"
        elif "access denied" in error_message.lower():
            status_code = status.HTTP_403_FORBIDDEN
            error_code = "FORBIDDEN"
        else:
            status_code = status.HTTP_400_BAD_REQUEST
            error_code = "BAD_REQUEST"

        # Log authentication failure
        print(f"❌ Token exchange failed: {error_message}")

        raise HTTPException(
            status_code=status_code,
            detail={
                "ok": False,
                "error": {
                    "code": error_code,
                    "message": error_message
                }
            }
        )

    except Exception as e:
        # Log unexpected errors
        print(f"🚨 Unexpected error in token exchange: {str(e)}")

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "ok": False,
                "error": {
                    "code": "INTERNAL_ERROR",
                    "message": "내부 서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
                }
            }
        )


@router.get(
    "/me",
    response_model=Dict,
    responses={
        401: {"model": ErrorResponse, "description": "Invalid or missing JWT token"},
        403: {"model": ErrorResponse, "description": "Token expired or malformed"}
    },
    summary="Get current user information",
    description="""
    Get the current authenticated user's information from their JWT token.

    This endpoint requires a valid JWT token in the Authorization header.
    Returns the user's profile information and current permissions.
    """
)
async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict:
    """
    Get current user information from JWT token.

    Args:
        credentials (HTTPAuthorizationCredentials): JWT token from Authorization header

    Returns:
        Dict: Current user information and permissions

    Raises:
        HTTPException: If token is invalid or expired
    """
    try:
        # Extract token from credentials
        token = credentials.credentials

        # Verify and decode JWT token
        payload = JWTManager.verify_access_token(token)

        # Return user information
        return {
            "ok": True,
            "data": {
                "uid": payload.get("sub"),
                "email": payload.get("email"),
                "name": payload.get("name"),
                "role": payload.get("role"),
                "permissions": payload.get("permissions", []),
                "expires_at": payload.get("exp")
            }
        }

    except ValueError as e:
        error_message = str(e)

        if "expired" in error_message.lower():
            status_code = status.HTTP_401_UNAUTHORIZED
            error_code = "TOKEN_EXPIRED"
            message = "토큰이 만료되었습니다. 다시 로그인해주세요."
        else:
            status_code = status.HTTP_403_FORBIDDEN
            error_code = "INVALID_TOKEN"
            message = "유효하지 않은 토큰입니다."

        raise HTTPException(
            status_code=status_code,
            detail={
                "ok": False,
                "error": {
                    "code": error_code,
                    "message": message
                }
            }
        )

    except Exception as e:
        print(f"🚨 Unexpected error in get_current_user: {str(e)}")

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "ok": False,
                "error": {
                    "code": "INTERNAL_ERROR",
                    "message": "사용자 정보를 가져오는 중 오류가 발생했습니다."
                }
            }
        )


@router.post(
    "/refresh",
    response_model=TokenExchangeResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Invalid or expired token"},
        500: {"model": ErrorResponse, "description": "Internal server error"}
    },
    summary="Refresh JWT token",
    description="""
    Refresh an existing JWT token if it's close to expiration.

    This endpoint can be used to extend the session without requiring
    the user to re-authenticate with Firebase.
    """
)
async def refresh_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> TokenExchangeResponse:
    """
    Refresh JWT token if close to expiration.

    Args:
        credentials (HTTPAuthorizationCredentials): Current JWT token

    Returns:
        TokenExchangeResponse: New JWT token if refreshed

    Raises:
        HTTPException: If token is invalid or cannot be refreshed
    """
    try:
        token = credentials.credentials

        # Verify current token
        payload = JWTManager.verify_access_token(token)

        # Create user object from token payload
        user_with_role = UserWithRole(
            uid=payload["sub"],
            email=payload["email"],
            name=payload.get("name"),
            picture=None,  # Not stored in JWT
            email_verified=True,  # Assumed true if token exists
            role=payload["role"],
            permissions=payload.get("permissions", [])
        )

        # Generate new token
        new_token, expires_at = JWTManager.create_access_token(user_with_role)

        token_data = TokenData(
            jwt_token=new_token,
            user=user_with_role,
            expires_at=expires_at
        )

        return TokenExchangeResponse(data=token_data)

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "ok": False,
                "error": {
                    "code": "INVALID_TOKEN",
                    "message": f"토큰 갱신에 실패했습니다: {str(e)}"
                }
            }
        )

    except Exception as e:
        print(f"🚨 Unexpected error in refresh_token: {str(e)}")

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "ok": False,
                "error": {
                    "code": "INTERNAL_ERROR",
                    "message": "토큰 갱신 중 오류가 발생했습니다."
                }
            }
        )