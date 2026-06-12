import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _isDoctor = false;
  String _email = '';
  String _password = '';
  String _errorMessage = '';

  Future<void> _submitAuthForm() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus(); // Close the keyboard

    if (isValid) {
      _formKey.currentState!.save();
      try {
        if (_isLogin) {
          // Log user in
          await _auth.signInWithEmailAndPassword(
            email: _email.trim(),
            password: _password.trim(),
          );
        } else {
          // Sign user up
          UserCredential userCred = await _auth.createUserWithEmailAndPassword(
            email: _email.trim(),
            password: _password.trim(),
          );
          // Save user role and data to Firestore
          await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
            'email': _email.trim(),
            'isDoctor': _isDoctor,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        // If successful, you can navigate to the home screen here later
      } on FirebaseAuthException catch (error) {
        setState(() {
          _errorMessage =
              error.message ??
              'An error occurred. Please check your credentials.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo.png', height: 150),
                  const SizedBox(height: 16),
                  Text(
                    _isLogin ? 'Welcome Back' : 'Create an Account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 32),
                  // Display error message if any
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextFormField(
                  key: const ValueKey('email'),
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _email = value!;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('password'),
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 6) {
                      return 'Password must be at least 6 characters long.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _password = value!;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Are you a doctor?', style: TextStyle(fontWeight: FontWeight.w500)),
                  value: _isDoctor,
                  onChanged: (bool value) {
                    setState(() {
                      _isDoctor = value;
                    });
                  },
                  secondary: const Icon(Icons.medical_services),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _submitAuthForm,
                  child: Text(_isLogin ? 'Login' : 'Signup'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _errorMessage = ''; // Clear errors on toggle
                    });
                  },
                  child: Text(
                    _isLogin
                        ? 'Create new account'
                        : 'I already have an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
