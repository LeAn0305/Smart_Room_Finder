import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// Upload một ảnh từ đường dẫn thiết bị (local path) lên Firebase Storage.
  Future<String> uploadImage(String filePath) async {
    // Nếu vốn đã là link web hoặc asset mặc định thì trả về luôn không cần đẩy lại
    if (filePath.startsWith('http')) return filePath;
    if (filePath.startsWith('assets/')) return filePath;

    try {
      File file = File(filePath);
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
      // Tạo tên ngẫu nhiên kết hợp timestamp
      String fileName = 'room_images/$userId/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      Reference ref = _storage.ref().child(fileName);
      
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image to storage: $e');
      return '';
    }
  }

  /// Upload toàn bộ một danh sách đường dẫn ảnh
  Future<List<String>> uploadImagesList(List<String> filePaths) async {
    List<String> urls = [];
    for (String path in filePaths) {
      String url = await uploadImage(path);
      if (url.isNotEmpty) {
        urls.add(url);
      }
    }
    return urls;
  }
}
