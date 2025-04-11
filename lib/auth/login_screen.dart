import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart'; // Assuming this handles sign-in logic

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _errorMessage = '';
  bool _isLoading = false; // State for loading indicator during login
  bool _isPasswordVisible = false; // State for password visibility toggle

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Login Function
  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true; // Show loading indicator
        _errorMessage = ''; // Clear previous errors
      });
      try {
        // Let AuthService handle the actual sign-in and navigation (or success feedback)
        await _auth.signInWithEmailAndPassword(
          _emailController.text.trim(), // Trim whitespace
          _passwordController.text.trim(),
        );
        // If sign-in is successful, the AuthWrapper should handle navigation.
        // No need to explicitly navigate here unless AuthService requires it.
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          // Check if widget is still mounted
          setState(() {
            _errorMessage = e.message ?? 'Login failed. Please try again.';
          });
        }
      } catch (e) {
        // Catch other potential errors
        if (mounted) {
          setState(() {
            _errorMessage = 'An unexpected error occurred. Please try again.';
          });
        }
        print("Login Error: $e"); // Log unexpected errors
      } finally {
        if (mounted) {
          // Ensure widget is still mounted before setting state
          setState(() {
            _isLoading = false; // Hide loading indicator
          });
        }
      }
    }
  }

  // Forgot Password Function
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter your email address first."),
          ),
        );
      }
      return;
    }

    // Show loading feedback (optional, simple snackbar used here)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sending password reset email...")),
      );
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password reset email sent to $email")),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: ${e.message ?? 'Could not send reset email.'}",
            ),
          ),
        );
      }
      print("Forgot Password Error: ${e.code} - ${e.message}");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An unexpected error occurred.")),
        );
      }
      print("Forgot Password Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Scaffold(
      // Use AppBar for consistent back navigation if needed, otherwise keep body directly
      // appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent), // Optional transparent AppBar
      body: SafeArea(
        child: Center(
          // Center the content vertically
          child: SingleChildScrollView(
            // Handles smaller screens and keyboard
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 20.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- Logo and App Name ---
                    Icon(
                      Icons.medical_services_outlined, // Using outlined version
                      size: 80, // Slightly smaller
                      color: colorScheme.primary, // Use primary theme color
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "MedMle Expert",
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Medical Resources",
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.secondary, // Use secondary color
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40), // More space before form
                    // --- Email Field ---
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction:
                          TextInputAction.next, // Move to next field
                      decoration: InputDecoration(
                        labelText: "Email / Username", // Use labelText
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: colorScheme.secondary,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        filled: true, // Add subtle background
                        fillColor: colorScheme.onSurface.withOpacity(0.05),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return "Please enter your email/username";
                        // Basic email format check (optional but recommended)
                        // if (!RegExp(r'\S+@\S+\.\S+').hasMatch(val)) return "Please enter a valid email";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- Password Field ---
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible, // Toggle based on state
                      textInputAction: TextInputAction.done, // Submit action
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: colorScheme.secondary,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        filled: true,
                        fillColor: colorScheme.onSurface.withOpacity(0.05),
                        // Suffix icon to toggle visibility
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: colorScheme.secondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator:
                          (val) =>
                              (val?.length ?? 0) < 6
                                  ? "Password must be 6+ characters"
                                  : null,
                      onFieldSubmitted:
                          (_) => _login(), // Allow login on keyboard 'done'
                    ),
                    const SizedBox(height: 8),

                    // --- Forgot Password Link ---
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword, // Call dedicated function
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 4,
                          ), // Reduce padding
                          tapTargetSize:
                              MaterialTapTargetSize
                                  .shrinkWrap, // Reduce tap area
                        ),
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24), // Increased space before button
                    // --- Login Button ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ), // Taller button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Show loading indicator on the button or disable it
                        onPressed: _isLoading ? null : _login,
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text("LOGIN"),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Error Message ---
                    AnimatedOpacity(
                      // Fade error message in/out
                      opacity: _errorMessage.isNotEmpty ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _errorMessage.isNotEmpty
                            ? _errorMessage
                            : '', // Ensure empty string when hidden
                        style: TextStyle(color: colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Removed Server Selection
                    // Removed Social Media Icons
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
