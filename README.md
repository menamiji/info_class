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

## 📊 개발 진행 상황

### ✅ 완료된 작업
- **인프라**: 서버, 네트워킹, 파일 저장소 설정
- **프론트엔드 기반**: Flutter 프로젝트, Firebase 인증, 의존성 설정
- **코드 정리**: Google Sign-In 최적화, 테스트 인프라, 의존성 업데이트
- **품질 보증**: 모든 분석 및 테스트 통과

### 🔄 진행 중
- **인증 구현**: 로그인/로그아웃 화면, 상태 관리, 역할 기반 라우팅

### ❌ 예정된 작업
- **파일 관리**: 업로드/다운로드, 과목별 컨텐츠 관리
- **백엔드**: FastAPI, JWT 검증, 파일 작업 API
- **데이터베이스**: Supabase PostgreSQL 스키마 및 연동

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
**Version**: 1.0 (Cleanup-Complete)
**Last Updated**: 2025-01-09
**Status**: 🔄 Phase 1 Authentication Implementation Ready