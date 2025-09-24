import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/issue_model.dart';
import '../../models/user_model.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class IssueDetailScreen extends StatefulWidget {
  final IssueModel issue;
  final bool isAdmin;

  const IssueDetailScreen({
    super.key,
    required this.issue,
    this.isAdmin = false,
  });

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  
  late IssueModel _issue;
  UserModel? _issueCreator;
  bool _isLoadingCreator = true;
  bool _isUpdatingStatus = false;
  bool _isUpvoting = false;

  @override
  void initState() {
    super.initState();
    _issue = widget.issue;
    _loadIssueCreator();
  }

  Future<void> _loadIssueCreator() async {
    try {
      final creator = await _authService.getUserData(_issue.createdBy);
      setState(() {
        _issueCreator = creator;
        _isLoadingCreator = false;
      });
    } catch (e) {
      setState(() => _isLoadingCreator = false);
    }
  }

  Future<void> _toggleUpvote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isUpvoting = true);

    try {
      await _databaseService.toggleUpvote(_issue.id, user.uid);
      
      // Update local state optimistically
      final hasUpvoted = _issue.upvotedBy.contains(user.uid);
      setState(() {
        if (hasUpvoted) {
          _issue = _issue.copyWith(
            upvotes: _issue.upvotes > 0 ? _issue.upvotes - 1 : 0,
            upvotedBy: _issue.upvotedBy.where((id) => id != user.uid).toList(),
          );
        } else {
          _issue = _issue.copyWith(
            upvotes: _issue.upvotes + 1,
            upvotedBy: [..._issue.upvotedBy, user.uid],
          );
        }
      });

      if (mounted) {
        Helpers.showSnackBar(
          context, 
          hasUpvoted ? 'Upvote removed' : 'Upvote added',
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to update upvote: ${e.toString()}', isError: true);
      }
    } finally {
      setState(() => _isUpvoting = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdatingStatus = true);

    try {
      await _databaseService.updateIssueStatus(_issue.id, newStatus);
      setState(() {
        _issue = _issue.copyWith(status: newStatus);
      });

      if (mounted) {
        Helpers.showSnackBar(context, 'Status updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to update status: ${e.toString()}', isError: true);
      }
    } finally {
      setState(() => _isUpdatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final hasUpvoted = user != null && _issue.upvotedBy.contains(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Details'),
        actions: widget.isAdmin && _issue.status != 'Resolved' ? [
          PopupMenuButton<String>(
            onSelected: (status) => _updateStatus(status),
            itemBuilder: (context) => [
              if (_issue.status == 'Pending')
                const PopupMenuItem(
                  value: 'In Progress',
                  child: Row(
                    children: [
                      Icon(Icons.build, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Mark In Progress'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'Resolved',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Mark Resolved'),
                  ],
                ),
              ),
            ],
          ),
        ] : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            if (_issue.imageUrl != null)
              CachedNetworkImage(
                imageUrl: _issue.imageUrl!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.error, size: 64)),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(AppConstants.mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and category badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.mediumSpacing,
                          vertical: AppConstants.smallSpacing,
                        ),
                        decoration: BoxDecoration(
                          color: Helpers.getStatusColor(_issue.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Helpers.getStatusIcon(_issue.status),
                              size: 18,
                              color: Helpers.getStatusColor(_issue.status),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _issue.status,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Helpers.getStatusColor(_issue.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppConstants.smallSpacing),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.mediumSpacing,
                          vertical: AppConstants.smallSpacing,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Helpers.getCategoryIcon(_issue.category),
                              size: 18,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _issue.category,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppConstants.largeSpacing),

                  // Title
                  Text(
                    _issue.title,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: AppConstants.mediumSpacing),

                  // Description
                  Text(
                    _issue.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: AppConstants.largeSpacing),

                  // Location section
                  if (_issue.location != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.red),
                                const SizedBox(width: AppConstants.smallSpacing),
                                Text(
                                  'Location',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.smallSpacing),
                            Text(
                              _issue.address ?? _issue.location!.address ??
                                  'Lat: ${_issue.location!.latitude.toStringAsFixed(6)}, Lng: ${_issue.location!.longitude.toStringAsFixed(6)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.mediumSpacing),
                  ],

                  // Issue info section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Issue Information',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppConstants.mediumSpacing),
                          
                          _buildInfoRow(
                            'Reported by',
                            _isLoadingCreator 
                                ? 'Loading...' 
                                : _issueCreator?.name ?? 'Unknown',
                            Icons.person,
                          ),
                          const SizedBox(height: AppConstants.smallSpacing),
                          
                          _buildInfoRow(
                            'Date reported',
                            Helpers.formatDateTime(_issue.createdAt),
                            Icons.calendar_today,
                          ),
                          const SizedBox(height: AppConstants.smallSpacing),
                          
                          _buildInfoRow(
                            'Upvotes',
                            '${_issue.upvotes} citizen${_issue.upvotes != 1 ? 's' : ''} support${_issue.upvotes == 1 ? 's' : ''} this issue',
                            Icons.thumb_up,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: user != null && !widget.isAdmin
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isUpvoting ? null : _toggleUpvote,
                        icon: _isUpvoting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                hasUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                                color: hasUpvoted ? Theme.of(context).primaryColor : null,
                              ),
                        label: Text(
                          hasUpvoted ? 'Upvoted (${_issue.upvotes})' : 'Upvote (${_issue.upvotes})',
                          style: TextStyle(
                            color: hasUpvoted ? Theme.of(context).primaryColor : null,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: hasUpvoted ? Theme.of(context).primaryColor : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: AppConstants.smallSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}