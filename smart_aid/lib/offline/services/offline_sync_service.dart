import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../security/services/secure_logger.dart';
import 'package:smart_aid/services/local_db_service.dart';
import '../models/sync_queue_item.dart';
import '../../repositories/medication_repository.dart';
import '../../repositories/appointment_repository.dart';

class OfflineSyncService extends ChangeNotifier {
  final MedicationRepository medicationRepository;
  final AppointmentRepository appointmentRepository;
  final LocalDbService _localDb = LocalDbService();

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  OfflineSyncService({
    required this.medicationRepository,
    required this.appointmentRepository,
  }) {
    _init();
  }

  Future<void> _init() async {
    await _updatePendingCount();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        _attemptSync();
      }
    });
    
    final results = await Connectivity().checkConnectivity();
    if (!results.contains(ConnectivityResult.none)) {
      _attemptSync();
    }
  }

  Future<void> _updatePendingCount() async {
    final items = await _localDb.getPendingSyncItems();
    _pendingCount = items.length;
    notifyListeners();
  }

  Future<void> refreshPendingCount() async {
    await _updatePendingCount();
  }

  Future<void> _attemptSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final items = await _localDb.getPendingSyncItems();
      if (items.isEmpty) return;

      for (final item in items) {
        try {
          await _replayItem(item);
          await _localDb.removeSyncItem(item.id);
        } catch (e, stack) {
          SecureLogger.logError('Failed to sync item ${item.id}', e, stackTrace: stack);
          // Constraint: "Sync replay failures must not halt the entire queue."
        }
      }
    } finally {
      _isSyncing = false;
      await _updatePendingCount();
    }
  }

  Future<void> _replayItem(SyncQueueItem item) async {
    switch (item.operationType) {
      case SyncOperationType.saveDoseLog:
        await medicationRepository.syncDoseLog(item.userId, item.payload);
        break;
      case SyncOperationType.addAppointment:
        await appointmentRepository.syncAddAppointment(item.userId, item.payload);
        break;
      case SyncOperationType.updateAppointment:
        await appointmentRepository.syncUpdateAppointment(item.userId, item.payload);
        break;
      case SyncOperationType.deleteAppointment:
        await appointmentRepository.syncDeleteAppointment(item.userId, item.payload['appointmentId']);
        break;
      default:
        SecureLogger.log('Unknown sync operation: ${item.operationType}');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
