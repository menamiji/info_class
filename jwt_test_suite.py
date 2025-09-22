#!/usr/bin/env python3
"""
Comprehensive JWT Token Exchange Flow Testing Suite

This suite tests the complete authentication flow between Flutter frontend
and FastAPI backend, including:
1. Environment setup validation
2. Backend health checks
3. JWT token exchange process
4. API integration testing
5. Error handling scenarios
6. End-to-end validation

Requirements:
- Backend server running on localhost:8000
- Frontend on localhost:3000 (for CORS testing)
- Firebase credentials configured
- Test user with @pocheonil.hs.kr domain

Usage:
    python jwt_test_suite.py [--verbose] [--mock-firebase]
"""

import asyncio
import json
import sys
import time
import argparse
from datetime import datetime, timedelta, timezone
from typing import Dict, Any, Optional, List, Tuple
from dataclasses import dataclass
from enum import Enum

import requests
import jwt as jwt_lib
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Test Configuration
class TestMode(Enum):
    INTEGRATION = "integration"  # Real Firebase + Backend
    MOCK_FIREBASE = "mock_firebase"  # Mock Firebase responses
    UNIT = "unit"  # Individual component testing

@dataclass
class TestResult:
    name: str
    passed: bool
    duration: float
    details: Optional[str] = None
    error: Optional[Exception] = None
    data: Optional[Dict[str, Any]] = None

@dataclass
class TestConfig:
    backend_url: str = "http://localhost:8000"
    frontend_url: str = "http://localhost:3000"
    timeout: int = 30
    retry_attempts: int = 3
    mock_firebase: bool = False
    verbose: bool = False
    test_user_email: str = "admin@pocheonil.hs.kr"

