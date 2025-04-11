import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../auth/auth_service.dart';
import '../downloads/downloads_screen.dart';
import '../profile/profile_screen.dart';
import 'pdf_model.dart';
import 'pdf_viewer_screen.dart'; // Assuming your PdfViewerScreen is in this file

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
      Future<void> _downloadFile(
        String url,
        String filename,
        BuildContext context,
      ) async {
        print("Starting download from URL: $url");
        int retries = 3;
        while (retries > 0) {
          try {
            final encodedUrl = Uri.encodeFull(url); // Encode URL
            final http.Response response = await http.get(
              Uri.parse(encodedUrl),
              headers: {
                'User-Agent': 'Flutter-Download-App',
                'Accept': '*/*',
                'Accept-Encoding': 'gzip, deflate, br',
                'Connection': 'keep-alive',
              },
            );

            if (response.statusCode == 200) {
              final bytes = response.bodyBytes;
              final directory = await getApplicationDocumentsDirectory();
              final file = File('${directory.path}/$filename.pdf');
              await file.writeAsBytes(bytes);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloaded ${filename}.pdf')),
              );
              return;
            } else {
              print("Download failed. Status code: ${response.statusCode}");
              retries--;
              if (retries == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Download failed after multiple attempts.'),
                  ),
                );
              }
            }
          } catch (e) {
            retries--;
            if (retries == 0) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
            }
            await Future.delayed(Duration(seconds: 2)); // Delay before retry
          }
        }
      }
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

  Future<void> _downloadFile(
    String url,
    String filename,
    BuildContext context,
  ) async {
    print("Starting download from URL: $url");
    int retries = 3;

    // --- Permission Request ---
    print("Checking MANAGE storage permission status..."); // Change message
    // Request the MANAGE permission
    PermissionStatus permissionStatus =
        await Permission.manageExternalStorage.status;
    print("Initial permission status: $permissionStatus");

    if (!permissionStatus.isGranted) {
      print(
        "MANAGE Storage permission is NOT granted. Requesting now...",
      ); // Change message
      // Request the MANAGE permission
      permissionStatus = await Permission.manageExternalStorage.request();
      print("Permission request result: $permissionStatus");

      if (permissionStatus.isGranted) {
        print(
          "MANAGE Storage permission GRANTED after request!",
        ); // Change message
      } else {
        // isDenied or permanentlyDenied (handle both simply for test)
        print(
          "MANAGE Storage permission DENIED after request. Showing snackbar.",
        ); // Change message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              // Adjust message if needed, e.g., 'All files access required...'
              'Storage permission required to download files.',
            ),
          ),
        );
        return; // Stop download if permission not granted
      }
    } else {
      print("MANAGE Storage permission ALREADY granted!"); // Change message
    }
    // --- Permission Request End ---

    while (retries > 0) {
      try {
        final encodedUrl = Uri.encodeFull(url);
        final http.Response response = await http.get(
          Uri.parse(encodedUrl),
          headers: {
            'User-Agent': 'Flutter-Download-App',
            'Accept': '*/*',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
          },
        );

        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;

          String? directoryPath = await FilePicker.platform.getDirectoryPath();
          if (directoryPath == null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Download cancelled')));
            return;
          }

          print("Selected directory path: $directoryPath");
          final file = File('$directoryPath/$filename.pdf');
          print("File path for saving: ${file.path}");

          try {
            await file.writeAsBytes(bytes);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Downloaded ${filename}.pdf to ${directoryPath}'),
              ),
            );
            return;
          } catch (fileWriteError) {
            print("Error writing file: $fileWriteError");
            String errorMessage = 'Error saving file: ';
            if (fileWriteError is FileSystemException) {
              if (fileWriteError.osError?.errorCode == 30) {
                // Corrected to errorCode
                errorMessage +=
                    'Read-only directory selected. Please choose a different location.';
              } else if (fileWriteError.osError?.errorCode == 1) {
                // Corrected to errorCode
                errorMessage +=
                    'Permission denied. Please choose a directory where you have write access.';
              } else if (fileWriteError.message.contains(
                'No space left on device',
              )) {
                errorMessage +=
                    'Not enough free space in the selected location.';
              } else {
                errorMessage +=
                    'Unknown file system error: ${fileWriteError.message}';
              }
            } else {
              errorMessage += 'Unknown error: $fileWriteError';
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(errorMessage)));
            return;
          }
        } else {
          print("Download failed. Status code: ${response.statusCode}");
          retries--;
          if (retries == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Download failed after multiple attempts. Status code: ${response.statusCode}',
                ),
              ),
            );
          }
        }
      } catch (e) {
        retries--;
        if (retries == 0) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
        }
        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

  Future<void> downloadFile(String fileName) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final bytes = await ref.getData();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes!);
      print('Download successful: ${file.path}');
    } catch (e) {
      print('Error downloading file: $e');
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
                              margin: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Color(
                                    0xFF1A73E8,
                                  ).withOpacity(0.1),
                                  child: Icon(
                                    Icons.book,
                                    color: Color(0xFF1A73E8),
                                  ),
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
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Flexible(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 4.0,
                                            horizontal: 8.0,
                                          ),
                                          textStyle: TextStyle(fontSize: 10),
                                          minimumSize: Size(0, 30),
                                        ),
                                        onPressed: () async {
                                          print(
                                            "VIEW button pressed for: ${pdf.title}",
                                          );
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => PdfViewerScreen(
                                                    filePath:
                                                        pdf.url, // Pass the Firebase Storage URL
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Text("VIEW"),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Flexible(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 4.0,
                                            horizontal: 8.0,
                                          ),
                                          textStyle: TextStyle(fontSize: 10),
                                          minimumSize: Size(0, 30),
                                        ),
                                        onPressed: () {
                                          _downloadFile(
                                            pdf.url,
                                            pdf.title,
                                            context,
                                          ); // Pass context
                                        },
                                        child: Text("DOWNLOAD"),
                                      ),
                                    ),
                                  ],
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
