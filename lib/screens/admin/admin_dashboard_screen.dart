import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseService _databaseService = DatabaseService();
  Map<String, int>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _databaseService.getDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to load statistics: ${e.toString()}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _stats == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Failed to load statistics'),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome section
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppConstants.largeSpacing),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.admin_panel_settings,
                                  size: 48,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: AppConstants.mediumSpacing),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome, Admin',
                                        style: Theme.of(context).textTheme.displaySmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Manage civic issues and track resolution progress',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppConstants.largeSpacing),

                        // Statistics cards
                        Text(
                          'Issue Statistics',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: AppConstants.mediumSpacing),

                        // Stats grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: AppConstants.mediumSpacing,
                          mainAxisSpacing: AppConstants.mediumSpacing,
                          childAspectRatio: 1.3,
                          children: [
                            _buildStatCard(
                              'Total Issues',
                              _stats!['total']!,
                              Icons.assignment,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              'Pending',
                              _stats!['pending']!,
                              Icons.schedule,
                              Colors.orange,
                            ),
                            _buildStatCard(
                              'In Progress',
                              _stats!['inProgress']!,
                              Icons.build,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              'Resolved',
                              _stats!['resolved']!,
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ],
                        ),

                        const SizedBox(height: AppConstants.largeSpacing),

                        // Progress section
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppConstants.largeSpacing),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resolution Progress',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: AppConstants.mediumSpacing),
                                
                                if (_stats!['total']! > 0) ...[
                                  _buildProgressBar(
                                    'Resolved',
                                    _stats!['resolved']!,
                                    _stats!['total']!,
                                    Colors.green,
                                  ),
                                  const SizedBox(height: AppConstants.smallSpacing),
                                  _buildProgressBar(
                                    'In Progress',
                                    _stats!['inProgress']!,
                                    _stats!['total']!,
                                    Colors.blue,
                                  ),
                                  const SizedBox(height: AppConstants.smallSpacing),
                                  _buildProgressBar(
                                    'Pending',
                                    _stats!['pending']!,
                                    _stats!['total']!,
                                    Colors.orange,
                                  ),
                                ] else ...[
                                  const Center(
                                    child: Text(
                                      'No issues to display progress',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppConstants.largeSpacing),

                        // Quick actions
                        Text(
                          'Quick Actions',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: AppConstants.mediumSpacing),

                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
                                  onTap: () {
                                    // Navigate to issues screen
                                    DefaultTabController.of(context).animateTo(1);
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(AppConstants.largeSpacing),
                                    child: Column(
                                      children: [
                                        Icon(Icons.list, size: 32, color: Colors.blue),
                                        SizedBox(height: AppConstants.smallSpacing),
                                        Text('View All Issues'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppConstants.mediumSpacing),
                            Expanded(
                              child: Card(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
                                  onTap: _loadStats,
                                  child: const Padding(
                                    padding: EdgeInsets.all(AppConstants.largeSpacing),
                                    child: Column(
                                      children: [
                                        Icon(Icons.refresh, size: 32, color: Colors.green),
                                        SizedBox(height: AppConstants.smallSpacing),
                                        Text('Refresh Data'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.mediumSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: AppConstants.smallSpacing),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '$count / $total (${(percentage * 100).toStringAsFixed(1)}%)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}