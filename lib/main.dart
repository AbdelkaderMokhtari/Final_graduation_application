import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/administration/administration_dashboard.dart';
import 'screens/worker/worker_dashboard.dart';
import 'screens/citizen_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}

/// 🔥 النظام الذكي لتحديد الصفحة
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ⏳ تحميل
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 👤 لا يوجد مستخدم → شاشة المواطن (وليس Login)
        if (!snapshot.hasData) {
          return const CitizenScreen();
        }

        final user = snapshot.data!;

        // 🔎 جلب الدور من Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!roleSnapshot.hasData || !roleSnapshot.data!.exists) {
              return const CitizenScreen();
            }

            final data = roleSnapshot.data!.data() as Map<String, dynamic>?;

            if (data == null || !data.containsKey('role')) {
              return const CitizenScreen();
            }

            final role = data['role'];

            /// 🔀 تحويل حسب الدور
            switch (role) {
              case 'admin':
                return const AdminDashboard();

              case 'administration':
                return const AdministrationDashboard();

              case 'worker':
                return const WorkerScreen();

              default:
                return const CitizenScreen();
            }
          },
        );
      },
    );
  }
}
