import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/issue_model.dart';
import 'dart:io';

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Create issue
  Future<void> createIssue(IssueModel issue) async {
    try {
      final issueRef = _database.child('issues').push();
      final issueWithId = issue.copyWith(id: issueRef.key!);

      // Prepare map and include top-level 'address' for easier querying/display
      final data = Map<String, dynamic>.from(issueWithId.toJson());
      final loc = issueWithId.location;
      if (loc != null && loc.address != null && loc.address!.trim().isNotEmpty) {
        data['address'] = loc.address!.trim();
      }

      await issueRef.set(data);
    } catch (e) {
      throw 'Failed to create issue: ${e.toString()}';
    }
  }

  // One-time migration helper: copy location.address -> top-level address for existing issues
  // Returns number of records updated.
  Future<int> migrateAddressToTopLevel() async {
    int updated = 0;
    try {
      final snapshot = await _database.child('issues').once();
      if (!snapshot.snapshot.exists) return updated;

      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      for (final entry in data.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          // if top-level address exists, skip
          if (map.containsKey('address') && map['address'] != null && map['address'].toString().trim().isNotEmpty) continue;

          // try to pull location.address
          final loc = map['location'];
          String? addr;
          if (loc is Map && loc['address'] != null && loc['address'].toString().trim().isNotEmpty) {
            addr = loc['address'].toString().trim();
          }

          if (addr != null) {
            await _database.child('issues').child(key).update({'address': addr});
            updated++;
          }
        }
      }
    } catch (e) {
      throw 'Failed to migrate addresses: ${e.toString()}';
    }
    return updated;
  }

  // Get all issues
  Stream<List<IssueModel>> getAllIssues() {
    return _database.child('issues').onValue.map((event) {
      final List<IssueModel> issues = [];
      final List<String> skippedEntries = [];
      if (event.snapshot.exists) {
        final rawData = event.snapshot.value as Map<Object?, Object?>;
        rawData.forEach((key, value) {
          try {
            if (value is Map) {
              final issueMap = value.map((k, v) => MapEntry(k.toString(), v));
              final issue = IssueModel.fromJson(key.toString(), Map<String, dynamic>.from(issueMap));
              issues.add(issue);
            } else {
              skippedEntries.add(key.toString());
            }
          } catch (e) {
            skippedEntries.add(key.toString());
          }
        });
        // Sort by creation date (newest first)
        issues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (skippedEntries.isNotEmpty) {
          print('Skipped malformed issue entries: ${skippedEntries.join(", ")}');
        }
      }
      return issues;
    });
  }

  // Get user's issues
  Stream<List<IssueModel>> getUserIssues(String userId) {
    return _database
        .child('issues')
        .orderByChild('createdBy')
        .equalTo(userId)
        .onValue
        .map((event) {
      final List<IssueModel> issues = [];
      final List<String> skippedEntries = [];
      if (event.snapshot.exists) {
        final rawData = event.snapshot.value as Map<Object?, Object?>;
        rawData.forEach((key, value) {
          try {
            if (value is Map) {
              final issueMap = value.map((k, v) => MapEntry(k.toString(), v));
              final issue = IssueModel.fromJson(key.toString(), Map<String, dynamic>.from(issueMap));
              issues.add(issue);
            } else {
              skippedEntries.add(key.toString());
            }
          } catch (e) {
            skippedEntries.add(key.toString());
          }
        });
        // Sort by creation date (newest first)
        issues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (skippedEntries.isNotEmpty) {
          // Optionally log skipped entries for debugging
          print('Skipped malformed issue entries: ${skippedEntries.join(", ")}');
        }
      }
      return issues;
    });
  }

  // Update issue status
  Future<void> updateIssueStatus(String issueId, String newStatus) async {
    try {
      await _database.child('issues').child(issueId).update({
        'status': newStatus,
      });
    } catch (e) {
      throw 'Failed to update issue status: ${e.toString()}';
    }
  }

  // Toggle upvote
  Future<void> toggleUpvote(String issueId, String userId) async {
    try {
      final issueRef = _database.child('issues').child(issueId);
      final snapshot = await issueRef.once();
      
      if (snapshot.snapshot.exists) {
        final issueData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        final issue = IssueModel.fromJson(issueId, issueData);
        
        List<String> upvotedBy = List<String>.from(issue.upvotedBy);
        int upvotes = issue.upvotes;
        
        if (upvotedBy.contains(userId)) {
          // Remove upvote
          upvotedBy.remove(userId);
          upvotes = (upvotes > 0) ? upvotes - 1 : 0;
        } else {
          // Add upvote
          upvotedBy.add(userId);
          upvotes += 1;
        }
        
        await issueRef.update({
          'upvotes': upvotes,
          'upvotedBy': upvotedBy,
        });
      }
    } catch (e) {
      throw 'Failed to toggle upvote: ${e.toString()}';
    }
  }

  // Upload image to Cloudinary
  Future<String> uploadImage(File imageFile, String path) async {
    try {
      final cloudinaryUrl = 'https://api.cloudinary.com/v1_1/dfctkbew3/image/upload';
  // Use the provided unsigned upload preset for Cloudinary
  final uploadPreset = 'civicx';

      final request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final resStr = await response.stream.bytesToString();
      final resJson = json.decode(resStr);

      if (response.statusCode == 200 && resJson['secure_url'] != null) {
        return resJson['secure_url'];
      } else {
        throw 'Cloudinary upload failed: \\${resJson['error']['message'] ?? 'Unknown error'}';
      }
    } catch (e) {
      throw 'Failed to upload image: \\${e.toString()}';
    }
  }

  // Get dashboard stats (for admin)
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final snapshot = await _database.child('issues').once();
      
      int totalIssues = 0;
      int pendingIssues = 0;
      int inProgressIssues = 0;
      int resolvedIssues = 0;
      
      if (snapshot.snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        totalIssues = data.length;
        
        data.forEach((key, value) {
          final status = value['status'] ?? 'Pending';
          switch (status) {
            case 'Pending':
              pendingIssues++;
              break;
            case 'In Progress':
              inProgressIssues++;
              break;
            case 'Resolved':
              resolvedIssues++;
              break;
          }
        });
      }
      
      return {
        'total': totalIssues,
        'pending': pendingIssues,
        'inProgress': inProgressIssues,
        'resolved': resolvedIssues,
      };
    } catch (e) {
      throw 'Failed to get dashboard stats: ${e.toString()}';
    }
  }
}