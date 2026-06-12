import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:smart_aid/screens/emergency_screen.dart';
import 'package:smart_aid/screens/health_records_screen.dart';
import 'package:smart_aid/screens/home_screen.dart';
import 'package:smart_aid/screens/profile_screen.dart';
import 'package:smart_aid/screens/nearby_hospitals_screen.dart';
import 'package:smart_aid/screens/doctor_dashboard_screen.dart';
import 'package:smart_aid/services/user_service.dart';
import 'package:smart_aid/models/user_model.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Stream<UserModel?>? _userStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStream = context.read<UserService>().getUserStream(user.uid);
    }
  }

  static const List<Widget> _patientWidgetOptions = <Widget>[
    HomeScreen(),
    HealthRecordsScreen(),
    NearbyHospitalsScreen(),
    EmergencyScreen(),
    ProfileScreen(),
  ];

  static const List<Widget> _doctorWidgetOptions = <Widget>[
    DoctorDashboardScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    if (_userStream == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return StreamBuilder<UserModel?>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Constraint: Missing or malformed role fields must fail safely to patient mode
        bool isDoctor = snapshot.data?.isDoctor ?? false;

        // Make sure index is within bounds if we switch roles (e.g., debugging)
        final widgetOptions = isDoctor ? _doctorWidgetOptions : _patientWidgetOptions;
        if (_selectedIndex >= widgetOptions.length) {
          _selectedIndex = 0;
        }

        return Scaffold(
          body: Center(child: widgetOptions.elementAt(_selectedIndex)),
          bottomNavigationBar: isDoctor
              ? BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard),
                      label: 'Dashboard',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  selectedItemColor: Colors.amber[800],
                  onTap: _onItemTapped,
                )
              : BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.folder_shared),
                      label: 'Health Records',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.local_hospital),
                      label: 'Hospitals',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.emergency),
                      label: 'Emergency',
                    ),
                    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                  ],
                  currentIndex: _selectedIndex,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: Colors.amber[800],
                  onTap: _onItemTapped,
                ),
        );
      },
    );
  }
}
