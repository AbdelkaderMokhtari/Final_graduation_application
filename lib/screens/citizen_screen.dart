import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'my_reports_screen.dart';
import 'login_screen.dart';
import 'services/notification_service.dart';

// ─────────────────────────────────────────────
// 🌍 Translations
// ─────────────────────────────────────────────
const Map<String, Map<String, String>> _t = {
  'ar': {
    'appTitle': 'تقديم بلاغ',
    'myReports': 'بلاغاتي',
    'adminPanel': 'لوحة الإدارة',
    'newReport': '📢 تقديم بلاغ جديد',
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
    'noImage': 'لم يتم اختيار صورة بعد',
    'captureImage': 'التقاط صورة',
    'location': 'الموقع',
    'noLocation': 'لم يتم تحديد الموقع',
    'detectLocation': 'تحديد الموقع',
    'sendReport': 'إرسال البلاغ',
    'completeData': 'أكمل جميع البيانات',
    'reportSent': '✅ تم إرسال البلاغ بنجاح',
    'error': 'خطأ',
    'language': 'اللغة',
    'theme': 'المظهر',
  },
  'en': {
    'appTitle': 'Submit Report',
    'myReports': 'My Reports',
    'adminPanel': 'Admin Panel',
    'newReport': '📢 New Report',
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
    'noImage': 'No image selected yet',
    'captureImage': 'Capture Image',
    'location': 'Location',
    'noLocation': 'Location not set',
    'detectLocation': 'Detect Location',
    'sendReport': 'Send Report',
    'completeData': 'Please complete all fields',
    'reportSent': '✅ Report sent successfully',
    'error': 'Error',
    'language': 'Language',
    'theme': 'Theme',
  },
  'fr': {
    'appTitle': 'Soumettre un rapport',
    'myReports': 'Mes rapports',
    'adminPanel': 'Panneau admin',
    'newReport': '📢 Nouveau rapport',
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
    'noImage': 'Aucune image sélectionnée',
    'captureImage': 'Prendre une photo',
    'location': 'Localisation',
    'noLocation': 'Localisation non définie',
    'detectLocation': 'Détecter la position',
    'sendReport': 'Envoyer le rapport',
    'completeData': 'Veuillez compléter tous les champs',
    'reportSent': '✅ Rapport envoyé avec succès',
    'error': 'Erreur',
    'language': 'Langue',
    'theme': 'Thème',
  },
};

// ─────────────────────────────────────────────
// 🎨 Theme Notifier
// ─────────────────────────────────────────────
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.light);

// ─────────────────────────────────────────────
// 🏠 CitizenScreen
// ─────────────────────────────────────────────
class CitizenScreen extends StatefulWidget {
  const CitizenScreen({super.key});

  @override
  State<CitizenScreen> createState() => _CitizenScreenState();
}

class _CitizenScreenState extends State<CitizenScreen> {
  final descriptionController = TextEditingController();

  String selectedCategory = "waste";
  String selectedWasteType = "plastic";
  String _lang = 'ar';
  bool _isDark = false;

  File? selectedImage;
  double? latitude;
  double? longitude;
  bool isLoading = false;
  User? user;

  // ── 🔔 لتتبع حالات البلاغات السابقة ──────────
  // key: reportId — value: آخر status معروف
  final Map<String, String> _reportStatuses = {};
  bool _firstStatusLoad = true;

  String tr(String key) => _t[_lang]?[key] ?? key;

  String get categoryValue {
    switch (selectedCategory) {
      case 'waste':
        return tr('waste');
      case 'lighting':
        return tr('lighting');
      case 'roads':
        return tr('roads');
      default:
        return tr('waste');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    signInAnonymous();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('lang') ?? 'ar';
      _isDark = prefs.getBool('dark') ?? false;
      themeModeNotifier.value = _isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _saveLang(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
    setState(() => _lang = lang);
  }

  Future<void> _toggleTheme(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark', val);
    setState(() => _isDark = val);
    themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> signInAnonymous() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    user = FirebaseAuth.instance.currentUser;
  }

  // ─────────────────────────────────────────────
  // 🔔 فحص تغير حالة البلاغات وإرسال notification
  // ─────────────────────────────────────────────
  void _checkStatusChanges(List<DocumentSnapshot> docs) {
    // أول تحميل — سجل الحالات بدون notification
    if (_firstStatusLoad) {
      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'pending';
        _reportStatuses[doc.id] = status;
      }
      _firstStatusLoad = false;
      return;
    }

    // تحقق من التغييرات
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final newStatus = data['status'] ?? 'pending';
      final oldStatus = _reportStatuses[doc.id];

      // حالة جديدة أو تغيرت
      if (oldStatus != newStatus) {
        _reportStatuses[doc.id] = newStatus;

        // أرسل notification فقط للحالات المهمة
        if (newStatus == 'assigned' ||
            newStatus == 'in_progress' ||
            newStatus == 'completed') {
          NotificationService().notifyCitizen(
            status: newStatus,
            description: data['description'] ?? 'بلاغك',
          );
        }
      }
    }

    // أضف بلاغات جديدة للقاموس
    for (final doc in docs) {
      if (!_reportStatuses.containsKey(doc.id)) {
        final data = doc.data() as Map<String, dynamic>;
        _reportStatuses[doc.id] = data['status'] ?? 'pending';
      }
    }
  }

