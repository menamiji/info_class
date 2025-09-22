# Info Class - 교육용 파일 제출 시스템

포천일고등학교 정보처리와관리 과목의 연습 파일 배포 및 과제 제출 시스템입니다.

## 📋 프로젝트 개요

**목적**: 학생들이 연습 파일을 다운로드하고 완성된 과제를 제출할 수 있는 교육용 웹 시스템

**사용자**:
- 👨‍🎓 학생: 연습 파일 다운로드, 과제 제출
- 👨‍🏫 교사: 연습 파일 업로드, 과제 확인 및 평가
- 👨‍💼 관리자: 전체 시스템 관리, 사용자 권한 관리

## 🛠 기술 스택

- **Frontend**: Flutter Web (Dart)
- **State Management**: Riverpod + Code Generation
- **Authentication**: Firebase Auth (Google OAuth)
- **Backend**: FastAPI (Python)
- **Database**: Supabase PostgreSQL
- **File Storage**: NAS (Synology) with direct file access
- **Infrastructure**: Docker + nginx + Tailscale networking

## 🚀 개발 환경 설정

### 필수 요구사항
- Flutter SDK 3.9.2+
- Dart SDK
- Chrome (웹 개발용)

### 설치 및 실행
```bash
# 저장소 클론
git clone <repository-url>
cd info_class

# 의존성 설치
flutter pub get

# Riverpod 코드 생성 (백그라운드)
dart run build_runner watch

# 개발 서버 실행
flutter run -d chrome
```

### 코드 품질 확인
```bash
# 정적 분석 + 테스트 실행
flutter analyze && flutter test

# 의존성 체크
flutter pub deps
```

## 📁 프로젝트 구조

```
lib/
├── main.dart                   # 앱 진입점
├── auth_service.dart          # Firebase 인증 서비스
├── login_page.dart           # 로그인 화면
└── (향후 feature 기반 구조로 리팩토링 예정)

test/
└── widget_test.dart          # 기본 위젯 테스트

web/
├── index.html               # Firebase/Google OAuth 설정
└── icons/                   # 웹 아이콘

docs/                        # 프로젝트 문서 (예정)
├── TROUBLESHOOTING.md       # 문제해결 가이드
├── API.md                   # API 명세서
└── DEPLOYMENT.md            # 배포 가이드
```

## 🔐 인증 시스템

### 현재 상태: ✅ 기반 완료
1. **Firebase 프로젝트 설정**: `info-class-7398a`
2. **Google OAuth 설정**: @pocheonil.hs.kr 도메인 제한
3. **웹 환경 최적화**: Google Sign-In 웹 호환성 개선
4. **의존성 정리**: Riverpod, HTTP client, file_picker 최신화

### 인증 흐름
```
[사용자] → [Google OAuth] → [Firebase Token]
    ↓
[백엔드 /auth/exchange] → [커스텀 JWT + 역할]
    ↓
[Flutter 앱] → [JWT로 API 호출] → [FastAPI 백엔드] → [NAS 파일 + DB]
```

## 📊 개발 진행 상황 (2025-01-09 업데이트)

### ✅ 완료된 작업
- **인프라**: 서버, 네트워킹, 파일 저장소 설정 ✅
- **프론트엔드 인증**: Firebase Auth, Riverpod 상태관리, 로그인/로그아웃 완료 ✅
- **백엔드 인증 시스템**: FastAPI + Firebase + JWT 완전 구현 ✅
- **JWT 토큰 교환**: Firebase → Backend JWT 연동 완료 ✅
- **역할 기반 UI**: admin/student/guest 화면 라우팅 완전 구현 ✅
- **권한 제어**: 이메일 기반 admin/student 자동 구분 및 UI 분기 ✅
- **API 설계**: 토큰 교환, 사용자 정보, 헬스체크 엔드포인트 ✅
- **보안 시스템**: CORS, 에러 핸들링, 입력 검증 완료 ✅

### 🎯 **현재 상태: 85% 완료** (2025-01-09 업데이트)
- **프론트엔드**: 85% ✅ (Role-based UI 라우팅 완료, Mock 데이터 UI)
- **백엔드**: 100% ✅ (완전한 FastAPI 인증 시스템 구현 완료)
- **인프라**: 100% ✅
- **데이터베이스**: 100% ✅

### 🔄 **다음 우선순위 작업**
1. **관리자/학생 화면 UI 개선**: 현재 Mock 데이터를 실제 기능으로 교체 (우선순위 1)
2. **실제 API 연동**: 파일 업로드/다운로드, 과목 관리 API 구현 (우선순위 2)
3. **프로덕션 배포 준비**: 성능 최적화, 보안 강화 (우선순위 3)

### 🎉 **최근 완료된 주요 구현 (2025-01-09)**
- **AuthenticatedUserState 모델**: Clean async state management 패턴
- **AppLayout 공통 컴포넌트**: Material Design 3 기반 일관된 UI
- **AdminScreen & StudentScreen**: 역할별 대시보드 및 기능 화면
- **API 응답 파싱 개선**: UserInfoResponse 모델로 올바른 권한 처리
- **관리자 계정 설정**: menamiji@pocheonil.hs.kr 관리자 권한 검증 완료

## 🔗 주요 URL

