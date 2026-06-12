import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class DoctorDashboardRepository {
  final _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // RAW ANALYTICS STREAMS
  // ---------------------------------------------------------------------------

  /// Returns a stream of users who have opted into research at the database level.
  Stream<List<UserModel>> getConsentingUsersStream() {
    return _db
        .collection('users')
        .where('share_data_research', isEqualTo: true) // Initial Firestore-level consent filter
        .snapshots()
        .map((snapshot) {
      final List<UserModel> users = [];

      for (var doc in snapshot.docs) {
        try {
          users.add(UserModel.fromFirestore(doc));
        } catch (e) {
          debugPrint('Analytics skipping malformed user doc ${doc.id}: $e');
        }
      }

      return users;
    });
  }
}
