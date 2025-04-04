import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_service.dart';
import 'pdf_model.dart';
import 'pdf_viewer_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Medical Expert App"),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('pdfs').snapshots(),
        builder: (context, snapshot) {
          // Debug: Print snapshot state to console
          print("Connection State: ${snapshot.connectionState}");
          if (snapshot.hasError) {
            print("Error: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            print("No data yet, waiting...");
            return Center(child: Text("Loading PDFs..."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final pdfs =
              snapshot.data!.docs
                  .map((doc) => PdfModel.fromDocument(doc))
                  .toList();
          print("Fetched ${pdfs.length} PDFs");
          if (pdfs.isEmpty) {
            return Center(child: Text("No PDFs available"));
          }
          return ListView.builder(
            itemCount: pdfs.length,
            itemBuilder: (context, index) {
              PdfModel pdf = pdfs[index];
              return ListTile(
                title: Text(pdf.title),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerScreen(filePath: pdf.url),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
