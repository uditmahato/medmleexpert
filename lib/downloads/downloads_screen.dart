import 'dart:io'; // For File and Directory
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'; // For permissions
import 'package:path_provider/path_provider.dart'; // To potentially find download dir (can be unreliable)
import 'package:path/path.dart' as p; // For manipulating paths (basename)
import 'package:device_info_plus/device_info_plus.dart';

// Import your PDF Viewer
import '../home/pdf_viewer_screen.dart';

// Consider using a package like `downloads_path_provider` for a more reliable path
// or get the path explicitly from where flutter_file_downloader saves.

class DownloadsScreen extends StatefulWidget {
  @override
  _DownloadsScreenState createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<FileSystemEntity> _downloadedPdfs =
      []; // Store FileSystemEntity (usually File)
  bool _isLoading = true;
  String _errorMessage = '';
  String? _downloadDirPath; // To store the path we are scanning

  @override
  void initState() {
    super.initState();
    _loadDownloadedFiles();
  }

  Future<int> _getAndroidSDKVersion() async {
    // Keep this helper function
    if (Platform.isAndroid) {
      try {
        // Add try-catch for plugin errors
        var androidInfo = await DeviceInfoPlugin().androidInfo;
        return androidInfo.version.sdkInt ?? 0;
      } catch (e) {
        print("Error getting Android SDK version: $e");
        return 0; // Fallback on error
      }
    }
    return 0;
  }

  Future<void> _checkAndRequestPermission() async {
    print("Checking necessary read permissions...");
    Map<Permission, PermissionStatus> statuses;
    bool permissionRequired = false;
    int sdkVersion = await _getAndroidSDKVersion();

    // Determine which permissions are needed based on SDK
    List<Permission> permissionsToRequest = [];
    if (sdkVersion >= 33) {
      permissionsToRequest.add(Permission.photos); // Primary for listing on 33+
      // permissionsToRequest.add(Permission.videos); // Add if listing videos too
      // permissionsToRequest.add(Permission.audio);  // Add if listing audio too
      permissionRequired = true;
    } else if (sdkVersion > 0) {
      // Android versions SDK 1+ up to 32
      permissionsToRequest.add(
        Permission.storage,
      ); // Use general storage permission
      permissionRequired = true;
    } else {
      print("Cannot determine Android SDK version or not on Android.");
      // Assume permission might be needed or handle non-Android case
      // For simplicity, we'll proceed, but you might want different logic.
    }

    if (permissionRequired) {
      print(
        "Requesting permissions: $permissionsToRequest for SDK $sdkVersion",
      );
      statuses = await permissionsToRequest.request();

      // Check if the essential permission was granted
      bool granted = false;
      if (sdkVersion >= 33) {
        granted = statuses[Permission.photos]?.isGranted ?? false;
        print(
          "Photos Permission Status (SDK 33+): ${statuses[Permission.photos]}",
        );
      } else {
        granted = statuses[Permission.storage]?.isGranted ?? false;
        print(
          "Storage Permission Status (SDK <33): ${statuses[Permission.storage]}",
        );
      }

      if (!granted) {
        // Find the status of the permission that was actually denied or permanently denied
        // This assumes permissionsToRequest has at least one item if granted is false
        Permission firstDeniedPermission = permissionsToRequest.firstWhere(
          (p) =>
              statuses[p]?.isDenied ??
              statuses[p]?.isPermanentlyDenied ??
              false,
          orElse:
              () =>
                  permissionsToRequest
                      .first, // Fallback, though shouldn't happen if !granted
        );
        PermissionStatus deniedStatus =
            statuses[firstDeniedPermission] ??
            PermissionStatus.denied; // Get the actual status

        if (deniedStatus.isPermanentlyDenied) {
          print(
            "Read permission permanently denied for $firstDeniedPermission.",
          );
          if (mounted) {
            await showDialog(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: const Text('Permission Required'),
                    content: const Text(
                      'Storage access is permanently denied. Please go to app settings and grant the necessary permission (e.g., "Photos and videos", "Files and media") to view downloads.',
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Open Settings'),
                        onPressed: openAppSettings,
                      ),
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
            );
          }
        } else {
          // isDenied or other non-granted states
          print("Read permission denied for $firstDeniedPermission.");
        }
        throw Exception(
          "Required storage/media permission denied.",
        ); // Stop loading
      }
      print("Required read permission granted.");
    } else {
      print(
        "No specific permission request needed for this platform/SDK or error occurred.",
      );
      // If not Android, proceed assuming access or handle other platforms
    }
  }

