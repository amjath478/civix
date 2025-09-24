import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../models/issue_model.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedCategory = AppConstants.issueCategories.isNotEmpty ? AppConstants.issueCategories[0] : 'General';
  File? _selectedImage;
  LocationData? _currentLocation;
  bool _isLoading = false;
  bool _isLoadingLocation = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Image pick failed: ${e.toString()}', isError: true);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final loc = await _locationService.getCurrentLocation();
      final address = (loc?.address ?? '').trim();
      setState(() {
        // store address-only: lat/lng set to neutral values (0.0)
        _currentLocation = LocationData(latitude: 0.0, longitude: 0.0, address: address);
        _addressController.text = address;
      });
      if (mounted) Helpers.showSnackBar(context, 'Location captured');
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Failed to get location: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Helpers.showSnackBar(context, 'You must be logged in to report an issue', isError: true);
      return;
    }

    final address = (_currentLocation?.address ?? _addressController.text).trim();
    if (address.isEmpty) {
      Helpers.showSnackBar(context, 'Location is required. Use current location or enter address.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final imagePath = '${AppConstants.issueImagesPath}/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await _databaseService.uploadImage(_selectedImage!, imagePath);
      }

      final issue = IssueModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        imageUrl: imageUrl,
        // save address-only location (lat/lng neutral)
        location: LocationData(latitude: 0.0, longitude: 0.0, address: address),
        status: 'Pending',
        createdBy: user.uid,
        createdAt: DateTime.now(),
      );

      await _databaseService.createIssue(issue);

      if (mounted) {
        Helpers.showSnackBar(context, 'Issue submitted');
        _resetForm();
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Submission failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _addressController.clear();
    setState(() {
      _selectedCategory = AppConstants.issueCategories.isNotEmpty ? AppConstants.issueCategories[0] : 'General';
      _selectedImage = null;
      _currentLocation = null;
    });
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Issue'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _resetForm,
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.mediumSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  prefixIcon: Icon(Icons.title),
                ),
                maxLength: AppConstants.maxTitleLength,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter a title';
                  if (v.trim().length < 10) return 'Title must be at least 10 characters';
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.mediumSpacing),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category *', prefixIcon: Icon(Icons.category)),
                items: AppConstants.issueCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: _isLoading ? null : (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),

              const SizedBox(height: AppConstants.mediumSpacing),

              TextFormField(
                controller: _descriptionController,
                enabled: !_isLoading,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description *', prefixIcon: Icon(Icons.description)),
                maxLength: AppConstants.maxDescriptionLength,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter a description';
                  if (v.trim().length < 20) return 'Description must be at least 20 characters';
                  return null;
                },
              ),

              const SizedBox(height: AppConstants.mediumSpacing),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Photo', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppConstants.smallSpacing),
                      if (_selectedImage != null) ...[
                        Image.file(_selectedImage!, height: 180, width: double.infinity, fit: BoxFit.cover),
                        const SizedBox(height: AppConstants.smallSpacing),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => setState(() => _selectedImage = null),
                                icon: const Icon(Icons.delete),
                                label: const Text('Remove'),
                              ),
                            ),
                            const SizedBox(width: AppConstants.smallSpacing),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showImageOptions,
                                icon: const Icon(Icons.edit),
                                label: const Text('Change'),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        OutlinedButton.icon(
                          onPressed: _showImageOptions,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Add Photo (optional)'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.mediumSpacing),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location *', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppConstants.smallSpacing),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                              icon: _isLoadingLocation ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.my_location),
                              label: Text(_isLoadingLocation ? 'Getting...' : 'Use Current Location'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.smallSpacing),
                      TextFormField(
                        controller: _addressController,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(labelText: 'Address *', prefixIcon: Icon(Icons.location_on)),
                        validator: (v) {
                          if ((v == null || v.trim().isEmpty) && (_currentLocation == null || (_currentLocation?.address ?? '').trim().isEmpty)) {
                            return 'Location is required.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.largeSpacing),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitIssue,
                icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                label: Text(_isLoading ? 'Submitting...' : 'Submit Issue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}