import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:our_community_fund/core/config/firebase_config.dart';
import 'package:our_community_fund/presentation/providers/app_providers.dart';
import 'package:our_community_fund/presentation/providers/theme_provider.dart';
import 'package:our_community_fund/presentation/screens/auth/login_screen.dart';
import 'package:our_community_fund/presentation/screens/auth/register_screen.dart';
import 'package:our_community_fund/presentation/screens/auth/forgot_password_screen.dart';
import 'package:our_community_fund/screens/admin/admin_home_screen.dart';
import 'package:our_community_fund/screens/user/user_home_screen.dart';
import 'package:our_community_fund/services/auth_service.dart';
import 'package:our_community_fund/theme/app_theme.dart';
import 'package:our_community_fund/widgets/connectivity_wrapper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:our_community_fund/services/firebase_messaging_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseConfig.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  final prefs = await SharedPreferences.getInstance();
  runApp(MainApp(prefs: prefs));
}

class MainApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MainApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildAppProviders(prefs),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => ConnectivityWrapper(
          child: MaterialApp(
            title: 'Our Community Fund',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(null),
            darkTheme: AppTheme.darkTheme(null),
            themeMode: themeProvider.themeMode,
            builder: (context, child) {
              // Limit text scaling to prevent UI overflow from accessibility settings
              final mediaQueryData = MediaQuery.of(context);
              final constrainedTextScaleFactor =
                  mediaQueryData.textScaler.clamp(
                minScaleFactor: 0.8,
                maxScaleFactor: 1.2,
              );

              return MediaQuery(
                data: mediaQueryData.copyWith(
                  textScaler: constrainedTextScaleFactor,
                ),
                child: Theme(
                  data: themeProvider.themeMode == ThemeMode.dark
                      ? AppTheme.darkTheme(null)
                      : AppTheme.lightTheme(null),
                  child: child!,
                ),
              );
            },
            home: const AuthWrapper(),
            routes: {
              '/register': (context) => const RegisterScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
            },
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    if (user == null) {
      return const LoginScreen();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Something went wrong')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await context.read<AuthService>().signOut();
          });

          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Redirecting to login...'),
                ],
              ),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final isAdmin = userData['isAdmin'] ?? false;

        return isAdmin ? const AdminHomeScreen() : const UserHomeScreen();
      },
    );
  }
}
