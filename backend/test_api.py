#!/usr/bin/env python3
"""
Simple API testing script for Info Class Backend.

This script provides basic testing for the authentication endpoints.
"""

import asyncio
import httpx
import json
import sys
from typing import Dict, Optional

# Test configuration
BASE_URL = "http://localhost:8000"
TEST_FIREBASE_TOKEN = "your-firebase-token-here"  # Replace with actual token for testing


class APITester:
    """Simple API testing utility."""

    def __init__(self, base_url: str = BASE_URL):
        self.base_url = base_url
        self.jwt_token: Optional[str] = None

    async def test_health_check(self) -> bool:
        """Test health check endpoints."""
        print("🔍 Testing health check endpoints...")

        try:
            async with httpx.AsyncClient() as client:
                # Test root endpoint
                response = await client.get(f"{self.base_url}/")
                print(f"GET / -> {response.status_code}")
                if response.status_code == 200:
                    data = response.json()
                    print(f"   Message: {data.get('message')}")
                    print(f"   Version: {data.get('version')}")
                else:
                    print(f"   Error: {response.text}")
                    return False

                # Test health endpoint
                response = await client.get(f"{self.base_url}/healthz")
                print(f"GET /healthz -> {response.status_code}")
                if response.status_code == 200:
                    data = response.json()
                    print(f"   Status: {data.get('status')}")
                    print(f"   Firebase: {data.get('services', {}).get('firebase')}")
                else:
                    print(f"   Error: {response.text}")
                    return False

                return True

        except Exception as e:
            print(f"❌ Health check failed: {str(e)}")
            return False

    async def test_token_exchange(self, firebase_token: str) -> bool:
        """Test Firebase token exchange."""
        print("🔐 Testing Firebase token exchange...")

        if firebase_token == "your-firebase-token-here":
            print("⚠️  Skipping token exchange - no Firebase token provided")
            print("   Set TEST_FIREBASE_TOKEN in this script to test token exchange")
            return True

        try:
            async with httpx.AsyncClient() as client:
                payload = {"firebase_token": firebase_token}
                response = await client.post(
                    f"{self.base_url}/auth/exchange",
                    json=payload
                )

                print(f"POST /auth/exchange -> {response.status_code}")

                if response.status_code == 200:
                    data = response.json()
                    if data.get("ok"):
                        self.jwt_token = data["data"]["jwt_token"]
                        user = data["data"]["user"]
                        print(f"   ✅ Token exchange successful")
                        print(f"   User: {user['email']} (role: {user['role']})")
                        print(f"   Permissions: {user['permissions']}")
                        return True
                    else:
                        print(f"   ❌ Exchange failed: {data}")
                        return False
                else:
                    print(f"   ❌ HTTP {response.status_code}: {response.text}")
                    return False

        except Exception as e:
            print(f"❌ Token exchange failed: {str(e)}")
            return False

    async def test_protected_endpoint(self) -> bool:
        """Test protected /auth/me endpoint."""
        print("🛡️  Testing protected endpoint...")

        if not self.jwt_token:
            print("⚠️  Skipping protected endpoint - no JWT token available")
            return True

        try:
            async with httpx.AsyncClient() as client:
                headers = {"Authorization": f"Bearer {self.jwt_token}"}
                response = await client.get(
                    f"{self.base_url}/auth/me",
                    headers=headers
                )

                print(f"GET /auth/me -> {response.status_code}")

                if response.status_code == 200:
                    data = response.json()
                    if data.get("ok"):
                        user_data = data["data"]
                        print(f"   ✅ Protected endpoint accessible")
                        print(f"   User: {user_data['email']} (role: {user_data['role']})")
                        return True
                    else:
                        print(f"   ❌ Unexpected response: {data}")
                        return False
                else:
                    print(f"   ❌ HTTP {response.status_code}: {response.text}")
                    return False

        except Exception as e:
            print(f"❌ Protected endpoint test failed: {str(e)}")
            return False

    async def test_invalid_token(self) -> bool:
        """Test behavior with invalid JWT token."""
        print("🚫 Testing invalid token handling...")

        try:
            async with httpx.AsyncClient() as client:
                headers = {"Authorization": "Bearer invalid-token"}
                response = await client.get(
                    f"{self.base_url}/auth/me",
                    headers=headers
                )

                print(f"GET /auth/me (invalid token) -> {response.status_code}")

                if response.status_code in [401, 403]:
                    data = response.json()
                    print(f"   ✅ Correctly rejected invalid token")
                    print(f"   Error: {data.get('error', {}).get('message')}")
                    return True
                else:
                    print(f"   ❌ Unexpected status code: {response.status_code}")
                    return False

        except Exception as e:
            print(f"❌ Invalid token test failed: {str(e)}")
            return False

    async def run_all_tests(self) -> None:
        """Run all API tests."""
        print(f"🚀 Starting API tests for {self.base_url}")
        print("=" * 60)

        tests = [
            ("Health Check", self.test_health_check()),
            ("Token Exchange", self.test_token_exchange(TEST_FIREBASE_TOKEN)),
            ("Protected Endpoint", self.test_protected_endpoint()),
            ("Invalid Token", self.test_invalid_token()),
        ]

        results = []
        for test_name, test_coro in tests:
            print(f"\n📋 {test_name}")
            print("-" * 40)
            try:
                success = await test_coro
                results.append((test_name, success))
            except Exception as e:
                print(f"❌ {test_name} crashed: {str(e)}")
                results.append((test_name, False))

        # Print summary
        print("\n" + "=" * 60)
        print("📊 TEST RESULTS SUMMARY")
        print("=" * 60)

        passed = 0
        for test_name, success in results:
            status = "✅ PASS" if success else "❌ FAIL"
            print(f"{status} {test_name}")
            if success:
                passed += 1

        print(f"\nTotal: {passed}/{len(results)} tests passed")

        if passed == len(results):
            print("🎉 All tests passed! API is working correctly.")
            sys.exit(0)
        else:
            print("⚠️  Some tests failed. Check the output above for details.")
            sys.exit(1)


async def main():
    """Main test runner."""
    import argparse

    parser = argparse.ArgumentParser(description="Test Info Class Backend API")
    parser.add_argument(
        "--url",
        default=BASE_URL,
        help=f"Base URL for API (default: {BASE_URL})"
    )
    parser.add_argument(
        "--firebase-token",
        help="Firebase ID token for testing token exchange"
    )

    args = parser.parse_args()

    if args.firebase_token:
        global TEST_FIREBASE_TOKEN
        TEST_FIREBASE_TOKEN = args.firebase_token

    tester = APITester(args.url)
    await tester.run_all_tests()


if __name__ == "__main__":
    asyncio.run(main())