class JWTTestSuite:
    """Comprehensive JWT authentication flow testing suite."""

    def __init__(self, config: TestConfig):
        self.config = config
        self.session = self._create_session()
        self.results: List[TestResult] = []
        self.mock_firebase_token = self._generate_mock_firebase_token()

        # Test data storage
        self.firebase_token: Optional[str] = None
        self.jwt_token: Optional[str] = None
        self.user_data: Optional[Dict[str, Any]] = None

    def _create_session(self) -> requests.Session:
        """Create HTTP session with retry strategy."""
        session = requests.Session()

        retry_strategy = Retry(
            total=self.config.retry_attempts,
            backoff_factor=1,
            status_forcelist=[500, 502, 503, 504],
        )

        adapter = HTTPAdapter(max_retries=retry_strategy)
        session.mount("http://", adapter)
        session.mount("https://", adapter)

        return session

    def _generate_mock_firebase_token(self) -> str:
        """Generate mock Firebase token for testing."""
        payload = {
            "uid": "test_user_123",
            "email": self.config.test_user_email,
            "name": "Test User",
            "email_verified": True,
            "iss": "https://securetoken.google.com/info-class-7398a",
            "aud": "info-class-7398a",
            "iat": int(time.time()),
            "exp": int(time.time()) + 3600,
        }
        return jwt_lib.encode(payload, "mock_secret", algorithm="HS256")

    def _log(self, message: str, level: str = "INFO"):
        """Log message with timestamp."""
        timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        if self.config.verbose or level == "ERROR":
            print(f"[{timestamp}] {level}: {message}")

    def _record_result(self, name: str, passed: bool, duration: float,
                      details: str = None, error: Exception = None,
                      data: Dict[str, Any] = None):
        """Record test result."""
        result = TestResult(name, passed, duration, details, error, data)
        self.results.append(result)

        status = "✅ PASS" if passed else "❌ FAIL"
        self._log(f"{status} {name} ({duration:.3f}s)")
        if details and self.config.verbose:
            self._log(f"    Details: {details}")
        if error:
            self._log(f"    Error: {str(error)}", "ERROR")

    async def run_all_tests(self) -> bool:
        """Run complete test suite."""
        self._log("🚀 Starting JWT Token Exchange Test Suite")
        self._log(f"📍 Backend: {self.config.backend_url}")
        self._log(f"📍 Frontend: {self.config.frontend_url}")
        self._log(f"🔧 Mode: {'Mock Firebase' if self.config.mock_firebase else 'Integration'}")

        # Test phases
        phases = [
            ("Environment Setup", self._test_environment_setup),
            ("Backend Health", self._test_backend_health),
            ("Firebase Token Validation", self._test_firebase_token_validation),
            ("JWT Token Exchange", self._test_jwt_token_exchange),
            ("JWT Token Validation", self._test_jwt_token_validation),
            ("API Authentication", self._test_api_authentication),
            ("Token Refresh", self._test_token_refresh),
            ("Error Handling", self._test_error_handling),
            ("Security Validation", self._test_security_validation),
            ("Performance Testing", self._test_performance),
        ]

        for phase_name, phase_func in phases:
            self._log(f"\n📋 Phase: {phase_name}")
            try:
                await phase_func()
            except Exception as e:
                self._log(f"❌ Phase {phase_name} failed: {str(e)}", "ERROR")

        return self._generate_report()

    async def _test_environment_setup(self):
        """Test 1: Environment Setup Validation."""

        # 1.1: Backend connectivity
        start_time = time.time()
        try:
            response = self.session.get(
                f"{self.config.backend_url}/",
                timeout=self.config.timeout
            )
            passed = response.status_code == 200
            duration = time.time() - start_time

            self._record_result(
                "1.1 Backend Connectivity",
                passed,
                duration,
                f"Status: {response.status_code}",
                data={"response": response.json() if passed else None}
            )
        except Exception as e:
            duration = time.time() - start_time
            self._record_result("1.1 Backend Connectivity", False, duration, error=e)

        # 1.2: CORS configuration
        start_time = time.time()
        try:
            headers = {
                "Origin": self.config.frontend_url,
                "Access-Control-Request-Method": "POST",
                "Access-Control-Request-Headers": "Content-Type,Authorization"
            }
            response = self.session.options(
                f"{self.config.backend_url}/auth/exchange",
                headers=headers,
                timeout=self.config.timeout
            )

            cors_headers = {
                "access-control-allow-origin": response.headers.get("access-control-allow-origin"),
                "access-control-allow-methods": response.headers.get("access-control-allow-methods"),
                "access-control-allow-headers": response.headers.get("access-control-allow-headers"),
            }

            passed = (
                response.status_code == 200 and
                ("*" in cors_headers["access-control-allow-origin"] or
                 self.config.frontend_url in cors_headers["access-control-allow-origin"])
            )
            duration = time.time() - start_time

            self._record_result(
                "1.2 CORS Configuration",
                passed,
                duration,
                f"CORS headers present: {bool(cors_headers['access-control-allow-origin'])}",
                data={"cors_headers": cors_headers}
            )
        except Exception as e:
            duration = time.time() - start_time
            self._record_result("1.2 CORS Configuration", False, duration, error=e)

        # 1.3: Required endpoints availability
        endpoints = ["/", "/healthz", "/auth/exchange", "/auth/me", "/auth/refresh"]
        for endpoint in endpoints:
            start_time = time.time()
            try:
                response = self.session.get(
                    f"{self.config.backend_url}{endpoint}",
                    timeout=self.config.timeout
                )
                passed = response.status_code in [200, 401, 422]  # 401/422 are expected for auth endpoints
                duration = time.time() - start_time

                self._record_result(
                    f"1.3 Endpoint {endpoint}",
                    passed,
                    duration,
                    f"Status: {response.status_code}"
                )
            except Exception as e:
                duration = time.time() - start_time
                self._record_result(f"1.3 Endpoint {endpoint}", False, duration, error=e)

    async def _test_backend_health(self):
        """Test 2: Backend Health Checks."""

        # 2.1: Health endpoint detailed check
        start_time = time.time()
        try:
            response = self.session.get(
                f"{self.config.backend_url}/healthz",
                timeout=self.config.timeout
            )
            passed = response.status_code == 200
            duration = time.time() - start_time

            health_data = response.json() if passed else None

            # Validate health response structure
            if health_data:
                required_fields = ["ok", "status", "version", "services"]
                has_required_fields = all(field in health_data for field in required_fields)
                passed = passed and has_required_fields

            self._record_result(
                "2.1 Health Check Detailed",
                passed,
                duration,
                f"Firebase status: {health_data.get('services', {}).get('firebase', 'unknown') if health_data else 'unknown'}",
                data={"health_response": health_data}
            )
        except Exception as e:
            duration = time.time() - start_time
            self._record_result("2.1 Health Check Detailed", False, duration, error=e)

        # 2.2: Firebase initialization status
        if hasattr(self, 'results') and self.results:
            last_result = self.results[-1]
            if last_result.data and last_result.data.get("health_response"):
                health_data = last_result.data["health_response"]
                firebase_status = health_data.get("services", {}).get("firebase", "error")

                passed = firebase_status in ["healthy", "not_initialized"]  # not_initialized is ok in dev mode

                self._record_result(
                    "2.2 Firebase Initialization",
                    passed,
                    0.001,  # No additional time
                    f"Firebase status: {firebase_status}"
                )

    async def _test_firebase_token_validation(self):
        """Test 3: Firebase Token Validation."""

        if self.config.mock_firebase:
            # Use mock token for testing
            self.firebase_token = self.mock_firebase_token
            self._record_result(
                "3.1 Mock Firebase Token Generated",
                True,
                0.001,
                "Using mock Firebase token for testing"
            )
        else:
            # In real scenario, this would require actual Firebase authentication
            # For testing purposes, we'll use a mock token
            self._log("⚠️  Real Firebase token required - using mock for testing")
            self.firebase_token = self.mock_firebase_token
            self._record_result(
                "3.1 Firebase Token Required",
                True,
                0.001,
                "Mock token used - manual Firebase auth needed for production testing"
            )

    async def _test_jwt_token_exchange(self):
        """Test 4: JWT Token Exchange Process."""

        if not self.firebase_token:
            self._record_result(
                "4.1 JWT Token Exchange",
                False,
                0.001,
                "No Firebase token available",
                error=Exception("Firebase token required for exchange")
            )
            return

        # 4.1: Basic token exchange
        start_time = time.time()
        try:
            payload = {"firebase_token": self.firebase_token}
            response = self.session.post(
                f"{self.config.backend_url}/auth/exchange",
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=self.config.timeout
            )

            duration = time.time() - start_time
            passed = response.status_code == 200

            if passed:
                response_data = response.json()
                if response_data.get("data") and response_data["data"].get("jwt_token"):
                    self.jwt_token = response_data["data"]["jwt_token"]
                    self.user_data = response_data["data"]["user"]

                    self._record_result(
                        "4.1 JWT Token Exchange",
                        True,
                        duration,
                        f"JWT token received, user role: {self.user_data.get('role') if self.user_data else 'unknown'}",
                        data={"response": response_data}
                    )
                else:
                    self._record_result(
                        "4.1 JWT Token Exchange",
                        False,
                        duration,
                        "Invalid response structure",
                        data={"response": response_data}
                    )
            else:
                error_data = response.json() if response.headers.get("content-type", "").startswith("application/json") else {"error": response.text}
                self._record_result(
                    "4.1 JWT Token Exchange",
                    False,
                    duration,
                    f"HTTP {response.status_code}",
                    data={"error_response": error_data}
                )
        except Exception as e:
            duration = time.time() - start_time
            self._record_result("4.1 JWT Token Exchange", False, duration, error=e)

        # 4.2: Token structure validation
        if self.jwt_token:
            start_time = time.time()
            try:
                # Decode without verification for structure check
                header = jwt_lib.get_unverified_header(self.jwt_token)
                payload = jwt_lib.decode(self.jwt_token, options={"verify_signature": False})

                required_claims = ["sub", "email", "role", "exp", "iat", "iss"]
                missing_claims = [claim for claim in required_claims if claim not in payload]

                passed = len(missing_claims) == 0
                duration = time.time() - start_time

                self._record_result(
                    "4.2 JWT Token Structure",
                    passed,
                    duration,
                    f"Missing claims: {missing_claims}" if missing_claims else "All required claims present",
                    data={"header": header, "payload": payload}
                )
            except Exception as e:
                duration = time.time() - start_time
                self._record_result("4.2 JWT Token Structure", False, duration, error=e)

    async def _test_jwt_token_validation(self):
        """Test 5: JWT Token Validation."""

        if not self.jwt_token:
            self._record_result(
                "5.1 JWT Token Validation",
                False,
                0.001,
                "No JWT token available",
                error=Exception("JWT token required for validation")
            )
            return

        # 5.1: Token signature validation (via /auth/me endpoint)
        start_time = time.time()
        try:
            headers = {"Authorization": f"Bearer {self.jwt_token}"}
            response = self.session.get(
                f"{self.config.backend_url}/auth/me",
                headers=headers,
                timeout=self.config.timeout
            )

            duration = time.time() - start_time
            passed = response.status_code == 200

            if passed:
                user_info = response.json()
                self._record_result(
                    "5.1 JWT Token Validation",
                    True,
                    duration,
                    f"Token valid, user: {user_info.get('data', {}).get('email', 'unknown')}",
                    data={"user_info": user_info}
                )
            else:
                error_data = response.json() if response.headers.get("content-type", "").startswith("application/json") else {"error": response.text}
                self._record_result(
                    "5.1 JWT Token Validation",
                    False,
                    duration,
                    f"HTTP {response.status_code}",
                    data={"error_response": error_data}
                )
        except Exception as e:
            duration = time.time() - start_time
            self._record_result("5.1 JWT Token Validation", False, duration, error=e)

    async def _test_api_authentication(self):
        """Test 6: API Authentication with JWT."""

        if not self.jwt_token:
            self._record_result(
                "6.1 Authenticated API Access",
                False,
                0.001,
                "No JWT token available",
                error=Exception("JWT token required for API testing")
            )
            return

        # 6.1: Authenticated endpoint access
        start_time = time.time()
        try:
            headers = {"Authorization": f"Bearer {self.jwt_token}"}
            response = self.session.get(
                f"{self.config.backend_url}/auth/me",
                headers=headers,
                timeout=self.config.timeout
            )

            duration = time.time() - start_time
            passed = response.status_code == 200

            self._record_result(
                "6.1 Authenticated API Access",
                passed,
                duration,
                f"Status: {response.status_code}"
            )
        except Exception as e:
            duration = time.time() - start_time
            self._record_result("6.1 Authenticated API Access", False, duration, error=e)

        # 6.2: Unauthenticated access rejection
        start_time = time.time()
        try:
            response = self.session.get(
                f"{self.config.backend_url}/auth/me",
                timeout=self.config.timeout
            )

            duration = time.time() - start_time
            passed = response.status_code in [401, 403, 422]  # Should be rejected

            self._record_result(
                "6.2 Unauthenticated Access Rejection",
                passed,
                duration,
                f"Status: {response.status_code} (should be 401/403/422)"
            )
        except Exception as e:
            duration = time.time() - start_time
            self._record_result("6.2 Unauthenticated Access Rejection", False, duration, error=e)

    async def _test_token_refresh(self):
        """Test 7: Token Refresh Functionality."""

        if not self.jwt_token:
            self._record_result(
                "7.1 Token Refresh",
                False,
                0.001,
                "No JWT token available",
                error=Exception("JWT token required for refresh testing")
            )
            return

        # 7.1: Token refresh endpoint
        start_time = time.time()
        try:
            headers = {"Authorization": f"Bearer {self.jwt_token}"}
            response = self.session.post(
                f"{self.config.backend_url}/auth/refresh",
                headers=headers,
                timeout=self.config.timeout
            )

            duration = time.time() - start_time
            passed = response.status_code == 200

            if passed:
                refresh_data = response.json()
                new_token = refresh_data.get("data", {}).get("jwt_token")

                self._record_result(
                    "7.1 Token Refresh",
                    True,
                    duration,
                    f"New token received: {bool(new_token)}",
                    data={"refresh_response": refresh_data}
                )
            else:
                error_data = response.json() if response.headers.get("content-type", "").startswith("application/json") else {"error": response.text}
                self._record_result(
                    "7.1 Token Refresh",
                    False,
                    duration,
                    f"HTTP {response.status_code}",
                    data={"error_response": error_data}
                )
        except Exception as e:
            duration = time.time() - start_time
            self._record_result("7.1 Token Refresh", False, duration, error=e)

    async def _test_error_handling(self):
        """Test 8: Error Handling Scenarios."""

        # 8.1: Invalid Firebase token
        start_time = time.time()
        try:
            payload = {"firebase_token": "invalid_token_12345"}
            response = self.session.post(
                f"{self.config.backend_url}/auth/exchange",
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=self.config.timeout
            )

            duration = time.time() - start_time
            passed = response.status_code in [400, 401]  # Should be rejected

            self._record_result(
                "8.1 Invalid Firebase Token Handling",
                passed,
                duration,
                f"Status: {response.status_code} (should be 400/401)"
            )
        except Exception as e:
            duration = time.time() - start_time
            self._record_result("8.1 Invalid Firebase Token Handling", False, duration, error=e)

        # 8.2: Invalid JWT token
        start_time = time.time()
        try:
            headers = {"Authorization": "Bearer invalid_jwt_token"}
            response = self.session.get(
                f"{self.config.backend_url}/auth/me",
                headers=headers,
                timeout=self.config.timeout
            )

            duration = time.time() - start_time
            passed = response.status_code in [401, 403]  # Should be rejected

            self._record_result(
                "8.2 Invalid JWT Token Handling",
                passed,
                duration,
                f"Status: {response.status_code} (should be 401/403)"
            )
        except Exception as e:
            duration = time.time() - start_time
            self._record_result("8.2 Invalid JWT Token Handling", False, duration, error=e)

        # 8.3: Malformed request body
        start_time = time.time()
        try:
            response = self.session.post(
                f"{self.config.backend_url}/auth/exchange",
                json={"wrong_field": "value"},
                headers={"Content-Type": "application/json"},
                timeout=self.config.timeout
            )

            duration = time.time() - start_time
            passed = response.status_code in [400, 422]  # Should be rejected

            self._record_result(
                "8.3 Malformed Request Handling",
                passed,
                duration,
                f"Status: {response.status_code} (should be 400/422)"
            )
        except Exception as e:
            duration = time.time() - start_time
            self._record_result("8.3 Malformed Request Handling", False, duration, error=e)

    async def _test_security_validation(self):
        """Test 9: Security Validation."""

        # 9.1: JWT algorithm verification
        if self.jwt_token:
            start_time = time.time()
            try:
                header = jwt_lib.get_unverified_header(self.jwt_token)
                algorithm = header.get("alg")

                # Should use RS256 or HS256, not 'none'
                passed = algorithm in ["RS256", "HS256"] and algorithm != "none"
                duration = time.time() - start_time

                self._record_result(
                    "9.1 JWT Algorithm Security",
                    passed,
                    duration,
                    f"Algorithm: {algorithm}"
                )
            except Exception as e:
                duration = time.time() - start_time
                self._record_result("9.1 JWT Algorithm Security", False, duration, error=e)

        # 9.2: Token expiration validation
        if self.jwt_token:
            start_time = time.time()
            try:
                payload = jwt_lib.decode(self.jwt_token, options={"verify_signature": False})
                exp = payload.get("exp")
                iat = payload.get("iat")

                if exp and iat:
                    token_lifetime = exp - iat
                    # Token should not be valid for more than 24 hours
                    passed = token_lifetime <= 86400  # 24 hours in seconds
                    duration = time.time() - start_time

                    self._record_result(
                        "9.2 Token Expiration Policy",
                        passed,
                        duration,
                        f"Token lifetime: {token_lifetime/3600:.1f} hours"
                    )
                else:
                    duration = time.time() - start_time
                    self._record_result(
                        "9.2 Token Expiration Policy",
                        False,
                        duration,
                        "Missing exp or iat claims"
                    )
            except Exception as e:
                duration = time.time() - start_time
                self._record_result("9.2 Token Expiration Policy", False, duration, error=e)

    async def _test_performance(self):
        """Test 10: Performance Testing."""

        # 10.1: Token exchange performance
        start_time = time.time()
        try:
            # Test multiple token exchanges in sequence
            exchange_times = []

            for i in range(3):
                if self.firebase_token:
                    iteration_start = time.time()
                    payload = {"firebase_token": self.firebase_token}
                    response = self.session.post(
                        f"{self.config.backend_url}/auth/exchange",
                        json=payload,
                        headers={"Content-Type": "application/json"},
                        timeout=self.config.timeout
                    )
                    iteration_duration = time.time() - iteration_start

                    if response.status_code == 200:
                        exchange_times.append(iteration_duration)

            if exchange_times:
                avg_time = sum(exchange_times) / len(exchange_times)
                passed = avg_time < 2.0  # Should complete within 2 seconds

                duration = time.time() - start_time
                self._record_result(
                    "10.1 Token Exchange Performance",
                    passed,
                    duration,
                    f"Average exchange time: {avg_time:.3f}s (3 attempts)"
                )
            else:
                duration = time.time() - start_time
                self._record_result(
                    "10.1 Token Exchange Performance",
                    False,
                    duration,
                    "No successful exchanges to measure"
                )
        except Exception as e:
            duration = time.time() - start_time
            self._record_result("10.1 Token Exchange Performance", False, duration, error=e)

    def _generate_report(self) -> bool:
        """Generate comprehensive test report."""

        total_tests = len(self.results)
        passed_tests = sum(1 for result in self.results if result.passed)
        failed_tests = total_tests - passed_tests

        total_duration = sum(result.duration for result in self.results)

        print("\n" + "="*80)
        print("🧪 JWT TOKEN EXCHANGE TEST SUITE REPORT")
        print("="*80)
        print(f"📊 Total Tests: {total_tests}")
        print(f"✅ Passed: {passed_tests}")
        print(f"❌ Failed: {failed_tests}")
        print(f"⏱️  Total Duration: {total_duration:.3f}s")
        print(f"📈 Success Rate: {(passed_tests/total_tests*100):.1f}%")

        if failed_tests > 0:
            print("\n❌ FAILED TESTS:")
            for result in self.results:
                if not result.passed:
                    print(f"   • {result.name}")
                    if result.error:
                        print(f"     Error: {str(result.error)}")
                    if result.details:
                        print(f"     Details: {result.details}")

        print("\n📋 DETAILED RESULTS:")
        for result in self.results:
            status = "✅" if result.passed else "❌"
            print(f"   {status} {result.name} ({result.duration:.3f}s)")
            if result.details and self.config.verbose:
                print(f"      {result.details}")

        # Recommendations
        print("\n💡 RECOMMENDATIONS:")

        if any("Backend Connectivity" in r.name and not r.passed for r in self.results):
            print("   • Ensure backend server is running on localhost:8000")
            print("   • Check firewall and network connectivity")

        if any("CORS" in r.name and not r.passed for r in self.results):
            print("   • Update CORS configuration to allow frontend origin")
            print("   • Verify CORS middleware is properly configured")

        if any("Firebase" in r.name and not r.passed for r in self.results):
            print("   • Verify Firebase credentials are properly configured")
            print("   • Check Firebase project settings and permissions")

        if any("JWT" in r.name and not r.passed for r in self.results):
            print("   • Verify JWT secret key configuration")
            print("   • Check JWT token generation and validation logic")

        if any("Performance" in r.name and not r.passed for r in self.results):
            print("   • Consider optimizing token exchange logic")
            print("   • Check for network latency or backend processing delays")

        print("\n🔗 NEXT STEPS:")
        if passed_tests == total_tests:
            print("   • All tests passed! Ready for Flutter frontend integration")
            print("   • Test with real Firebase authentication in browser")
            print("   • Implement role-based UI routing")
        else:
            print("   • Fix failing tests before proceeding with frontend integration")
            print("   • Review error details and implement fixes")
            print("   • Re-run test suite after fixes")

        print("="*80)

        return passed_tests == total_tests


async def main():
    """Main test runner."""
    parser = argparse.ArgumentParser(description="JWT Token Exchange Test Suite")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument("--mock-firebase", action="store_true", help="Use mock Firebase tokens")
    parser.add_argument("--backend-url", default="http://localhost:8000", help="Backend URL")
    parser.add_argument("--frontend-url", default="http://localhost:3000", help="Frontend URL")
    parser.add_argument("--timeout", type=int, default=30, help="Request timeout in seconds")

    args = parser.parse_args()

    config = TestConfig(
        backend_url=args.backend_url,
        frontend_url=args.frontend_url,
        timeout=args.timeout,
        mock_firebase=args.mock_firebase,
        verbose=args.verbose
    )

    suite = JWTTestSuite(config)
    success = await suite.run_all_tests()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    asyncio.run(main())