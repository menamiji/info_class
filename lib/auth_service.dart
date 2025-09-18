import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<User?> signInWithGoogle() async {
    try {
      // Google 로그인 초기화 확인
      await _googleSignIn.signOut(); // 이전 세션 정리

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // 사용자가 로그인을 취소함
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 웹에서는 idToken이 없을 수 있으므로 accessToken만으로도 시도
      if (googleAuth.accessToken == null) {
        throw Exception('Google 액세스 토큰을 가져올 수 없습니다.');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken, // idToken이 null이어도 괜찮음
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Firebase 인증 관련 오류
      throw Exception('Firebase 인증 오류: ${e.message}');
    } catch (e) {
      // 기타 오류
      throw Exception('로그인 처리 중 오류 발생: $e');
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}