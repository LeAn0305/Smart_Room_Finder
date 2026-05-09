import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload từ File (mobile/desktop)
  Future<String> uploadProfileImage(File file) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('profile_images/${user.uid}/$fileName');
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    await ref.putFile(file, metadata);
    return ref.getDownloadURL();
  }

  /// Upload từ bytes (web)
  Future<String> uploadProfileImageBytes(Uint8List bytes, String mimeType) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    final ext = mimeType.contains('png') ? 'png' : 'jpg';
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref().child('profile_images/${user.uid}/$fileName');
    final metadata = SettableMetadata(contentType: mimeType);

    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }
}