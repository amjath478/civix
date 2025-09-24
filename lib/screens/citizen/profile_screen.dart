import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userData = await _authService.getUserData(user.uid);
        setState(() {
          _currentUser = userData;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      'Sign Out',
      'Are you sure you want to sign out?',
    );

    if (confirmed == true) {
      try {
        await _authService.signOut();
      } catch (e) {
        if (mounted) {
          Helpers.showSnackBar(context, 'Failed to sign out: ${e.toString()}', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(
                  child: Text('Failed to load user data'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                  child: Column(
                    children: [
                      // Profile header
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppConstants.largeSpacing),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Theme.of(context).primaryColor,
                                backgroundImage: _currentUser!.photoUrl != null
                                    ? NetworkImage(_currentUser!.photoUrl!)
                                    : null,
                                child: _currentUser!.photoUrl == null
                                    ? Text(
                                        _currentUser!.name.isNotEmpty
                                            ? _currentUser!.name[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: AppConstants.mediumSpacing),
                              Text(
                                _currentUser!.name,
                                style: Theme.of(context).textTheme.displaySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppConstants.smallSpacing),
                              Text(
                                _currentUser!.email,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppConstants.smallSpacing),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.mediumSpacing,
                                  vertical: AppConstants.smallSpacing,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                                ),
                                child: Text(
                                  _currentUser!.role.toUpperCase(),
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppConstants.mediumSpacing),

                      // Account info
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: const Text('Member Since'),
                              subtitle: Text(
                                Helpers.formatDate(_currentUser!.createdAt),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.person),
                              title: const Text('Account Type'),
                              subtitle: Text(
                                _currentUser!.role == 'admin' ? 'Administrator' : 'Citizen',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppConstants.mediumSpacing),

                      // App info
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.info_outline),
                              title: const Text('About CivicX'),
                              subtitle: const Text(AppConstants.appDescription),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.verified),
                              title: const Text('Version'),
                              subtitle: const Text(AppConstants.appVersion),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppConstants.mediumSpacing),

                      // Sign out button
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text(
                            'Sign Out',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: _signOut,
                        ),
                      ),

                      const SizedBox(height: AppConstants.largeSpacing),
                    ],
                  ),
                ),
    );
  }
}