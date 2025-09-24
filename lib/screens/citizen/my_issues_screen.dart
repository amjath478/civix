import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/database_service.dart';
import '../../models/issue_model.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../shared/issue_detail_screen.dart';

class MyIssuesScreen extends StatefulWidget {
  const MyIssuesScreen({super.key});

  @override
  State<MyIssuesScreen> createState() => _MyIssuesScreenState();
}

class _MyIssuesScreenState extends State<MyIssuesScreen> with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<IssueModel> _filterIssuesByStatus(List<IssueModel> issues, String status) {
    if (status == 'All') return issues;
    return issues.where((issue) => issue.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your issues'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Issues'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: StreamBuilder<List<IssueModel>>(
        stream: _databaseService.getUserIssues(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: AppConstants.mediumSpacing),
                  Text(
                    'Error loading issues',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppConstants.smallSpacing),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final allIssues = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildIssuesList(allIssues, 'All'),
              _buildIssuesList(_filterIssuesByStatus(allIssues, 'Pending'), 'Pending'),
              _buildIssuesList(_filterIssuesByStatus(allIssues, 'In Progress'), 'In Progress'),
              _buildIssuesList(_filterIssuesByStatus(allIssues, 'Resolved'), 'Resolved'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIssuesList(List<IssueModel> issues, String status) {
    if (issues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: AppConstants.mediumSpacing),
            Text(
              status == 'All' 
                  ? 'No issues reported yet'
                  : 'No $status issues',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppConstants.smallSpacing),
            Text(
              status == 'All'
                  ? 'Start reporting civic issues in your community'
                  : 'Issues with $status status will appear here',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh is handled automatically by the stream
      },
      child: ListView.builder(
        itemCount: issues.length,
        padding: const EdgeInsets.symmetric(vertical: AppConstants.smallSpacing),
        itemBuilder: (context, index) {
          final issue = issues[index];
          return MyIssueCard(
            issue: issue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IssueDetailScreen(issue: issue),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MyIssueCard extends StatelessWidget {
  final IssueModel issue;
  final VoidCallback onTap;

  const MyIssueCard({
    super.key,
    required this.issue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.mediumSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.smallSpacing,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Helpers.getStatusColor(issue.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Helpers.getStatusIcon(issue.status),
                          size: 16,
                          color: Helpers.getStatusColor(issue.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          issue.status,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Helpers.getStatusColor(issue.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    Helpers.getRelativeTime(issue.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppConstants.mediumSpacing),
              
              // Title
              Text(
                issue.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: AppConstants.smallSpacing),
              
              // Category and description
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.smallSpacing,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Helpers.getCategoryIcon(issue.category),
                          size: 14,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          issue.category,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppConstants.smallSpacing),
              
              Text(
                issue.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              if (issue.imageUrl != null) ...[
                const SizedBox(height: AppConstants.mediumSpacing),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                  child: CachedNetworkImage(
                    imageUrl: issue.imageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 120,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 120,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.error)),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: AppConstants.mediumSpacing),
              
              // Footer with upvotes
              Row(
                children: [
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.thumb_up, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${issue.upvotes} upvote${issue.upvotes != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}