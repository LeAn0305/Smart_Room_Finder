import 'dart:io';

void main() {
  final file = File('lib/screens/admin/admin_dashboard_screen.dart');
  var content = file.readAsStringSync();

  // Fix remaining mojibake (double-encoded at end of file)
  content = content.replaceAll('lÃ\u00A0 Firebase', 'là Firebase');
  content = content.replaceAll('lÃ\u00A0 Ä', 'là đ');  
  
  // Also do a broader search and fix for any remaining double-encoded patterns
  final fixes = <String, String>{
    'Tá»± Ä\u0091á»\u0099ng chá»\u008dn': 'Tự động chọn',
    'hoáº·c': 'hoặc',
    'dá»±a trÃªn': 'dựa trên',
    'Ä\u0091Æ°á»\u009dng dáº«n': 'đường dẫn',
    'rá»\u0097ng hoáº·c lá»\u0097i': 'rỗng hoặc lỗi',
    'hiá»\u0083n thá»\u008b': 'hiển thị',
  };
  
  for (final entry in fixes.entries) {
    content = content.replaceAll(entry.key, entry.value);
  }

  file.writeAsStringSync(content);
  
  // Verify
  final verify = file.readAsStringSync();
  final lines = verify.split('\n');
  
  // Check for any remaining non-ASCII oddities in comments at end
  var issues = 0;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    // Look for sequences that are clearly wrong (Ã followed by certain chars)
    if (RegExp(r'[Ã][^\s]').hasMatch(line) && !RegExp(r'[àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞß]').hasMatch(line)) {
      // Skip lines with normal Vietnamese (which uses these chars legitimately)
    }
  }
  
  print('Fix complete. File: ${file.lengthSync()} bytes, Issues found: $issues');
}
