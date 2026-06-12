import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_aid/services/pdf_export_service.dart';
import 'package:smart_aid/services/medication_service.dart';
import 'package:smart_aid/services/health_record_service.dart';
import '../models/health_record_model.dart';
import '../models/dose_log_model.dart';
import '../reports/services/report_generation_service.dart';
import '../ui/loading/shimmer_loading.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  bool _isUploading = false;
  Stream<List<DoseLogModel>>? _doseLogsStream;
  Stream<List<HealthRecordModel>>? _healthRecordsStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _doseLogsStream = context.read<MedicationService>().getAllDoseLogsStream(user.uid);
      _healthRecordsStream = context.read<HealthRecordService>().getHealthRecordsStream(user.uid);
    }
  }

  Future<void> _pickAndSaveFile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        File originalFile = File(result.files.single.path!);
        String fileName = result.files.single.name;

        // Copy to app document directory for permanent local storage
        final directory = await getApplicationDocumentsDirectory();
        final localPath = '${directory.path}/$fileName';
        final newFile = await originalFile.copy(localPath);

        if (!mounted) return;
        // Save metadata to Firestore using service
        await context.read<HealthRecordService>().saveRecordMetadata(
          userId: user.uid,
          fileName: fileName,
          localPath: newFile.path,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File saved locally.')),
          );
        }
      } on FirebaseException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.code == 'permission-denied' ? 'Permission denied to save record.' : 'Database error: ${e.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving file: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  void _openFile(String path) async {
    final success = await context.read<HealthRecordService>().openLocalFile(path);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found or cannot be opened.')),
      );
    }
  }

  void _deleteFile(HealthRecordModel record) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await context.read<HealthRecordService>().deleteRecord(userId: user.uid, record: record);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.code == 'permission-denied' ? 'Permission denied to delete record.' : 'Error: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Health Records'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.folder), text: 'Uploaded Files'),
              Tab(icon: Icon(Icons.medication), text: 'Medication Logs'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: 'Export Full Report',
              onPressed: () async {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generating PDF Report...')),
                  );
                  final report = await context.read<ReportGenerationService>().generatePatientReport(user.uid);
                  await PdfExportService().generateAndSharePdf(report);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to export PDF: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildFilesTab(user),
            _buildDoseLogsTab(user),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isUploading ? null : _pickAndSaveFile,
          icon: _isUploading 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.add),
          label: Text(_isUploading ? 'Saving...' : 'Add File'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFilesTab(User user) {
    if (_healthRecordsStream == null) {
      return const Center(child: Text('User not logged in.'));
    }

    return StreamBuilder<List<HealthRecordModel>>(
      stream: _healthRecordsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            itemCount: 4,
            itemBuilder: (context, index) => const SkeletonCard(
              height: 70,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        }

        if (snapshot.hasError) {
          if (snapshot.error is FirebaseException && (snapshot.error as FirebaseException).code == 'permission-denied') {
            return const Center(child: Text('Data temporarily unavailable.', style: TextStyle(color: Colors.grey)));
          }
          return const Center(child: Text('Unable to load at this time.', style: TextStyle(color: Colors.grey)));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Your digital filing cabinet is ready.\nTap + to securely store your first document.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final records = snapshot.data!;

        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final fileName = record.fileName;
            final localPath = record.localPath;
            final createdAt = record.createdAt;
            
            String dateStr = 'Unknown Date';
            if (createdAt != null) {
              dateStr = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.insert_drive_file, color: Colors.blue, size: 32),
                title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Added: $dateStr'),
                onTap: () => _openFile(localPath),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete File?'),
                        content: Text('Are you sure you want to delete "$fileName"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteFile(record);
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDoseLogsTab(User user) {
    if (_doseLogsStream == null) {
      return const Center(child: Text('User not logged in.'));
    }

    return StreamBuilder<List<DoseLogModel>>(
      stream: _doseLogsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            itemCount: 4,
            itemBuilder: (context, index) => const SkeletonCard(
              height: 70,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        }

        if (snapshot.hasError) {
          if (snapshot.error is FirebaseException && (snapshot.error as FirebaseException).code == 'permission-denied') {
            return const Center(child: Text('Data temporarily unavailable.', style: TextStyle(color: Colors.grey)));
          }
          return const Center(child: Text('Unable to load at this time.', style: TextStyle(color: Colors.grey)));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Awaiting your first medication dose.\nYour history will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final logs = snapshot.data!;

        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final medName = log.medicationName.isNotEmpty ? log.medicationName : 'Unknown Medicine';
            final count = log.count;
            final dateStr = log.date.isNotEmpty ? log.date : 'Unknown Date';
            final lastTaken = log.lastTaken;
            
            String timeStr = '';
            if (lastTaken != null) {
              timeStr = ' at ${lastTaken.hour.toString().padLeft(2, '0')}:${lastTaken.minute.toString().padLeft(2, '0')}';
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check_circle, color: Colors.white),
                ),
                title: Text(medName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Taken $count time(s) on $dateStr$timeStr'),
              ),
            );
          },
        );
      },
    );
  }
}
