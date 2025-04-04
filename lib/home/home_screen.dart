import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String _dbMessage = "Loading...";
  String _firestoreDebugMessage = "Loading Firestore collections...";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _testDatabaseConnection();
    _debugFirestoreCollections();
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

  Future<void> _debugFirestoreCollections() async {
    try {
      // List all collections in Firestore
      final collections =
          await FirebaseFirestore.instance.collectionGroup('pdfs').get();
      final docs = collections.docs;
      if (docs.isEmpty) {
        setState(() {
          _firestoreDebugMessage = "No documents found in 'pdfs' collection";
        });
      } else {
        setState(() {
          _firestoreDebugMessage =
              "Found ${docs.length} documents in 'pdfs' collection: ${docs.map((doc) => doc.id).join(', ')}";
        });
      }
    } catch (e) {
      setState(() {
        _firestoreDebugMessage = "Error accessing Firestore: $e";
      });
      print("Firestore debug error: $e");
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Firestore Debug: $_firestoreDebugMessage",
              style: TextStyle(color: Color(0xFF333333)),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pdfs').snapshots(),
              builder: (context, snapshot) {
                print("StreamBuilder state: ${snapshot.connectionState}");
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
                  print("No data yet, waiting...");
                  return Center(child: Text("Loading PDFs..."));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  print("Firestore connection state: waiting");
                  return Center(child: CircularProgressIndicator());
                }
                List<PdfModel> pdfs = [];
                try {
                  pdfs =
                      snapshot.data!.docs.map((doc) {
                        print("Document data: ${doc.data()}");
                        return PdfModel.fromDocument(doc);
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
                print("Fetched ${pdfs.length} PDFs");
                if (pdfs.isEmpty) {
                  print("No PDFs available in Firestore");
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
                        trailing: ElevatedButton(
                          onPressed: () async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            List<Map<String, String>> downloadedPdfs = [];
                            String? pdfsJson = prefs.getString(
                              'downloaded_pdfs',
                            );
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
                            print(
                              "Navigating to PdfViewerScreen with URL: ${pdf.url}",
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        PdfViewerScreen(filePath: pdf.url),
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
          ),
        ],
      ),
    );
  }
}
