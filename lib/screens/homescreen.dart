// home_screen.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'settings_manager.dart';
import 'login_screen.dart';
import 'my_reports_screen.dart';

// ─────────────────────────────────────────────
// 🎨 Light + Dark tokens
// ─────────────────────────────────────────────
class _LC {
  static const green = Color(0xFF2E7D32);
  static const greenLight = Color(0xFF4CAF50);
  static const greenSoft = Color(0xFFE8F5E9);
  static const white = Colors.white;
  static const bg = Color(0xFFF4F9F4);
  static const card = Colors.white;
  static const text = Color(0xFF1B2E1B);
  static const textSub = Color(0xFF6B7B6B);
  static const divider = Color(0xFFDDEEDD);
}

class _DC {
  static const navy = Color(0xFF0A1628);
  static const navyMid = Color(0xFF0F2044);
  static const blue = Color(0xFF1E6FFF);
  static const accent = Color(0xFF00E5FF);
  static const green = Color(0xFF00D68F);
  static const orange = Color(0xFFFF8C42);
  static const card = Color(0xFF162040);
  static const card2 = Color(0xFF1A2848);
  static const divider = Color(0xFF1E2E50);
  static const textPrimary = Color(0xFFE8F0FF);
  static const textSub = Color(0xFF8899BB);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  String tr(String k) => SettingsManager.tr(k);
  bool get _dark => SettingsManager.isDark;

  Color get _bg => _dark ? _DC.navy : _LC.bg;
  Color get _appBar => _dark ? _DC.navyMid : _LC.green;
  Color get _cardBg => _dark ? _DC.card : _LC.card;
  Color get _divColor => _dark ? _DC.divider : _LC.divider;
  Color get _txtPri => _dark ? _DC.textPrimary : _LC.text;
  Color get _txtSub => _dark ? _DC.textSub : _LC.textSub;
  Color get _primary => _dark ? _DC.blue : _LC.green;
  Color get _accent => _dark ? _DC.accent : _LC.greenLight;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _signInAnonymous();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInAnonymous() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  void _switchTab(int i) {
    if (i == _tabIndex) return;
    setState(() => _tabIndex = i);
    _animCtrl.reset();
    _animCtrl.forward();
  }

  void _rebuildAfterSettings() => setState(() {});

  // ── Settings sheet ────────────────────────────
  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _dark ? _DC.card : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          final dark = SettingsManager.isDark;
          final sheetCard = dark ? _DC.card2 : const Color(0xFFF4F9F4);
          final sheetText = dark ? _DC.textPrimary : _LC.text;
          final sheetSub = dark ? _DC.textSub : _LC.textSub;
          final sheetDiv = dark ? _DC.divider : _LC.divider;
          final primary = dark ? _DC.blue : _LC.green;

