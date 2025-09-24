import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/database_service.dart';
import '../../models/issue_model.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../shared/issue_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CivicX'),
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

          final issues = snapshot.data ?? [];
          final filteredIssues = _selectedCategory == 'All'
              ? issues
              : issues.where((issue) => issue.category == _selectedCategory).toList();

          if (filteredIssues.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: AppConstants.mediumSpacing),
                  Text(
                    _selectedCategory == 'All' 
                        ? 'No issues reported yet'
                        : 'No $_selectedCategory issues found',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppConstants.smallSpacing),
                  Text(
                    'Be the first to report a civic issue in your community',
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
              itemCount: filteredIssues.length,
              padding: const EdgeInsets.symmetric(vertical: AppConstants.smallSpacing),
              itemBuilder: (context, index) {
                final issue = filteredIssues[index];
                return IssueCard(
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
        },
      ),
    );
  }
}

class IssueCard extends StatelessWidget {
  final IssueModel issue;
  final VoidCallback onTap;

  const IssueCard({
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
              // Header with category and status
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
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.error)),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: AppConstants.mediumSpacing),
              
              // Footer with location, date, and upvotes
              Row(
                children: [
                  if (issue.location != null) ...[
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        issue.address ??
                            issue.location!.address ??
                            'Lat: ${issue.location!.latitude.toStringAsFixed(4)}, Lng: ${issue.location!.longitude.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else ...[
                    const Expanded(child: SizedBox()),
                  ],
                  
                  Text(
                    Helpers.getRelativeTime(issue.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(width: AppConstants.mediumSpacing),
                  
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
    );
  }
}