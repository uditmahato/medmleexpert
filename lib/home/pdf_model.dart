import 'package:cloud_firestore/cloud_firestore.dart';

class PdfModel {
  final String id;
  final String title;
  final String url;
  final String? size; // New field for size
  final String? date; // New field for date

  PdfModel({
    required this.id,
    required this.title,
    required this.url,
    this.size,
    this.date,
  });

  factory PdfModel.fromDocument(DocumentSnapshot doc) {
    return PdfModel(
      id: doc.id,
      title: doc['title'],
      url: doc['url'],
      size: doc['size'], // Optional field
      date: doc['date'], // Optional field
    );
  }
}
