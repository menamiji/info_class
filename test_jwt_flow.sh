#!/bin/bash

# JWT Token Exchange Flow Testing Script
# This script provides comprehensive testing of the authentication flow
# between Flutter frontend and FastAPI backend

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_DIR="backend"
BACKEND_URL="http://localhost:8000"
FRONTEND_URL="http://localhost:3000"
BACKEND_PORT=8000
FRONTEND_PORT=3000

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if a port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Check if backend is running
check_backend() {
    log "Checking backend status..."
    if curl -s -f "$BACKEND_URL/healthz" >/dev/null 2>&1; then
        success "Backend is running and healthy"
        return 0
    else
        error "Backend is not accessible at $BACKEND_URL"
        return 1
    fi
}

# Check if frontend is running
check_frontend() {
    log "Checking frontend status..."
    if check_port $FRONTEND_PORT; then
        success "Frontend is running on port $FRONTEND_PORT"
        return 0
    else
        warning "Frontend is not running on port $FRONTEND_PORT"
        return 1
    fi
}

# Start backend server
start_backend() {
    log "Starting backend server..."

    if [ ! -d "$BACKEND_DIR" ]; then
        error "Backend directory not found: $BACKEND_DIR"
        exit 1
    fi

    cd "$BACKEND_DIR"

    # Check if virtual environment exists
    if [ ! -d "venv" ]; then
        error "Virtual environment not found. Run: python -m venv venv"
        exit 1
    fi

    # Activate virtual environment
    source venv/bin/activate

    # Check if requirements are installed
    if ! pip show fastapi >/dev/null 2>&1; then
        log "Installing backend dependencies..."
        pip install -r requirements.txt
    fi

    # Start server in background
    log "Launching FastAPI server on port $BACKEND_PORT..."
    python main.py &
    BACKEND_PID=$!

    # Wait for server to start
    local attempts=0
    local max_attempts=30

    while [ $attempts -lt $max_attempts ]; do
        if curl -s -f "$BACKEND_URL/healthz" >/dev/null 2>&1; then
            success "Backend server started successfully (PID: $BACKEND_PID)"
            cd ..
            return 0
        fi

        sleep 1
        attempts=$((attempts + 1))
        log "Waiting for backend to start... ($attempts/$max_attempts)"
    done

    error "Backend failed to start within $max_attempts seconds"
    kill $BACKEND_PID 2>/dev/null || true
    cd ..
    exit 1
}

# Start frontend server
start_frontend() {
    log "Starting frontend server..."

    # Check if Flutter is installed
    if ! command -v flutter >/dev/null 2>&1; then
        error "Flutter is not installed or not in PATH"
        exit 1
    fi

    # Check if this is a Flutter project
    if [ ! -f "pubspec.yaml" ]; then
        error "Not a Flutter project (pubspec.yaml not found)"
        exit 1
    fi

    # Install dependencies
    log "Installing Flutter dependencies..."
    flutter pub get

    # Generate code if needed
    if [ -f "pubspec.yaml" ] && grep -q "build_runner" pubspec.yaml; then
        log "Generating code with build_runner..."
        dart run build_runner build --delete-conflicting-outputs
    fi

    # Start Flutter web server in background
    log "Launching Flutter web server on port $FRONTEND_PORT..."
    flutter run -d chrome --web-port=$FRONTEND_PORT &
    FRONTEND_PID=$!

    # Wait for server to start
    local attempts=0
    local max_attempts=60  # Flutter can take longer to start

    while [ $attempts -lt $max_attempts ]; do
        if check_port $FRONTEND_PORT; then
            success "Frontend server started successfully (PID: $FRONTEND_PID)"
            return 0
        fi

        sleep 2
        attempts=$((attempts + 1))
        log "Waiting for frontend to start... ($attempts/$max_attempts)"
    done

    error "Frontend failed to start within $((max_attempts * 2)) seconds"
    kill $FRONTEND_PID 2>/dev/null || true
    exit 1
}

# Run Python backend tests
run_backend_tests() {
    log "Running backend JWT tests..."

    # Install test dependencies
    cd "$BACKEND_DIR"
    source venv/bin/activate

    if ! pip show requests >/dev/null 2>&1; then
        log "Installing test dependencies..."
        pip install requests PyJWT
    fi

    cd ..

    # Run the comprehensive test suite
    log "Executing JWT test suite..."
    python jwt_test_suite.py --verbose --mock-firebase

    if [ $? -eq 0 ]; then
        success "Backend tests completed successfully"
    else
        error "Backend tests failed"
        return 1
    fi
}

# Run Flutter tests
run_flutter_tests() {
    log "Running Flutter integration tests..."

    # Check if integration test exists
    if [ ! -f "test/integration/jwt_integration_test.dart" ]; then
        warning "Integration test not found, running unit tests only"
        flutter test
        return $?
    fi

    # Run unit tests first
    log "Running Flutter unit tests..."
    flutter test

    if [ $? -ne 0 ]; then
        error "Flutter unit tests failed"
        return 1
    fi

    # Run integration tests
    log "Running Flutter integration tests..."
    flutter test integration_test/jwt_integration_test.dart

    if [ $? -eq 0 ]; then
        success "Flutter tests completed successfully"
    else
        error "Flutter integration tests failed"
        return 1
    fi
}