  // ─────────────────────────────────────────────
  // 📷 Pick Image
  // ─────────────────────────────────────────────
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 25,
      maxWidth: 800,
    );
    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  }

  // ─────────────────────────────────────────────
  // 📍 Get Location
  // ─────────────────────────────────────────────
  Future<void> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });
  }

  // ─────────────────────────────────────────────
  // 📤 Submit Report
  // ─────────────────────────────────────────────
  Future<void> submitReport() async {
    if (descriptionController.text.isEmpty ||
        selectedImage == null ||
        latitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('completeData'))),
      );
      return;
    }
    if (user == null) return;

    try {
      setState(() => isLoading = true);

      List<int> imageBytes = await selectedImage!.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      await FirebaseFirestore.instance.collection('reports').add({
        'userId': user!.uid,
        'description': descriptionController.text.trim(),
        'category': categoryValue,
        'wasteType': selectedCategory == "waste" ? tr(selectedWasteType) : null,
        'beforeImageBase64': base64Image,
        'status': 'pending',
        'latitude': latitude,
        'longitude': longitude,
        'assignedTo': null,
        'timestamp': Timestamp.now(),
      });

      descriptionController.clear();
      setState(() {
        selectedImage = null;
        latitude = null;
        longitude = null;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('reportSent'))),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${tr('error')}: $e")),
      );
    }
  }

  // ─── Settings Bottom Sheet ───────────────────
  void _showSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Icon(
                  _isDark ? Icons.dark_mode : Icons.light_mode,
                  color: const Color(0xFF4A90E2),
                ),
                const SizedBox(width: 12),
                Text(tr('theme'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Switch(
                  value: _isDark,
                  activeColor: const Color(0xFF4A90E2),
                  onChanged: (val) {
                    setModal(() {});
                    _toggleTheme(val);
                  },
                ),
              ]),
              const Divider(height: 28),
              Row(children: [
                const Icon(Icons.language, color: Color(0xFF4A90E2)),
                const SizedBox(width: 12),
                Text(tr('language'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _langChip('ar', 'العربية', setModal),
                  _langChip('en', 'English', setModal),
                  _langChip('fr', 'Français', setModal),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langChip(String code, String label, StateSetter setModal) {
    final selected = _lang == code;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFF4A90E2),
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) {
        _saveLang(code);
        setModal(() {});
      },
    );
  }

  Widget buildCategorySelector() {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      items: [
        DropdownMenuItem(value: "waste", child: Text(tr('waste'))),
        DropdownMenuItem(value: "lighting", child: Text(tr('lighting'))),
        DropdownMenuItem(value: "roads", child: Text(tr('roads'))),
      ],
      onChanged: (value) => setState(() => selectedCategory = value!),
      decoration: InputDecoration(
        labelText: tr('reportType'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget buildWasteSelector() {
    if (selectedCategory != "waste") return const SizedBox();
    return Column(children: [
      const SizedBox(height: 20),
      DropdownButtonFormField<String>(
        value: selectedWasteType,
        items: [
          DropdownMenuItem(value: "plastic", child: Text(tr('plastic'))),
          DropdownMenuItem(value: "glass", child: Text(tr('glass'))),
          DropdownMenuItem(value: "organic", child: Text(tr('organic'))),
          DropdownMenuItem(value: "metals", child: Text(tr('metals'))),
        ],
        onChanged: (value) => setState(() => selectedWasteType = value!),
        decoration: InputDecoration(
          labelText: tr('wasteType'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ]);
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = _isDark;

    return Directionality(
      textDirection: _lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF7F9FC),
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
              ),
            ),
          ),
          title: Text(
            tr('appTitle'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: _showSettings,
            ),
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              tooltip: tr('adminPanel'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            ),
          ],
        ),

        // ── 🔔 StreamBuilder لمراقبة بلاغات المواطن ──
        body: StreamBuilder<QuerySnapshot>(
          stream: user != null
              ? FirebaseFirestore.instance
                  .collection('reports')
                  .where('userId', isEqualTo: user!.uid)
                  .snapshots()
              : const Stream.empty(),
          builder: (context, snapshot) {
            // فحص التغييرات في الخلفية
            if (snapshot.hasData) {
              _checkStatusChanges(snapshot.data!.docs);
            }

            // الـ UI الأصلي بدون تغيير
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                      : [const Color(0xFFF7F9FC), const Color(0xFFEAF0F9)],
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('newReport'),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 35),

                    // Description
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: tr('descHint'),
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    buildCategorySelector(),
                    buildWasteSelector(),
                    const SizedBox(height: 30),

                    // Image section
                    Row(children: [
                      const Icon(Icons.camera_alt, size: 26),
                      const SizedBox(width: 10),
                      Text(tr('reportImage'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                    ]),
                    const SizedBox(height: 15),
                    Center(
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.file(
                                selectedImage!,
                                height: 170,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(tr('noImage')),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(Icons.camera),
                        label: Text(tr('captureImage')),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Location section
                    Row(children: [
                      const Icon(Icons.location_on, size: 26),
                      const SizedBox(width: 10),
                      Text(tr('location'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                    ]),
                    const SizedBox(height: 12),
                    Text(
                      latitude != null
                          ? "📍 $latitude , $longitude"
                          : tr('noLocation'),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: getLocation,
                        icon: const Icon(Icons.my_location),
                        label: Text(tr('detectLocation')),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: submitReport,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                tr('sendReport'),
                                style: const TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
