import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<File> downloadPdf(String url, String filename) async {
  final response = await http.get(Uri.parse(url));
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(response.bodyBytes);
  return file;
}

Future<File> getPdfFile(String url, String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');
  if (await file.exists()) {
    return file;
  } else {
    return downloadPdf(url, filename);
  }
}
