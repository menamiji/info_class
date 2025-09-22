import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/common/app_layout.dart';
import '../shared/models/backend_user.dart';
import '../providers/auth_provider.dart';

class PortalScreen extends ConsumerWidget {
  const PortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRoleAsync = ref.watch(userRoleProvider);

    return userRoleAsync.when(
      data: (userRole) => _buildPortalContent(context, userRole),
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('권한 확인 중 오류 발생: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userRoleProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortalContent(BuildContext context, UserRole userRole) {
    return AppLayout(
      title: '포천일고 통합 시스템',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context, userRole),
            const SizedBox(height: 32),
            _buildSystemGrid(context, userRole),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, UserRole userRole) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Icon(
              _getRoleIcon(userRole),
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '환영합니다!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '역할: ${userRole.displayName}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '사용하실 시스템을 선택해주세요.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemGrid(BuildContext context, UserRole userRole) {
    final systems = _getAvailableSystems(userRole);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: systems.length,
      itemBuilder: (context, index) {
        final system = systems[index];
        return _buildSystemCard(context, system);
      },
    );
  }

  Widget _buildSystemCard(BuildContext context, SystemInfo system) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: system.enabled
          ? () => context.go(system.route)
          : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                system.icon,
                size: 48,
                color: system.enabled
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                system.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: system.enabled ? null : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                system.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: system.enabled ? null : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!system.enabled) ...[
                const SizedBox(height: 8),
                Text(
                  '접근 권한 없음',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<SystemInfo> _getAvailableSystems(UserRole userRole) {
    return [
      SystemInfo(
        title: '파일 제출 시스템',
        description: '과제 및 연습 파일 관리',
        icon: Icons.upload_file,
        route: '/info',
        enabled: [UserRole.admin, UserRole.student].contains(userRole),
      ),
      SystemInfo(
        title: '도서관 시스템',
        description: '도서 검색 및 대출 관리',
        icon: Icons.library_books,
        route: '/library',
        enabled: [UserRole.admin, UserRole.student].contains(userRole),
      ),
      SystemInfo(
        title: '성적 관리 시스템',
        description: '성적 입력 및 조회',
        icon: Icons.grade,
        route: '/grade',
        enabled: [UserRole.admin].contains(userRole),
      ),
      SystemInfo(
        title: '관리자 도구',
        description: '시스템 관리 및 설정',
        icon: Icons.admin_panel_settings,
        route: '/admin',
        enabled: [UserRole.admin].contains(userRole),
      ),
    ];
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.student:
        return Icons.school;
      case UserRole.guest:
        return Icons.person_outline;
    }
  }
}

class SystemInfo {
  final String title;
  final String description;
  final IconData icon;
  final String route;
  final bool enabled;

  SystemInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
    required this.enabled,
  });
}