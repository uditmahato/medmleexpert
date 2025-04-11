import 'dart:async';
import 'package:flutter/material.dart';
// Keep for user info
// import 'package:cloud_firestore/cloud_firestore.dart'; // Not needed for static data
import 'package:intl/intl.dart'; // For date formatting
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening links
import 'package:file_picker/file_picker.dart'; // For directory selection
import 'package:path_provider/path_provider.dart'; // To potentially show current path
import 'dart:io'; // For Directory and Platform
import 'package:flutter/foundation.dart' show kIsWeb; // For kIsWeb check
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
// Keep if AppBar icon needs it
import '../subscription/subscription_service.dart'; // Import static subscription service

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // State variables
  DateTime? subscriptionEndDate;
  int remainingDays = 0;
  String subscriptionPackage = 'Loading...';
  Timer? _timer;
  bool _isLoading = true;
  String _errorMessage = '';
  String? _selectedDownloadPath;

  // State for Switches
  bool _hideListOnSelect = true;
  bool _lockInFullscreen = true;
  // Add more state variables for other switches if you implement them

  // State for Expansion Tiles
  bool _isSettingsExpanded = false; // Start collapsed
  bool _isMaintenanceExpanded = false;
  bool _isAboutExpanded = false;

  // Keys for SharedPreferences
  static const String _hideListPrefKey = 'hideListOnSelect';
  static const String _lockFullscreenPrefKey = 'lockInFullscreen';
  static const String _downloadPathPrefKey = 'downloadPath';

  // Services and Formatters
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');
  final SubscriptionService _subscriptionService = SubscriptionService();

  @override
  @override
  void initState() {
    super.initState();
    // --- CALL THIS FUNCTION FIRST ---
    _loadAllPreferences();
    // --------------------------------
    _fetchSubscriptionData(); // Then fetch dynamic data
    // _loadDownloadPathPreference(); // This is now part of _loadAllPreferences
    _timer = Timer.periodic(const Duration(hours: 1), (timer) {
      if (subscriptionEndDate != null) {
        _calculateRemainingDays();
      }
    });
  }

  // --- ADD THIS FUNCTION ---
  // Loads all saved preferences
  Future<void> _loadAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load switch states, providing default values if not found
      _hideListOnSelect =
          prefs.getBool(_hideListPrefKey) ?? true; // Default true
      _lockInFullscreen =
          prefs.getBool(_lockFullscreenPrefKey) ?? true; // Default true
      _selectedDownloadPath = prefs.getString(
        _downloadPathPrefKey,
      ); // Load saved path
    });
    // If no saved path, try getting default app docs path (moved from separate func)
    if (_selectedDownloadPath == null) {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          if (mounted) {
            // Set only if still null
            setState(() {
              _selectedDownloadPath = directory.path;
            });
          }
        } catch (e) {
          print("Error getting default doc dir: $e");
        }
      }
    }
  }

  // --- ADD THIS FUNCTION ---
  // Saves a boolean preference
  Future<void> _saveBoolPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    print("Saved preference: $key = $value");
  }

  // --- ADD THIS FUNCTION ---
  // Saves a string preference
  Future<void> _saveStringPreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    print("Saved preference: $key = $value");
  }

  // --- ADD THESE PLACEHOLDER FUNCTIONS for Maintenance ---
  Future<void> _checkForUpdate() async {
    print("Check App Update tapped");
    // TODO: Implement actual update check logic
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Checking for updates... (simulation)")),
      );
      await Future.delayed(const Duration(seconds: 1)); // Simulate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("App is up to date (simulation)")),
        );
      }
    }
  }

  Future<void> _backupData() async {
    print("Backup tapped");
    // TODO: Implement actual backup logic
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Starting backup... (simulation)")),
      );
      await Future.delayed(const Duration(seconds: 1)); // Simulate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Backup complete (simulation)")),
        );
      }
    }
  }

  Future<void> _restoreData() async {
    print("Restore tapped");
    // TODO: Implement actual restore logic
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Starting restore... (simulation)")),
      );
      await Future.delayed(const Duration(seconds: 1)); // Simulate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Restore complete (simulation)")),
        );
      }
    }
  }

  // ----------------------------------------------------
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Data Fetching & Calculation ---
  Future<void> _fetchSubscriptionData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate delay
    try {
      final details = _subscriptionService.getStaticSubscriptionDetails();
      if (mounted) {
        setState(() {
          subscriptionEndDate = details.endDate;
          subscriptionPackage = details.package;
          _calculateRemainingDays();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error getting static subscription data: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading subscription info.";
          _isLoading = false;
        });
      }
    }
  }

  void _calculateRemainingDays() {
    if (subscriptionEndDate == null) {
      if (mounted) setState(() => remainingDays = 0);
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
    if (mounted) {
      setState(() {
        remainingDays = difference.inDays < 0 ? 0 : difference.inDays;
      });
    }
  }

  // --- Preference Handling (Placeholders/Simulation) ---
  Future<void> _loadDownloadPathPreference() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        if (mounted)
          setState(() {
            _selectedDownloadPath = directory.path;
          });
      } catch (e) {
        print("Error getting default doc dir: $e");
      }
    }
  }

  Future<void> _saveDownloadPathPreference(String path) async {
    // Placeholder - Save using shared_preferences in real app
    if (mounted) setState(() => _selectedDownloadPath = path);
    print("Download path preference saved (simulation): $path");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Download path preference updated (simulated)"),
        ),
      );
    }
  }

  // --- UI Actions ---
  Future<void> _selectDownloadPath() async {
    try {
      String? directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Download Folder',
        initialDirectory:
            _selectedDownloadPath, // Start from previously selected path
      );
      if (directoryPath != null) {
        // --- ADD THIS LINE ---
        await _saveStringPreference(_downloadPathPrefKey, directoryPath);
        // ---------------------
        if (mounted) {
          setState(
            () => _selectedDownloadPath = directoryPath,
          ); // Update UI immediately
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Download path updated")),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download path selection cancelled.')),
        );
      }
    } catch (e) {
      print("Error selecting directory: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting folder: $e')));
      }
    }
  }

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

  Future<void> _launchURL(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      print('Could not launch $urlString');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $urlString')),
        );
      }
    }
  }

  Future<void> _deleteTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (!await tempDir.exists()) {
        print("Temp directory doesn't exist.");
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No temporary files found to delete."),
            ),
          );
        return;
      }
      final files = tempDir.listSync();
      int count = 0;
      for (var file in files) {
        try {
          if (file is File) {
            await file.delete();
            count++;
          } else if (file is Directory) {
            await file.delete(recursive: true); /* Optionally delete subdirs */
          }
        } catch (e) {
          print(
            "Error deleting file/dir ${file.path}: $e",
          ); // Log specific errors
        }
      }
      print("Attempted to delete $count temporary files/dirs.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Deleted $count temporary items.")),
        );
      }
    } catch (e) {
      print("Error accessing/deleting temp files: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error clearing temporary files: $e")),
        );
      }
    }
  }

  Future<void> _logout() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await AuthService().signOut();
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Logged out successfully")));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error logging out: $e")));
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Account & Settings")),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: colorScheme.error, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Account & Subscription Section (Always Visible) ---
                    _buildSectionTitle(context, "Account & Subscription"),
                    Card(
                      elevation: 2,
                      clipBehavior:
                          Clip.antiAlias, // Ensures corners are clipped
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              Icons.email_outlined,
                              "Email:",
                              AuthService().currentUser?.email ??
                                  "Not logged in",
                            ),
                            const Divider(height: 20, thickness: 0.5),
                            _buildInfoRow(
                              Icons.workspace_premium_outlined,
                              "Status:",
                              subscriptionEndDate == null
                                  ? "No Subscription Data"
                                  : subscriptionEndDate!.isAfter(DateTime.now())
                                  ? "$subscriptionPackage - Active"
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
                            const Divider(height: 20, thickness: 0.5),
                            Text(
                              "Extend Subscription:",
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: _showStaticDataMessage,
                                  child: const Text("6 Months"),
                                ),
                                ElevatedButton(
                                  onPressed: _showStaticDataMessage,
                                  child: const Text("12 Months"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Settings Section (Expandable) ---
                    ExpansionTile(
                      initiallyExpanded: _isSettingsExpanded,
                      onExpansionChanged:
                          (bool expanding) =>
                              setState(() => _isSettingsExpanded = expanding),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ), // Match card shape
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      backgroundColor: theme.colorScheme.surfaceVariant
                          .withOpacity(0.3), // Subtle background when expanded
                      collapsedBackgroundColor:
                          theme.cardColor, // Match card color when collapsed
                      title: _buildSectionTitle(context, "Settings"),
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ), // Padding for title
                      childrenPadding: const EdgeInsets.only(
                        bottom: 8.0,
                        left: 0,
                        right: 0,
                      ), // Padding for children list
                      children: <Widget>[
                        // No need for inner Card if ExpansionTile is styled
                        Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.folder_open_outlined,
                                color: colorScheme.secondary,
                              ),
                              title: const Text("Select Download Path"),
                              subtitle: Text(
                                _selectedDownloadPath ?? "Not set",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: _selectDownloadPath,
                              trailing: const Icon(Icons.chevron_right),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            SwitchListTile(
                              title: const Text("Hide List On Select"),
                              secondary: Icon(
                                Icons.visibility_off_outlined,
                                color: colorScheme.secondary,
                              ),
                              value: _hideListOnSelect,
                              contentPadding: const EdgeInsets.only(
                                left: 16.0,
                                right: 8.0,
                              ), // Adjust padding for switch
                              onChanged: (value) {
                                setState(() => _hideListOnSelect = value);
                                _saveBoolPreference(
                                  _hideListPrefKey,
                                  value,
                                ); // <-- ADD THIS
                                print("Hide List On Select: $value");
                              },
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            SwitchListTile(
                              title: const Text("Lock in Fullscreen (PDF)"),
                              secondary: Icon(
                                Icons.fullscreen_outlined,
                                color: colorScheme.secondary,
                              ),
                              value: _lockInFullscreen,
                              contentPadding: const EdgeInsets.only(
                                left: 16.0,
                                right: 8.0,
                              ),
                              onChanged: (value) {
                                setState(() => _lockInFullscreen = value);
                                _saveBoolPreference(
                                  _lockFullscreenPrefKey,
                                  value,
                                ); // <-- ADD THIS
                                print("Lock in Fullscreen: $value");
                              },
                            ),
                            // TODO: Add other settings as SwitchListTile or ListTile here
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16), // Space between sections
                    // --- Maintenance Section (Expandable) ---
                    ExpansionTile(
                      initiallyExpanded: _isMaintenanceExpanded,
                      onExpansionChanged:
                          (bool expanding) => setState(
                            () => _isMaintenanceExpanded = expanding,
                          ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      backgroundColor: theme.colorScheme.surfaceVariant
                          .withOpacity(0.3),
                      collapsedBackgroundColor: theme.cardColor,
                      title: _buildSectionTitle(context, "Maintenance"),
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      childrenPadding: const EdgeInsets.only(
                        bottom: 8.0,
                        left: 0,
                        right: 0,
                      ),
                      children: <Widget>[
                        Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.update_outlined,
                                color: colorScheme.secondary,
                              ),
                              title: const Text("Check for App Update"),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              onTap: () {
                                _checkForUpdate;
                                print(
                                  "Check App Update tapped",
                                ); /* TODO: Implement update check */
                              },
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            ListTile(
                              leading: Icon(
                                Icons.backup_outlined,
                                color: colorScheme.secondary,
                              ),
                              title: const Text(
                                "Backup Favorites & Highlights",
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              onTap: () {
                                _backupData;
                                print(
                                  "Backup tapped",
                                ); /* TODO: Implement backup */
                              },
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            ListTile(
                              leading: Icon(
                                Icons.restore_outlined,
                                color: colorScheme.secondary,
                              ),
                              title: const Text(
                                "Restore Favorites & Highlights",
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              onTap: () {
                                _restoreData;
                                ;
                                print(
                                  "Restore tapped",
                                ); /* TODO: Implement restore */
                              },
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            ListTile(
                              leading: Icon(
                                Icons.delete_sweep_outlined,
                                color: colorScheme.error,
                              ),
                              title: Text(
                                "Delete Temporary Files",
                                style: TextStyle(color: colorScheme.error),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              onTap: _deleteTempFiles,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- About & Support Section (Expandable) ---
                    ExpansionTile(
                      initiallyExpanded: _isAboutExpanded,
                      onExpansionChanged:
                          (bool expanding) =>
                              setState(() => _isAboutExpanded = expanding),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest
                      // ignore: deprecated_member_use
                      .withOpacity(0.3),
                      collapsedBackgroundColor: theme.cardColor,
                      title: _buildSectionTitle(context, "About & Support"),
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      childrenPadding: const EdgeInsets.only(
                        bottom: 8.0,
                        left: 0,
                        right: 0,
                      ),
                      children: <Widget>[
                        Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.info_outline,
                                color: colorScheme.secondary,
                              ),
                              title: const Text("MedMle Expert"),
                              subtitle: const Text(
                                "App Version: 1.0.1",
                              ), // Example: Replace with actual version logic
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            _buildLinkTile(
                              context,
                              Icons.web_outlined,
                              "Website",
                              "http://medmleexpert.net",
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            _buildLinkTile(
                              context,
                              Icons.email_outlined,
                              "Support Email",
                              "mailto:support@medmleexpert.net",
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            _buildLinkTile(
                              context,
                              Icons.telegram_outlined,
                              "Telegram Channel",
                              "https://t.me/your_channel",
                            ), // Replace URL
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            _buildLinkTile(
                              context,
                              Icons.group_outlined,
                              "Telegram Group",
                              "https://t.me/your_group",
                            ), // Replace URL
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            _buildLinkTile(
                              context,
                              Icons.camera_alt_outlined,
                              "Instagram",
                              "https://instagram.com/medmleexpert",
                            ), // Replace URL
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Log Out Button (Always Visible) ---
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text("Log Out"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ), // Make it pill shaped
                        ),
                        onPressed: _logout,
                      ),
                    ),
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildSectionTitle(BuildContext context, String title) {
    // This is now used inside ExpansionTile's title, so return the Text directly
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      // Add some padding around info rows
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 12),
          Text("$label ", style: Theme.of(context).textTheme.bodyMedium),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context,
    IconData icon,
    String title,
    String url,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(title),
      trailing: const Icon(Icons.open_in_new_outlined, size: 18),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
      ), // Standard padding
      onTap: () => _launchURL(url),
    );
  }

  // --------------------
}
