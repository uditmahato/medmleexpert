// Remove imports no longer directly needed in HomeScreen
import 'dart:io'; // Can likely remove if not used elsewhere
// import 'package:file_picker/file_picker.dart'; // Remove if not used
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:http/http.dart' as http; // Remove if not used
// import 'package:path_provider/path_provider.dart'; // Remove if not used
// import 'package:permission_handler/permission_handler.dart'; // Remove from here
// import 'package:flutter_file_downloader/flutter_file_downloader.dart'; // Remove from here

// Keep necessary imports
import '../auth/auth_service.dart';
import '../downloads/downloads_screen.dart';
import '../profile/profile_screen.dart';
import 'pdf_model.dart';
import 'pdf_viewer_screen.dart';
import '../downloads/download_service.dart'; // Import the new service

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DatabaseReference _database;
  String _dbMessage = "Loading...";
  late FirebaseFirestore firestore;
  late FirebaseStorage storage;
  Map<String, String> pdfDownloadUrls = {};
  bool _isLoadingPdfs = true;

  // Instantiate the DownloadService
  final DownloadService _downloadService = DownloadService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    // --- KEEP THIS METHOD AS IS, BUT REMOVE THE NESTED _downloadFile ---
    try {
      QuerySnapshot querySnapshot = await firestore.collection('pdfs').get();

      if (querySnapshot.docs.isEmpty) {
        print("No documents found in the 'pdfs' collection.");
        setState(() => _isLoadingPdfs = false);
        return;
      }

      Map<String, String> urls = {}; // Temporary map to build URLs
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        // print("Document ID: ${doc.id}"); // Keep printing if useful
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String gsPath = data['url'] as String? ?? '';
        // print("gsPath: $gsPath"); // Keep printing if useful

        if (gsPath.isNotEmpty) {
          try {
            Reference storageRef = storage.refFromURL(gsPath);
            String downloadURL = await storageRef.getDownloadURL();
            // print("Download URL: $downloadURL"); // Keep printing if useful
            urls[doc.id] = downloadURL;
          } catch (e) {
            print("Error getting download URL for ${doc.id}: $e");
            // Optionally set a placeholder or leave it out for this doc
          }
        } else {
          print("No URL provided for doc ${doc.id}.");
        }
      }
      // Update state once after the loop
      if (mounted) {
        setState(() {
          pdfDownloadUrls = urls;
          _isLoadingPdfs = false;
        });
      }
    } catch (e) {
      print("Error fetching PDFs: $e");
      if (mounted) {
        setState(() => _isLoadingPdfs = false);
      }
      // REMOVE THE OLD _downloadFile FUNCTION THAT WAS ACCIDENTALLY NESTED HERE
    }
  }

  Future<void> _testDatabaseConnection() async {
    // KEEP THIS METHOD AS IS
    try {
      await _database.child('test/message').set({
        'text': 'Hello from med_mle_expert!',
        'timestamp': DateTime.now().toIso8601String(),
      });
      print("Wrote test message to Realtime Database");

      DatabaseEvent event = await _database.child('test/message').once();
      if (event.snapshot.exists) {
        if (mounted) {
          setState(() {
            _dbMessage = event.snapshot.value.toString();
          });
        }
        print("Read from Realtime Database: $_dbMessage");
      } else {
        if (mounted) {
          setState(() {
            _dbMessage = "No data found in Realtime Database";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dbMessage = "Realtime Database Error: $e";
        });
      }
      print("Database error: $e");
    }
  }

  // --- REMOVE the entire _downloadFile function from here ---
  // Future<void> _downloadFile(...) async { ... } // DELETE THIS

  // --- REMOVE the unused downloadFile function ---
  // Future<void> downloadFile(String fileName) async { ... } // DELETE THIS

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MedMle Expert App"),
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
            child:
                _isLoadingPdfs
                    ? Center(child: CircularProgressIndicator())
                    : StreamBuilder<QuerySnapshot>(
                      stream: firestore.collection('pdfs').snapshots(),
                      builder: (context, snapshot) {
                        // --- KEEP StreamBuilder logic as is ---
                        if (snapshot.hasError || !snapshot.hasData) {
                          // Handle error/loading
                          return Center(
                            child: Text(
                              snapshot.hasError
                                  ? 'Error: ${snapshot.error}'
                                  : 'Loading PDFs...',
                            ),
                          );
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        List<PdfModel> pdfs = [];
                        try {
                          pdfs =
                              snapshot.data!.docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final String originalUrl = data['url'] ?? '';
                                final String downloadUrl =
                                    pdfDownloadUrls[doc.id] ?? originalUrl;
                                return PdfModel(
                                  title: data['title'] ?? 'Unknown Title',
                                  url:
                                      downloadUrl.isNotEmpty
                                          ? downloadUrl
                                          : originalUrl,
                                  date: data['date'] as String?,
                                  size:
                                      data['size'] != null
                                          ? data['size'].toString()
                                          : null,
                                );
                              }).toList();
                        } catch (e) {
                          print("Error parsing PDFs: $e");
                          return Center(
                            child: Text("Error parsing PDF data: $e"),
                          );
                        }

                        if (pdfs.isEmpty) {
                          return Center(child: Text("No PDFs available"));
                        }

                        // Inside the StreamBuilder's builder, after creating the pdfs list:
                        return ListView.builder(
                          itemCount: pdfs.length,
                          itemBuilder: (context, index) {
                            PdfModel pdf = pdfs[index];
                            return Card(
                              // Slightly adjust vertical margin for spacing, keep horizontal
                              margin: EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 16,
                              ),
                              elevation: 2, // Add a subtle shadow
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ), // Rounded corners
                              child: Padding(
                                // Add padding inside the card
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 4.0,
                                ), // Added padding
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 4.0,
                                  ), // Adjust ListTile padding
                                  leading: CircleAvatar(
                                    backgroundColor: Color(
                                      0xFF1A73E8,
                                    ).withOpacity(0.1),
                                    child: Icon(
                                      Icons.picture_as_pdf_outlined,
                                      color: Color(0xFF1A73E8),
                                    ), // Maybe a PDF icon?
                                  ),
                                  title: Text(
                                    pdf.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ), // Slightly larger title font
                                    maxLines: 2, // Allow max 2 lines for title
                                    overflow:
                                        TextOverflow
                                            .ellipsis, // Add ellipsis if title overflows
                                  ),
                                  subtitle: Padding(
                                    // Add padding below title
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      // Combine date and size on one line
                                      "${pdf.date ?? 'Date Unknown'} • Size: ${pdf.size ?? 'Unknown'}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ), // Slightly smaller subtitle
                                    ),
                                  ),
                                  trailing: Row(
                                    // Use a Row for buttons
                                    mainAxisSize:
                                        MainAxisSize
                                            .min, // Row takes minimum space needed
                                    children: <Widget>[
                                      // VIEW Button
                                      TextButton(
                                        // Use TextButton for less visual weight? Or keep ElevatedButton
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          textStyle: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ), // Adjust text style
                                          // minimumSize: Size(60, 36), // Control minimum size if needed
                                          visualDensity:
                                              VisualDensity
                                                  .compact, // Make it slightly more compact
                                        ),
                                        onPressed: () {
                                          print(
                                            "VIEW button pressed for: ${pdf.title}",
                                          );
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => PdfViewerScreen(
                                                    filePath: pdf.url,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Text("VIEW"),
                                      ),
                                      SizedBox(
                                        width: 6,
                                      ), // Space between buttons
                                      // DOWNLOAD Button
                                      ElevatedButton(
                                        // Keep ElevatedButton for primary action?
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Theme.of(
                                                context,
                                              ).primaryColor, // Use theme color
                                          foregroundColor:
                                              Colors.white, // Text color
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          textStyle: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          // minimumSize: Size(90, 36), // Control minimum size if needed
                                          visualDensity: VisualDensity.compact,
                                          shape: RoundedRectangleBorder(
                                            // Rounded corners for button
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          // Call the DownloadService
                                          _downloadService.downloadPdf(
                                            url: pdf.url,
                                            filename: pdf.title,
                                            context: context,
                                          );
                                        },
                                        child: Text("DOWNLOAD"),
                                      ),
                                    ],
                                  ),
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