          return Padding(
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
                      color: sheetDiv,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  )),
                  const SizedBox(height: 20),
                  Row(children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.settings_rounded,
                          color: primary, size: 17),
                    ),
                    const SizedBox(width: 10),
                    Text(tr('settings'),
                        style: TextStyle(
                            color: sheetText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 18),

                  // Dark mode
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: sheetCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sheetDiv),
                    ),
                    child: Row(children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: SettingsManager.isDark
                              ? const Color(0xFF8B5CF6).withOpacity(0.15)
                              : const Color(0xFFFF8C42).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          SettingsManager.isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: SettingsManager.isDark
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFFFF8C42),
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(tr('darkMode'),
                          style: TextStyle(
                              color: sheetText,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Switch(
                        value: SettingsManager.isDark,
                        activeColor: primary,
                        activeTrackColor: primary.withOpacity(0.3),
                        onChanged: (v) async {
                          await SettingsManager.setDark(v);
                          setModal(() {});
                          _rebuildAfterSettings();
                        },
                      ),
                    ]),
                  ),

                  const SizedBox(height: 12),

                  // Language
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: sheetCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sheetDiv),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _LC.greenLight.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.language_rounded,
                                  color: _LC.greenLight, size: 17),
                            ),
                            const SizedBox(width: 12),
                            Text(tr('language'),
                                style: TextStyle(
                                    color: sheetText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            _langBtn('ar', 'العربية', primary, setModal),
                            const SizedBox(width: 8),
                            _langBtn('en', 'English', primary, setModal),
                            const SizedBox(width: 8),
                            _langBtn('fr', 'Français', primary, setModal),
                          ]),
                        ]),
                  ),
                  const SizedBox(height: 10),
                ]),
          );
        },
      ),
    );
  }

  Widget _langBtn(
      String code, String label, Color primary, StateSetter setModal) {
    final active = SettingsManager.currentLang == code;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          await SettingsManager.setLang(code);
          setModal(() {});
          _rebuildAfterSettings();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? primary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? primary.withOpacity(0.5) : _divColor,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: active ? primary : _txtSub,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12)),
          ),
        ),
      ),
    );
  }

  // ── AppBar actions ────────────────────────────
  List<Widget> _appBarActions() => [
        IconButton(
          icon: Icon(
            SettingsManager.isDark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            color: Colors.white,
          ),
          onPressed: () async {
            await SettingsManager.setDark(!SettingsManager.isDark);
            setState(() {});
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: Colors.white),
          onPressed: _showSettings,
        ),
        IconButton(
          icon: const Icon(Icons.login_rounded, color: Colors.white),
          tooltip: tr('adminPanel'),
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const LoginScreen())),
        ),
      ];

  // ─────────────────────────────────────────────
  // TAB 0: Home
  // ─────────────────────────────────────────────
  Widget _buildHome() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Welcome banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _dark
                  ? [_DC.blue.withOpacity(0.22), _DC.accent.withOpacity(0.06)]
                  : [_LC.green, _LC.greenLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: _primary.withOpacity(0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(tr('homeGreeting'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          height: 1.4)),
                  const SizedBox(height: 5),
                  Text(tr('homeSubtitle'),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85), fontSize: 12)),
                ])),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  const Icon(Icons.eco_rounded, color: Colors.white, size: 28),
            ),
          ]),
        ),

        const SizedBox(height: 24),

        _sectionLabel(tr('cityInfo')),
        const SizedBox(height: 12),

        Column(children: [
          Row(children: [
            Expanded(
                child: _infoCard('👥', tr('population'), tr('populationVal'))),
            const SizedBox(width: 12),
            Expanded(child: _infoCard('📍', tr('location'), tr('locationVal'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _infoCard('🌡️', tr('climate'), tr('climateVal'))),
            const SizedBox(width: 12),
            Expanded(child: _infoCard('🗺️', tr('area'), tr('areaVal'))),
          ]),
        ]),

        const SizedBox(height: 26),

        // Report now button
        GestureDetector(
          onTap: () => setState(() => _tabIndex = 2),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _dark
                    ? [_DC.blue, _DC.accent.withOpacity(0.7)]
                    : [_LC.green, _LC.greenLight],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: _primary.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(tr('reportNow'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        ),

        const SizedBox(height: 12),

        // My reports button
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MyReportsScreen())),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _divColor),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.list_alt_rounded, color: _primary, size: 20),
              const SizedBox(width: 10),
              Text(tr('myReports'),
                  style: TextStyle(
                      color: _txtPri,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),

        const SizedBox(height: 12),

        // Admin login button
        GestureDetector(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: _dark ? const Color(0xFF1A2848) : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _dark
                    ? const Color(0xFF1E6FFF).withOpacity(0.3)
                    : const Color(0xFF2E7D32).withOpacity(0.25),
              ),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.admin_panel_settings_rounded,
                  color:
                      _dark ? const Color(0xFF8899BB) : const Color(0xFF6B7B6B),
                  size: 18),
              const SizedBox(width: 8),
              Text(tr('adminPanel'),
                  style: TextStyle(
                      color: _dark
                          ? const Color(0xFF8899BB)
                          : const Color(0xFF6B7B6B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ),

        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _infoCard(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(_dark ? 0.15 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(color: _txtSub, fontSize: 11),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  color: _txtPri, fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 2),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 1: Reading
  // ─────────────────────────────────────────────
  final List<Map<String, String>> _articles = [
    {
      'emoji': '🌍',
      'title': 'كيف تؤثر النفايات على البيئة؟',
      'tag': 'بيئة',
      'body':
          'تُعدّ النفايات من أخطر مصادر تلوث البيئة، إذ تُلوّث التربة والمياه الجوفية وتُطلق غازات ضارة عند حرقها. تراكم النفايات البلاستيكية في المحيطات يهدد الحياة البحرية، فيما تنبعث من مكبات النفايات غازات الميثان المُسرِّعة للاحترار العالمي.',
    },
    {
      'emoji': '♻️',
      'title': 'دليل الفرز الصحيح للمخلفات',
      'tag': 'إرشادات',
      'body':
          'الفرز الصحيح يبدأ من المنزل: ضع البلاستيك والزجاج والمعادن في حاويات منفصلة عن النفايات العضوية. تجنّب خلط البقايا الغذائية بالنفايات الجافة. النفايات الخطرة كالبطاريات والأدوية تُسلَّم لمراكز تجميع مخصصة.',
    },
    {
      'emoji': '🇩🇿',
      'title': 'مبادرات نظافة في الجزائر',
      'tag': 'أخبار',
      'body':
          'أطلقت الجزائر برامج وطنية لتحسين النظافة الحضرية، من بينها حملات التوعية المدرسية وتوزيع حاويات الفرز في المدن الكبرى. كما تشهد مدن كسعيدة وتلمسان وهران تجارب محلية لتفعيل دور المواطن في الإبلاغ عن مشاكل النظافة.',
    },
    {
      'emoji': '🤝',
      'title': 'دور المواطن في نظافة المدينة',
      'tag': 'توعية',
      'body':
          'المواطن هو الخط الأول في الحفاظ على نظافة المدينة. الإبلاغ الفوري عن تراكم النفايات، وتجنّب رمي المخلفات في الأماكن العامة، والمشاركة في حملات التنظيف الجماعية — كلها سلوكيات تُحدث فارقاً حقيقياً على أرض الواقع.',
    },
    {
      'emoji': '⚙️',
      'title': 'تقنيات معالجة النفايات الحديثة',
      'tag': 'تكنولوجيا',
      'body':
          'تشمل التقنيات الحديثة تحويل النفايات إلى طاقة عبر الحرق المتحكم فيه، وإنتاج السماد العضوي من البقايا الغذائية، واستخدام الذكاء الاصطناعي في تصنيف المخلفات آلياً. بعض الدول بدأت تعتمد حاويات ذكية تُرسل إشعارات تلقائية عند امتلائها.',
    },
  ];

  final List<bool> _expanded = List.filled(5, false);

  Widget _buildReading() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _articles.length,
      itemBuilder: (_, i) {
        final a = _articles[i];
        final isOpen = _expanded[i];

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 250 + i * 60),
          curve: Curves.easeOut,
          builder: (_, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
                offset: Offset(0, 16 * (1 - v)), child: child),
          ),
          child: GestureDetector(
            onTap: () => setState(() => _expanded[i] = !_expanded[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isOpen ? _primary.withOpacity(0.4) : _divColor,
                  width: isOpen ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isOpen
                        ? _primary.withOpacity(0.1)
                        : Colors.black.withOpacity(_dark ? 0.12 : 0.04),
                    blurRadius: isOpen ? 16 : 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _primary.withOpacity(0.2)),
                      ),
                      child: Center(
                          child: Text(a['emoji']!,
                              style: const TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a['title']!,
                                style: TextStyle(
                                    color: _txtPri,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(a['tag']!,
                                  style: TextStyle(
                                      color: _primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ]),
                    ),
                    // Arrow
                    AnimatedRotation(
                      turns: isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 280),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isOpen ? _primary : _txtSub,
                        size: 24,
                      ),
                    ),
                  ]),

                  // Expandable body
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),
                        Divider(color: _divColor, height: 1),
                        const SizedBox(height: 12),
                        Text(
                          a['body']!,
                          style: TextStyle(
                            color: _txtSub,
                            fontSize: 13,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                    crossFadeState: isOpen
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 280),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // TAB 2: Report
  // ─────────────────────────────────────────────
  final _descCtrl = TextEditingController();
  String _category = 'waste';
  String _wasteType = 'plastic';
  File? _image;
  double? _lat;
  double? _lng;
  bool _sending = false;
  bool _locLoading = false;

  String get _catDisplay {
    switch (_category) {
      case 'lighting':
        return tr('lighting');
      case 'roads':
        return tr('roads');
      default:
        return tr('waste');
    }
  }

  Future<void> _pickImage() async {
    final p = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 25, maxWidth: 800);
    if (p != null) setState(() => _image = File(p.path));
  }

  Future<void> _getLocation() async {
    setState(() => _locLoading = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } finally {
      setState(() => _locLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_descCtrl.text.isEmpty || _image == null || _lat == null) {
      _snack(tr('completeData'), _dark ? const Color(0xFFFF8C42) : _LC.green);
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() => _sending = true);
      final bytes = await _image!.readAsBytes();
      final base64 = base64Encode(bytes);
      await FirebaseFirestore.instance.collection('reports').add({
        'userId': user.uid,
        'description': _descCtrl.text.trim(),
        'category': _catDisplay,
        'wasteType': _category == 'waste' ? tr(_wasteType) : null,
        'beforeImageBase64': base64,
        'status': 'pending',
        'latitude': _lat,
        'longitude': _lng,
        'assignedTo': null,
        'timestamp': Timestamp.now(),
      });
      _descCtrl.clear();
      setState(() {
        _image = null;
        _lat = null;
        _lng = null;
      });
      _snack(tr('reportSent'), const Color(0xFF00D68F));
    } catch (e) {
      _snack('${tr('error')}: $e', Colors.red);
    } finally {
      setState(() => _sending = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _buildReport() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Hero
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _dark
                  ? [_DC.blue.withOpacity(0.2), _DC.accent.withOpacity(0.05)]
                  : [_LC.green, _LC.greenLight],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(tr('newReport'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(tr('newReportSub'),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 12)),
                ])),
            const Icon(Icons.campaign_rounded, color: Colors.white, size: 30),
          ]),
        ),

        const SizedBox(height: 20),

        _sectionLabel(tr('description')),
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _divColor),
          ),
          child: TextField(
            controller: _descCtrl,
            maxLines: 4,
            style: TextStyle(color: _txtPri, fontSize: 14),
            decoration: InputDecoration(
              hintText: tr('descHint'),
              hintStyle: TextStyle(color: _txtSub, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),

        const SizedBox(height: 20),

        _sectionLabel(tr('reportType')),
        Row(children: [
          _catChip('waste', tr('waste'), Icons.delete_rounded,
              const Color(0xFFFF8C42)),
          const SizedBox(width: 8),
          _catChip('lighting', tr('lighting'), Icons.lightbulb_rounded,
              const Color(0xFF00E5FF)),
          const SizedBox(width: 8),
          _catChip('roads', tr('roads'), Icons.construction_rounded,
              const Color(0xFF8B5CF6)),
        ]),

        if (_category == 'waste') ...[
          const SizedBox(height: 16),
          _sectionLabel(tr('wasteType')),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _wasteChip(
                'plastic', tr('plastic'), Icons.recycling_rounded, _primary),
            _wasteChip('glass', tr('glass'), Icons.wine_bar_rounded, _accent),
            _wasteChip('organic', tr('organic'), Icons.eco_rounded,
                const Color(0xFF00D68F)),
            _wasteChip('metals', tr('metals'), Icons.settings_rounded, _txtSub),
          ]),
        ],

        const SizedBox(height: 20),

        _sectionLabel(tr('reportImage')),
        GestureDetector(
          onTap: _pickImage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            width: double.infinity,
            height: _image != null ? 200 : 120,
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _image != null ? _primary.withOpacity(0.4) : _divColor,
                width: _image != null ? 1.5 : 1,
              ),
            ),
            child: _image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(_image!, fit: BoxFit.cover))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.add_a_photo_rounded,
                            color: _primary, size: 32),
                        const SizedBox(height: 8),
                        Text(tr('captureImage'),
                            style: TextStyle(color: _txtSub, fontSize: 13)),
                      ]),
          ),
        ),

        const SizedBox(height: 20),

        _sectionLabel(tr('location')),
        GestureDetector(
          onTap: _getLocation,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _lat != null
                    ? const Color(0xFF00D68F).withOpacity(0.4)
                    : _divColor,
                width: _lat != null ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _lat != null
                      ? const Color(0xFF00D68F).withOpacity(0.12)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: _locLoading
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            color: _primary, strokeWidth: 2.5))
                    : Icon(
                        _lat != null
                            ? Icons.location_on_rounded
                            : Icons.my_location_rounded,
                        color:
                            _lat != null ? const Color(0xFF00D68F) : Colors.red,
                        size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(
                _lat != null
                    ? '${_lat!.toStringAsFixed(4)},  ${_lng!.toStringAsFixed(4)}'
                    : tr('noLocation'),
                style: TextStyle(
                    color: _lat != null ? _txtPri : _txtSub, fontSize: 13),
              )),
              Icon(
                _lat != null
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: _lat != null ? const Color(0xFF00D68F) : _txtSub,
                size: 20,
              ),
            ]),
          ),
        ),

        const SizedBox(height: 28),

        // Submit
        GestureDetector(
          onTap: _sending ? null : _submit,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _sending
                    ? [_cardBg, _cardBg]
                    : _dark
                        ? [_DC.blue, const Color(0xFF4A90E2)]
                        : [_LC.green, _LC.greenLight],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: _sending
                  ? []
                  : [
                      BoxShadow(
                          color: _primary.withOpacity(0.38),
                          blurRadius: 18,
                          offset: const Offset(0, 6))
                    ],
            ),
            child: Center(
              child: _sending
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: _txtSub, strokeWidth: 2.5))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(tr('sendReport'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                    ]),
            ),
          ),
        ),

        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _catChip(String val, String label, IconData icon, Color color) {
    final active = _category == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _category = val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.15) : _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: active ? color.withOpacity(0.5) : _divColor,
                width: active ? 1.5 : 1),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: active ? color : _txtSub, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: active ? color : _txtSub,
                    fontSize: 11,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ]),
        ),
      ),
    );
  }

  Widget _wasteChip(String val, String label, IconData icon, Color color) {
    final active = _wasteType == val;
    return GestureDetector(
      onTap: () => setState(() => _wasteType = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.14) : _cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? color.withOpacity(0.45) : _divColor,
              width: active ? 1.5 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? color : _txtSub, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: active ? color : _txtSub,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: TextStyle(
                color: _txtSub,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6)),
      );

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final pages = [_buildHome(), _buildReading(), _buildReport()];
    final navLabels = [tr('navHome'), tr('navRead'), tr('navReport')];
    final navIcons = [
      Icons.home_rounded,
      Icons.menu_book_rounded,
      Icons.warning_amber_rounded,
    ];

    return Directionality(
      textDirection: SettingsManager.currentLang == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _appBar,
          elevation: 0,
          title: const Text(
            'سعيدة  EcoCity',
            style: TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          actions: _appBarActions(),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              color: _appBar,
              child: Row(
                children: List.generate(3, (i) {
                  final active = _tabIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _switchTab(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: active ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(navIcons[i],
                              color: active
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.55),
                              size: 20),
                          const SizedBox(height: 2),
                          Text(navLabels[i],
                              style: TextStyle(
                                  color: active
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.55),
                                  fontSize: 11,
                                  fontWeight: active
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ]),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: pages[_tabIndex],
        ),
      ),
    );
  }
}
