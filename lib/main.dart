import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:our_community_fund/screens/auth/login_screen.dart';
import 'package:our_community_fund/screens/auth/register_screen.dart';
import 'package:our_community_fund/screens/auth/forgot_password_screen.dart';
import 'package:our_community_fund/screens/admin/admin_home_screen.dart';
import 'package:our_community_fund/screens/user/user_home_screen.dart';
import 'package:our_community_fund/services/auth_service.dart';
import 'package:our_community_fund/theme/app_theme.dart';
import 'package:our_community_fund/widgets/connectivity_wrapper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: ConnectivityWrapper(
        child: MaterialApp(
          title: 'Our Community Fund',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(null),
          darkTheme: AppTheme.darkTheme(null),
          themeMode: ThemeMode.system,
          home: const AuthWrapper(),
          routes: {
            '/register': (context) => const RegisterScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
          },
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
            body: Center(
              child: Text('Something went wrong'),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(
              child: Text('User data not found'),
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
