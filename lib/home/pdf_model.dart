import 'package:cloud_firestore/cloud_firestore.dart';

class PdfModel {
  final String id;
  final String title;
  final String url;

  PdfModel({required this.id, required this.title, required this.url});

  factory PdfModel.fromDocument(DocumentSnapshot doc) {
    return PdfModel(id: doc.id, title: doc['title'], url: doc['url']);
  }
}
