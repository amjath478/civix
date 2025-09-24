import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/database_service.dart';
import '../../models/issue_model.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../shared/issue_detail_screen.dart';

class AdminIssuesScreen extends StatefulWidget {
  const AdminIssuesScreen({super.key});

  @override
  State<AdminIssuesScreen> createState() => _AdminIssuesScreenState();
}

class _AdminIssuesScreenState extends State<AdminIssuesScreen> with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;
  String _selectedCategory = 'All';

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

  List<IssueModel> _filterIssues(List<IssueModel> issues, String status) {
    List<IssueModel> filteredByStatus = status == 'All' 
        ? issues 
        : issues.where((issue) => issue.status == status).toList();

    if (_selectedCategory == 'All') {
      return filteredByStatus;
    }

    return filteredByStatus.where((issue) => issue.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Issues'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedCategory,
            onSelected: (value) => setState(() => _selectedCategory = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Categories')),
              ...AppConstants.issueCategories.map(
                (category) => PopupMenuItem(
                  value: category,
                  child: Text(category),
                ),
              ),
            ],
            child: const Icon(Icons.filter_list),
          ),
        ],
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
        stream: _databaseService.getAllIssues(),
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
              _buildIssuesList(_filterIssues(allIssues, 'All'), 'All'),
              _buildIssuesList(_filterIssues(allIssues, 'Pending'), 'Pending'),
              _buildIssuesList(_filterIssues(allIssues, 'In Progress'), 'In Progress'),
              _buildIssuesList(_filterIssues(allIssues, 'Resolved'), 'Resolved'),
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
              _selectedCategory == 'All' && status == 'All' 
                  ? 'No issues found'
                  : _selectedCategory == 'All'
                      ? 'No $status issues found'
                      : 'No $_selectedCategory issues with $status status',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
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
          return AdminIssueCard(
            issue: issue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IssueDetailScreen(
                  issue: issue,
                  isAdmin: true,
                ),
              ),
            ),
            onStatusChanged: (newStatus) => _updateIssueStatus(issue.id, newStatus),
          );
        },
      ),
    );
  }

  Future<void> _updateIssueStatus(String issueId, String newStatus) async {
    try {
      await _databaseService.updateIssueStatus(issueId, newStatus);
      if (mounted) {
        Helpers.showSnackBar(context, 'Issue status updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to update status: ${e.toString()}', isError: true);
      }
    }
  }
}

class AdminIssueCard extends StatelessWidget {
  final IssueModel issue;
  final VoidCallback onTap;
  final Function(String) onStatusChanged;

  const AdminIssueCard({
    super.key,
    required this.issue,
    required this.onTap,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppConstants.mediumRadius),
              topRight: Radius.circular(AppConstants.mediumRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with category and current status
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
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              issue.category,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
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
                  
                  // Description
                  Text(
                    issue.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                    maxLines: 3,
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
                  
                  // Footer with info
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              Helpers.getRelativeTime(issue.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.thumb_up, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            issue.upvotes.toString(),
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
          
          // Status update buttons
          if (issue.status != 'Resolved') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppConstants.smallSpacing),
              child: Row(
                children: [
                  if (issue.status == 'Pending') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onStatusChanged('In Progress'),
                        icon: const Icon(Icons.build, size: 16),
                        label: const Text('Start Progress'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.smallSpacing),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onStatusChanged('Resolved'),
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(issue.status == 'Pending' ? 'Mark Resolved' : 'Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}