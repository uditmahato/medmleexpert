import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath; // Can be gs:// URL, https:// URL, OR a local file path

  const PdfViewerScreen({Key? key, required this.filePath}) : super(key: key);

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath; // Path to the PDF file on the device (if applicable)
  String _errorMessage = '';
  String? _webLaunchUrl; // URL to launch for web
  bool _isLoading = true;
  bool _isDownloading =
      false; // Separate state for mobile download step (if needed)

  // PDFView specific state
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfViewController;
  bool _pdfReady = false;

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  // --- MODIFIED _preparePdf ---
  Future<void> _preparePdf() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isDownloading = false;
      _errorMessage = '';
      _pdfReady = false;
      _localPath = null; // Reset local path
      _webLaunchUrl = null; // Reset web url
    });

    final String inputPath = widget.filePath;
    bool isLocalFile =
        !inputPath.startsWith('gs://') &&
        !inputPath.startsWith('http'); // Simple check for local

    print("Preparing PDF. Input path: $inputPath, Is local: $isLocalFile");

    try {
      String?
      finalUrlToLoad; // This will be the https url if we need to download

      // Step 1: Determine if it's local or needs downloading
      if (isLocalFile) {
        // It's already a local path (likely from DownloadsScreen)
        if (!kIsWeb) {
          // Local files only make sense on mobile
          // Check if file exists before setting path
          final file = File(inputPath);
          if (!await file.exists()) {
            throw Exception("Local file not found at path: $inputPath");
          }
          print("Using existing local file: $inputPath");
          if (mounted) setState(() => _localPath = inputPath);
        } else {
          // Cannot directly view local files on web this way
          throw Exception("Cannot view local file paths on the web platform.");
        }
      } else if (inputPath.startsWith('gs://')) {
        // Fetch download URL from Firebase Storage
        final ref = FirebaseStorage.instance.refFromURL(inputPath);
        finalUrlToLoad = await ref.getDownloadURL();
        print("Resolved Firebase Download URL: $finalUrlToLoad");
      } else if (inputPath.startsWith('http')) {
        // It's already an HTTPS URL
        finalUrlToLoad = inputPath;
        print("Using direct HTTPS URL: $finalUrlToLoad");
      } else {
        // Should not happen due to isLocalFile check, but handle defensively
        throw Exception("Invalid file path format provided.");
      }

      // Step 2: Handle based on platform IF we needed to download/get a URL
      if (!isLocalFile && finalUrlToLoad != null) {
        if (kIsWeb) {
          _webLaunchUrl = finalUrlToLoad; // Store for potential relaunch
          _launchUrlInBrowser(finalUrlToLoad);
        } else {
          // Mobile: Download the file locally from the URL
          if (mounted) setState(() => _isDownloading = true);

          final response = await http.get(Uri.parse(finalUrlToLoad));
          if (response.statusCode == 200) {
            final tempDir = await getTemporaryDirectory();
            final uniqueFileName =
                '${DateTime.now().millisecondsSinceEpoch}_temp.pdf';
            final file = File('${tempDir.path}/$uniqueFileName');
            await file.writeAsBytes(response.bodyBytes);
            if (mounted) setState(() => _localPath = file.path);
            print("Downloaded to temporary path: $_localPath");
          } else {
            throw Exception(
              "Failed to download PDF. Status code: ${response.statusCode}",
            );
          }
        }
      } else if (!isLocalFile && finalUrlToLoad == null) {
        // This case means it wasn't local, but we couldn't get a URL (e.g., Firebase error)
        // The specific error should have been caught below, but double-check.
        throw Exception("Failed to obtain a valid URL for the PDF.");
      }

      // If we reach here and _localPath is set (either originally or after download)
      // or if it's web, loading is effectively done.
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isDownloading = false; // Ensure download indicator is off
        });
      }
    } catch (error) {
      print("Error in _preparePdf: $error");
      String message = "Error loading PDF.";
      if (error is FirebaseException) {
        message = "Firebase error: ${error.message ?? error.code}";
      } else if (error is Exception) {
        message = error.toString().replaceFirst(
          "Exception: ",
          "",
        ); // Clean up message
      }
      if (mounted) {
        setState(() {
          _errorMessage = message;
          _isLoading = false;
          _isDownloading = false;
        });
      }
    }
  }
  // --- END MODIFIED _preparePdf ---

  Future<void> _launchUrlInBrowser(String url) async {
    // Keep this function as is
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      bodyContent = Center(/* ... Error message UI ... */);
    } else if (kIsWeb) {
      // Web platform UI - now uses _webLaunchUrl
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.open_in_browser_outlined,
              size: 50,
              color: Colors.grey,
            ),
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
              // Use the stored _webLaunchUrl
              onPressed:
                  _webLaunchUrl != null
                      ? () => _launchUrlInBrowser(_webLaunchUrl!)
                      : null,
            ),
          ],
        ),
      );
    } else {
      // Mobile platform UI
      if (_isDownloading) {
        // Should only show if downloading from URL
        bodyContent = const Center(/* ... Downloading indicator ... */);
      } else if (_localPath != null) {
        // PDFView and controls - THIS PART REMAINS LARGELY THE SAME
        bodyContent = Column(
          children: [
            if (_pdfReady &&
                _totalPages > 0) // Also check if totalPages is greater than 0
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
                    // Display page number only if pages exist
                    Text(
                      "Page ${_currentPage + 1} of $_totalPages",
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
                filePath: _localPath!, // Use the determined local path
                // ... other PDFView properties and callbacks ...
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: false,
                pageFling: true,
                pageSnap: true,
                defaultPage: _currentPage,
                fitPolicy: FitPolicy.BOTH,
                preventLinkNavigation: false,
                onViewCreated: (PDFViewController pdfViewController) {
                  _pdfViewController = pdfViewController;
                  print("PDF View Created");
                },
                onRender: (pages) {
                  if (mounted)
                    setState(() {
                      _totalPages = pages ?? 0;
                      _pdfReady = true;
                    });
                  print("PDF Rendered with $_totalPages pages.");
                },
                onPageChanged: (int? page, int? total) {
                  if (mounted && page != null)
                    setState(() {
                      _currentPage = page;
                    });
                },
                onError: (error) {
                  if (mounted)
                    setState(() {
                      _errorMessage = "Error displaying PDF: $error";
                      _pdfReady = false;
                    });
                },
                onPageError: (page, error) {
                  if (mounted)
                    setState(() {
                      _errorMessage = "Error loading page $page: $error";
                    });
                },
              ),
            ),
          ],
        );
      } else {
        // Fallback if local path is somehow null after loading finishes
        bodyContent = const Center(child: Text("Could not load PDF view."));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("PDF Viewer")),
      body: bodyContent,
    );
  }
}
