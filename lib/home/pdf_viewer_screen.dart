import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath; // Can be gs:// URL or https:// download URL

  const PdfViewerScreen({Key? key, required this.filePath}) : super(key: key);

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  String _errorMessage = '';
  String? _downloadUrl; // Store the final download URL
  bool _isLoading = true;
  bool _isDownloading = false; // Separate state for mobile download step

  // PDFView specific state
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfViewController;
  bool _pdfReady = false; // Track if PDFView is ready

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  Future<void> _preparePdf() async {
    setState(() {
      _isLoading = true;
      _isDownloading = false;
      _errorMessage = '';
      _pdfReady = false; // Reset PDF ready state
    });

    try {
      // Step 1: Get the HTTPS download URL if necessary
      if (widget.filePath.startsWith('gs://')) {
        final ref = FirebaseStorage.instance.refFromURL(widget.filePath);
        _downloadUrl = await ref.getDownloadURL();
        print("Resolved Download URL: $_downloadUrl");
      } else if (widget.filePath.startsWith('https://')) {
        _downloadUrl = widget.filePath; // Assume it's already a download URL
      } else {
        throw Exception(
          "Invalid file path format. Must start with gs:// or https://",
        );
      }

      if (_downloadUrl == null) {
        throw Exception("Could not get download URL.");
      }

      // Step 2: Handle based on platform
      if (kIsWeb) {
        // Web: Attempt to launch externally
        setState(() {
          _isLoading = false;
        }); // Loading is done, show web UI
        _launchUrlInBrowser(_downloadUrl!); // Attempt to launch
      } else {
        // Mobile: Download the file locally
        setState(() {
          _isDownloading = true; // Show download progress indicator
        });
        final response = await http.get(Uri.parse(_downloadUrl!));

        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          // Use a more unique filename to avoid potential collisions if multiple PDFs are viewed quickly
          final uniqueFileName =
              '${DateTime.now().millisecondsSinceEpoch}_temp.pdf';
          final file = File('${tempDir.path}/$uniqueFileName');
          await file.writeAsBytes(response.bodyBytes);

          if (mounted) {
            // Check if widget is still in the tree
            setState(() {
              _localPath = file.path;
              _isDownloading = false; // Download finished
              _isLoading = false; // Overall loading finished
            });
          }
        } else {
          throw Exception(
            "Failed to download PDF. Status code: ${response.statusCode}",
          );
        }
      }
    } catch (error) {
      print("Error in _preparePdf: $error");
      String message = "Error loading PDF.";
      if (error is FirebaseException) {
        message += " Firebase error: ${error.message} (Code: ${error.code})";
      } else if (error is Exception) {
        message = error.toString(); // Show specific exception message
      }
      if (mounted) {
        setState(() {
          _errorMessage = message;
          _isLoading = false;
          _isDownloading = false;
        });
      }
    }
    // No finally block needed as state is set within try/catch
  }

  Future<void> _launchUrlInBrowser(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Optionally show a success message or just rely on the default text
      } else {
        throw Exception("Cannot launch URL: $url");
      }
    } catch (e) {
      print("Error launching URL: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Could not open PDF in browser. Please try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_isLoading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage.isNotEmpty) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Error: $_errorMessage",
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (kIsWeb) {
      // Web platform UI
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.open_in_browser, size: 50, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "The PDF should have opened in a new browser tab.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Try Opening Again"),
              onPressed:
                  _downloadUrl != null
                      ? () => _launchUrlInBrowser(_downloadUrl!)
                      : null,
            ),
          ],
        ),
      );
    } else {
      // Mobile platform UI
      if (_isDownloading) {
        bodyContent = const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Downloading PDF..."),
            ],
          ),
        );
      } else if (_localPath != null) {
        // PDFView and controls
        bodyContent = Column(
          children: [
            // Optional: Add page info/controls at the top
            if (_pdfReady) // Only show controls when PDF is rendered
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 8.0,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // Space out elements
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Previous Page',
                      // Disable if on first page or controller not ready
                      onPressed:
                          (_currentPage > 0 && _pdfViewController != null)
                              ? () {
                                _pdfViewController!.setPage(_currentPage - 1);
                              }
                              : null,
                    ),
                    Text(
                      "Page ${_currentPage + 1} of $_totalPages", // Display 1-based index
                      style: const TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Next Page',
                      // Disable if on last page or controller not ready
                      onPressed:
                          (_currentPage < _totalPages - 1 &&
                                  _pdfViewController != null)
                              ? () {
                                _pdfViewController!.setPage(_currentPage + 1);
                              }
                              : null,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: PDFView(
                filePath: _localPath!,
                enableSwipe: true, // Enable swipe gestures
                swipeHorizontal: false, // Default vertical scroll
                autoSpacing: false,
                pageFling: true, // Allow flinging between pages
                pageSnap: true, // Snap to page boundaries
                defaultPage: _currentPage,
                fitPolicy:
                    FitPolicy.BOTH, // Fit both width and height initially
                preventLinkNavigation: false, // Allow links within PDF
                onViewCreated: (PDFViewController pdfViewController) {
                  // Use .complete() if you need to await this in the future
                  // _controller.complete(pdfViewController);
                  _pdfViewController = pdfViewController;
                  print("PDF View Created");
                },
                onRender: (pages) {
                  if (mounted) {
                    setState(() {
                      _totalPages = pages ?? 0;
                      _pdfReady = true; // PDF is ready to be interacted with
                    });
                    print("PDF Rendered with $_totalPages pages.");
                  }
                },
                onPageChanged: (int? page, int? total) {
                  if (mounted && page != null && total != null) {
                    setState(() {
                      _currentPage = page;
                      // _totalPages = total; // onRender is usually better for total
                    });
                    print('Page changed: $_currentPage / $_totalPages');
                  }
                },
                onError: (error) {
                  print("PDFView Error: $error");
                  if (mounted) {
                    setState(() {
                      _errorMessage = "Error displaying PDF: $error";
                      _pdfReady = false; // PDF is no longer ready
                    });
                  }
                },
                onPageError: (page, error) {
                  print('Error on page $page: $error');
                  if (mounted) {
                    setState(() {
                      // You could show a more specific error if needed
                      _errorMessage = "Error loading page $page: $error";
                    });
                  }
                },
              ),
            ),
            // Optional: Add controls at the bottom as well or instead
          ],
        );
      } else {
        // Should not happen if logic is correct, but handle defensively
        bodyContent = const Center(child: Text("PDF path not available."));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Viewer"),
        // Optional: Add actions like sharing, etc.
      ),
      body: bodyContent,
      // Remove the FAB for web, use button inside bodyContent instead
      // floatingActionButton: kIsWeb && _downloadUrl != null ? ... : null,
    );
  }
}
