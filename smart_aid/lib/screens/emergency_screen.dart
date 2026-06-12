import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/fall_detection_service.dart';
import 'package:smart_aid/screens/first_aid_screen.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final FallDetectionService _fallService = FallDetectionService();

  bool _isMonitoring = false;
  int? _currentCountdown;

  @override
  void initState() {
    super.initState();

    _loadEmergencyContacts();

    // Listen for the countdown from the service
    _fallService.onCountdown = (secondsLeft) {
      setState(() {
        _currentCountdown = secondsLeft;
      });
    };

    // What happens when the timer hits zero
    _fallService.onSosSent = () {
      setState(() {
        _currentCountdown = null;
        _isMonitoring = false; // Turn off monitoring after an event
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency Protocol Activated! Calling ambulance...'),
          backgroundColor: Colors.red,
        ),
      );
    };
  }

  @override
  void dispose() {
    _fallService.stopListening();
    super.dispose();
  }

  void _toggleMonitoring() {
    setState(() {
      _isMonitoring = !_isMonitoring;
      if (_isMonitoring) {
        _fallService.startListening();
      } else {
        _fallService.stopListening();
        _currentCountdown = null;
      }
    });
  }

  Future<void> _loadEmergencyContacts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final contacts = data['emergency_contacts'] as List<dynamic>? ?? [];
        _fallService.emergencyContacts = contacts.map((c) => c.toString()).toList();
      }
    }
  }

  void _cancelEmergency() {
    _fallService.cancelSos();
    setState(() {
      _currentCountdown = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // IF FALL DETECTED: Show the giant warning and countdown
              if (_currentCountdown != null) ...[
                const Icon(Icons.warning_rounded, color: Colors.red, size: 100),
                const SizedBox(height: 16),
                const Text(
                  'FALL DETECTED!',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Alerting contacts in\n$_currentCountdown seconds...',
                  style: const TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _cancelEmergency,
                  child: const Text(
                    "I'm OK - Cancel Alert",
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ]
              // NORMAL STATE: Show the toggle switch
              else ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _isMonitoring
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isMonitoring ? Colors.red : Colors.grey,
                      width: 8,
                    ),
                  ),
                  child: Icon(
                    Icons.medical_services,
                    size: 100,
                    color: _isMonitoring ? Colors.red : Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  _isMonitoring ? 'Monitoring Active' : 'Monitoring Offline',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _isMonitoring
                        ? Colors.red.shade700
                        : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text(
                    'Auto-Fall Detection',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Uses device sensors to detect sudden drops or impacts.',
                  ),
                  value: _isMonitoring,
                  onChanged: (bool value) => _toggleMonitoring(),
                  activeThumbColor: Colors.red,
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FirstAidScreen()),
                    );
                  },
                  icon: const Icon(Icons.medical_services),
                  label: const Text('View First Aid Guides', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
