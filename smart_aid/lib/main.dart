import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:smart_aid/theme/app_theme.dart';
import 'package:smart_aid/providers/theme_provider.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_aid/screens/auth_screen.dart';
import 'package:smart_aid/screens/main_screen.dart';

import 'package:smart_aid/services/user_service.dart';
import 'package:smart_aid/services/medication_service.dart';
import 'package:smart_aid/services/appointment_service.dart';
import 'package:smart_aid/services/health_record_service.dart';
import 'package:smart_aid/analytics/services/adherence_analytics_service.dart';
import 'package:smart_aid/analytics/services/research_analytics_service.dart';
import 'package:smart_aid/analytics/intelligence/services/product_insights_service.dart';
import 'package:smart_aid/reports/services/report_generation_service.dart';
import 'package:smart_aid/ai/services/ai_insight_service.dart';
import 'package:smart_aid/offline/services/offline_sync_service.dart';
import 'package:smart_aid/services/notification_service.dart';

import 'package:smart_aid/repositories/user_repository.dart';
import 'package:smart_aid/repositories/medication_repository.dart';
import 'package:smart_aid/repositories/appointment_repository.dart';
import 'package:smart_aid/repositories/health_record_repository.dart';
import 'package:smart_aid/repositories/doctor_dashboard_repository.dart';
import 'package:smart_aid/repositories/places_repository.dart';

import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notifications (permissions + timezone)
  await NotificationService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Repositories
        Provider(create: (_) => UserRepository()),
        Provider(create: (_) => MedicationRepository()),
        Provider(create: (_) => AppointmentRepository()),
        Provider(create: (_) => HealthRecordRepository()),
        Provider(create: (_) => DoctorDashboardRepository()),
        Provider(create: (_) => PlacesRepository()),

        // Services
        ProxyProvider<UserRepository, UserService>(
          update: (_, repo, _) => UserService(userRepository: repo),
        ),
        ProxyProvider<MedicationRepository, MedicationService>(
          update: (_, repo, _) => MedicationService(medicationRepository: repo),
        ),
        ProxyProvider<AppointmentRepository, AppointmentService>(
          update: (_, repo, _) => AppointmentService(appointmentRepository: repo),
        ),
        ProxyProvider<HealthRecordRepository, HealthRecordService>(
          update: (_, repo, _) => HealthRecordService(healthRecordRepository: repo),
        ),
        
        // Analytics Services
        ProxyProvider<MedicationRepository, AdherenceAnalyticsService>(
          update: (_, repo, _) => AdherenceAnalyticsService(medicationRepository: repo),
        ),
        ProxyProvider<DoctorDashboardRepository, ResearchAnalyticsService>(
          update: (_, repo, _) => ResearchAnalyticsService(doctorDashboardRepository: repo),
        ),
        ProxyProvider<MedicationRepository, ProductInsightsService>(
          update: (_, repo, _) => ProductInsightsService(medicationRepository: repo),
        ),
        ProxyProvider3<MedicationService, AppointmentService, ProductInsightsService, ReportGenerationService>(
          update: (_, med, appt, insights, _) => ReportGenerationService(
            medicationService: med,
            appointmentService: appt,
            insightsService: insights,
          ),
        ),
        Provider<AiInsightService>(
          create: (_) => AiInsightService(apiKey: const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '')),
        ),
        ChangeNotifierProxyProvider2<MedicationRepository, AppointmentRepository, OfflineSyncService>(
          create: (context) => OfflineSyncService(
            medicationRepository: context.read<MedicationRepository>(),
            appointmentRepository: context.read<AppointmentRepository>(),
          ),
          update: (_, med, appt, prev) => prev ?? OfflineSyncService(
            medicationRepository: med,
            appointmentRepository: appt,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: 'Smart AID',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: _router,
        );
      },
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((dynamic _) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isGoingToAuth = state.matchedLocation == '/auth';

    if (!isLoggedIn && !isGoingToAuth) return '/auth';
    if (isLoggedIn && isGoingToAuth) return '/';

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainScreen()),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
  ],
);
