import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/issue_model.dart';
import 'dart:io';

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create issue
  Future<void> createIssue(IssueModel issue) async {
    try {
      final issueRef = _database.child('issues').push();
      final issueWithId = issue.copyWith(id: issueRef.key!);
      await issueRef.set(issueWithId.toJson());
    } catch (e) {
      throw 'Failed to create issue: ${e.toString()}';
    }
  }

  // Get all issues
  Stream<List<IssueModel>> getAllIssues() {
    return _database.child('issues').onValue.map((event) {
      final List<IssueModel> issues = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final issue = IssueModel.fromJson(
            key, 
            Map<String, dynamic>.from(value)
          );
          issues.add(issue);
        });
        // Sort by creation date (newest first)
        issues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final issue = IssueModel.fromJson(
            key, 
            Map<String, dynamic>.from(value)
          );
          issues.add(issue);
        });
        // Sort by creation date (newest first)
        issues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  // Upload image to Firebase Storage
  Future<String> uploadImage(File imageFile, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload image: ${e.toString()}';
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