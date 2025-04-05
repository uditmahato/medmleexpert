import 'package:cloud_firestore/cloud_firestore.dart';

class PdfModel {
  final String title;
  final String url;
  final String? date;
  final String? size;

  PdfModel({required this.title, required this.url, this.date, this.size});

  factory PdfModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String title = data['title'] ?? 'Unknown Title';
    final String url = data['url'] ?? '';
    if (url.isEmpty) {
      print("Warning: Document ${doc.id} has an empty URL. Skipping.");
      throw Exception("Invalid PDF document: URL is empty");
    }
    return PdfModel(
      title: title,
      url: url,
      date: data['date'] as String?,
      size: data['size'] != null ? data['size'].toString() : null, // Convert here
    );
  }
}
