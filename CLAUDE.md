# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview & Current Status

**Purpose**: Educational file submission system where students download practice files and submit completed work.

**Tech Stack**: Flutter Web + Firebase Auth + Riverpod + FastAPI + NAS Storage

### Implementation Status
- ✅ **Infrastructure**: Complete (server, networking, file storage)
- ❌ **Frontend**: Start here - Flutter project with auth and file management
- ❌ **Backend**: FastAPI with JWT validation and file operations
- ⚠️ **Database**: Choose between Supabase PostgreSQL or custom setup

### Current Priority
**Phase 1**: Authentication system (Firebase → custom JWT → role-based routing)

## Quick Start

### Essential Commands
```bash
# Daily development workflow
flutter pub get                          # Install dependencies
dart run build_runner watch             # Auto-generate Riverpod code
flutter run -d chrome                   # Start dev server

# Code quality
flutter analyze && flutter test         # Before commits

# Server connectivity check
curl http://ubuntu/info_class/api/healthz
```

### Required Dependencies
```yaml
dependencies:
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.0
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  http: ^1.1.0
  file_picker: ^6.1.1

dev_dependencies:
  build_runner: ^2.4.7
  riverpod_generator: ^2.3.9
```

## System Architecture

### Authentication Flow
```
[User] → [Google OAuth] → [Firebase Token] → [Backend /auth/exchange] → [Custom JWT + Role]
                                                       ↓
[Flutter App] → [API calls with JWT] → [FastAPI Backend] → [NAS Files + DB Metadata]
```

### Key URLs
- **Development**: http://localhost:3000
- **Production**: https://info.pocheonil.hs.kr/info_class/
- **API Base**: https://info.pocheonil.hs.kr/info_class/api/
- **Server SSH**: `ssh menamiji@ubuntu` (Tailscale hostname preferred)

## Implementation Patterns

### Riverpod State Management
```dart
// 1. Create Provider with code generation
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<User?> build() async {
    return await ref.read(authRepositoryProvider).getCurrentUser();
  }

  Future<void> signIn() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      ref.read(authRepositoryProvider).signInWithGoogle()
    );
  }
}

// 2. Use in widgets
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      data: (user) => user != null ? HomePage() : LoginButton(),
      loading: () => CircularProgressIndicator(),
      error: (error, _) => Text('Error: $error'),
    );
  }
}
```

### Authentication Implementation
```dart
// Firebase → Backend JWT exchange
Future<User?> signInWithGoogle() async {
  final credential = await GoogleAuthProvider().credential();
  final firebaseUser = await FirebaseAuth.instance.signInWithCredential(credential);
  final token = await firebaseUser.user?.getIdToken();

  // Exchange for backend JWT
  final response = await apiClient.post('/auth/exchange', {
    'firebase_token': token
  });

  return User.fromJson(response.data);
}
```

### File Upload Pattern
```dart
// Optimistic updates with error handling
Future<void> uploadFile(File file) async {
  // Add optimistically to UI
  state = [...state, PendingSubmission(file)];

  try {
    final result = await repository.uploadSubmission(file);
    // Replace with actual result
    state = state.map((item) =>
      item.id == file.id ? result : item
    ).toList();
  } catch (e) {
    // Remove on error
    state = state.where((item) => item.id != file.id).toList();
    rethrow;
  }
}
```

## Project Structure

### Recommended Directory Layout
```
lib/
├── main.dart                    # ProviderScope + Firebase initialization
├── app/
│   ├── app.dart                 # MaterialApp + routing
│   └── router.dart              # Route configuration
├── features/                    # Feature-based organization
│   ├── auth/                   # Start with authentication
│   │   ├── domain/user_model.dart
│   │   ├── data/auth_repository.dart
│   │   ├── presentation/login_screen.dart
│   │   └── providers/auth_providers.dart
│   ├── subjects/               # Add after auth works
│   └── submissions/            # File management features
├── shared/                     # Cross-cutting concerns
│   ├── data/api_client.dart    # HTTP client with JWT
│   ├── domain/api_result.dart  # Response wrapper
│   └── widgets/                # Reusable UI components
├── core/
│   ├── constants/app_constants.dart
│   └── utils/date_utils.dart
└── generated/                  # Auto-generated code (gitignore)
```

