// lib/screens/language_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  static const List<Map<String, String>> languages = [
    {'code': 'en', 'label': 'English', 'native': 'English'},
    {'code': 'te', 'label': 'Telugu', 'native': 'తెలుగు'},
    {'code': 'hi', 'label': 'Hindi', 'native': 'हिन्दी'},
    {'code': 'ta', 'label': 'Tamil', 'native': 'தமிழ்'},
    {'code': 'kn', 'label': 'Kannada', 'native': 'ಕನ್ನಡ'},
    {'code': 'ml', 'label': 'Malayalam', 'native': 'മലയാളം'},
    {'code': 'mr', 'label': 'Marathi', 'native': 'मराठी'},
    {'code': 'bn', 'label': 'Bengali', 'native': 'বাংলা'},
  ];

  Future<void> _selectLanguage(BuildContext context, String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);
    if (!context.mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // App icon/logo area
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D9E75),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'MedCare',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D3A2E),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'Select your language',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.4,
                  ),
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    return _LanguageTile(
                      label: lang['label']!,
                      native: lang['native']!,
                      code: lang['code']!,
                      onTap: () => _selectLanguage(context, lang['code']!),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label, native, code;
  final VoidCallback onTap;
  const _LanguageTile({
    required this.label,
    required this.native,
    required this.code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Text(
              code.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  native,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D3A2E),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
