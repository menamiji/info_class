"""
User role determination and permission management.
"""
from typing import List

from ..config.settings import settings
from .models import UserInfo, UserWithRole, UserRole


class RoleManager:
    """Handles user role determination and permission assignment."""

    # Define permissions for each role
    ROLE_PERMISSIONS = {
        UserRole.ADMIN: [
            "read_all_files",
            "upload_files",
            "delete_files",
            "manage_users",
            "view_submissions",
            "manage_subjects",
            "system_admin"
        ],
        UserRole.STUDENT: [
            "read_assigned_files",
            "download_files",
            "upload_submissions",
            "view_own_submissions"
        ],
        UserRole.GUEST: [
            "read_public_info"
        ]
    }

    @staticmethod
    def determine_user_role(user: UserInfo) -> str:
        """
        Determine user role based on email and other factors.

        Args:
            user (UserInfo): User information from Firebase

        Returns:
            str: User role (admin/student/guest)
        """
        email = user.email.lower()

        # Check if user is in admin list
        if settings.is_admin_email(email):
            return UserRole.ADMIN

        # Check if user is from allowed domain
        if settings.is_allowed_domain(email):
            # For now, all domain users except admins are students
            return UserRole.STUDENT

        # Users from other domains are guests (limited access)
        return UserRole.GUEST

    @staticmethod
    def get_role_permissions(role: str) -> List[str]:
        """
        Get permissions list for a given role.

        Args:
            role (str): User role

        Returns:
            List[str]: List of permissions for the role
        """
        return RoleManager.ROLE_PERMISSIONS.get(role, [])

    @staticmethod
    def create_user_with_role(user: UserInfo) -> UserWithRole:
        """
        Create UserWithRole instance with determined role and permissions.

        Args:
            user (UserInfo): Base user information

        Returns:
            UserWithRole: User with role and permissions assigned
        """
        role = RoleManager.determine_user_role(user)
        permissions = RoleManager.get_role_permissions(role)

        return UserWithRole(
            uid=user.uid,
            email=user.email,
            name=user.name,
            picture=user.picture,
            email_verified=user.email_verified,
            role=role,
            permissions=permissions
        )

    @staticmethod
    def has_permission(user_role: str, required_permission: str) -> bool:
        """
        Check if a role has a specific permission.

        Args:
            user_role (str): User's role
            required_permission (str): Permission to check

        Returns:
            bool: True if role has the permission, False otherwise
        """
        role_permissions = RoleManager.get_role_permissions(user_role)
        return required_permission in role_permissions

    @staticmethod
    def is_admin(user_role: str) -> bool:
        """
        Check if user role is admin.

        Args:
            user_role (str): User's role

        Returns:
            bool: True if user is admin, False otherwise
        """
        return user_role == UserRole.ADMIN

    @staticmethod
    def is_student(user_role: str) -> bool:
        """
        Check if user role is student.

        Args:
            user_role (str): User's role

        Returns:
            bool: True if user is student, False otherwise
        """
        return user_role == UserRole.STUDENT

    @staticmethod
    def can_access_admin_features(user_role: str) -> bool:
        """
        Check if user can access admin features.

        Args:
            user_role (str): User's role

        Returns:
            bool: True if user can access admin features
        """
        return RoleManager.has_permission(user_role, "system_admin")

    @staticmethod
    def can_manage_files(user_role: str) -> bool:
        """
        Check if user can manage (upload/delete) files.

        Args:
            user_role (str): User's role

        Returns:
            bool: True if user can manage files
        """
        return RoleManager.has_permission(user_role, "upload_files")

    @staticmethod
    def can_view_submissions(user_role: str) -> bool:
        """
        Check if user can view submissions.

        Args:
            user_role (str): User's role

        Returns:
            bool: True if user can view submissions
        """
        return RoleManager.has_permission(user_role, "view_submissions")

    @classmethod
    def add_admin_email(cls, email: str) -> None:
        """
        Add email to admin list (runtime addition).

        Note: This only affects the current runtime session.
        For permanent changes, update the ADMIN_EMAILS in settings.

        Args:
            email (str): Email to add to admin list
        """
        if email.lower() not in [admin.lower() for admin in settings.ADMIN_EMAILS]:
            settings.ADMIN_EMAILS.append(email.lower())

    @classmethod
    def remove_admin_email(cls, email: str) -> bool:
        """
        Remove email from admin list (runtime removal).

        Args:
            email (str): Email to remove from admin list

        Returns:
            bool: True if email was removed, False if not found
        """
        try:
            # Find and remove the email (case-insensitive)
            for admin_email in settings.ADMIN_EMAILS:
                if admin_email.lower() == email.lower():
                    settings.ADMIN_EMAILS.remove(admin_email)
                    return True
            return False
        except ValueError:
            return False