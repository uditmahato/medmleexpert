import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http; // Import http package
import 'package:path_provider/path_provider.dart'; // Import path_provider
import 'dart:convert';
import '../auth/auth_service.dart';
import '../downloads/downloads_screen.dart';
import '../profile/profile_screen.dart';
import 'pdf_model.dart';
import 'pdf_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DatabaseReference _database;
  String _dbMessage = "Loading...";
  late FirebaseFirestore firestore;
  late FirebaseStorage storage;
  Map<String, String> pdfDownloadUrls = {};
  bool _isLoadingPdfs = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    firestore = FirebaseFirestore.instance;
    storage = FirebaseStorage.instance;
    try {
      _database = FirebaseDatabase.instance.ref();
    } catch (e) {
      print("Error initializing database: $e");
      _dbMessage = "Database initialization failed";
    }
    _testDatabaseConnection();
    _fetchPdfsAndDownloadUrls();
  }

  Future<void> _fetchPdfsAndDownloadUrls() async {
    try {
      QuerySnapshot querySnapshot = await firestore.collection('pdfs').get();

      if (querySnapshot.docs.isEmpty) {
        print("No documents found in the 'pdfs' collection.");
        setState(() => _isLoadingPdfs = false);
        return;
      }

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        print("Document ID: ${doc.id}");
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        String title = data['title'] as String? ?? 'No Title';
        String gsPath = data['url'] as String? ?? '';

        print("Title: $title");
        print("gsPath: $gsPath");

        if (gsPath.isNotEmpty) {
          try {
            Reference storageRef = storage.refFromURL(gsPath);
            String downloadURL = await storageRef.getDownloadURL();
            print("Download URL: $downloadURL");
            setState(() {
              pdfDownloadUrls[doc.id] = downloadURL;
            });
          } catch (e) {
            print("Error getting download URL: $e");
          }
        } else {
          print("No URL provided.");
        }
      }
      setState(() => _isLoadingPdfs = false);
    } catch (e) {
      print("Error fetching PDFs: $e");
      setState(() => _isLoadingPdfs = false);
    }
  }

  Future<void> _testDatabaseConnection() async {
    try {
      await _database.child('test/message').set({
        'text': 'Hello from med_mle_expert!',
        'timestamp': DateTime.now().toIso8601String(),
      });
      print("Wrote test message to Realtime Database");

      DatabaseEvent event = await _database.child('test/message').once();
      if (event.snapshot.exists) {
        setState(() {
          _dbMessage = event.snapshot.value.toString();
        });
        print("Read from Realtime Database: $_dbMessage");
      } else {
        setState(() {
          _dbMessage = "No data found in Realtime Database";
        });
      }
    } catch (e) {
      setState(() {
        _dbMessage = "Realtime Database Error: $e";
      });
      print("Database error: $e");
    }
  }

  Future<void> _downloadFile(String url, String filename) async {
    try {
      final http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Get the device's documents directory
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename.pdf');

        // Write the bytes to the file
        await file.writeAsBytes(bytes);

        print("File downloaded to: ${file.path}");
        // Optionally, show a snackbar or dialog to inform the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded ${filename}.pdf to ${directory.path}')),
        );
      } else {
        print("Download failed. Status code: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed. Status code: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print("Exception during download: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
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
        title: Text("Medical Expert App"),
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
          unselectedLabelColor: Color(0xFFB0BEC5),
          indicatorColor: Color(0xFF4CAF50),
          tabs: [
            Tab(text: "NEWEST"),
            Tab(text: "POPULAR"),
            Tab(text: "TRENDING"),
            Tab(text: "UPDATES"),
            Tab(text: "PAID"),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Realtime Database Message: $_dbMessage",
              style: TextStyle(color: Color(0xFF333333)),
            ),
          ),
          Expanded(
            child: _isLoadingPdfs
                ? Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: firestore.collection('pdfs').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        print("Firestore error: ${snapshot.error}");
                        return Center(
                          child: Text(
                            "Error loading PDFs: ${snapshot.error}",
                            style: TextStyle(color: Color(0xFFD32F2F)),
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return Center(child: Text("Loading PDFs..."));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      List<PdfModel> pdfs = [];
                      try {
                        pdfs = snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final String originalUrl = data['url'] ?? '';
                          final String downloadUrl = pdfDownloadUrls[doc.id] ?? originalUrl;
                          return PdfModel(
                            title: data['title'] ?? 'Unknown Title',
                            url: downloadUrl.isNotEmpty ? downloadUrl : originalUrl,
                            date: data['date'] as String?,
                            size: data['size'] != null ? data['size'].toString() : null,
                          );
                        }).toList();
                      } catch (e) {
                        print("Error parsing PDFs: $e");
                        return Center(
                          child: Text(
                            "Error parsing PDFs: $e",
                            style: TextStyle(color: Color(0xFFD32F2F)),
                          ),
                        );
                      }
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
                                backgroundColor: Color(0xFF1A73E8).withOpacity(0.1),
                                child: Icon(Icons.book, color: Color(0xFF1A73E8)),
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
trailing: Column(
  mainAxisSize: MainAxisSize.min, // Makes the column take only the space needed
  children: <Widget>[
    // View Button
    Flexible(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),  // Reduced padding for smaller button
          textStyle: TextStyle(fontSize: 10), // Smaller font size (set to 10)
          minimumSize: Size(0, 30),  // Allow button to shrink
        ),
        onPressed: () async {
          print("VIEW button pressed for: ${pdf.title}");
          // Your logic for the view button...
        },
        child: Text("VIEW"),
      ),
    ),
    SizedBox(height: 8),  // Space between buttons vertically
    // Download Button
    Flexible(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),  // Reduced padding for smaller button
          textStyle: TextStyle(fontSize: 10), // Smaller font size (set to 10)
          minimumSize: Size(0, 30),  // Allow button to shrink
        ),
        onPressed: () {
          _downloadFile(pdf.url, pdf.title);
        },
        child: Text("DOWNLOAD"),
      ),
    ),
  ],
)




                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
