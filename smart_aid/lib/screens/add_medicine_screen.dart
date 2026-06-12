import 'package:flutter/material.dart';
import '../services/medication_service.dart';
import '../services/pill_verification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rationaleController = TextEditingController();
  final _dosageController = TextEditingController(text: '1');
  final _gapInDaysController = TextEditingController();
  final PillVerificationService _pillVerificationService =
      PillVerificationService();

  bool _isScanning = false;
  
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
           _startDate = picked;
        } else {
           _endDate = picked;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rationaleController.dispose();
    _dosageController.dispose();
    _gapInDaysController.dispose();
    _pillVerificationService.dispose();
    super.dispose();
  }

  // Function to test the ML Kit Scanner
  Future<void> _scanMedicine() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AI Camera scanning is only supported on Android and iOS devices. Please enter the name manually.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    setState(() => _isScanning = true);

    try {
      final result = await _pillVerificationService.scanAndVerify("");

      if (!result.cancelled && result.scannedText != null) {
        setState(() {
          _nameController.text = result.scannedText!;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scan successful! Please edit the name if needed.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning: $e')),
        );
      }
    } finally {
      setState(() => _isScanning = false);
    }
  }

  // Function to save to Firebase
  Future<void> _saveMedicine() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
        await context.read<MedicationService>().addMedication(
          userId: userId,
          name: _nameController.text,
          composition: 'Standard',
          rationale: _rationaleController.text,
          dailyDoseLimit: int.parse(_dosageController.text),
          scheduledTimes: ['${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'],
          startDate: _startDate,
          endDate: _endDate,
          gapInDays: _gapInDaysController.text.isNotEmpty ? int.tryParse(_gapInDaysController.text) : null,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine saved successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Medicine'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The AI Camera Button
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanMedicine,
                icon: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(
                  _isScanning ? 'Scanning...' : 'Scan Pill Box with Camera',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // Manual Entry Form
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _rationaleController,
                decoration: const InputDecoration(
                  labelText: 'Why am I taking this?',
                  hintText: 'e.g., Blood Pressure',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a reason' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dosageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Daily Dose Limit (Pills)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              // Time Selection
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.grey.shade400)
                ),
                title: Text('Scheduled Time: ${_selectedTime.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 16),
              
              // Advanced Options (Dates)
              ExpansionTile(
                title: const Text('Advanced Options (Dates)'),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.grey.shade400)
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.grey.shade400)
                ),
                children: [
                   ListTile(
                     title: Text(_startDate == null ? 'Select Start Date' : 'Start Date: ${_startDate!.toLocal().toString().split(' ')[0]}'),
                     trailing: const Icon(Icons.calendar_today),
                     onTap: () => _selectDate(context, true),
                   ),
                   ListTile(
                     title: Text(_endDate == null ? 'Select End Date' : 'End Date: ${_endDate!.toLocal().toString().split(' ')[0]}'),
                     trailing: const Icon(Icons.calendar_today),
                     onTap: () => _selectDate(context, false),
                   ),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                     child: TextFormField(
                       controller: _gapInDaysController,
                       keyboardType: TextInputType.number,
                       decoration: const InputDecoration(
                         labelText: 'Gap in Days (Optional)',
                         hintText: 'e.g., 2',
                         border: OutlineInputBorder(),
                         prefixIcon: Icon(Icons.hourglass_empty),
                         isDense: true,
                       ),
                     ),
                   ),
                   const SizedBox(height: 8),
                ],
              ),

              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _saveMedicine,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Save Medicine',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
