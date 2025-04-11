import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

class DownloadService {
  Future<void> downloadPdf({
    required String url,
    required String filename,
    required BuildContext context, // Context is needed for UI feedback
  }) async {
    // --- Permission Request (Updated for Granular Permissions Android 13+) ---
    print("Checking media permissions status...");

    Map<Permission, PermissionStatus> statuses =
        await [
          Permission
              .photos, // Request photos permission (often needed on API 33+)
        ].request();

    PermissionStatus? accessStatus = statuses[Permission.photos];
    print("Permission request result (Photos/Media): $accessStatus");

    if (accessStatus == null || !accessStatus.isGranted) {
      if (accessStatus == PermissionStatus.permanentlyDenied) {
        print("Media permission PERMANENTLY DENIED. Showing guidance dialog.");
        // Use showDialog safely within the async gap check
        if (context.mounted) {
          await showDialog(
            context: context,
            builder:
                (BuildContext dialogContext) => AlertDialog(
                  title: Text('Permission Required'),
                  content: Text(
                    'Media storage permission is permanently denied. Please go to app settings and manually grant the permission to download files.',
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text('Open Settings'),
                      onPressed: () {
                        openAppSettings(); // Opens app settings
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
          );
        }
      } else {
        // Denied or other non-granted status
        print("Media permission DENIED after request. Showing snackbar.");
        if (context.mounted) {
          // Check if context is still valid
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Media storage permission required to download files.',
              ),
            ),
          );
        }
      }
      return; // Stop download
    } else {
      print("Media permission GRANTED after request!");
    }
    // --- Permission Check End ---

    // --- Use flutter_file_downloader to save to Public Downloads ---
    print("Starting download using flutter_file_downloader for URL: $url");
    FileDownloader.downloadFile(
      url: url.trim(),
      name: "$filename.pdf", // Ensure '.pdf' extension if needed
      downloadDestination: DownloadDestinations.publicDownloads,
      onProgress: (String? downloadedFileName, double progress) {
        print('File $downloadedFileName Download Progress: $progress%');
      },
      onDownloadCompleted: (String path) {
        print('File Download Completed: $path');
        if (context.mounted) {
          // Check if context is still valid
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded ${filename}.pdf successfully to $path'),
            ),
          );
        }
      },
      onDownloadError: (String error) {
        print('Download ERROR: $error');
        if (context.mounted) {
          // Check if context is still valid
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Download failed: $error')));
        }
      },
    );
    // --- Download Logic End ---
  }
}
