import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String error = '';
  String _selectedServer = 'Iran Server';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _auth.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
        setState(() {
          error = '';
        });
      } on FirebaseAuthException catch (e) {
        setState(() {
          error = e.message ?? 'An error occurred';
        });
      }
    }
  }

  void _toggleServer() {
    setState(() {
      _selectedServer =
          _selectedServer == 'Iran Server' ? 'Germany Server' : 'Iran Server';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and App Name
                  Icon(
                    Icons.medical_services,
                    size: 100,
                    color: Color(0xFF4CAF50), // Calming Green
                  ),
                  SizedBox(height: 16),
                  Text(
                    "MedMle Expert",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A73E8), // Trustworthy Blue
                    ),
                  ),
                  Text(
                    "Medical Resources",
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF333333), // Dark Gray
                    ),
                  ),
                  SizedBox(height: 40),
                  Divider(color: Color(0xFF4CAF50)), // Calming Green
                  SizedBox(height: 40),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: Color(0xFF333333)),
                    decoration: InputDecoration(
                      hintText: "Username",
                      prefixIcon: Icon(
                        Icons.person,
                        color: Color(0xFFB0BEC5),
                      ), // Neutral Gray
                    ),
                    validator: (val) => val!.isEmpty ? "Enter an email" : null,
                  ),
                  SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(color: Color(0xFF333333)),
                    decoration: InputDecoration(
                      hintText: "Password",
                      prefixIcon: Icon(
                        Icons.lock,
                        color: Color(0xFFB0BEC5),
                      ), // Neutral Gray
                    ),
                    validator:
                        (val) =>
                            val!.length < 6
                                ? "Password must be 6+ chars"
                                : null,
                  ),
                  SizedBox(height: 8),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        if (_emailController.text.isNotEmpty) {
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: _emailController.text,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Password reset email sent"),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Please enter your email")),
                          );
                        }
                      },
                      child: Text(
                        "Forgot Password ?",
                        style: TextStyle(
                          color: Color(0xFF1A73E8),
                        ), // Trustworthy Blue
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      child: Text(
                        "LOGIN",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Error Message
                  if (error.isNotEmpty)
                    Text(
                      error,
                      style: TextStyle(color: Color(0xFFD32F2F)), // Error Red
                    ),
                  SizedBox(height: 16),

                  // Server Selection
                  GestureDetector(
                    onTap: _toggleServer,
                    child: Text(
                      "$_selectedServer (Tap to change)",
                      style: TextStyle(
                        color: Color(0xFFB0BEC5),
                      ), // Neutral Gray
                    ),
                  ),
                  SizedBox(height: 40),

                  // Social Media Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.telegram,
                          color: Color(0xFF1A73E8),
                        ), // Trustworthy Blue
                        onPressed: () {
                          print("Open Telegram");
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: Color(0xFF4CAF50),
                        ), // Calming Green
                        onPressed: () {
                          print("Open Instagram");
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.email,
                          color: Color(0xFFD32F2F),
                        ), // Error Red
                        onPressed: () {
                          print("Open Email");
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
