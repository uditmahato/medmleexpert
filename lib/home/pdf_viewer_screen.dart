import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PdfViewerScreen extends StatefulWidget {
  final String filePath;

  const PdfViewerScreen({super.key, required this.filePath});

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  String _errorMessage = '';
  String? _downloadUrl;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(widget.filePath);
      final downloadUrl = await ref.getDownloadURL();
      print("Download URL: $downloadUrl");

      if (kIsWeb) {
        setState(() {
          _downloadUrl = downloadUrl;
        });
        if (await canLaunchUrl(Uri.parse(downloadUrl))) {
          await launchUrl(
            Uri.parse(downloadUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          setState(() {
            _errorMessage = "Cannot launch URL";
          });
        }
      } else {
        final response = await http.get(Uri.parse(downloadUrl));
        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/temp_pdf.pdf');
          await file.writeAsBytes(response.bodyBytes);
          setState(() {
            _localPath = file.path;
          });
        } else {
          setState(() {
            _errorMessage = "Failed to download PDF: ${response.statusCode}";
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading PDF: $e";
      });
      print("Error in PdfViewerScreen: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("PDF Viewer")),
      body:
          _errorMessage.isNotEmpty
              ? Center(
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Color(0xFFD32F2F)),
                ),
              )
              : kIsWeb
              ? _downloadUrl == null
                  ? Center(child: CircularProgressIndicator())
                  : Center(
                    child: Text(
                      "PDF opened in browser. If it didn't open, click below.",
                      textAlign: TextAlign.center,
                    ),
                  )
              : _localPath == null
              ? Center(child: CircularProgressIndicator())
              : PDFView(
                filePath: _localPath!,
                onError: (error) {
                  setState(() {
                    _errorMessage = "Error rendering PDF: $error";
                  });
                },
              ),
      floatingActionButton:
          kIsWeb && _downloadUrl != null
              ? FloatingActionButton(
                onPressed: () async {
                  if (await canLaunchUrl(Uri.parse(_downloadUrl!))) {
                    await launchUrl(
                      Uri.parse(_downloadUrl!),
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    setState(() {
                      _errorMessage = "Cannot launch URL";
                    });
                  }
                },
                child: Icon(Icons.open_in_browser),
              )
              : null,
    );
  }
}
