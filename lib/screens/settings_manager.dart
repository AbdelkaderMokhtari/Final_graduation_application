// settings_manager.dart
// ─────────────────────────────────────────────
// Shared state for language & theme across all citizen screens
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Theme notifier (global) ───────────────────
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.light);

// ── Translations ──────────────────────────────
const Map<String, Map<String, String>> appTranslations = {
  'ar': {
    // General
    'appName': 'EcoCity',
    'settings': 'الإعدادات',
    'language': 'اللغة',
    'theme': 'المظهر',
    'darkMode': 'الوضع الداكن',
    'close': 'إغلاق',
    // Welcome
    'welcomeTitle': 'بلاغي',
    'welcomeSlogan': 'مدينتك بيدك — بلّغ، تابع، غيّر',
    'welcomeImpact': 'أثر حقيقي على أرض الواقع',
    'startNow': 'ابدأ الآن',
    'totalReports': 'بلاغ مُرسَل',
    'solvedReports': 'بلاغ مُحَلّ',
    'activeWorkers': 'عامل نشيط',
    // Home
    'homeGreeting': 'مرحبًا بك في EcoCity 🌿',
    'homeSubtitle': 'ساعد في الحفاظ على نظافة مدينتك',
    'cityInfo': 'معلومات عن سعيدة',
    'population': 'السكان',
    'populationVal': '~330,000 نسمة',
    'location': 'الموقع',
    'locationVal': 'شمال غرب الجزائر',
    'climate': 'المناخ',
    'climateVal': 'شبه جاف معتدل',
    'area': 'المساحة',
    'areaVal': '6,764 كم²',
    'reportNow': 'أبلغ عن نفايات الآن',
    'myReports': 'بلاغاتي',
    // Nav
    'navHome': 'الرئيسية',
    'navRead': 'المطالعة',
    'navReport': 'إبلاغ',
    // Citizen
    'appTitle': 'تقديم بلاغ',
    'adminPanel': 'لوحة الإدارة',
    'newReport': 'تقديم بلاغ جديد',
    'newReportSub': 'ساعد في تحسين مدينتك',
    'descHint': 'اكتب وصف المشكلة هنا...',
    'reportType': 'نوع البلاغ',
    'wasteType': 'نوع النفايات',
    'waste': 'نفايات',
    'lighting': 'إنارة عمومية',
    'roads': 'طرقات',
    'plastic': 'بلاستيك',
    'glass': 'زجاج',
    'organic': 'عضوي',
    'metals': 'معادن',
    'reportImage': 'صورة البلاغ',
    'captureImage': 'التقاط صورة',
    'noLocation': 'لم يتم تحديد الموقع بعد',
    'detectLocation': 'تحديد موقعي',
    'sendReport': 'إرسال البلاغ',
    'completeData': 'أكمل جميع البيانات',
    'reportSent': 'تم إرسال البلاغ بنجاح ✅',
    'error': 'خطأ',
    // Reading
    'readingTitle': 'المطالعة',
    'readingSubtitle': 'تعرف أكثر على البيئة',
  },
  'en': {
    'appName': 'EcoCity',
    'settings': 'Settings',
    'language': 'Language',
    'theme': 'Theme',
    'darkMode': 'Dark Mode',
    'close': 'Close',
    'welcomeTitle': 'Blaghi',
    'welcomeSlogan': 'Your city in your hands — Report, Track, Change',
    'welcomeImpact': 'Real impact on the ground',
    'startNow': 'Get Started',
    'totalReports': 'Reports Sent',
    'solvedReports': 'Solved',
    'activeWorkers': 'Active Workers',
    'homeGreeting': 'Welcome to EcoCity 🌿',
    'homeSubtitle': 'Help keep your city clean',
    'cityInfo': 'About Saida',
    'population': 'Population',
    'populationVal': '~330,000',
    'location': 'Location',
    'locationVal': 'NW Algeria',
    'climate': 'Climate',
    'climateVal': 'Semi-arid',
    'area': 'Area',
    'areaVal': '6,764 km²',
    'reportNow': 'Report Waste Now',
    'myReports': 'My Reports',
    'navHome': 'Home',
    'navRead': 'Reading',
    'navReport': 'Report',
    'appTitle': 'Submit Report',
    'adminPanel': 'Admin Panel',
    'newReport': 'New Report',
    'newReportSub': 'Help improve your city',
    'descHint': 'Describe the problem here...',
    'reportType': 'Report Type',
    'wasteType': 'Waste Type',
    'waste': 'Waste',
    'lighting': 'Public Lighting',
    'roads': 'Roads',
    'plastic': 'Plastic',
    'glass': 'Glass',
    'organic': 'Organic',
    'metals': 'Metals',
    'reportImage': 'Report Image',
    'captureImage': 'Capture Image',
    'noLocation': 'Location not set yet',
    'detectLocation': 'Detect My Location',
    'sendReport': 'Send Report',
    'completeData': 'Please complete all fields',
    'reportSent': 'Report sent successfully ✅',
    'error': 'Error',
    'readingTitle': 'Reading',
    'readingSubtitle': 'Learn more about the environment',
  },
  'fr': {
    'appName': 'EcoCity',
    'settings': 'Paramètres',
    'language': 'Langue',
    'theme': 'Thème',
    'darkMode': 'Mode sombre',
    'close': 'Fermer',
    'welcomeTitle': 'Blaghi',
    'welcomeSlogan': 'Ta ville entre tes mains — Signale, Suis, Change',
    'welcomeImpact': 'Un impact réel sur le terrain',
    'startNow': 'Commencer',
    'totalReports': 'Rapports envoyés',
    'solvedReports': 'Résolus',
    'activeWorkers': 'Travailleurs actifs',
    'homeGreeting': 'Bienvenue sur EcoCity 🌿',
    'homeSubtitle': 'Aidez à garder votre ville propre',
    'cityInfo': 'Infos sur Saïda',
    'population': 'Population',
    'populationVal': '~330 000 hab.',
    'location': 'Localisation',
    'locationVal': 'NO Algérie',
    'climate': 'Climat',
    'climateVal': 'Semi-aride',
    'area': 'Superficie',
    'areaVal': '6 764 km²',
    'reportNow': 'Signaler des déchets',
    'myReports': 'Mes rapports',
    'navHome': 'Accueil',
    'navRead': 'Lecture',
    'navReport': 'Signaler',
    'appTitle': 'Soumettre un rapport',
    'adminPanel': 'Panneau admin',
    'newReport': 'Nouveau rapport',
    'newReportSub': 'Aidez à améliorer votre ville',
    'descHint': 'Décrivez le problème ici...',
    'reportType': 'Type de rapport',
    'wasteType': 'Type de déchet',
    'waste': 'Déchets',
    'lighting': 'Éclairage public',
    'roads': 'Routes',
    'plastic': 'Plastique',
    'glass': 'Verre',
    'organic': 'Organique',
    'metals': 'Métaux',
    'reportImage': 'Image du rapport',
    'captureImage': 'Prendre une photo',
    'noLocation': 'Localisation non définie',
    'detectLocation': 'Détecter ma position',
    'sendReport': 'Envoyer le rapport',
    'completeData': 'Veuillez compléter tous les champs',
    'reportSent': 'Rapport envoyé avec succès ✅',
    'error': 'Erreur',
    'readingTitle': 'Lecture',
    'readingSubtitle': "En savoir plus sur l'environnement",
  },
};

// ── Settings Manager ──────────────────────────
class SettingsManager {
  static String currentLang = 'ar';
  static bool isDark = false;

  static String tr(String key) => appTranslations[currentLang]?[key] ?? key;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    currentLang = p.getString('lang') ?? 'ar';
    isDark = p.getBool('dark') ?? false;
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setLang(String lang) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', lang);
    currentLang = lang;
  }

  static Future<void> setDark(bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark', val);
    isDark = val;
    themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
  }
}
