# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview & Current Status

**Purpose**: Educational file submission system where students download practice files and submit completed work.

**Tech Stack**: Flutter Web + Firebase Auth + Riverpod + FastAPI + NAS Storage

### Implementation Status (2025-09-19 업데이트)
- ✅ **Infrastructure**: Complete (server, networking, file storage)
- ✅ **Frontend Authentication**: Complete (Riverpod + Firebase Auth, HomePage 마이그레이션 완료)
- ✅ **Backend Authentication**: Complete (FastAPI + Firebase + JWT 완전 구현 - 19개 파일)
- 🔄 **JWT Integration**: Next phase - Flutter에서 Backend JWT 토큰 교환 구현 (우선순위 1)
- 🔄 **Role-based UI**: admin/student 화면 분기 구현 (우선순위 2)
- ✅ **Documentation**: Complete (작업 완료 내역 및 향후 로드맵 문서화)

### Current Priority
**Phase 3**: Flutter-Backend JWT 연동 → 역할 기반 UI → 파일 관리 API
- 상세 계획: `claudedocs/next_tasks_roadmap.md` 참조
- 진행률: 40% → 목표 100%

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
  file_picker: ^8.1.2

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

### Firebase Setup & Google Sign-In Configuration
```bash
# Firebase project configuration
flutterfire configure --project=info-class-7398a

# If flutterfire CLI not found, install first:
dart pub global activate flutterfire_cli
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

**Manual Firebase Configuration:**
```dart
// lib/firebase_options.dart - Update with new project settings
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyAKOJuQm6s_BjmNaYsBwDbGr_p7xGCpiIo',
  appId: '1:39629805865:web:3082daaa6741f4bd49ff38',
  messagingSenderId: '39629805865',
  projectId: 'info-class-7398a',
  authDomain: 'info-class-7398a.firebaseapp.com',
  storageBucket: 'info-class-7398a.firebasestorage.app',
  measurementId: 'G-SZ73LYNGND',
);
```

**Google Sign-In Web Configuration:**
```html
<!-- web/index.html - Add Google Client ID -->
<meta name="google-signin-client_id" content="39629805865-ji2gb8uktr43i3m5fcqf9to22v97193l.apps.googleusercontent.com">

<!-- Firebase SDK -->
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-auth-compat.js"></script>
```

**Required Google Cloud Console Setup:**
1. **OAuth 동의 화면**: 외부 → 테스트 모드로 설정
2. **People API 활성화**: https://console.cloud.google.com/apis/library/people.googleapis.com
3. **OAuth 2.0 클라이언트 ID**: 승인된 JavaScript 원본에 `http://localhost:3000` 추가
4. **테스트 사용자**: 로그인할 Google 계정 추가

**Web-Specific Google Sign-In Issue Fix:**
```dart
// lib/auth_service.dart - Handle missing idToken in web environment
static Future<User?> signInWithGoogle() async {
  try {
    await _googleSignIn.signOut(); // Clear previous session
    
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    // 웹에서는 idToken이 없을 수 있음 - accessToken만 확인
    if (googleAuth.accessToken == null) {
      throw Exception('Google 액세스 토큰을 가져올 수 없습니다.');
    }
    
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken, // null이어도 Firebase가 처리
    );
    
    final UserCredential result = await _auth.signInWithCredential(credential);
    return result.user;
  } catch (e) {
    throw Exception('로그인 처리 중 오류 발생: $e');
  }
}
```

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

## 📚 추가 문서

- **[트러블슈팅 가이드](docs/TROUBLESHOOTING.md)**: Firebase Google Sign-In 문제해결 가이드
- **[API 문서](docs/API.md)**: FastAPI 백엔드 API 명세서 (예정)
- **[배포 가이드](docs/DEPLOYMENT.md)**: 프로덕션 배포 절차 (예정)

---
**Document Version**: 3.1 (Authentication-Complete)
**Last Updated**: 2025-01-09
**Next Review**: After Phase 2 (File Management) completion