### Development Phases
**Phase 1**: Authentication Foundation
- Firebase Auth setup
- Login/logout screens
- Role-based routing
- Token management

**Phase 2**: File Management
- File upload/download
- Subject and content management
- Admin/student interfaces

**Phase 3**: Backend Integration
- FastAPI implementation
- JWT validation
- File storage operations

## API Design

### Authentication Endpoints
```http
POST /auth/exchange
Body: {"firebase_token": "eyJ..."}
Response: {"jwt_token": "...", "role": "admin", "user_id": "..."}

GET /auth/me
Authorization: Bearer <jwt_token>
Response: {"ok": true, "data": {"email": "...", "role": "admin"}}
```

### File Management Endpoints
```http
GET /subjects
Response: {"ok": true, "data": [{"id": "...", "name": "정보처리와관리"}]}

POST /submissions/upload
Content-Type: multipart/form-data
Fields: date_key, files[]
Response: {"ok": true, "data": {"uploaded_count": 2}}

GET /subjects/{id}/contents
Response: {"ok": true, "data": {"files": [{"name": "template.xlsx"}]}}
```

### Error Response Format
```json
{
  "ok": false,
  "error": {
    "code": "PERMISSION_DENIED",
    "message": "관리자 권한이 필요합니다."
  }
}
```

## Common Issues & Quick Fixes

### Authentication Problems
```dart
// Token refresh issue
final user = FirebaseAuth.instance.currentUser;
final token = await user?.getIdToken(true); // Force refresh

// Role validation
if (!['student', 'teacher', 'admin'].contains(userRole)) {
  throw Exception('Invalid user role');
}
```

### Riverpod Code Generation
```bash
# Provider not found after creation
dart run build_runner build --delete-conflicting-outputs

# Watch mode not updating
killall dart
dart run build_runner watch

# Import errors - check dependencies
flutter pub deps
```

### Server Connectivity
```bash
# Test API health
curl http://ubuntu/info_class/api/healthz

# SSH to server if needed
ssh menamiji@ubuntu
docker compose logs -f info-class-service

# NAS file permissions
sudo chown -R menamiji:docker /mnt/nas-info-class/
```

### File Upload Issues
```dart
// Progress tracking for large files
StreamSubscription<double>? uploadProgress;

Future<void> uploadWithProgress(File file) async {
  final request = http.MultipartRequest('POST', uploadUrl);
  final stream = http.ByteStream(file.openRead());

  request.files.add(http.MultipartFile(
    'file', stream, file.lengthSync(),
    filename: basename(file.path)
  ));

  // Track progress
  var bytesSent = 0;
  stream.listen((chunk) {
    bytesSent += chunk.length;
    final progress = bytesSent / file.lengthSync();
    // Update UI with progress
  });
}
```

## Infrastructure Information

### File Storage Structure
```bash
# NAS storage paths
/mnt/nas-info-class/
├── content/                    # Admin uploaded practice files
│   └── <subject>/<category>/<item>/
└── submissions/                # Student submitted files
    └── <YYYYMMDD>/<student_no>/

# File permissions
directories: 775 (rwxrwxr-x)
files: 664 (rw-rw-r--)
owner: menamiji:docker
```

### Server Access & Monitoring
```bash
# Primary access (Tailscale)
ssh menamiji@ubuntu

# Service management
cd ~/docker-services
docker compose restart info-class-service
docker compose logs -f info-class-service

# Health checks
curl http://ubuntu/info_class/api/healthz
curl https://info.pocheonil.hs.kr/info_class/api/healthz
```

### Development Environment
- **Firebase**: Domain restricted to @pocheonil.hs.kr
- **Database**: Choose Supabase PostgreSQL or custom SQL after auth works
- **File Storage**: Direct NAS storage with metadata in DB
- **Deployment**: Build locally, deploy to server manually

### Technology Choices
- **Riverpod**: Better than Provider for code generation and testing
- **Firebase Auth**: Handles Google OAuth and domain restrictions easily
- **Custom JWT**: Enables role-based backend access control
- **Feature Structure**: Easier maintenance and testing than layer-based

---
**Document Version**: 3.0 (Development-Focused)
**Last Updated**: 2025-09-15
**Next Review**: After Phase 1 (Auth) completion