// scripts/firestore_cleanup.dart
// 
// Instructions:
// 1. You can run this script as a temporary Flutter widget/button press in a development build,
//    or adapt it into a Firebase Cloud Function.
// 2. This script iterates over collections and standardizes data types (e.g. converting String dates to Timestamps).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreCleanupTool {
  static final _db = FirebaseFirestore.instance;

  static Future<void> runFullCleanup() async {
    debugPrint("Starting Firestore Cleanup...");

    try {
      await _cleanupUsers();
      debugPrint("Cleanup complete!");
    } catch (e) {
      debugPrint("Cleanup failed: $e");
    }
  }

  static Future<void> _cleanupUsers() async {
    final usersSnapshot = await _db.collection('users').get();

    for (var userDoc in usersSnapshot.docs) {
      final data = userDoc.data();
      bool needsUpdate = false;
      Map<String, dynamic> updates = {};

      // 1. Fix emergency contacts arrays containing non-strings
      if (data['emergency_contacts'] != null && data['emergency_contacts'] is List) {
        List<dynamic> contacts = data['emergency_contacts'];
        bool hasBadData = contacts.any((c) => c is! String);
        if (hasBadData) {
          updates['emergency_contacts'] = contacts.map((e) => e.toString()).toList();
          needsUpdate = true;
        }
      }

      // 2. Fix boolean flags stored as strings
      if (data['isDoctor'] is String) {
        updates['isDoctor'] = data['isDoctor'].toString().toLowerCase() == 'true';
        needsUpdate = true;
      }
      
      if (data['share_data_research'] is String) {
        updates['share_data_research'] = data['share_data_research'].toString().toLowerCase() == 'true';
        needsUpdate = true;
      }

      if (needsUpdate) {
        debugPrint("Cleaning up User ${userDoc.id}");
        await userDoc.reference.update(updates);
      }

      // 3. Clean subcollections for this user
      await _cleanupMedications(userDoc.reference);
      await _cleanupDoseLogs(userDoc.reference);
    }
  }

  static Future<void> _cleanupMedications(DocumentReference userRef) async {
    final medsSnapshot = await userRef.collection('medications').get();

    for (var medDoc in medsSnapshot.docs) {
      final data = medDoc.data();
      bool needsUpdate = false;
      Map<String, dynamic> updates = {};

      // Convert String dates to Timestamps
      if (data['createdAt'] is String) {
        final parsed = DateTime.tryParse(data['createdAt']);
        if (parsed != null) {
          updates['createdAt'] = Timestamp.fromDate(parsed);
          needsUpdate = true;
        }
      }

      // Ensure dailyDoseLimit is integer
      if (data['dailyDoseLimit'] is String) {
        updates['dailyDoseLimit'] = int.tryParse(data['dailyDoseLimit']) ?? 1;
        needsUpdate = true;
      } else if (data['dailyDoseLimit'] is double) {
        updates['dailyDoseLimit'] = (data['dailyDoseLimit'] as double).toInt();
        needsUpdate = true;
      }

      if (needsUpdate) {
        debugPrint("Cleaning up Medication ${medDoc.id}");
        await medDoc.reference.update(updates);
      }
    }
  }

  static Future<void> _cleanupDoseLogs(DocumentReference userRef) async {
    final logsSnapshot = await userRef.collection('dose_logs').get();

    for (var logDoc in logsSnapshot.docs) {
      final data = logDoc.data();
      bool needsUpdate = false;
      Map<String, dynamic> updates = {};

      // Ensure count is integer
      if (data['count'] is String) {
        updates['count'] = int.tryParse(data['count']) ?? 0;
        needsUpdate = true;
      } else if (data['count'] is double) {
        updates['count'] = (data['count'] as double).toInt();
        needsUpdate = true;
      }

      if (needsUpdate) {
        debugPrint("Cleaning up Dose Log ${logDoc.id}");
        await logDoc.reference.update(updates);
      }
    }
  }
}
