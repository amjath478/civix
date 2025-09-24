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

  String _selectedCategory = AppConstants.issueCategories[0];
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
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to pick image: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final location = await _locationService.getCurrentLocation();
      setState(() {
        _currentLocation = location;
        _addressController.text = location?.address ?? '';
      });

      if (mounted) {
        Helpers.showSnackBar(context, 'Location captured successfully!');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, e.toString(), isError: true);
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Helpers.showSnackBar(context, 'You must be logged in to report an issue', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      
      // Upload image if selected
      if (_selectedImage != null) {
        final imagePath = '${AppConstants.issueImagesPath}/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await _databaseService.uploadImage(_selectedImage!, imagePath);
      }

      // Create issue
      final issue = IssueModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        imageUrl: imageUrl,
        location: _currentLocation,
        status: 'Pending',
        createdBy: user.uid,
        createdAt: DateTime.now(),
      );

      await _databaseService.createIssue(issue);

      if (mounted) {
        Helpers.showSnackBar(context, 'Issue reported successfully!');
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to report issue: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _addressController.clear();
    setState(() {
      _selectedCategory = AppConstants.issueCategories[0];
      _selectedImage = null;
      _currentLocation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Issue'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _resetForm,
            child: const Text('Clear'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.mediumSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Issue Title *',
                  hintText: 'Briefly describe the issue',
                  prefixIcon: Icon(Icons.title),
                ),
                maxLength: AppConstants.maxTitleLength,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length < 10) {
                    return 'Title must be at least 10 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppConstants.mediumSpacing),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: AppConstants.issueCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          Helpers.getCategoryIcon(category),
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: AppConstants.smallSpacing),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _isLoading ? null : (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),

              const SizedBox(height: AppConstants.mediumSpacing),

              // Description field
              TextFormField(
                controller: _descriptionController,
                enabled: !_isLoading,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Provide detailed information about the issue',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLength: AppConstants.maxDescriptionLength,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.trim().length < 20) {
                    return 'Description must be at least 20 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppConstants.mediumSpacing),

              // Image section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Photo',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppConstants.smallSpacing),
                      if (_selectedImage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                          child: Image.file(
                            _selectedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: AppConstants.smallSpacing),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : () => setState(() => _selectedImage = null),
                                icon: const Icon(Icons.delete),
                                label: const Text('Remove'),
                              ),
                            ),
                            const SizedBox(width: AppConstants.smallSpacing),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : () => _showImageSourceDialog(),
                                icon: const Icon(Icons.edit),
                                label: const Text('Change'),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _showImageSourceDialog,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Add Photo'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.mediumSpacing),

              // Location section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppConstants.smallSpacing),
                      
                      // GPS location button
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: (_isLoading || _isLoadingLocation) ? null : _getCurrentLocation,
                              icon: _isLoadingLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.my_location),
                              label: Text(_isLoadingLocation ? 'Getting Location...' : 'Use Current Location'),
                            ),
                          ),
                        ],
                      ),
                      
                      if (_currentLocation != null) ...[
                        const SizedBox(height: AppConstants.smallSpacing),
                        Container(
                          padding: const EdgeInsets.all(AppConstants.smallSpacing),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 16),
                              const SizedBox(width: AppConstants.smallSpacing),
                              Expanded(
                                child: Text(
                                  'Location captured: ${_currentLocation!.address}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: AppConstants.smallSpacing),
                      
                      // Manual address input
                      TextFormField(
                        controller: _addressController,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Address (Optional)',
                          hintText: 'Enter or modify the address',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.largeSpacing),

              // Submit button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitIssue,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'Submitting...' : 'Submit Issue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}