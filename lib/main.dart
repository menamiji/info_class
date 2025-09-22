import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'login_page.dart';
import 'screens/admin_screen.dart';
import 'screens/student_screen.dart';
import 'screens/portal_screen.dart';
import 'widgets/common/app_layout.dart';
import 'shared/models/backend_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Info Class',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthRouter(), // 간단한 라우팅
    );
  }
}

// GoRouter 설정
final _router = GoRouter(
  routes: [
    // 루트 경로 - 포털 또는 로그인
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthRouter(),
    ),
    // 포털 화면
    GoRoute(
      path: '/portal',
      builder: (context, state) => const PortalScreen(),
    ),
    // 정보 수업 시스템
    GoRoute(
      path: '/info',
      builder: (context, state) => const AuthRouter(),
    ),
    // 향후 추가될 시스템들
    GoRoute(
      path: '/library',
      builder: (context, state) => const AuthRouter(), // 임시로 AuthRouter 사용
    ),
    GoRoute(
      path: '/grade',
      builder: (context, state) => const AuthRouter(), // 임시로 AuthRouter 사용
    ),
  ],
);

class AuthRouter extends ConsumerWidget {
  const AuthRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      data: (firebaseUser) {
        if (firebaseUser == null) {
          return const LoginPage();
        }

        // 인증된 사용자 - 포털 화면으로 이동
        return const PortalScreen();
      },
      loading: () => const AuthLoadingScreen(
        message: '로그인을 확인하는 중...',
      ),
      error: (error, stackTrace) => AuthErrorScreen(
        error: error.toString(),
        onRetry: () {
          // Refresh authentication state
          ref.invalidate(authNotifierProvider);
        },
      ),
    );
  }

}

