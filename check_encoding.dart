import 'dart:io';

void main() {
  final file = File('lib/screens/admin/admin_dashboard_screen.dart');
  final content = file.readAsStringSync();
  
  // Check specific lines for mojibake
  final lines = content.split('\n');
  print('Line 21: ${lines[20].trim()}');
  print('Line 255: ${lines[254].trim()}');
  
  // Check if there are any non-UTF8 sequences by looking for replacement chars
  final hasReplacement = content.contains('\uFFFD');
  print('Has replacement chars: $hasReplacement');
  
  // Search for common mojibake patterns (Latin1 misinterpretation)
  final mojibakePatterns = [
    'Ã\u00A0', 'Ã\u00A1', 'Ã\u00A9', 'Ã\u00AD', 'Ã\u00B3', 'Ã\u00BA',
    'Ã\u0083', 'Ã\u0084', 'Ã\u0089',
  ];
  
  for (final p in mojibakePatterns) {
    if (content.contains(p)) {
      final idx = content.indexOf(p);
      final ctx = content.substring(
        idx > 10 ? idx - 10 : 0, 
        idx + p.length + 10 < content.length ? idx + p.length + 10 : content.length
      );
      print('Found mojibake pattern at index $idx: ...${ctx.replaceAll('\n', '\\n')}...');
    }
  }
  
  // Also check for the specific broken strings
  if (content.contains('ngÃ\u00A0y')) print('Found: ngÃ\u00A0y (should be ngày)');
  if (content.contains('ngày')) print('Found correct: ngày');
}
