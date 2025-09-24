class AppConstants {
  // App info
  static const String appName = 'CivicX';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Crowdsourced Civic Issue Reporting & Resolution System';

  // Issue categories
  static const List<String> issueCategories = [
    'Road Works',
    'Waste Management',
    'Water authority',
    'Public infrastructure',
    'Animal and Pest control',
    'Other',
  ];

  // Issue statuses
  static const List<String> issueStatuses = [
    'Pending',
    'In Progress',
    'Resolved',
  ];

  // User roles
  static const String citizenRole = 'citizen';
  static const String adminRole = 'admin';

  // Storage paths
  static const String issueImagesPath = 'issue_images';
  static const String profileImagesPath = 'profile_images';

  // Validation
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 500;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Spacing
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;

  // Border radius
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 24.0;
}