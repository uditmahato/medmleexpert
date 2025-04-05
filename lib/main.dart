import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/auth_service.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = await Firebase.initializeApp(
    options: const FirebaseOptions(
	apiKey: "AIzaSyDT19wJzp9ce7T11e98S3IVMGslI9TrQFM",
  authDomain: "medmleexpert.firebaseapp.com",
  projectId: "medmleexpert",
  storageBucket: "medmleexpert.appspot.com",
  messagingSenderId: "569834885497",
  appId: "1:569834885497:web:816817f4af71fe4787dfa8",
  databaseURL: "https://medmleexpert.firebaseio.com"
    ),
  );
  print("Firebase project ID: ${app.options.projectId}");
  // Explicitly set the Firestore database to '(default)'
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  print("Firestore database: ${FirebaseFirestore.instance.app.options.projectId}");
  runApp(MyApp());
}

// Rest of the main.dart remains the same
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
        primaryColor: Color(0xFF1A73E8),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF1A73E8),
          secondary: Color(0xFF4CAF50),
          error: Color(0xFFD32F2F),
          surface: Color(0xFFF5F7FA),
        ),
        scaffoldBackgroundColor: Color(0xFFF5F7FA),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1A73E8),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF333333)),
          bodyMedium: TextStyle(color: Color(0xFF333333)),
          titleLarge: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1A73E8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Color(0xFFB0BEC5), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFFB0BEC5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF1A73E8)),
          ),
          hintStyle: TextStyle(color: Color(0xFFB0BEC5)),
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
