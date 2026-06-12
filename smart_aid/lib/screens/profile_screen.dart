import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_aid/providers/theme_provider.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _contactController = TextEditingController();
  Stream<UserModel?>? _userStream;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId != null) {
      _userStream = context.read<UserService>().getUserStream(_userId!);
    }
  }

  Future<void> _addContact() async {
    if (_userId == null || _contactController.text.isEmpty) return;

    try {
      await context.read<UserService>().addEmergencyContact(
        userId: _userId!,
        contact: _contactController.text,
      );
      _contactController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding contact: $e')),
        );
      }
    }
  }

  Future<void> _removeContact(String contact) async {
    if (_userId == null) return;

    try {
      await context.read<UserService>().removeEmergencyContact(
        userId: _userId!,
        contact: contact,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing contact: $e')),
        );
      }
    }
  }

  Future<void> _toggleShareData(bool value) async {
    if (_userId == null) return;
    
    try {
      await context.read<UserService>().updateConsent(
        userId: _userId!,
        consent: value,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating consent: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authUser = FirebaseAuth.instance.currentUser;

    if (authUser == null || _userStream == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: StreamBuilder<UserModel?>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading profile data.', style: TextStyle(color: Colors.red)),
            );
          }

          final userModel = snapshot.data;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Icon(Icons.account_circle, size: 80, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    authUser.email ?? 'Unknown User',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  
                  const Divider(),
                  const Text(
                    'Emergency Contacts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _contactController,
                          decoration: const InputDecoration(
                            labelText: 'Add Phone Number',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _addContact,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  if (userModel == null || userModel.emergencyContacts.isEmpty)
                    const Text('No emergency contacts found.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: userModel.emergencyContacts.length,
                      itemBuilder: (context, index) {
                        final contact = userModel.emergencyContacts[index];
                        return ListTile(
                          leading: const Icon(Icons.contact_emergency),
                          title: Text(contact),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeContact(contact),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 30),
                  const Divider(),
                  const Text(
                    'Theme Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ListTile(
                    title: const Text('Dark Mode'),
                    trailing: IconButton(
                      icon: Icon(
                        themeProvider.themeMode == ThemeMode.dark
                            ? Icons.light_mode
                            : Icons.dark_mode,
                      ),
                      onPressed: () => themeProvider.toggleTheme(),
                      tooltip: 'Toggle Theme',
                    ),
                  ),
                  ListTile(
                    title: const Text('System Default Theme'),
                    trailing: IconButton(
                      icon: const Icon(Icons.auto_mode),
                      onPressed: () => themeProvider.setSystemTheme(),
                      tooltip: 'Set System Theme',
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Divider(),
                  const Text(
                    'Privacy Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SwitchListTile(
                    title: const Text('Share Data for Research'),
                    subtitle: const Text('Help us improve medical AI by sharing anonymized health data.'),
                    value: userModel?.shareDataResearch ?? false,
                    onChanged: _toggleShareData,
                    secondary: const Icon(Icons.science),
                  ),

                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