- **개발**: http://localhost:3000
- **프로덕션**: https://info.pocheonil.hs.kr/info_class/
- **API**: https://info.pocheonil.hs.kr/info_class/api/
- **서버 SSH**: `ssh menamiji@ubuntu` (Tailscale)

## 🚨 알려진 문제 및 해결 방법

### Google Sign-In 웹 환경
```dart
// 세션 정리 코드는 웹 호환성을 위해 필수
await _googleSignIn.signOut(); // 이전 세션 정리
```

### file_picker 플러그인 경고
```yaml
# pubspec.yaml - 버전 8.1.2+ 사용
file_picker: ^8.1.2  # DEBUG 콘솔 경고 해결됨
```

### Riverpod 코드 생성
```bash
# Provider 인식 안 될 때
dart run build_runner build --delete-conflicting-outputs
```

## 🔧 JWT 인증 트러블슈팅 가이드

**문제**: "Exception: 요청 처리 중 오류가 발생했습니다."

### 해결된 주요 문제들

#### 1. 백엔드 서버 미실행
```bash
# 문제: API 요청 실패
# 해결: Python 가상환경 설정 및 서버 시작
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

#### 2. 환경변수 누락 (.env 파일)
```bash
# 문제: SECRET_KEY environment variable is required
# 해결: .env 파일 생성
cd backend
echo "SECRET_KEY=$(openssl rand -hex 32)" > .env
echo "DEBUG=true" >> .env
echo "FIREBASE_PROJECT_ID=info-class-7398a" >> .env
```

#### 3. Python 상대 import 오류
```bash
# 문제: ImportError: attempted relative import beyond top-level package
# 해결: 모든 상대 import를 절대 import로 변경
find . -name "*.py" -exec sed -i 's/from \.\./from /g' {} \;
find . -name "*.py" -exec sed -i 's/from \./from /g' {} \;
```

#### 4. 누락된 종속성
```bash
# 문제: email-validator is not installed
# 해결: Pydantic 이메일 검증 패키지 설치
pip install pydantic[email]
```

#### 5. CORS 정책 위반
```python
# backend/config/settings.py
# 개발 모드에서 모든 origin 허용
ALLOWED_ORIGINS: List[str] = ["*"] if os.getenv("DEBUG", "False").lower() == "true" else [
    "https://info.pocheonil.hs.kr",
]
```

#### 6. Firebase Admin SDK 자격 증명 누락
```python
# backend/auth/firebase_validator.py
# 개발 모드 우회 기능 추가
if settings.DEBUG and not firebase_config.is_initialized():
    print("🔧 Development mode: Using mock Firebase token validation")
    return UserInfo(
        uid="dev_user_123",
        email="admin@pocheonil.hs.kr",
        name="개발자 계정",
        picture=None,
        email_verified=True
    )
```

### 진단 도구
```bash
# API 서버 상태 확인
curl http://localhost:8000/api/healthz

# 백엔드 로그 모니터링
cd backend && source venv/bin/activate && uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Flutter 앱 로그 확인 (Chrome 개발자 도구)
# Console 탭에서 네트워크 오류 및 인증 관련 메시지 확인
```

### 예방 방법
1. **환경 설정 체크리스트**: 새 개발 환경에서 .env 파일, 가상환경, 종속성 설치 확인
2. **개발 모드 설정**: DEBUG=true로 설정하여 Firebase 우회 및 CORS 완화 활성화
3. **로그 모니터링**: 백엔드와 프론트엔드 로그를 동시에 모니터링하여 빠른 문제 진단
4. **단계별 테스트**: 서버 → API → 인증 → JWT 교환 순서로 각 단계별 테스트 수행

### 추가 문서
- **상세 트러블슈팅**: `4_dev/401_info_class/JWT 인증 트러블슈팅 가이드.md` (Obsidian)
- **개발 가이드**: `CLAUDE.md` 프로젝트별 개발 지침

## 🏗 시스템 아키텍처

### 파일 저장 구조
```
/mnt/nas-info-class/
├── content/                 # 관리자 업로드 연습 파일
│   └── <과목>/<분류>/<항목>/
└── submissions/             # 학생 제출 파일
    └── <YYYYMMDD>/<학번>/
```

### 역할 기반 접근 제어
- **student**: 파일 다운로드, 과제 제출
- **teacher**: + 과제 확인, 평가 입력
- **admin**: + 전체 시스템 관리, 사용자 관리

## 📚 개발 가이드

상세한 개발 지침은 `CLAUDE.md`를 참조하세요:
- 🔧 개발 환경 설정
- 🏗 코딩 패턴 및 아키텍처
- 🧪 테스트 및 품질 관리
- 🚀 배포 및 인프라 관리

## 👥 기여하기

1. 기능 브랜치 생성: `git checkout -b feature/기능명`
2. 변경사항 커밋: `git commit -m "feat: 기능 설명"`
3. 테스트 실행: `flutter test && flutter analyze`
4. 풀 리퀘스트 생성

## 📄 라이선스

포천일고등학교 교육용 시스템 - 내부 사용 목적

---
**Version**: 2.0 (Role-based-UI-Complete)
**Last Updated**: 2025-01-09
**Status**: 🎯 85% Complete - 역할 기반 UI 라우팅 완료, 파일 관리 API 개발 단계