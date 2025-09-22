#!/usr/bin/env python3
"""
Quick JWT Authentication System Validation

This script performs rapid validation of the JWT authentication system
to ensure all components are properly configured before running the
comprehensive test suite.

Usage:
    python quick_validation.py
"""

import os
import sys
import requests
import subprocess
import json
from pathlib import Path

def check_mark(condition):
    return "✅" if condition else "❌"

def print_section(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print('='*60)

def check_backend_environment():
    """Check backend environment and configuration."""
    print_section("BACKEND ENVIRONMENT")

    issues = []

    # Check if we're in the right directory
    if not os.path.exists('backend'):
        print(f"{check_mark(False)} Backend directory not found")
        issues.append("Move to project root directory")
        return issues

    print(f"{check_mark(True)} Backend directory exists")

    # Check backend files
    backend_files = [
        'backend/main.py',
        'backend/.env',
        'backend/requirements.txt',
        'backend/auth/__init__.py',
        'backend/auth/jwt_manager.py',
        'backend/auth/firebase_validator.py',
        'backend/auth/role_manager.py',
        'backend/api/auth_routes.py'
    ]

    for file_path in backend_files:
        exists = os.path.exists(file_path)
        print(f"{check_mark(exists)} {file_path}")
        if not exists:
            issues.append(f"Missing file: {file_path}")

    # Check .env file content
    env_path = 'backend/.env'
    if os.path.exists(env_path):
        with open(env_path, 'r') as f:
            env_content = f.read()

        required_env_vars = [
            'SECRET_KEY',
            'ALLOWED_EMAIL_DOMAIN',
            'ACCESS_TOKEN_EXPIRE_HOURS',
            'DEBUG'
        ]

        for var in required_env_vars:
            has_var = var in env_content and f'{var}=' in env_content
            print(f"{check_mark(has_var)} Environment variable: {var}")
            if not has_var:
                issues.append(f"Missing environment variable: {var}")

    # Check Python virtual environment
    venv_exists = os.path.exists('backend/venv')
    print(f"{check_mark(venv_exists)} Python virtual environment")
    if not venv_exists:
        issues.append("Create virtual environment: cd backend && python -m venv venv")

    return issues

def check_flutter_environment():
    """Check Flutter environment and configuration."""
    print_section("FLUTTER ENVIRONMENT")

    issues = []

    # Check if this is a Flutter project
    pubspec_exists = os.path.exists('pubspec.yaml')
    print(f"{check_mark(pubspec_exists)} pubspec.yaml exists")
    if not pubspec_exists:
        issues.append("Not a Flutter project")
        return issues

    # Check Flutter installation
    try:
        result = subprocess.run(['flutter', '--version'],
                               capture_output=True, text=True, timeout=10)
        flutter_installed = result.returncode == 0
    except (subprocess.TimeoutExpired, FileNotFoundError):
        flutter_installed = False

    print(f"{check_mark(flutter_installed)} Flutter CLI available")
    if not flutter_installed:
        issues.append("Install Flutter and add to PATH")

    # Check key Flutter files
    flutter_files = [
        'lib/main.dart',
        'lib/auth_service.dart',
        'lib/providers/auth_provider.dart',
        'lib/shared/data/api_client.dart',
        'lib/shared/services/token_storage.dart',
        'web/index.html'
    ]

    for file_path in flutter_files:
        exists = os.path.exists(file_path)
        print(f"{check_mark(exists)} {file_path}")
        if not exists:
            issues.append(f"Missing file: {file_path}")

    # Check Firebase configuration
    firebase_files = [
        'lib/firebase_options.dart',
        'web/index.html'  # Should contain Firebase config
    ]

    for file_path in firebase_files:
        exists = os.path.exists(file_path)
        print(f"{check_mark(exists)} Firebase config: {file_path}")
        if not exists:
            issues.append(f"Configure Firebase: {file_path}")

    return issues

def check_dependencies():
    """Check that required dependencies are installed."""
    print_section("DEPENDENCIES")

    issues = []

    # Check Python dependencies
    if os.path.exists('backend/venv'):
        python_deps = [
            ('fastapi', 'FastAPI framework'),
            ('uvicorn', 'ASGI server'),
            ('firebase-admin', 'Firebase Admin SDK'),
            ('pyjwt', 'JWT handling'),
            ('python-dotenv', 'Environment variables'),
        ]

        for dep, description in python_deps:
            try:
                # Check if dependency is installed in venv
                result = subprocess.run([
                    'bash', '-c',
                    f'cd backend && source venv/bin/activate && pip show {dep}'
                ], capture_output=True, text=True, timeout=10)
                installed = result.returncode == 0
            except (subprocess.TimeoutExpired, FileNotFoundError):
                installed = False

            print(f"{check_mark(installed)} Python: {dep} ({description})")
            if not installed:
                issues.append(f"Install Python dependency: {dep}")

    # Check if Flutter dependencies are listed in pubspec.yaml
    if os.path.exists('pubspec.yaml'):
        with open('pubspec.yaml', 'r') as f:
            pubspec_content = f.read()

        flutter_deps = [
            ('flutter_riverpod', 'State management'),
            ('firebase_core', 'Firebase core'),
            ('firebase_auth', 'Firebase authentication'),
            ('google_sign_in', 'Google Sign-In'),
            ('http', 'HTTP client'),
            ('riverpod_annotation', 'Riverpod code generation'),
        ]

        for dep, description in flutter_deps:
            has_dep = dep in pubspec_content
            print(f"{check_mark(has_dep)} Flutter: {dep} ({description})")
            if not has_dep:
                issues.append(f"Add Flutter dependency: {dep}")

    return issues

def test_backend_startup():
    """Test if backend can start successfully."""
    print_section("BACKEND STARTUP TEST")

    issues = []

    if not os.path.exists('backend/main.py'):
        print(f"{check_mark(False)} Backend main.py not found")
        issues.append("Backend files missing")
        return issues

    try:
        # Try to import and validate backend modules
        result = subprocess.run([
            'bash', '-c',
            'cd backend && source venv/bin/activate && python -c "import main; from auth import jwt_manager, firebase_validator; print(\'Backend modules OK\')"'
        ], capture_output=True, text=True, timeout=30)

        modules_ok = result.returncode == 0
        print(f"{check_mark(modules_ok)} Backend module imports")

        if not modules_ok:
            print(f"Import error: {result.stderr}")
            issues.append("Fix backend module import errors")

    except subprocess.TimeoutExpired:
        print(f"{check_mark(False)} Backend startup timeout")
        issues.append("Backend startup takes too long")
    except Exception as e:
        print(f"{check_mark(False)} Backend startup error: {e}")
        issues.append("Fix backend startup issues")

    return issues

def test_connectivity():
    """Test if servers can be reached."""
    print_section("CONNECTIVITY TEST")

    issues = []

    # Test backend connectivity
    backend_url = "http://localhost:8000"
    try:
        response = requests.get(f"{backend_url}/healthz", timeout=5)
        backend_reachable = response.status_code == 200

        if backend_reachable:
            health_data = response.json()
            print(f"{check_mark(True)} Backend health endpoint")
            print(f"    Status: {health_data.get('status', 'unknown')}")
            print(f"    Firebase: {health_data.get('services', {}).get('firebase', 'unknown')}")
        else:
            print(f"{check_mark(False)} Backend health endpoint (HTTP {response.status_code})")
            issues.append("Backend health check failed")

    except requests.exceptions.ConnectionError:
        print(f"{check_mark(False)} Backend connectivity (not running)")
        print("    Note: This is expected if backend is not started")
    except Exception as e:
        print(f"{check_mark(False)} Backend connectivity error: {e}")
        issues.append("Backend connection issues")

    # Test frontend port availability
    frontend_port = 3000
    try:
        import socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)
        result = sock.connect_ex(('localhost', frontend_port))
        sock.close()

        frontend_port_free = result != 0
        print(f"{check_mark(frontend_port_free)} Frontend port {frontend_port} available")
        if not frontend_port_free:
            print(f"    Note: Port {frontend_port} is in use (Flutter may be running)")
    except Exception as e:
        print(f"{check_mark(False)} Frontend port check error: {e}")

    return issues

