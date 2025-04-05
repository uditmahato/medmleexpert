import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath;

  const PdfViewerScreen({Key? key, required this.filePath}) : super(key: key);

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  String _errorMessage = '';
  String? _downloadUrl;
  bool _isLoading = true; // Add a loading state

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true; // Set loading to true at the start
      _errorMessage = ''; // Clear any previous error messages
    });

    try {
      final ref = FirebaseStorage.instance.refFromURL(widget.filePath);
      final downloadUrl = await ref.getDownloadURL();
      print("Download URL: $downloadUrl");

      if (kIsWeb) {
        // Web platform
        setState(() {
          _downloadUrl = downloadUrl;
        });

        final uri = Uri.parse(downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          setState(() {
            _errorMessage = "Cannot launch URL in browser.";
          });
        }
      } else {
        // Mobile Platform
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
            _errorMessage = "Failed to download PDF. Status code: ${response.statusCode}";
          });
        }
      }
    } catch (error) {
      // Capture specific exceptions for improved error handling
      String message = "Error loading PDF.";
      if (error is FirebaseException) {
        message += " Firebase error code: ${error.code}";
      }
      setState(() {
        _errorMessage = message;
      });
      print("Error in PdfViewerScreen: $error");
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false when done (success or failure)
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PDF Viewer")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) //Show loading indicator
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Color(0xFFD32F2F)),
                  ),
                )
              : kIsWeb
                  ? _downloadUrl == null
                      ? const Center(child: CircularProgressIndicator()) // This should not occur because of the isLoading implementation
                      : const Center(
                          child: Text(
                            "PDF opened in browser. If it didn't open, click below.",
                            textAlign: TextAlign.center,
                          ),
                        )
                  : _localPath == null
                      ? const Center(child: CircularProgressIndicator())
                      : PDFView(
                          filePath: _localPath!,
                          onError: (error) {
                            setState(() {
                              _errorMessage = "Error rendering PDF: $error";
                            });
                          },
                        ),
      floatingActionButton: kIsWeb && _downloadUrl != null
          ? FloatingActionButton(
              onPressed: () async {
                final uri = Uri.parse(_downloadUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  setState(() {
                    _errorMessage = "Cannot launch URL";
                  });
                }
              },
              child: const Icon(Icons.open_in_browser),
            )
          : null,
    );
  }
}
