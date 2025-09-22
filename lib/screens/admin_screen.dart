import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/common/app_layout.dart';
import '../providers/auth_provider.dart';

/// Admin screen for teachers and administrators
///
/// Provides access to:
/// - Subject management
/// - Content upload and management
/// - Student submission management
/// - User role management
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticatedUserStateProvider);

    return authState.when(
      data: (userState) {
        if (!userState.isAdmin) {
          return _buildAccessDenied(context);
        }

        return AppLayout(
          title: '관리자 대시보드',
          body: _buildAdminContent(context, ref, userState),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Refresh data
                ref.invalidate(authenticatedUserStateProvider);
              },
              tooltip: '새로고침',
            ),
          ],
        );
      },
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
              Text('관리자 정보를 불러올 수 없습니다'),
              Text(error.toString()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('접근 거부'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              '관리자 권한이 필요합니다',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '이 페이지에 접근하려면 관리자 권한이 필요합니다.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminContent(
    BuildContext context,
    WidgetRef ref,
    dynamic userState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          _buildWelcomeCard(context, userState),
          const SizedBox(height: 24),

          // Quick stats
          _buildQuickStats(context),
          const SizedBox(height: 24),

          // Main admin functions
          Text(
            '관리 기능',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildAdminFunctions(context),
          const SizedBox(height: 24),

          // Recent activity
          Text(
            '최근 활동',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildRecentActivity(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, dynamic userState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '안녕하세요, ${userState.displayName}님!',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '관리자 대시보드에 오신 것을 환영합니다.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '이메일: ${userState.email}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            '활성 과목',
            '4',
            Icons.subject,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            '등록 학생',
            '28',
            Icons.people,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            '제출물',
            '156',
            Icons.assignment,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminFunctions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildFunctionCard(
          context,
          '과목 관리',
          '과목 생성, 편집 및 관리',
          Icons.book,
          Colors.blue,
          () => _showComingSoon(context, '과목 관리'),
        ),
        _buildFunctionCard(
          context,
          '콘텐츠 업로드',
          '수업 자료 및 과제 업로드',
          Icons.upload_file,
          Colors.green,
          () => _showComingSoon(context, '콘텐츠 업로드'),
        ),
        _buildFunctionCard(
          context,
          '제출물 관리',
          '학생 제출물 확인 및 관리',
          Icons.assignment_turned_in,
          Colors.orange,
          () => _showComingSoon(context, '제출물 관리'),
        ),
        _buildFunctionCard(
          context,
          '사용자 관리',
          '학생 및 권한 관리',
          Icons.manage_accounts,
          Colors.purple,
          () => _showComingSoon(context, '사용자 관리'),
        ),
      ],
    );
  }

  Widget _buildFunctionCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildActivityItem(
            context,
            '학생 김철수가 과제를 제출했습니다',
            '5분 전',
            Icons.assignment_turned_in,
            Colors.green,
          ),
          const Divider(height: 1),
          _buildActivityItem(
            context,
            '새로운 학생이 등록되었습니다',
            '1시간 전',
            Icons.person_add,
            Colors.blue,
          ),
          const Divider(height: 1),
          _buildActivityItem(
            context,
            '스프레드시트 과제가 업로드되었습니다',
            '2시간 전',
            Icons.upload_file,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text(time),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showComingSoon(context, '활동 세부사항'),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature 기능은 곧 추가될 예정입니다!'),
        action: SnackBarAction(
          label: '확인',
          onPressed: () {},
        ),
      ),
    );
  }
}