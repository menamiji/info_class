# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview & Current Status

**Purpose**: Educational file submission system where students download practice files and submit completed work.

**Tech Stack**: Flutter Web + Firebase Auth + Riverpod + FastAPI + NAS Storage

### Implementation Status (2025-01-09 업데이트)
- ✅ **Infrastructure**: Complete (server, networking, file storage)
- ✅ **Frontend Authentication**: Complete (Riverpod + Firebase Auth, HomePage 마이그레이션 완료)
- ✅ **Backend Authentication**: Complete (FastAPI + Firebase + JWT 완전 구현 - 19개 파일)
- ✅ **JWT Integration**: **COMPLETE** - Flutter-Backend JWT 토큰 교환 완전 구현 (2025-09-22)
- ✅ **Development Environment**: Complete (CORS, Firebase 개발모드, 환경설정 완료)
- ✅ **Role-based UI**: **COMPLETE** - admin/student/guest 화면 분기 및 라우팅 완전 구현 (2025-01-09)
- ✅ **Documentation**: Complete (트러블슈팅 가이드 포함)

### Current Priority
**Phase 5**: 파일 관리 API 구현 → 실제 데이터 연동 → 프로덕션 배포
- 역할 기반 라우팅: ✅ 100% 완료 (2025-01-09)
- 전체 진행률: 85% → 목표 100%

### Recent Updates (2025-01-09)
🎉 **역할 기반 UI 라우팅 시스템 완전 구현 완료**
- ✅ AuthenticatedUserState 모델 구현 (clean async state management)
- ✅ Admin/Student/Guest 화면 및 라우팅 구현
- ✅ Role-based navigation 및 권한 제어 완료
- ✅ API 응답 파싱 이슈 해결 (UserInfoResponse 모델 추가)
- ✅ 관리자 계정 설정 및 검증 완료 (menamiji@pocheonil.hs.kr)
- ✅ Material Design 3 기반 공통 레이아웃 (AppLayout) 구현

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
**Phase 1**: Authentication Foundation ✅ **COMPLETE**
- Firebase Auth setup
- Login/logout screens
- Role-based routing
- Token management

**Phase 2**: Role-based UI ✅ **COMPLETE**
- Admin/Student/Guest 화면 구현
- AuthenticatedUserState 모델
- API 응답 파싱 및 권한 제어
- Material Design 3 레이아웃

**Phase 3**: File Management 🔄 **NEXT**
- File upload/download API
- Subject and content management
- 실제 백엔드 데이터 연동
- NAS 스토리지 통합

**Phase 4**: Production Deployment
- 프로덕션 환경 설정
- 성능 최적화
- 보안 강화

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

## 구현된 주요 파일 및 컴포넌트

### 새로 구현된 파일들 (Role-based UI)
- `lib/models/authenticated_user_state.dart` - Clean async state management 모델
- `lib/widgets/common/app_layout.dart` - Material Design 3 공통 레이아웃
- `lib/screens/admin_screen.dart` - 관리자 대시보드 (과목관리, 콘텐츠 업로드)
- `lib/screens/student_screen.dart` - 학생 인터페이스 (수업자료, 과제제출)
- `lib/shared/models/user_info_response.dart` - `/auth/me` API 응답 모델

### 주요 수정된 파일들
- `lib/main.dart` - AuthRouter 단순화, role-based routing 구현
- `lib/login_page.dart` - ConsumerWidget 전환, Riverpod 패턴 적용
- `lib/providers/auth_provider.dart` - authenticatedUserStateProvider 추가
- `lib/shared/data/api_client.dart` - getCurrentUser() 메서드 개선
- `backend/config/settings.py` - ADMIN_EMAILS에 menamiji@pocheonil.hs.kr 추가
- `backend/auth/firebase_validator.py` - 개발모드 mock 이메일 업데이트

### 해결된 주요 이슈들
1. **로그인 버튼 동작 안함** → LoginPage Riverpod 패턴 적용
2. **무한 로딩 (권한 확인중)** → AuthRouter 복잡한 provider chain 단순화
3. **관리자 권한 인식 안됨** → API 응답 파싱 이슈 해결
4. **Guest 역할 잘못 표시** → UserInfoResponse 모델로 올바른 파싱

## 📚 추가 문서

- **[트러블슈팅 가이드](docs/TROUBLESHOOTING.md)**: Firebase Google Sign-In 문제해결 가이드
- **[API 문서](docs/API.md)**: FastAPI 백엔드 API 명세서 (예정)
- **[배포 가이드](docs/DEPLOYMENT.md)**: 프로덕션 배포 절차 (예정)

## 다음 개발 우선순위

1. **관리자/학생 화면 UI 개선** (현재 Mock 데이터)
2. **실제 API 연동** (파일 업로드/다운로드)
3. **프로덕션 배포 준비** (성능 최적화, 보안 강화)

---
**Document Version**: 4.0 (Role-based-UI-Complete)
**Last Updated**: 2025-01-09
**Next Review**: After Phase 3 (File Management API) completion