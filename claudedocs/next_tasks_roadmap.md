# Info Class 프로젝트 - 향후 작업 로드맵

**작성일**: 2025-09-19
**현재 진행률**: 40%
**목표 진행률**: 100% (완전한 파일 제출 시스템)

## 🎯 작업 우선순위 및 상세 계획

### Priority 1: 🔄 Flutter-Backend JWT 연동 (필수)
**예상 소요시간**: 1-2시간
**완료 후 진행률**: 40% → 60%

#### 구현 내용:
1. **API 클라이언트 생성**
   - `lib/shared/data/api_client.dart` 파일 생성
   - HTTP 클라이언트 설정 (base URL, timeout, interceptors)
   - JWT 토큰 자동 헤더 추가 기능

2. **토큰 교환 로직 구현**
   ```dart
   // lib/features/auth/data/auth_repository.dart
   Future<JWTResponse> exchangeFirebaseToken(String firebaseToken) async {
     final response = await apiClient.post('/auth/exchange', {
       'firebase_token': firebaseToken
     });
     return JWTResponse.fromJson(response.data);
   }
   ```

3. **AuthNotifier 업데이트**
   - Firebase 로그인 후 백엔드 JWT 교환 추가
   - JWT 토큰 로컬 저장 (SharedPreferences 또는 Secure Storage)
   - 자동 토큰 갱신 로직

4. **테스트 케이스**
   - 토큰 교환 성공/실패 시나리오
   - 만료된 토큰 갱신 테스트
   - 네트워크 오류 처리 테스트

#### 구현 순서:
1. API 클라이언트 기반 구조 생성
2. 토큰 교환 엔드포인트 연동
3. AuthNotifier에 통합
4. 에러 처리 및 테스트

---

### Priority 2: 🎨 역할 기반 UI 라우팅 (필수)
**예상 소요시간**: 1-2시간
**완료 후 진행률**: 60% → 75%

#### 구현 내용:
1. **역할별 홈 화면 생성**
   - `AdminHomePage`: 파일 업로드, 사용자 관리, 제출물 확인
   - `StudentHomePage`: 연습파일 다운로드, 과제 제출, 제출 이력

2. **라우팅 로직 구현**
   ```dart
   // lib/app/router.dart
   Widget _buildHomePage(UserRole role) {
     switch (role) {
       case UserRole.admin:
         return AdminHomePage();
       case UserRole.student:
         return StudentHomePage();
       default:
         return UnauthorizedPage();
     }
   }
   ```

3. **권한별 네비게이션 메뉴**
   - 관리자: 파일관리, 사용자관리, 제출물관리, 시스템설정
   - 학생: 과목선택, 과제제출, 제출이력, 프로필

4. **권한 가드 구현**
   - API 호출 전 권한 검증
   - 권한 없는 페이지 접근 시 리다이렉트

---

### Priority 3: 📁 파일 관리 API 구현 (핵심기능)
**예상 소요시간**: 3-4시간
**완료 후 진행률**: 75% → 90%

#### 백엔드 API 구현:
1. **과목 관리 엔드포인트**
   ```python
   # backend/api/subjects_routes.py
   @router.get("/subjects")
   async def get_subjects() -> APIResponse:
       # NAS에서 과목 디렉토리 목록 조회

   @router.get("/subjects/{subject_id}/contents")
   async def get_subject_contents(subject_id: str) -> APIResponse:
       # 특정 과목의 연습파일 목록
   ```

2. **파일 업로드/다운로드**
   ```python
   @router.post("/submissions/upload")
   async def upload_submission(
       files: List[UploadFile],
       date_key: str,
       current_user: User = Depends(get_current_user)
   ) -> APIResponse:
       # NAS에 학생 제출물 저장

   @router.get("/files/download/{file_path}")
   async def download_file(file_path: str) -> FileResponse:
       # NAS에서 파일 다운로드
   ```

3. **제출물 관리**
   ```python
   @router.get("/submissions")
   async def get_submissions(
       date_filter: Optional[str] = None,
       student_filter: Optional[str] = None
   ) -> APIResponse:
       # 제출물 목록 및 검색
   ```

#### 프론트엔드 구현:
1. **파일 선택 및 업로드 UI**
   - file_picker 패키지 활용
   - 업로드 진행률 표시
   - 다중 파일 선택 지원

