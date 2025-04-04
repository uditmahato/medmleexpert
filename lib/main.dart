import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/auth_service.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDT19wJzp9ce7T11e98S3IVMGslI9TrQFM",
      authDomain: "medmleexpert.firebaseapp.com",
      projectId: "medmleexpert",
      storageBucket: "medmleexpert.firebasestorage.app",
      messagingSenderId: "569834885497",
      appId: "1:569834885497:web:816817f4af71fe4787dfa8",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
      theme: ThemeData(
        // Primary color for buttons, AppBar, etc.
        primaryColor: Color(0xFF1A73E8), // Trustworthy Blue
        // Secondary color for accents
        colorScheme: ColorScheme.light(
          primary: Color(0xFF1A73E8),
          secondary: Color(0xFF4CAF50), // Calming Green
          error: Color(0xFFD32F2F), // Error Red
          surface: Color(0xFFF5F7FA), // Background
        ),
        // Background color for Scaffold
        scaffoldBackgroundColor: Color(0xFFF5F7FA), // Clean White
        // AppBar theme
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1A73E8), // Trustworthy Blue
          foregroundColor: Colors.white, // Text/icons on AppBar
          elevation: 0,
        ),
        // Text theme
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            color: Color(0xFF333333),
          ), // Dark Gray for body text
          bodyMedium: TextStyle(color: Color(0xFF333333)),
          titleLarge: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
          ),
        ),
        // Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1A73E8), // Trustworthy Blue
            foregroundColor: Colors.white, // Text/icon color on buttons
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        // Card theme
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Color(0xFFB0BEC5),
              width: 1,
            ), // Neutral Gray border
          ),
        ),
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFFB0BEC5)), // Neutral Gray
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Color(0xFF1A73E8),
            ), // Trustworthy Blue
          ),
          hintStyle: TextStyle(color: Color(0xFFB0BEC5)), // Neutral Gray
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      key: ValueKey("auth_stream"),
      stream: AuthService().user,
      builder: (context, snapshot) {
        print("AuthWrapper: Connection state: ${snapshot.connectionState}");
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            print(
              "AuthWrapper: User is not logged in, navigating to LoginScreen",
            );
            return LoginScreen();
          } else {
            print(
              "AuthWrapper: User is logged in (UID: ${user.uid}), navigating to HomeScreen",
            );
            return HomeScreen();
          }
        } else {
          print("AuthWrapper: Waiting for connection state to be active");
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
      },
    );
  }
}
