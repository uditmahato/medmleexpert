import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../home/pdf_viewer_screen.dart';

class DownloadsScreen extends StatefulWidget {
  @override
  _DownloadsScreenState createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<Map<String, String>> _downloadedPdfs = [];

  @override
  void initState() {
    super.initState();
    _loadDownloadedPdfs();
  }

  Future<void> _loadDownloadedPdfs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? pdfsJson = prefs.getString('downloaded_pdfs');
    if (pdfsJson != null) {
      List<dynamic> pdfsList = jsonDecode(pdfsJson);
      setState(() {
        _downloadedPdfs =
            pdfsList.map((pdf) => Map<String, String>.from(pdf)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Downloads")),
      body:
          _downloadedPdfs.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.download,
                      size: 100,
                      color: Color(0xFFB0BEC5), // Neutral Gray
                    ),
                    SizedBox(height: 16),
                    Text(
                      "No Downloads Yet",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Your downloaded PDFs will appear here.",
                      style: TextStyle(
                        color: Color(0xFFB0BEC5),
                      ), // Neutral Gray
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: _downloadedPdfs.length,
                itemBuilder: (context, index) {
                  final pdf = _downloadedPdfs[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      leading: Icon(
                        Icons.picture_as_pdf,
                        color: Color(0xFF1A73E8),
                      ), // Trustworthy Blue
                      title: Text(pdf['title'] ?? 'Unknown'),
                      subtitle: Text(pdf['date'] ?? 'Unknown'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    PdfViewerScreen(filePath: pdf['url']!),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
