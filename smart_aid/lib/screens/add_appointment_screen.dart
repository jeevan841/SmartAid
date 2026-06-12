import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/appointment_service.dart';

import '../models/appointment_model.dart';

class AddAppointmentScreen extends StatefulWidget {
  final AppointmentModel? appointment;

  const AddAppointmentScreen({
    super.key,
    this.appointment,
  });

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doctorController = TextEditingController();
  final _reasonController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  bool _isSaving = false;

  bool get _isEditing => widget.appointment != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _doctorController.text = widget.appointment!.doctorName;
      _reasonController.text = widget.appointment!.reason;
      final dt = widget.appointment!.dateTime;
      if (dt != null) {
        _selectedDate = dt;
        _selectedTime = TimeOfDay.fromDateTime(dt);
      }
    }
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      if (!context.mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
        });
      }
    }
  }

  Future<void> _deleteAppointment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text('Are you sure you want to completely remove this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isSaving = true);
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
        await context.read<AppointmentService>().deleteAppointment(
          userId: userId,
          appointmentId: widget.appointment!.id,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  Future<void> _saveAppointment() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Date and Time')),
        );
        return;
      }
      
      setState(() => _isSaving = true);
      
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
        final dateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

        final newAppt = AppointmentModel(
          id: _isEditing ? widget.appointment!.id : '',
          doctorName: _doctorController.text,
          reason: _reasonController.text,
          dateTime: dateTime,
          createdAt: _isEditing ? widget.appointment!.createdAt : null,
        );

        if (_isEditing) {
          await context.read<AppointmentService>().updateAppointment(
            userId: userId,
            appointment: newAppt,
          );
        } else {
          await context.read<AppointmentService>().addAppointment(
            userId: userId,
            appointment: newAppt,
          );
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Appointment ${_isEditing ? 'updated' : 'saved'} successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving: $e')),
          );
        }
      } finally {
        if (mounted) {
            setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Appointment' : 'Book Appointment'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteAppointment,
              tooltip: 'Delete Appointment',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _doctorController,
                decoration: const InputDecoration(
                  labelText: 'Doctor Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for visit',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter a reason' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.grey.shade400)
                ),
                title: Text(_selectedDate == null || _selectedTime == null 
                  ? 'Select Date & Time' 
                  : '${_selectedDate!.toLocal().toString().split(' ')[0]} at ${_selectedTime!.format(context)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDateTime(context),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveAppointment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving 
                   ? const CircularProgressIndicator(color: Colors.white)
                   : Text(_isEditing ? 'Update Appointment' : 'Save Appointment', style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