  Future<String?> _getDownloadsDirectoryPath() async {
    // !!! CRITICAL: This needs to be the *exact* directory where
    // flutter_file_downloader saves using DownloadDestinations.publicDownloads.
    // This often corresponds to the primary external storage "Download" folder.
    // Getting this path reliably is tricky.

    // Option 1: Hardcode (Less reliable, device-dependent) - USE WITH CAUTION
    // return "/storage/emulated/0/Download";

    // Option 2: Use path_provider (May not point to the *public* Downloads)
    // Directory? downloadsDir = await getDownloadsDirectory(); // Often null or app-specific
    // return downloadsDir?.path;

    // Option 3: Use a dedicated package (Recommended if available)
    // try {
    //   Directory? downloadsPath = await DownloadsPathProvider.downloadsDirectory;
    //   return downloadsPath?.path;
    // } catch (e) {
    //   print("Error getting downloads path from package: $e");
    //   return null; // Fallback needed
    // }

    // --- TEMPORARY FALLBACK/PLACEHOLDER ---
    // For now, we'll assume the common path. Replace this with a more reliable method!
    // Check the actual path printed by flutter_file_downloader's onDownloadCompleted callback!
    const String commonPath = "/storage/emulated/0/Download";
    final dir = Directory(commonPath);
    if (await dir.exists()) {
      print("Using common download path: $commonPath");
      return commonPath;
    } else {
      print("Common download path $commonPath not found.");
      // Try another common location or return null
      return null;
    }
    // -------------------------------------
  }

  Future<void> _loadDownloadedFiles() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Ensure Permissions
      await _checkAndRequestPermission();

      // 2. Get Downloads Directory Path
      _downloadDirPath = await _getDownloadsDirectoryPath();
      if (_downloadDirPath == null) {
        throw Exception("Could not determine downloads directory path.");
      }
      print("Scanning directory: $_downloadDirPath");
      final downloadsDir = Directory(_downloadDirPath!);

      // 3. Check if Directory Exists
      if (!await downloadsDir.exists()) {
        print("Downloads directory does not exist: $_downloadDirPath");
        if (mounted) {
          setState(() {
            _errorMessage = "Downloads folder not found.";
            _isLoading = false;
            _downloadedPdfs = [];
          });
        }
        return;
      }

      // 4. List and Filter Files
      List<FileSystemEntity> foundFiles = [];
      await for (final FileSystemEntity entity in downloadsDir.list()) {
        // Check if it's a file and ends with .pdf (case-insensitive)
        if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
          print("Found PDF: ${entity.path}");
          foundFiles.add(entity);
        }
      }

      // Optional: Sort files (e.g., by modification date, descending)
      foundFiles.sort((a, b) {
        try {
          // Handle potential errors during stat()
          DateTime modA = (a as File).lastModifiedSync();
          DateTime modB = (b as File).lastModifiedSync();
          return modB.compareTo(modA); // Newest first
        } catch (_) {
          return 0; // Keep original order on error
        }
      });

      if (mounted) {
        setState(() {
          _downloadedPdfs = foundFiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading downloaded files: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading files: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  // Function to get a readable file name
  String _getFileName(FileSystemEntity file) {
    return p.basename(file.path); // Uses the path package
  }

  // Function to get modification date string
  String _getFileDate(FileSystemEntity file) {
    try {
      DateTime modDate = (file as File).lastModifiedSync();
      // Format date as desired (using intl package if available)
      return '${modDate.day}/${modDate.month}/${modDate.year}';
    } catch (_) {
      return 'Unknown date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Downloads"),
        actions: [
          // Add a refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Downloads',
            onPressed:
                _isLoading
                    ? null
                    : _loadDownloadedFiles, // Disable while loading
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red[700], fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : _downloadedPdfs.isEmpty
              ? Center(
                // Keep the "No Downloads Yet" message
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_download_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No Downloads Yet",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "PDFs saved to your 'Download' folder will appear here.",
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                // Add pull-to-refresh
                onRefresh: _loadDownloadedFiles,
                child: ListView.builder(
                  itemCount: _downloadedPdfs.length,
                  itemBuilder: (context, index) {
                    final fileEntity = _downloadedPdfs[index];
                    // Ensure it's a File before accessing path
                    if (fileEntity is! File) return const SizedBox.shrink();
                    final pdfFile = fileEntity;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.picture_as_pdf_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          _getFileName(pdfFile), // Get filename from path
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Downloaded: ${_getFileDate(pdfFile)}',
                        ), // Show modified date
                        onTap: () {
                          // View the downloaded file using its local path
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PdfViewerScreen(
                                    filePath: pdfFile.path,
                                  ), // Pass the actual file path
                            ),
                          );
                        },
                        // Optional: Add delete button
                        // trailing: IconButton(
                        //   icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                        //   onPressed: () => _deleteDownloadedFile(pdfFile),
                        // ),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  // Optional: Implement delete functionality
  // Future<void> _deleteDownloadedFile(File fileToDelete) async {
  //   try {
  //     await fileToDelete.delete();
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Deleted ${p.basename(fileToDelete.path)}')),
  //       );
  //       // Refresh the list after deleting
  //       _loadDownloadedFiles();
  //     }
  //   } catch (e) {
  //     print("Error deleting file: $e");
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error deleting file: $e')),
  //       );
  //     }
  //   }
  // }
}
