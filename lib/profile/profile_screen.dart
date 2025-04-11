import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Keep for user info
// import 'package:cloud_firestore/cloud_firestore.dart'; // REMOVE if not needed elsewhere
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import '../downloads/downloads_screen.dart';
import '../subscription/subscription_service.dart'; // <-- IMPORT new service

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  DateTime? subscriptionEndDate;
  int remainingDays = 0;
  String subscriptionPackage = 'Loading...'; // Add state for package name
  Timer? _timer;
  bool _isLoading = true; // Keep loading state
  String _errorMessage = '';
  String? _selectedDownloadPath;

  // Switches state
  bool _hideListOnSelect = true;
  bool _lockInFullscreen = true;

  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');
  final SubscriptionService _subscriptionService =
      SubscriptionService(); // Instantiate service

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionData(); // Call the modified function
    _loadDownloadPathPreference();
    _timer = Timer.periodic(const Duration(hours: 1), (timer) {
      if (subscriptionEndDate != null) {
        _calculateRemainingDays();
      }
    });
  }

  // --- MODIFIED: Use Static Data ---
  Future<void> _fetchSubscriptionData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Simulate a slight delay like a network call might have
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      // Get static data directly from the service
      final details = _subscriptionService.getStaticSubscriptionDetails();

      if (mounted) {
        setState(() {
          subscriptionEndDate = details.endDate;
          subscriptionPackage = details.package; // Store package name
          _calculateRemainingDays(); // Calculate based on the static date
          _isLoading = false; // Loading finished
          _errorMessage = ''; // Clear any previous error
        });
      }
    } catch (e) {
      // Should ideally not happen with static data unless service throws error
      print("Error getting static subscription data: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading subscription info.";
          _isLoading = false;
        });
      }
    }
  }
  // --- END MODIFIED SECTION ---

  // --- Load/Save/Select Download Path Methods (Keep as they are) ---
  Future<void> _loadDownloadPathPreference() async {
    /* ... Keep ... */
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        if (mounted) {
          setState(() {
            _selectedDownloadPath = directory.path;
          });
        }
      } catch (e) {
        print("Error getting default doc dir: $e");
      }
    }
  }

  Future<void> _saveDownloadPathPreference(String path) async {
    /* ... Keep ... */
    setState(() {
      _selectedDownloadPath = path;
    });
    print("Download path preference saved (simulation): $path");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Download path preference updated (simulated)"),
        ),
      );
    }
  }

  Future<void> _selectDownloadPath() async {
    /* ... Keep ... */
    try {
      String? directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Download Folder',
      );
      if (directoryPath != null) {
        await _saveDownloadPathPreference(directoryPath);
      } else {
        print('User cancelled download path selection.'); /* Show SnackBar */
      }
    } catch (e) {
      print("Error selecting directory: $e"); /* Show SnackBar */
    }
  }
  // -----------------------------------------------------------

  void _calculateRemainingDays() {
    // Keep this method as is
    if (subscriptionEndDate == null) {
      setState(() => remainingDays = 0);
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDateOnly = DateTime(
      subscriptionEndDate!.year,
      subscriptionEndDate!.month,
      subscriptionEndDate!.day,
    );
    final difference = endDateOnly.difference(today);
    setState(() {
      remainingDays = difference.inDays;
      if (remainingDays < 0) remainingDays = 0;
    });
  }

  // --- MODIFIED: Disable Extend Subscription ---
  Future<void> _showStaticDataMessage() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Subscription management disabled (using static data).",
          ),
        ),
      );
    }
  }
  // --- END MODIFIED SECTION ---

  // --- Keep _launchURL, _logout, _deleteTempFiles ---
  Future<void> _launchURL(String urlString) async {
    /* ... Keep ... */
  }
  Future<void> _logout() async {
    /* ... Keep ... */
  }
  Future<void> _deleteTempFiles() async {
    /* ... Keep ... */
  }
  // ---------------------------------------------

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Account & Settings")),
      body:
          _isLoading // Show loading indicator until static data is processed
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage
                  .isNotEmpty // Show error if static data somehow failed
              ? Center(
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: colorScheme.error),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Account & Subscription Section ---
                    _buildSectionTitle(context, "Account & Subscription"),
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Email (Still uses AuthService)
                            _buildInfoRow(
                              Icons.email_outlined,
                              "Email:",
                              AuthService().currentUser?.email ??
                                  "Not logged in",
                            ),
                            const Divider(height: 20),
                            // Subscription Status (Uses state set from static data)
                            _buildInfoRow(
                              Icons.workspace_premium_outlined,
                              "Status:",
                              subscriptionEndDate == null
                                  ? "No Subscription Data" // Changed message
                                  : subscriptionEndDate!.isAfter(DateTime.now())
                                  ? "$subscriptionPackage - Active" // Show package name
                                  : "Subscription Expired",
                              valueColor:
                                  subscriptionEndDate?.isAfter(
                                            DateTime.now(),
                                          ) ??
                                          false
                                      ? colorScheme.primary
                                      : colorScheme.error,
                            ),
                            if (subscriptionEndDate != null) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.calendar_today_outlined,
                                "Active Until:",
                                _dateFormatter.format(subscriptionEndDate!),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.hourglass_bottom_outlined,
                                "Remaining:",
                                "$remainingDays Days",
                              ),
                            ],
                            const Divider(height: 20),
                            Text(
                              "Extend Subscription:",
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // --- MODIFIED: Disabled Buttons ---
                                ElevatedButton(
                                  onPressed:
                                      _showStaticDataMessage, // Call message function
                                  child: const Text("6 Months"),
                                ),
                                ElevatedButton(
                                  onPressed:
                                      _showStaticDataMessage, // Call message function
                                  child: const Text("12 Months"),
                                ),
                                // --- END MODIFIED SECTION ---
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Settings Section (Keep as is) ---
                    _buildSectionTitle(context, "Settings"),
                    Card(/* ... Settings ListTiles ... */),
                    const SizedBox(height: 16),

                    // --- Maintenance Actions (Keep as is) ---
                    _buildSectionTitle(context, "Maintenance"),
                    Card(/* ... Maintenance ListTiles ... */),
                    const SizedBox(height: 24),

                    // --- About & Support Section (Keep as is) ---
                    _buildSectionTitle(context, "About & Support"),
                    Card(/* ... About ListTiles ... */),
                    const SizedBox(height: 24),

                    // --- Log Out Button (Keep as is) ---
                    // --- Log Out Button ---
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout), // Add the icon
                        label: const Text("Log Out"), // Add the label
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              colorScheme.error, // Use error color for logout
                          foregroundColor: colorScheme.onError,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                        ),
                        onPressed: _logout, // Add the onPressed handler
                      ),
                    ),
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
    );
  }

  // --- Helper Widgets (Keep as they are) ---
  // --- Helper Widgets ---
  Widget _buildSectionTitle(BuildContext context, String title) {
    // Ensure this returns a Widget
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ); // Added return
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    // Ensure this returns a Widget
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 12),
        Text("$label ", style: Theme.of(context).textTheme.bodyMedium),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.end, // Align value to the right
          ),
        ),
      ],
    ); // Added return
  }

  Widget _buildLinkTile(
    BuildContext context,
    IconData icon,
    String title,
    String url,
  ) {
    // Ensure this returns a Widget
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(title),
      trailing: const Icon(Icons.open_in_new_outlined, size: 18),
      onTap: () => _launchURL(url),
    ); // Added return
  }

  // -------------------------------------------------------------------------------
}
