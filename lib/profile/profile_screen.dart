import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import '../downloads/downloads_screen.dart';

class ProfileScreen extends StatelessWidget {
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
              Text(
                "Account Information - uditmahat",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                child: ListTile(title: Text("2026-03-27 - 359 Days Remaining")),
              ),
              Card(
                child: ListTile(
                  title: Text(
                    "Extend Subscription",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  tileColor: Color(0xFF4CAF50), // Calming Green
                  onTap: () {
                    print("Extend Subscription tapped");
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
