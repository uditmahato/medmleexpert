import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for SharedPreferences
import 'dart:convert'; // Added for jsonEncode/jsonDecode
import '../auth/auth_service.dart';
import '../downloads/downloads_screen.dart';
import '../profile/profile_screen.dart';
import 'pdf_model.dart';
import 'pdf_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MedMle Expert"),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Color(0xFFB0BEC5), // Neutral Gray
          indicatorColor: Color(0xFF4CAF50), // Calming Green
          tabs: [
            Tab(text: "NEWEST"),
            Tab(text: "POPULAR"),
            Tab(text: "TRENDING"),
            Tab(text: "UPDATES"),
            Tab(text: "PAID"),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('pdfs').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("Error: ${snapshot.error}");
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: TextStyle(color: Color(0xFFD32F2F)),
              ),
            ); // Error Red
          }
          if (!snapshot.hasData) {
            print("No data yet, waiting...");
            return Center(child: Text("Loading PDFs..."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final pdfs =
              snapshot.data!.docs
                  .map((doc) => PdfModel.fromDocument(doc))
                  .toList();
          print("Fetched ${pdfs.length} PDFs");
          if (pdfs.isEmpty) {
            return Center(child: Text("No PDFs available"));
          }
          return ListView.builder(
            itemCount: pdfs.length,
            itemBuilder: (context, index) {
              PdfModel pdf = pdfs[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(
                      0xFF1A73E8,
                    ).withOpacity(0.1), // Trustworthy Blue (light)
                    child: Icon(
                      Icons.book,
                      color: Color(0xFF1A73E8),
                    ), // Trustworthy Blue
                  ),
                  title: Text(
                    pdf.title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(pdf.date ?? "March 2025"),
                      Text("Size: ${pdf.size ?? 'Unknown'}"),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      List<Map<String, String>> downloadedPdfs = [];
                      String? pdfsJson = prefs.getString('downloaded_pdfs');
                      if (pdfsJson != null) {
                        downloadedPdfs = List<Map<String, String>>.from(
                          jsonDecode(pdfsJson),
                        );
                      }
                      downloadedPdfs.add({
                        'title': pdf.title,
                        'url': pdf.url,
                        'date': pdf.date ?? 'March 2025',
                      });
                      await prefs.setString(
                        'downloaded_pdfs',
                        jsonEncode(downloadedPdfs),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => PdfViewerScreen(filePath: pdf.url),
                        ),
                      );
                    },
                    child: Text("VIEW"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
