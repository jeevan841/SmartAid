import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserModel {
  final String uid;
  final String email;
  final bool isDoctor;
  final bool shareDataResearch;
  final List<String> emergencyContacts;

  UserModel({
    required this.uid,
    required this.email,
    required this.isDoctor,
    required this.shareDataResearch,
    required this.emergencyContacts,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Constraint: Missing or malformed role fields must fail safely to patient mode (false)
    bool isDoctor = false;
    if (data['isDoctor'] != null) {
      if (data['isDoctor'] is bool) {
        isDoctor = data['isDoctor'];
      } else if (data['isDoctor'].toString().toLowerCase() == 'true') {
        isDoctor = true;
      }
    }

    bool shareDataResearch = false;
    if (data['share_data_research'] != null) {
      if (data['share_data_research'] is bool) {
        shareDataResearch = data['share_data_research'];
      } else if (data['share_data_research'].toString().toLowerCase() == 'true') {
        shareDataResearch = true;
      }
    }

    // Constraint: Invalid emergency contact entries should be skipped and logged
    List<String> validContacts = [];
    final rawContacts = data['emergency_contacts'];
    if (rawContacts is List) {
      for (var item in rawContacts) {
        if (item is String) {
          validContacts.add(item);
        } else {
          debugPrint('Invalid emergency contact skipped for user ${doc.id}: $item');
        }
      }
    } else if (rawContacts != null) {
      debugPrint('Malformed emergency_contacts array for user ${doc.id}');
    }

    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      isDoctor: isDoctor,
      shareDataResearch: shareDataResearch,
      emergencyContacts: validContacts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'isDoctor': isDoctor,
      'share_data_research': shareDataResearch,
      'emergency_contacts': emergencyContacts,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    bool? isDoctor,
    bool? shareDataResearch,
    List<String>? emergencyContacts,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      isDoctor: isDoctor ?? this.isDoctor,
      shareDataResearch: shareDataResearch ?? this.shareDataResearch,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }
}
