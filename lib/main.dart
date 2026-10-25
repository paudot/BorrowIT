import 'package:borrow_it/equipment_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase must start first or every Firebase call crashes with "No Firebase App"
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Sets up notifications. If this is removed the app runs but no notification shows
  await initNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BorrowIT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF1E40AF)),
        scaffoldBackgroundColor: Color(0xFFFAF9F5),
        useMaterial3: true,
      ),
      
      // Logged in users go to EquipmentPage, everyone else goes to LoginPage
      home: FirebaseAuth.instance.currentUser == null ? LoginPage() : EquipmentPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}