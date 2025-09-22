import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/authenticated_user_state.dart';

/// Common layout widget for role-based screens
///
/// Provides shared UI elements including:
/// - App bar with user information and logout
/// - Navigation appropriate to user role
/// - Consistent Material Design 3 styling
class AppLayout extends ConsumerWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const AppLayout({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.drawer,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticatedUserStateProvider);

    return Scaffold(
      appBar: _buildAppBar(context, ref, authState),
      drawer: drawer,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<AuthenticatedUserState> authState,
  ) {
    return AppBar(
      title: Text(title),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        // Custom actions if provided
        if (actions != null) ...actions!,

        // User profile and menu
        authState.when(
          data: (userState) => _buildUserMenu(context, ref, userState),
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Icon(Icons.error),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildUserMenu(
    BuildContext context,
    WidgetRef ref,
    AuthenticatedUserState userState,
  ) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            _showUserProfile(context, userState);
            break;
          case 'logout':
            await _handleLogout(ref);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person),
              const SizedBox(width: 8),
              Text('프로필'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, color: Colors.red),
              const SizedBox(width: 8),
              Text('로그아웃', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: _buildUserAvatar(userState),
    );
  }

  Widget _buildUserAvatar(AuthenticatedUserState userState) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: userState.isAdmin ? Colors.purple : Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              userState.role.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // User avatar
          CircleAvatar(
            radius: 18,
            backgroundImage: userState.photoURL != null
                ? NetworkImage(userState.photoURL!)
                : null,
            child: userState.photoURL == null
                ? Text(
                    userState.displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  void _showUserProfile(BuildContext context, AuthenticatedUserState userState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 프로필'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User avatar (larger)
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage: userState.photoURL != null
                    ? NetworkImage(userState.photoURL!)
                    : null,
                child: userState.photoURL == null
                    ? Text(
                        userState.displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            // User information
            _buildProfileRow('이름', userState.displayName),
            _buildProfileRow('이메일', userState.email ?? '정보 없음'),
            _buildProfileRow('역할', userState.role.displayName),
            if (userState.backendUser?.uid != null)
              _buildProfileRow('사용자 ID', userState.backendUser!.uid),
            if (userState.isSchoolUser)
              const Chip(
                label: Text('교내 사용자'),
                backgroundColor: Colors.green,
                labelStyle: TextStyle(color: Colors.white),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(WidgetRef ref) async {
    try {
      await ref.read(authNotifierProvider.notifier).signOut();
    } catch (e) {
      // Error handling could be improved with snackbar
      debugPrint('Logout error: $e');
    }
  }
}

/// Common loading screen for authentication state
class AuthLoadingScreen extends StatelessWidget {
  final String? message;

  const AuthLoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message ?? '인증 정보를 확인하는 중...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// Common error screen for authentication failures
class AuthErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const AuthErrorScreen({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                '인증 오류',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('다시 시도'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}