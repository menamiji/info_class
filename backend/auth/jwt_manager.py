"""
JWT token generation, validation, and management.
"""
import jwt
from datetime import datetime, timedelta, timezone
from typing import Dict, Optional

from ..config.settings import settings
from .models import UserWithRole, JWTPayload


class JWTManager:
    """Handles JWT token generation and validation for custom authentication."""

    @staticmethod
    def create_access_token(user: UserWithRole) -> tuple[str, datetime]:
        """
        Create a custom JWT access token for the user.

        Args:
            user (UserWithRole): User information with role and permissions

        Returns:
            tuple[str, datetime]: JWT token string and expiration datetime

        Raises:
            ValueError: If token creation fails
        """
        try:
            # Calculate token expiration
            now = datetime.now(timezone.utc)
            expires_at = now + timedelta(hours=settings.ACCESS_TOKEN_EXPIRE_HOURS)

            # Create JWT payload
            payload = JWTPayload(
                sub=user.uid,  # Subject (user ID)
                email=user.email,
                name=user.name,
                role=user.role,
                permissions=user.permissions,
                iat=int(now.timestamp()),  # Issued at
                exp=int(expires_at.timestamp()),  # Expiration
                iss="info-class-api"  # Issuer
            )

            # Generate JWT token
            token = jwt.encode(
                payload.model_dump(),
                settings.SECRET_KEY,
                algorithm=settings.ALGORITHM
            )

            return token, expires_at

        except Exception as e:
            raise ValueError(f"Failed to create JWT token: {str(e)}")

    @staticmethod
    def verify_access_token(token: str) -> Dict:
        """
        Verify and decode a JWT access token.

        Args:
            token (str): JWT token to verify

        Returns:
            Dict: Decoded token payload

        Raises:
            ValueError: If token is invalid, expired, or malformed
        """
        try:
            # Decode and verify token
            payload = jwt.decode(
                token,
                settings.SECRET_KEY,
                algorithms=[settings.ALGORITHM],
                options={
                    "verify_signature": True,
                    "verify_exp": True,
                    "verify_iat": True,
                    "require_exp": True,
                    "require_iat": True,
                }
            )

            # Validate required claims
            required_claims = ['sub', 'email', 'role', 'exp', 'iat']
            for claim in required_claims:
                if claim not in payload:
                    raise ValueError(f"Missing required claim: {claim}")

            # Validate token issuer
            if payload.get('iss') != 'info-class-api':
                raise ValueError("Invalid token issuer")

            return payload

        except jwt.ExpiredSignatureError:
            raise ValueError("Token has expired")

        except jwt.InvalidTokenError as e:
            raise ValueError(f"Invalid token: {str(e)}")

        except Exception as e:
            raise ValueError(f"Token verification failed: {str(e)}")

    @staticmethod
    def decode_token_without_verification(token: str) -> Optional[Dict]:
        """
        Decode JWT token without verification (for debugging/logging only).

        Args:
            token (str): JWT token to decode

        Returns:
            Optional[Dict]: Decoded payload or None if decoding fails

        Warning:
            This method should NEVER be used for authentication purposes.
            Only use for debugging, logging, or informational purposes.
        """
        try:
            return jwt.decode(
                token,
                options={"verify_signature": False, "verify_exp": False}
            )
        except Exception:
            return None

    @staticmethod
    def get_token_expiration(token: str) -> Optional[datetime]:
        """
        Extract expiration time from token without full verification.

        Args:
            token (str): JWT token

        Returns:
            Optional[datetime]: Token expiration time or None if extraction fails
        """
        try:
            payload = JWTManager.decode_token_without_verification(token)
            if payload and 'exp' in payload:
                return datetime.fromtimestamp(payload['exp'], tz=timezone.utc)
            return None
        except Exception:
            return None

    @staticmethod
    def is_token_expired(token: str) -> bool:
        """
        Check if token is expired without full verification.

        Args:
            token (str): JWT token to check

        Returns:
            bool: True if token is expired, False otherwise
        """
        try:
            expiration = JWTManager.get_token_expiration(token)
            if expiration:
                return datetime.now(timezone.utc) > expiration
            return True  # If we can't get expiration, consider it expired
        except Exception:
            return True

    @staticmethod
    def refresh_token_if_needed(token: str, user: UserWithRole,
                               refresh_threshold_hours: int = 2) -> Optional[tuple[str, datetime]]:
        """
        Refresh token if it's close to expiration.

        Args:
            token (str): Current JWT token
            user (UserWithRole): User information for creating new token
            refresh_threshold_hours (int): Hours before expiration to refresh

        Returns:
            Optional[tuple[str, datetime]]: New token and expiration if refreshed, None otherwise
        """
        try:
            expiration = JWTManager.get_token_expiration(token)
            if not expiration:
                return None

            # Check if token is within refresh threshold
            threshold_time = datetime.now(timezone.utc) + timedelta(hours=refresh_threshold_hours)

            if expiration <= threshold_time:
                # Token is close to expiration, create new one
                return JWTManager.create_access_token(user)

            return None  # No refresh needed

        except Exception:
            return None