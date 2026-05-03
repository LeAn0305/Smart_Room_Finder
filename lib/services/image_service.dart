import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Xác định Content-Type dựa theo đuôi file.
  /// Fallback: image/jpeg nếu không xác định được.
  static String _contentTypeFromName(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Upload ảnh từ [XFile] (hỗ trợ Web + Android/iOS).
  /// Ưu tiên dùng readAsBytes() + putData() để hoạt động tốt trên Web.
  /// Luôn truyền SettableMetadata với contentType đúng.
  /// Trả về download URL (https://firebasestorage.googleapis.com/...).
  Future<String> uploadXFile(XFile xfile) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
      final ext = xfile.name.split('.').last.toLowerCase();
      final fileName =
          'room_images/$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = _storage.ref().child(fileName);

      final contentType = _contentTypeFromName(xfile.name);
      final metadata = SettableMetadata(contentType: contentType);

      // Dùng readAsBytes() + putData() — hoạt động trên cả Web và Mobile
      final bytes = await xfile.readAsBytes();
      final snapshot = await ref.putData(bytes, metadata);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading XFile to storage: $e');
      return '';
    }
  }

  /// Upload danh sách [XFile].
  Future<List<String>> uploadXFileList(List<XFile> xfiles) async {
    final urls = <String>[];
    for (final xfile in xfiles) {
      final url = await uploadXFile(xfile);
      if (url.isNotEmpty) urls.add(url);
    }
    return urls;
  }

  /// Upload ảnh từ local file path (chỉ dùng trên Mobile, không dùng trên Web).
  /// Nếu path là URL http hoặc assets, trả về luôn không upload lại.
  /// Luôn truyền SettableMetadata với contentType đúng.
  /// Trả về download URL (https://firebasestorage.googleapis.com/...).
  Future<String> uploadImage(String filePath) async {
    if (filePath.startsWith('http')) return filePath;
    if (filePath.startsWith('assets/')) return filePath;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
      final ext = filePath.split('.').last.toLowerCase();
      final safeExt = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)
          ? ext
          : 'jpg';
      final fileName =
          'room_images/$userId/${DateTime.now().millisecondsSinceEpoch}.$safeExt';
      final ref = _storage.ref().child(fileName);

      final contentType = _contentTypeFromName(filePath);
      final metadata = SettableMetadata(contentType: contentType);

      final file = File(filePath);
      final snapshot = await ref.putFile(file, metadata);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image to storage: $e');
      return '';
    }
  }

  /// Upload danh sách đường dẫn ảnh local (Mobile only).
  Future<List<String>> uploadImagesList(List<String> filePaths) async {
    final urls = <String>[];
    for (final path in filePaths) {
      final url = await uploadImage(path);
      if (url.isNotEmpty) urls.add(url);
    }
    return urls;
  }
}
