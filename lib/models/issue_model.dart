class IssueModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? imageUrl;
  final LocationData? location;
  final String status; // 'Pending', 'In Progress', 'Resolved'
  final String createdBy;
  final DateTime createdAt;
  final int upvotes;
  final List<String> upvotedBy;

  IssueModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
    this.location,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.upvotes = 0,
    this.upvotedBy = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'location': location?.toJson(),
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'upvotes': upvotes,
      'upvotedBy': upvotedBy,
    };
  }

  factory IssueModel.fromJson(String id, Map<String, dynamic> json) {
    DateTime createdAt;
    try {
      if (json['createdAt'] is String) {
        createdAt = DateTime.parse(json['createdAt']);
      } else if (json['createdAt'] is int) {
        // If stored as timestamp
        createdAt = DateTime.fromMillisecondsSinceEpoch(json['createdAt']);
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      createdAt = DateTime.now();
    }
    List<String> upvotedBy;
    try {
      upvotedBy = List<String>.from(json['upvotedBy'] ?? []);
    } catch (e) {
      upvotedBy = [];
    }
    return IssueModel(
      id: id,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      location: json['location'] != null && json['location'] is Map<String, dynamic>
          ? LocationData.fromJson(json['location'])
          : null,
      status: json['status']?.toString() ?? 'Pending',
      createdBy: json['createdBy']?.toString() ?? '',
      createdAt: createdAt,
      upvotes: (json['upvotes'] is int) ? json['upvotes'] : int.tryParse(json['upvotes']?.toString() ?? '0') ?? 0,
      upvotedBy: upvotedBy,
    );
  }

  IssueModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? imageUrl,
    LocationData? location,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    int? upvotes,
    List<String>? upvotedBy,
  }) {
    return IssueModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      upvotes: upvotes ?? this.upvotes,
      upvotedBy: upvotedBy ?? this.upvotedBy,
    );
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final String? address;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'],
    );
  }
}