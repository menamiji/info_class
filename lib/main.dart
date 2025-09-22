import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'login_page.dart';
import 'screens/admin_screen.dart';
import 'screens/student_screen.dart';
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
      home: const AuthRouter(),
    );
  }
}

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

        // User is authenticated, now check role
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

            // Route based on user role
            switch (role) {
              case UserRole.admin:
                return const AdminScreen();
              case UserRole.student:
                return const StudentScreen();
              case UserRole.guest:
                // Guest users or unknown roles get a limited interface
                return _buildGuestScreen(context, ref, firebaseUser, role);
            }
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

