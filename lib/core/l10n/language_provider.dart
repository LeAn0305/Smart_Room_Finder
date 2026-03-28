import 'package:flutter/material.dart';
import 'app_vi.dart';
import 'app_en.dart';
import 'app_ja.dart';
import 'app_ko.dart';
import 'app_zh.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('vi');

  Locale get locale => _locale;

  static const supportedLocales = [
    Locale('vi'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  static const languages = [
    ('vi', 'Tiếng Việt', '🇻🇳'),
    ('en', 'English', '🇬🇧'),
    ('ja', '日本語', '🇯🇵'),
    ('ko', '한국어', '🇰🇷'),
    ('zh', '中文', '🇨🇳'),
  ];

  Map<String, String> get _strings {
    switch (_locale.languageCode) {
      case 'en': return appEn;
      case 'ja': return appJa;
      case 'ko': return appKo;
      case 'zh': return appZh;
      default:   return appVi;
    }
  }

  String tr(String key) => _strings[key] ?? key;

  String get currentLanguageName =>
      languages.firstWhere((l) => l.$1 == _locale.languageCode,
          orElse: () => languages.first).$2;

  void setLocale(String languageCode) {
    _locale = Locale(languageCode);
    notifyListeners();
  }
}