def main():
    """Main validation function."""
    print("🧪 JWT Authentication System Quick Validation")
    print("=" * 60)

    all_issues = []

    # Run all validation checks
    all_issues.extend(check_backend_environment())
    all_issues.extend(check_flutter_environment())
    all_issues.extend(check_dependencies())
    all_issues.extend(test_backend_startup())
    all_issues.extend(test_connectivity())

    # Summary
    print_section("VALIDATION SUMMARY")

    if not all_issues:
        print("✅ All validation checks passed!")
        print("\n🚀 Ready to run comprehensive test suite:")
        print("   python jwt_test_suite.py --verbose --mock-firebase")
        print("   ./test_jwt_flow.sh --all-tests")
        print("\n📋 Manual testing:")
        print("   ./test_jwt_flow.sh --manual")
        success = True
    else:
        print("❌ Validation issues found:")
        for i, issue in enumerate(all_issues, 1):
            print(f"   {i}. {issue}")

        print("\n🔧 Fix these issues before running the test suite")
        success = False

    print("\n📚 Next Steps:")
    if success:
        print("   1. Run: ./test_jwt_flow.sh --backend-tests")
        print("   2. Start servers: ./test_jwt_flow.sh --start-servers")
        print("   3. Test manually in browser at http://localhost:3000")
        print("   4. Run full suite: ./test_jwt_flow.sh --all-tests")
    else:
        print("   1. Fix validation issues listed above")
        print("   2. Re-run: python quick_validation.py")
        print("   3. Proceed with testing once all issues resolved")

    return success

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)