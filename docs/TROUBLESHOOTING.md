# Firebase Google Sign-In 트러블슈팅 가이드

## 🔥 Google Sign-In 웹 환경 idToken 문제

### 문제 증상
```
Exception: Google 인증 토큰을 가져올 수 없습니다.
```

### 근본 원인
웹 환경에서 Google Identity Services API는 `idToken`을 항상 제공하지 않습니다. `accessToken`만 제공되는 경우가 있으며, 이는 정상적인 동작입니다.

### 해결 방법

**❌ 문제가 있던 코드:**
```dart
// 너무 엄격한 토큰 검증
if (googleAuth.accessToken == null || googleAuth.idToken == null) {
  throw Exception('Google 인증 토큰을 가져올 수 없습니다.');
}
```

**✅ 수정된 코드:**
```dart
// 웹 환경을 고려한 유연한 검증
if (googleAuth.accessToken == null) {
  throw Exception('Google 액세스 토큰을 가져올 수 없습니다.');
}
// idToken이 null이어도 Firebase가 처리 가능
```

**완전한 해결 코드 (lib/auth_service.dart):**
```dart
static Future<User?> signInWithGoogle() async {
  try {
    await _googleSignIn.signOut(); // 이전 세션 정리
    
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    // 웹에서는 accessToken만 확인
    if (googleAuth.accessToken == null) {
      throw Exception('Google 액세스 토큰을 가져올 수 없습니다.');
    }
    
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken, // null이어도 괜찮음
    );
    
    final UserCredential result = await _auth.signInWithCredential(credential);
    return result.user;
  } catch (e) {
    throw Exception('로그인 처리 중 오류 발생: $e');
  }
}
```

## 🔧 Firebase 프로젝트 설정 체크리스트

### 1. Firebase Console 설정
- [ ] **Authentication > Sign-in method > Google** 활성화
- [ ] **승인된 도메인**에 `localhost` 추가
- [ ] **웹 SDK 구성**에서 클라이언트 ID 확인

### 2. Google Cloud Console 설정
- [ ] **OAuth 동의 화면** 설정 (외부, 테스트 모드)
- [ ] **People API 활성화**: https://console.cloud.google.com/apis/library/people.googleapis.com
- [ ] **OAuth 2.0 클라이언트 ID**에 승인된 JavaScript 원본 추가:
  - `http://localhost`
  - `http://localhost:3000`
  - `http://localhost:5000`
- [ ] **테스트 사용자**에 로그인할 Google 계정 추가

### 3. 프로젝트 파일 설정
- [ ] **web/index.html**에 Google Client ID 추가:
  ```html
  <meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">
  ```
- [ ] **Firebase SDK 스크립트** 추가:
  ```html
  <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-auth-compat.js"></script>
  ```

## 🚨 자주 발생하는 에러들

### 1. People API 비활성화
```
ClientException: { "error": { "code": 403, "message": "People API has not been used" } }
```

**해결방법:**
- Google Cloud Console에서 People API 활성화
- https://console.cloud.google.com/apis/library/people.googleapis.com?project=PROJECT_ID

### 2. Client ID 불일치
```
Exception: ClientException: assertion failed: file:///.../google_sign_in_web.dart:144:9
```

**해결방법:**
- web/index.html의 Client ID와 Firebase 프로젝트의 Client ID 일치 확인
- OAuth 2.0 클라이언트 ID에서 올바른 웹 클라이언트 ID 복사

### 3. OAuth 동의 화면 미설정
```
OAuth 개요: No data is available for this project
```

**해결방법:**
1. Google Cloud Console > OAuth 동의 화면
2. 외부 선택 > 만들기
3. 앱 이름, 사용자 지원 이메일 입력
4. 테스트 사용자에 로그인할 계정 추가

## 🔍 디버깅 팁

### 1. 브라우저 개발자 도구 활용
- **F12** > **Console** 탭에서 Google Sign-In 로그 확인
- `[GSI_LOGGER]` 메시지들 분석
- 실제 토큰 응답 내용 확인

### 2. Firebase 콘솔에서 확인
- **Authentication > Users** 탭에서 사용자 등록 여부 확인
- 로그인 성공 시 사용자가 목록에 나타나야 함

### 3. 로그 분석
```javascript
// 정상적인 로그 예시
[GSI_LOGGER-TOKEN_CLIENT]: Handling response. {
  "access_token": "ya29.a0AQQ...",
  "token_type": "Bearer",
  "expires_in": 3599,
  // idToken이 없어도 정상
}
```

## ⚠️ 정상적인 경고 메시지들

### 1. 사용 중단 경고 (무시 가능)
```
The google_sign_in plugin `signIn` method is deprecated on the web
```
- 현재 정상 작동, 향후 `renderButton` 방식으로 마이그레이션 권장

### 2. CORS 경고 (무시 가능)
```
Cross-Origin-Opener-Policy policy would block the window.closed call
```
- 브라우저 보안 정책 관련, 기능에는 영향 없음

## 📝 핵심 교훈

1. **웹 환경 특성**: 모바일과 달리 `idToken`이 항상 제공되지 않음
2. **Firebase 호환성**: `accessToken`만으로도 인증 가능
3. **방어적 코딩**: 플랫폼별 차이점을 고려한 유연한 에러 처리
4. **설정 체크**: Google Cloud Console과 Firebase Console 양쪽 모두 확인 필요

## 🔗 참고 링크

- [Google Identity Services Migration Guide](https://developers.google.com/identity/gsi/web/guides/migration)
- [Flutter Google Sign-In Web Plugin](https://pub.dev/packages/google_sign_in_web)
- [Firebase Auth Web Guide](https://firebase.google.com/docs/auth/web/google-signin)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Firebase Console](https://console.firebase.google.com/)

---
**최종 업데이트**: 2025-01-09  
**프로젝트**: info_class (Flutter Web + Firebase Auth)