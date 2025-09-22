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
    return MaterialApp.router(
      title: 'Info Class',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: _router,
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
    final currentPath = GoRouterState.of(context).uri.path;

    return authState.when(
      data: (firebaseUser) {
        if (firebaseUser == null) {
          return const LoginPage();
        }

        // User is authenticated, now check role and route appropriately
        return FutureBuilder<UserRole>(
          future: ref.read(userRoleProvider.future),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AuthLoadingScreen(
                message: '사용자 권한을 확인하는 중...',
              );
            }

            if (snapshot.hasError) {
              return AuthErrorScreen(
                error: '권한 확인 중 오류 발생: ${snapshot.error}',
                onRetry: () {
                  ref.invalidate(userRoleProvider);
                },
              );
            }

            final role = snapshot.data ?? UserRole.guest;

            // Route based on current path and user role
            return _routeBasedOnPathAndRole(context, currentPath, role, firebaseUser, ref);
          },
        );
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

  Widget _routeBasedOnPathAndRole(
    BuildContext context,
    String path,
    UserRole role,
    User firebaseUser,
    WidgetRef ref
  ) {
    switch (path) {
      case '/':
        // Root path - redirect to portal for authenticated users
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/portal');
        });
        return const AuthLoadingScreen(message: '포털로 이동 중...');

      case '/portal':
        return const PortalScreen();

      case '/info':
        // 정보 수업 시스템 - 기존 role-based routing 유지
        switch (role) {
          case UserRole.admin:
            return const AdminScreen();
          case UserRole.student:
            return const StudentScreen();
          case UserRole.guest:
            return _buildGuestScreen(context, ref, firebaseUser, role);
        }

      case '/library':
      case '/grade':
        // 향후 구현될 시스템들 - 임시로 포털로 리다이렉트
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/portal');
        });
        return const AuthLoadingScreen(message: '시스템 준비 중...');

      default:
        // 알 수 없는 경로 - 포털로 리다이렉트
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/portal');
        });
        return const AuthLoadingScreen(message: '포털로 이동 중...');
    }
  }

  /// Screen for guest users or users with unrecognized roles
  Widget _buildGuestScreen(
    BuildContext context,
    WidgetRef ref,
    User firebaseUser,
    UserRole role,
  ) {
    return AppLayout(
      title: '정보 수업',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                '환영합니다!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '안녕하세요, ${firebaseUser.displayName ?? '사용자'}님!',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                '현재 계정에 할당된 역할이 없습니다.\n관리자에게 문의하여 적절한 권한을 요청하세요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '계정 정보',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('이메일: ${firebaseUser.email ?? '정보 없음'}'),
                      Text('역할: ${role.displayName}'),
                      if (firebaseUser.email?.endsWith('@pocheonil.hs.kr') == true)
                        const Text('상태: 교내 사용자 ✓')
                      else
                        const Text('상태: 외부 사용자'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(userRoleProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('권한 새로고침'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