2. **파일 목록 및 다운로드**
   - 과목별 연습파일 목록
   - 파일 미리보기 기능
   - 일괄 다운로드 지원

---

### Priority 4: 🧪 통합 테스트 및 품질 보증 (안정성)
**예상 소요시간**: 2-3시간
**완료 후 진행률**: 90% → 95%

#### 테스트 범위:
1. **E2E 테스트**
   - 로그인 → 파일다운로드 → 과제제출 전체 플로우
   - 관리자 권한으로 파일 업로드 및 관리

2. **API 통합 테스트**
   - 모든 엔드포인트 정상 동작 확인
   - 권한별 접근 제어 테스트
   - 에러 상황 처리 테스트

3. **성능 테스트**
   - 대용량 파일 업로드/다운로드
   - 동시 접속자 처리 능력
   - 응답 시간 측정

#### 품질 체크:
- Flutter `analyze` 통과
- 백엔드 `mypy` 타입 검사
- 보안 취약점 점검
- 사용자 경험 테스트

---

### Priority 5: 🚀 프로덕션 배포 및 운영 준비 (완성도)
**예상 소요시간**: 2-3시간
**완료 후 진행률**: 95% → 100%

#### 배포 환경 구성:
1. **Docker 컨테이너화**
   ```dockerfile
   # backend/Dockerfile
   FROM python:3.11-slim
   COPY requirements.txt .
   RUN pip install -r requirements.txt
   COPY . .
   CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
   ```

2. **nginx 프록시 설정**
   - Flutter 빌드 파일 서빙
   - API 요청 백엔드 프록시
   - SSL 인증서 적용

3. **환경 설정**
   - 프로덕션 환경변수 설정
   - Firebase 프로덕션 키 적용
   - 로그 레벨 및 모니터링 설정

#### 운영 준비:
- 에러 모니터링 (Sentry)
- 로그 수집 시스템
- 백업 및 복구 절차
- 사용자 가이드 문서

---

## 📅 단계별 실행 계획

### Week 1: 핵심 연동 (Priority 1-2)
- **Day 1-2**: Flutter-Backend JWT 연동
- **Day 3-4**: 역할 기반 UI 라우팅
- **Day 5**: 통합 테스트 및 버그 수정

### Week 2: 파일 시스템 (Priority 3)
- **Day 1-2**: 백엔드 파일 API 구현
- **Day 3-4**: 프론트엔드 파일 관리 UI
- **Day 5**: 파일 기능 통합 테스트

### Week 3: 완성 및 배포 (Priority 4-5)
- **Day 1-2**: 전체 시스템 테스트
- **Day 3-4**: 프로덕션 배포 준비
- **Day 5**: 최종 배포 및 사용자 테스트

---

## 🚨 주요 리스크 및 대응방안

### 기술적 리스크:
1. **Firebase 토큰 만료 처리**
   - 자동 갱신 로직 구현
   - 토큰 만료 시 재로그인 플로우

2. **대용량 파일 처리**
   - 파일 크기 제한 설정
   - 청크 업로드 구현 고려

3. **NAS 파일 시스템 권한**
   - 파일 권한 자동 설정
   - 백업 및 복구 계획

### 사용자 경험 리스크:
1. **네트워크 연결 불안정**
   - 오프라인 상태 감지
   - 재시도 메커니즘 구현

2. **파일 업로드 실패**
   - 업로드 재개 기능
   - 임시 저장 및 복구

---

## 📊 성공 지표

### 기능적 완성도:
- [ ] 모든 사용자 역할의 핵심 기능 동작
- [ ] 파일 업로드/다운로드 100% 성공률
- [ ] 인증 시스템 보안 검증 통과

### 성능 지표:
- [ ] 페이지 로딩 시간 < 3초
- [ ] 파일 업로드 속도 > 1MB/s
- [ ] 동시 접속자 50명 이상 지원

### 사용성 지표:
- [ ] 직관적인 UI/UX
- [ ] 모바일 반응형 지원
- [ ] 접근성 가이드라인 준수

---

**다음 작업 시작점**: Priority 1 - Flutter-Backend JWT 연동 구현
**권장 작업 순서**: 1 → 2 → 3 → 4 → 5
**전체 완성 예상 시간**: 12-16시간 (3주 분할 작업)