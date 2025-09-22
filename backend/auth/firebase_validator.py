"""
Firebase token validation and user information extraction.
"""
from typing import Optional
from firebase_admin import auth as firebase_auth
from firebase_admin.auth import InvalidIdTokenError, ExpiredIdTokenError, RevokedIdTokenError

from config.firebase_config import firebase_config
from config.settings import settings
from .models import UserInfo


class FirebaseTokenValidator:
    """Handles Firebase ID token validation and user info extraction."""

    @staticmethod
    async def validate_token(firebase_token: str) -> UserInfo:
        """
        Validate Firebase ID token and extract user information.

        Args:
            firebase_token (str): Firebase ID token to validate

        Returns:
            UserInfo: Validated user information

        Raises:
            ValueError: If token is invalid, expired, or user is not authorized
        """
        try:
            # In development mode, if Firebase is not initialized, return mock user
            if settings.DEBUG and not firebase_config.is_initialized():
                print("🔧 Development mode: Using mock Firebase token validation")
                return UserInfo(
                    uid="dev_user_123",
                    email="admin@pocheonil.hs.kr",
                    name="개발자 계정",
                    picture=None,
                    email_verified=True
                )

            # Verify the Firebase ID token
            decoded_token = firebase_config.verify_id_token(firebase_token)

            # Extract user information from decoded token
            uid = decoded_token.get('uid')
            email = decoded_token.get('email')
            name = decoded_token.get('name') or decoded_token.get('display_name')
            picture = decoded_token.get('picture')
            email_verified = decoded_token.get('email_verified', False)

            # Validate required fields
            if not uid:
                raise ValueError("Token does not contain user ID")

            if not email:
                raise ValueError("Token does not contain email")

            # Check if email is verified
            if not email_verified:
                raise ValueError("Email address is not verified")

            # Check if email is from allowed domain
            if not settings.is_allowed_domain(email):
                raise ValueError(
                    f"Email domain not allowed. Must be from {settings.ALLOWED_EMAIL_DOMAIN}"
                )

            # Create and return UserInfo instance
            return UserInfo(
                uid=uid,
                email=email,
                name=name,
                picture=picture,
                email_verified=email_verified
            )

        except InvalidIdTokenError as e:
            raise ValueError(f"Invalid Firebase token: {str(e)}")

        except ExpiredIdTokenError as e:
            raise ValueError(f"Expired Firebase token: {str(e)}")

        except RevokedIdTokenError as e:
            raise ValueError(f"Revoked Firebase token: {str(e)}")

        except Exception as e:
            if "Email domain not allowed" in str(e) or "Email address is not verified" in str(e):
                # Re-raise our custom validation errors
                raise e
            else:
                # Wrap unexpected errors
                raise ValueError(f"Token validation failed: {str(e)}")

    @staticmethod
    async def get_user_by_uid(uid: str) -> Optional[dict]:
        """
        Get additional user information from Firebase Auth by UID.

        Args:
            uid (str): Firebase user ID

        Returns:
            Optional[dict]: Additional user information or None if not found

        Note:
            This method can be used for additional user data if needed.
        """
        try:
            auth_client = firebase_config.get_auth_client()
            user_record = auth_client.get_user(uid)

            return {
                'uid': user_record.uid,
                'email': user_record.email,
                'display_name': user_record.display_name,
                'photo_url': user_record.photo_url,
                'email_verified': user_record.email_verified,
                'disabled': user_record.disabled,
                'custom_claims': user_record.custom_claims or {},
                'creation_timestamp': user_record.user_metadata.creation_timestamp,
                'last_sign_in_timestamp': user_record.user_metadata.last_sign_in_timestamp,
            }

        except firebase_auth.UserNotFoundError:
            return None
        except Exception as e:
            # Log error but don't fail the main authentication flow
            print(f"Warning: Could not fetch additional user info for {uid}: {str(e)}")
            return None