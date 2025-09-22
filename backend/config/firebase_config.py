"""
Firebase Admin SDK initialization and configuration.
"""
import os
import json
from typing import Optional
import firebase_admin
from firebase_admin import auth, credentials
from .settings import settings


class FirebaseConfig:
    """Firebase Admin SDK configuration and initialization."""

    _app: Optional[firebase_admin.App] = None

    @classmethod
    def initialize_firebase(cls) -> firebase_admin.App:
        """
        Initialize Firebase Admin SDK with service account credentials.

        Returns:
            firebase_admin.App: Initialized Firebase app instance

        Raises:
            ValueError: If Firebase credentials are not properly configured
        """
        if cls._app is not None:
            return cls._app

        try:
            # Try to use service account key file
            if os.path.exists(settings.FIREBASE_SERVICE_ACCOUNT_PATH):
                cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_PATH)
            else:
                # Try to use service account key from environment variable
                service_account_key = os.getenv("FIREBASE_SERVICE_ACCOUNT_KEY")
                if service_account_key:
                    # Parse JSON string from environment variable
                    service_account_info = json.loads(service_account_key)
                    cred = credentials.Certificate(service_account_info)
                else:
                    raise ValueError(
                        "Firebase service account credentials not found. "
                        "Please set FIREBASE_SERVICE_ACCOUNT_PATH or "
                        "FIREBASE_SERVICE_ACCOUNT_KEY environment variable."
                    )

            # Initialize Firebase app
            cls._app = firebase_admin.initialize_app(
                cred,
                {
                    'projectId': settings.FIREBASE_PROJECT_ID,
                }
            )

            print(f"✅ Firebase Admin SDK initialized for project: {settings.FIREBASE_PROJECT_ID}")
            return cls._app

        except Exception as e:
            raise ValueError(f"Failed to initialize Firebase Admin SDK: {str(e)}")

    @classmethod
    def get_auth_client(cls) -> auth:
        """
        Get Firebase Auth client instance.

        Returns:
            firebase_admin.auth: Firebase Auth client
        """
        if cls._app is None:
            cls.initialize_firebase()

        return auth

    @classmethod
    def verify_id_token(cls, id_token: str) -> dict:
        """
        Verify Firebase ID token and return decoded claims.

        Args:
            id_token (str): Firebase ID token to verify

        Returns:
            dict: Decoded token claims containing user information

        Raises:
            firebase_admin.auth.InvalidIdTokenError: If token is invalid
            firebase_admin.auth.ExpiredIdTokenError: If token is expired
            firebase_admin.auth.RevokedIdTokenError: If token is revoked
        """
        auth_client = cls.get_auth_client()

        # Verify the ID token and return decoded claims
        # This will automatically validate:
        # - Token signature
        # - Token expiration
        # - Token issuer
        # - Token audience (project ID)
        decoded_token = auth_client.verify_id_token(id_token)

        return decoded_token


# Global Firebase config instance
firebase_config = FirebaseConfig()