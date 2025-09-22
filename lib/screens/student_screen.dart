import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/common/app_layout.dart';
import '../providers/auth_provider.dart';

/// Student screen for accessing course materials and submitting assignments
///
/// Provides access to:
/// - Course selection and materials download
/// - Assignment submission
/// - Submission history
/// - Personal dashboard
class StudentScreen extends ConsumerWidget {
  const StudentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticatedUserStateProvider);

    return authState.when(
      data: (userState) {
        if (!userState.isStudent && !userState.isAdmin) {
          return _buildAccessDenied(context);
        }

        return AppLayout(
          title: '학생 대시보드',
          body: _buildStudentContent(context, ref, userState),
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
              Text('학생 정보를 불러올 수 없습니다'),
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
              '학생 권한이 필요합니다',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '이 페이지에 접근하려면 학생 권한이 필요합니다.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentContent(
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

          // Quick actions
          _buildQuickActions(context),
          const SizedBox(height: 24),

          // Available subjects
          Text(
            '수강 과목',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildSubjectsList(context),
          const SizedBox(height: 24),

          // Recent submissions
          Text(
            '최근 제출물',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildRecentSubmissions(context),
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
              Icons.school,
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
                    '오늘도 열심히 공부해봅시다!',
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

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            '과제 제출',
            '새 과제 제출하기',
            Icons.upload_file,
            Colors.blue,
            () => _showComingSoon(context, '과제 제출'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            context,
            '자료 다운로드',
            '수업 자료 받기',
            Icons.download,
            Colors.green,
            () => _showComingSoon(context, '자료 다운로드'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
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
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectsList(BuildContext context) {
    // Mock data - will be replaced with actual API calls
    final subjects = [
      {
        'name': '정보처리와관리',
        'description': '스프레드시트, 데이터베이스 활용',
        'assignments': 3,
        'materials': 8,
        'color': Colors.blue,
      },
      {
        'name': '프로그래밍',
        'description': 'Python 기초부터 응용까지',
        'assignments': 5,
        'materials': 12,
        'color': Colors.green,
      },
      {
        'name': '컴퓨터구조',
        'description': '하드웨어와 시스템 이해',
        'assignments': 2,
        'materials': 6,
        'color': Colors.orange,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (subject['color'] as Color).withOpacity(0.1),
              child: Icon(
                Icons.book,
                color: subject['color'] as Color,
              ),
            ),
            title: Text(
              subject['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject['description'] as String),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.assignment, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '과제 ${subject['assignments']}개',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.folder, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '자료 ${subject['materials']}개',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showComingSoon(context, subject['name'] as String),
          ),
        );
      },
    );
  }

  Widget _buildRecentSubmissions(BuildContext context) {
    // Mock data - will be replaced with actual API calls
    final submissions = [
      {
        'title': '스프레드시트 기본 과제',
        'subject': '정보처리와관리',
        'date': '2025-09-20',
        'status': '제출 완료',
        'statusColor': Colors.green,
      },
      {
        'title': 'Python 반복문 연습',
        'subject': '프로그래밍',
        'date': '2025-09-18',
        'status': '검토 중',
        'statusColor': Colors.orange,
      },
      {
        'title': 'CPU 구조 분석',
        'subject': '컴퓨터구조',
        'date': '2025-09-15',
        'status': '평가 완료',
        'statusColor': Colors.blue,
      },
    ];

    return Card(
      child: Column(
        children: submissions.map<Widget>((submission) {
          final isLast = submission == submissions.last;
          return Column(
            children: [
              ListTile(
                leading: const Icon(Icons.assignment_turned_in),
                title: Text(submission['title'] as String),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('과목: ${submission['subject']}'),
                    Text('제출일: ${submission['date']}'),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (submission['statusColor'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    submission['status'] as String,
                    style: TextStyle(
                      color: submission['statusColor'] as Color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () => _showComingSoon(context, '제출물 세부사항'),
              ),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
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