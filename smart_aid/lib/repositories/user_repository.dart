import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserRepository {
  final _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // STREAMS (Typed & Safe)
  // ---------------------------------------------------------------------------

  Stream<UserModel?> getUserStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      try {
        return UserModel.fromFirestore(doc);
      } catch (e) {
        debugPrint('Error parsing UserModel for doc ${doc.id}: $e');
        return null;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // OPERATIONS
  // ---------------------------------------------------------------------------

  Future<void> updateConsent({
    required String userId,
    required bool consent,
  }) async {
    await _db.collection('users').doc(userId).set({
      'share_data_research': consent,
    }, SetOptions(merge: true));
  }

  Future<void> addEmergencyContact({
    required String userId,
    required String contact,
  }) async {
    await _db.collection('users').doc(userId).set({
      'emergency_contacts': FieldValue.arrayUnion([contact]),
    }, SetOptions(merge: true));
  }

  Future<void> removeEmergencyContact({
    required String userId,
    required String contact,
  }) async {
    await _db.collection('users').doc(userId).update({
      'emergency_contacts': FieldValue.arrayRemove([contact]),
    });
  }
}
