import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> uploadProfileImage(File file) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('profile_images/${user.uid}/$fileName');

    final metadata = SettableMetadata(contentType: 'image/jpeg');

    final uploadTask = ref.putFile(file, metadata);
    await uploadTask;

    final downloadUrl = await ref.getDownloadURL();
    return downloadUrl;
  }
}