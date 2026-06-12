// lib/services/fall_detection_service.dart

import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class FallDetectionService {
  static const double _fallThreshold = 25.0; // m/s² — tune after testing
  static const int _countdownSeconds = 10;

  StreamSubscription<AccelerometerEvent>? _subscription;
  Function(int secondsLeft)? onCountdown;
  Function()? onSosSent;
  List<String> emergencyContacts = [];
  String emergencyNumber = '108'; // India ambulance

  void startListening() {
    _subscription = accelerometerEventStream().listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (magnitude > _fallThreshold) {
        _triggerFallProtocol();
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
  }

  Timer? _countdownTimer;
  bool _sosActive = false;

  void _triggerFallProtocol() {
    if (_sosActive) return;
    _sosActive = true;
    int secondsLeft = _countdownSeconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsLeft--;
      onCountdown?.call(secondsLeft);
      if (secondsLeft <= 0) {
        timer.cancel();
        _sendSos();
      }
    });
  }

  // Call this when user taps "I'm OK" to cancel
  void cancelSos() {
    _countdownTimer?.cancel();
    _sosActive = false;
  }

  Future<void> _sendSos() async {
    _sosActive = false;
    // Send SMS to each emergency contact
    for (final contact in emergencyContacts) {
      final smsUri = Uri.parse(
        'sms:$contact?body=EMERGENCY: I may have fallen. Please help!',
      );
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    }
    // Open dialer pre-filled with ambulance number
    final telUri = Uri.parse('tel:$emergencyNumber');
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
    onSosSent?.call();
  }
}
