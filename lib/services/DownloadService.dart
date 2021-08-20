import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class DownloadService {
  Future<void> downloadFileFromFireStore(String fileUrl, String path,
      {bool deleteAfter = true}) async {
    var ref = FirebaseStorage.instance.ref(fileUrl);
    var file = File(path);
    await ref.writeToFile(file);
    if (deleteAfter) ref.delete();
  }
}
//database ten veriyi siliyor