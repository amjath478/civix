class IssueModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? imageUrl;
  final LocationData? location;
  final String? address;
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
    this.address,
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
      'address': address,
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
  // Try to construct location from several possible shapes to support legacy data
    LocationData? location;
  String? address;
    try {
      if (json['location'] != null) {
        if (json['location'] is Map<String, dynamic>) {
          location = LocationData.fromJson(Map<String, dynamic>.from(json['location']));
        } else if (json['location'] is String) {
          // If old data stored location as a single string address
          location = LocationData(latitude: 0.0, longitude: 0.0, address: json['location'].toString());
        }
      }

      // Fallbacks: top-level 'address' or 'locationAddress'
      if (location == null) {
        final altAddress = json['address'] ?? json['locationAddress'] ?? json['location_address'];
        if (altAddress != null && altAddress.toString().trim().isNotEmpty) {
          location = LocationData(latitude: 0.0, longitude: 0.0, address: altAddress.toString());
        }
      }
      } catch (e) {
      location = null;
    }

    // top-level address fallbacks
    try {
      address = json['address']?.toString();
      if (address == null || address.trim().isEmpty) {
        address = json['locationAddress']?.toString() ?? json['location_address']?.toString();
      }
    } catch (_) {
      address = null;
    }

    return IssueModel(
      id: id,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
  imageUrl: json['imageUrl']?.toString(),
  location: location,
  address: address,
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
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      final s = v.toString();
      return double.tryParse(s) ?? 0.0;
    }

    String? parseAddress(Map<String, dynamic> j) {
      final possible = [
        'address',
        'locationAddress',
        'location_address',
        'place',
        'locality',
      ];
      for (var key in possible) {
        if (j.containsKey(key) && j[key] != null && j[key].toString().trim().isNotEmpty) {
          return j[key].toString();
        }
      }
      return null;
    }

    return LocationData(
      latitude: parseDouble(json['latitude'] ?? json['lat'] ?? json['lati'] ?? 0.0),
      longitude: parseDouble(json['longitude'] ?? json['lng'] ?? json['lon'] ?? 0.0),
      address: parseAddress(json),
    );
  }
}