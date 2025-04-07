import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import '../downloads/downloads_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late DateTime subscriptionEndDate;
  late int remainingDays;
  Timer? _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch subscription data after getting the UID
    _fetchSubscriptionData();
    // Update the remaining days every day
    _timer = Timer.periodic(Duration(days: 1), (timer) {
      _calculateRemainingDays();
    });
  }

  Future<void> _fetchSubscriptionData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('subscription')
                .doc('details')
                .get();
        if (doc.exists) {
          setState(() {
            subscriptionEndDate = DateTime.parse(doc.data()!['endDate']);
            _calculateRemainingDays();
            _isLoading = false;
          });
        } else {
          // Default subscription end date if not found
          setState(() {
            subscriptionEndDate = DateTime.parse("2026-03-27");
            _calculateRemainingDays();
            _isLoading = false;
          });
          // Optionally, create a default subscription entry in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('subscription')
              .doc('details')
              .set({
                'endDate': subscriptionEndDate.toIso8601String(),
                'package': 'Default',
              });
        }
      } else {
        // User not logged in, use default
        setState(() {
          subscriptionEndDate = DateTime.parse("2026-03-27");
          _calculateRemainingDays();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching subscription data: $e");
      setState(() {
        subscriptionEndDate = DateTime.parse("2026-03-27");
        _calculateRemainingDays();
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading subscription: $e")));
    }
  }

  void _calculateRemainingDays() {
    final now = DateTime.now();
    final difference = subscriptionEndDate.difference(now);
    setState(() {
      remainingDays = difference.inDays;
      if (remainingDays < 0) remainingDays = 0; // Prevent negative days
    });
  }

  Future<void> _extendSubscription(String package) async {
    try {
      final now = DateTime.now();
      DateTime newEndDate;
      if (package == "Biannual") {
        // Add 6 months (approximate)
        newEndDate = now.add(Duration(days: 6 * 30));
      } else {
        // Add 12 months
        newEndDate = now.add(Duration(days: 365));
      }
      final user = AuthService().currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('subscription')
            .doc('details')
            .set({'endDate': newEndDate.toIso8601String(), 'package': package});
        setState(() {
          subscriptionEndDate = newEndDate;
          _calculateRemainingDays();
        });
        print(
          "Extended subscription with $package package. New end date: $subscriptionEndDate",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Subscription extended successfully!")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("User not logged in")));
      }
    } catch (e) {
      print("Error extending subscription: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error extending subscription: $e")),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Account & Settings"),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DownloadsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              // Already on ProfileScreen, no action needed
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Information Section
              StreamBuilder<User?>(
                stream: AuthService().user,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      "Account Information - Loading...",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    final user = snapshot.data!;
                    return Text(
                      "Account Information - ${user.email ?? 'Unknown'}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  return Text(
                    "Account Information - Not Logged In",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  );
                },
              ),
              SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: Text(
                    "VIP Account - Active Till",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  tileColor: Color(0xFFFFD700), // Highlight Yellow
                ),
              ),
              Card(
                child: ListTile(
                  title:
                      _isLoading
                          ? Text("Loading subscription...")
                          : Text(
                            "${subscriptionEndDate.toString().split(' ')[0]} - $remainingDays Days Remaining",
                          ),
                ),
              ),
              Card(
                child: ListTile(
                  title: Text(
                    "Extend Subscription - Biannual (6 Months)",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  tileColor: Color(0xFF4CAF50), // Calming Green
                  onTap: () {
                    _extendSubscription("Biannual");
                  },
                ),
              ),
              Card(
                child: ListTile(
                  title: Text(
                    "Extend Subscription - Annual (12 Months)",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  tileColor: Color(0xFF4CAF50), // Calming Green
                  onTap: () {
                    _extendSubscription("Annual");
                  },
                ),
              ),
              SizedBox(height: 16),

              // Your Databases Section
              Text(
                "Your Databases",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: Text("You Are Subscribed To ALL Databases"),
                ),
              ),
              SizedBox(height: 16),

              // Settings Section
              Text(
                "Settings ( Tap to Hide ) - App Version : 180",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.settings,
                    color: Color(0xFF1A73E8),
                  ), // Trustworthy Blue
                  title: Text("Select Download Path"),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.settings, color: Color(0xFF1A73E8)),
                  title: Text("Main Server"),
                  trailing: Text("Iran"),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.settings, color: Color(0xFF1A73E8)),
                  title: Text("Download Server"),
                  trailing: Text("Germany"),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.settings, color: Color(0xFF1A73E8)),
                  title: Text("Hide List On Select"),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      print("Hide List On Select: $value");
                    },
                    activeColor: Color(0xFF4CAF50), // Calming Green
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.settings, color: Color(0xFF1A73E8)),
                  title: Text("Collapse Search Results"),
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {
                      print("Collapse Search Results: $value");
                    },
                    activeColor: Color(0xFF4CAF50),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.settings, color: Color(0xFF1A73E8)),
                  title: Text("Collapse Content Results"),
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {
                      print("Collapse Content Results: $value");
                    },
                    activeColor: Color(0xFF4CAF50),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.settings, color: Color(0xFF1A73E8)),
                  title: Text("Lock in Fullscreen"),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      print("Lock in Fullscreen: $value");
                    },
                    activeColor: Color(0xFF4CAF50),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.settings, color: Color(0xFF1A73E8)),
                  title: Text("Enable Swipe to Delete"),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      print("Enable Swipe to Delete: $value");
                    },
                    activeColor: Color(0xFF4CAF50),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.settings, color: Color(0xFF1A73E8)),
                  title: Text("Use Collapsing Toolbar"),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      print("Use Collapsing Toolbar: $value");
                    },
                    activeColor: Color(0xFF4CAF50),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.settings, color: Color(0xFF1A73E8)),
                  title: Text("Open Tables as Popup"),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      print("Open Tables as Popup: $value");
                    },
                    activeColor: Color(0xFF4CAF50),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.settings, color: Color(0xFF1A73E8)),
                  title: Text("Document Color"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("#ffffff"),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          print("Reset Document Color");
                        },
                        child: Text("RESET"),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.settings, color: Color(0xFF1A73E8)),
                  title: Text("Automatic QBank Backups"),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      print("Automatic QBank Backups: $value");
                    },
                    activeColor: Color(0xFF4CAF50),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: Text(
                    "Check App Update",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  tileColor: Color(0xFFB0BEC5), // Neutral Gray
                  onTap: () {
                    print("Check App Update tapped");
                  },
                ),
              ),
              Card(
                child: ListTile(
                  title: Text(
                    "Start File Web Server",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  tileColor: Color(0xFFFFD700), // Highlight Yellow
                  onTap: () {
                    print("Start File Web Server tapped");
                  },
                ),
              ),
              Card(
                child: ListTile(
                  title: Text(
                    "Backup Favorites & Highlights",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  tileColor: Color(0xFF1A73E8), // Trustworthy Blue
                  onTap: () {
                    print("Backup Favorites & Highlights tapped");
                  },
                ),
              ),
              Card(
                child: ListTile(
                  title: Text(
                    "Restore Favorites & Highlights",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  tileColor: Color(0xFF1A73E8).withOpacity(0.8),
                  onTap: () {
                    print("Restore Favorites & Highlights tapped");
                  },
                ),
              ),
              Card(
                child: ListTile(
                  title: Text(
                    "Delete Temp Files",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  tileColor: Color(0xFFD32F2F), // Error Red
                  onTap: () {
                    print("Delete Temp Files tapped");
                  },
                ),
              ),
              SizedBox(height: 16),

              // About Us Section
              Text(
                "About Us",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Card(child: ListTile(title: Text("IMO - Medical Resources"))),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.web,
                    color: Color(0xFF1A73E8),
                  ), // Trustworthy Blue
                  title: Text("http://medmleexpert.net"),
                  onTap: () {
                    print("Open http://medmleexpert.net");
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.email,
                    color: Color(0xFFD32F2F),
                  ), // Error Red
                  title: Text("support@medmleexpert.net"),
                  onTap: () {
                    print("Email support@medmleexpert.net");
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.telegram, color: Color(0xFF1A73E8)),
                  title: Text("Telegram Channel"),
                  onTap: () {
                    print("Open Telegram Channel");
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.telegram, color: Color(0xFF1A73E8)),
                  title: Text("Telegram Group"),
                  onTap: () {
                    print("Open Telegram Group");
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: Color(0xFF4CAF50),
                  ), // Calming Green
                  title: Text("@medmleexpert"),
                  onTap: () {
                    print("Open Instagram @medmleexpert");
                  },
                ),
              ),
              SizedBox(height: 16),

              // Log Out Button
              Card(
                child: ListTile(
                  title: Text(
                    "Log Out",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  tileColor: Color(0xFFD32F2F), // Error Red
                  onTap: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) =>
                              Center(child: CircularProgressIndicator()),
                    );
                    try {
                      await AuthService().signOut();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Logged out successfully")),
                      );
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                        (route) => false,
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error logging out: $e")),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
