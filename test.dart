import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

const firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyDT19wJzp9ce7T11e98S3IVMGslI9TrQFM",
  authDomain: "medmleexpert.firebaseapp.com",
  projectId: "medmleexpert",
  storageBucket: "medmleexpert.appspot.com",
  messagingSenderId: "569834885497",
  appId: "1:569834885497:web:816817f4af71fe4787dfa8"
);

Future<void> main() async {
  print('Initializing Firebase...');
  try {
    await Firebase.initializeApp(options: firebaseOptions);
    print('Firebase Initialized.');

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    FirebaseStorage storage = FirebaseStorage.instance;

    QuerySnapshot querySnapshot = await firestore.collection('pdfs').get();

    if (querySnapshot.docs.isEmpty) {
      print("No documents found in the 'pdfs' collection.");
      return;
    }

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      print("Document ID: ${doc.id}");
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      String title = data['title'] as String? ?? 'No Title';
      String gsPath = data['url'] as String? ?? '';

      print("Title: $title");
      print("gsPath: $gsPath");

      if (gsPath.isNotEmpty) {
        try {
          Reference storageRef = storage.refFromURL(gsPath);
          String downloadURL = await storageRef.getDownloadURL();
          print("Download URL: $downloadURL");
        } catch (e) {
          print("Error getting download URL: $e");
        }
      } else {
        print("No URL provided.");
      }
    }
  } catch (e) {
    print("Error: $e");
  }
}