# Manual testing guidance
manual_testing_guide() {
    log "Manual Testing Guide"
    echo
    echo "To manually test the JWT authentication flow:"
    echo
    echo "1. Open browser to: $FRONTEND_URL"
    echo "2. Open browser developer tools (F12)"
    echo "3. Click 'Sign in with Google' button"
    echo "4. Check console for authentication flow logs"
    echo "5. Verify JWT token is stored and API calls work"
    echo
    echo "Backend API endpoints to test:"
    echo "  • Health: $BACKEND_URL/healthz"
    echo "  • Exchange: $BACKEND_URL/auth/exchange (POST)"
    echo "  • User Info: $BACKEND_URL/auth/me (GET with JWT)"
    echo "  • Refresh: $BACKEND_URL/auth/refresh (POST with JWT)"
    echo
    echo "Expected flow:"
    echo "  Firebase Auth → Firebase Token → Backend Exchange → JWT Token → API Calls"
    echo
}

# Cleanup function
cleanup() {
    log "Cleaning up..."

    # Kill backend if started by this script
    if [ -n "$BACKEND_PID" ]; then
        log "Stopping backend server (PID: $BACKEND_PID)"
        kill $BACKEND_PID 2>/dev/null || true
    fi

    # Kill frontend if started by this script
    if [ -n "$FRONTEND_PID" ]; then
        log "Stopping frontend server (PID: $FRONTEND_PID)"
        kill $FRONTEND_PID 2>/dev/null || true
    fi

    success "Cleanup completed"
}

# Trap for cleanup on script exit
trap cleanup EXIT INT TERM

# Main function
main() {
    echo
    echo "============================================"
    echo "   JWT Token Exchange Flow Testing Suite   "
    echo "============================================"
    echo

    local run_backend_tests_flag=false
    local run_flutter_tests_flag=false
    local manual_mode=false
    local start_servers=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --backend-tests)
                run_backend_tests_flag=true
                shift
                ;;
            --flutter-tests)
                run_flutter_tests_flag=true
                shift
                ;;
            --all-tests)
                run_backend_tests_flag=true
                run_flutter_tests_flag=true
                shift
                ;;
            --manual)
                manual_mode=true
                shift
                ;;
            --start-servers)
                start_servers=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo
                echo "Options:"
                echo "  --backend-tests     Run backend JWT tests only"
                echo "  --flutter-tests     Run Flutter integration tests only"
                echo "  --all-tests         Run both backend and Flutter tests"
                echo "  --manual            Start servers and provide manual testing guide"
                echo "  --start-servers     Start both servers without running tests"
                echo "  --help, -h          Show this help message"
                echo
                echo "Examples:"
                echo "  $0 --all-tests      # Run complete test suite"
                echo "  $0 --manual         # Start servers for manual testing"
                echo "  $0 --backend-tests  # Test backend only"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Default to all tests if no specific test flag is provided
    if [ "$run_backend_tests_flag" = false ] && [ "$run_flutter_tests_flag" = false ] && [ "$manual_mode" = false ] && [ "$start_servers" = false ]; then
        run_backend_tests_flag=true
        run_flutter_tests_flag=true
    fi

    # Check if servers are already running
    local backend_running=false
    local frontend_running=false
    local start_backend_flag=false
    local start_frontend_flag=false

    if check_backend; then
        backend_running=true
    else
        start_backend_flag=true
    fi

    if check_frontend; then
        frontend_running=true
    elif [ "$run_flutter_tests_flag" = true ] || [ "$manual_mode" = true ] || [ "$start_servers" = true ]; then
        start_frontend_flag=true
    fi

    # Start servers if needed
    if [ "$start_backend_flag" = true ]; then
        start_backend
    fi

    if [ "$start_frontend_flag" = true ]; then
        start_frontend
    fi

    # Wait a moment for servers to stabilize
    if [ "$start_backend_flag" = true ] || [ "$start_frontend_flag" = true ]; then
        log "Waiting for servers to stabilize..."
        sleep 3
    fi

    # Run tests
    local test_success=true

    if [ "$run_backend_tests_flag" = true ]; then
        if ! run_backend_tests; then
            test_success=false
        fi
    fi

    if [ "$run_flutter_tests_flag" = true ]; then
        if ! run_flutter_tests; then
            test_success=false
        fi
    fi

    # Manual testing mode
    if [ "$manual_mode" = true ] || [ "$start_servers" = true ]; then
        manual_testing_guide

        if [ "$manual_mode" = true ]; then
            log "Servers are running. Press Ctrl+C to stop."

            # Keep script running until interrupted
            while true; do
                sleep 1
            done
        fi
    fi

    # Final results
    echo
    echo "============================================"
    if [ "$test_success" = true ]; then
        success "All tests completed successfully!"
        echo
        echo "✅ JWT token exchange flow is working correctly"
        echo "✅ Ready for production deployment"
    else
        error "Some tests failed!"
        echo
        echo "❌ Review failed tests and fix issues"
        echo "❌ Check logs for detailed error information"
        exit 1
    fi
    echo "============================================"
}

# Run main function with all arguments
main "$@"