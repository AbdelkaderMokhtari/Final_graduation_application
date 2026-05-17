import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// 🎨 Design Tokens
// ─────────────────────────────────────────────
class _C {
    static const purple = Color(0xFF8B5CF6); // ← زيد هاذ السطر
  static const navy = Color(0xFF0A1628);
  static const navyMid = Color(0xFF0F2044);
  static const blue = Color(0xFF1E6FFF);
  static const blueSoft = Color(0xFF4A90E2);
  static const accent = Color(0xFF00E5FF);
  static const orange = Color(0xFFFF8C42);
  static const green = Color(0xFF00D68F);
  static const red = Color(0xFFFF4D6A);
  static const surface = Color(0xFF111D35);
  static const card = Color(0xFF162040);
  static const card2 = Color(0xFF1A2848);
  static const divider = Color(0xFF1E2E50);
  static const textPrimary = Color(0xFFE8F0FF);
  static const textSub = Color(0xFF8899BB);
}

class CreateWorkerScreen extends StatefulWidget {
  const CreateWorkerScreen({super.key});

  @override
  State<CreateWorkerScreen> createState() => _CreateWorkerScreenState();
}

class _CreateWorkerScreenState extends State<CreateWorkerScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _selectedType = 'cleaner';
  bool _isLoading = false;
  bool _obscurePass = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Create worker ─────────────────────────────
  Future<void> _createWorker() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passwordCtrl.text.isEmpty) {
      _snack('يرجى ملء جميع الحقول', _C.orange);
      return;
    }

    try {
      setState(() => _isLoading = true);

      final secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'role': 'worker',
        'workerType': _selectedType,
        'createdAt': Timestamp.now(),
      });

      await secondaryApp.delete();

      _snack('تم إنشاء العامل بنجاح ✅', _C.green);
      _nameCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();
    } on FirebaseAuthException catch (e) {
      _snack('Firebase: ${e.message}', _C.red);
    } catch (e) {
      _snack('خطأ: $e', _C.red);
    } finally {
      setState(() => _isLoading = false);
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

  // ── Field ─────────────────────────────────────
  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    required Color color,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _C.card2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboard,
        style: const TextStyle(color: _C.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _C.textSub, fontSize: 13),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.navy,
      appBar: AppBar(
        backgroundColor: _C.navyMid,
        elevation: 0,
        iconTheme: const IconThemeData(color: _C.textPrimary),
        title: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _C.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _C.orange.withOpacity(0.3)),
            ),
            child: const Icon(Icons.engineering_rounded,
                color: _C.orange, size: 16),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('إنشاء عامل',
                style: TextStyle(
                    color: _C.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            Text('Create Worker',
                style: TextStyle(color: _C.textSub, fontSize: 10)),
          ]),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.divider),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Hero Card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  _C.orange.withOpacity(0.18),
                  _C.orange.withOpacity(0.04),
                ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.orange.withOpacity(0.25)),
              ),
              child: Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_C.orange, Color(0xFFFFB347)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: _C.orange.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Icon(Icons.engineering_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('إضافة عامل جديد',
                          style: TextStyle(
                              color: _C.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 3),
                      Text('أدخل بيانات العامل ليتمكن من تلقي المهام',
                          style: TextStyle(color: _C.textSub, fontSize: 11)),
                    ])),
              ]),
            ),

            const SizedBox(height: 24),

            // ── Section label ──
            _sectionLabel('بيانات الحساب'),

            // ── Fields ──
            _field(
              ctrl: _nameCtrl,
              label: 'الاسم الكامل',
              icon: Icons.person_rounded,
              color: _C.blue,
            ),
            const SizedBox(height: 12),

            _field(
              ctrl: _emailCtrl,
              label: 'البريد الإلكتروني',
              icon: Icons.email_rounded,
              color: _C.accent,
              keyboard: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            _field(
              ctrl: _passwordCtrl,
              label: 'كلمة المرور',
              icon: Icons.lock_rounded,
              color: _C.purple,
              obscure: _obscurePass,
              suffix: IconButton(
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: _C.textSub,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),

            const SizedBox(height: 24),

            // ── Worker type ──
            _sectionLabel('نوع العامل'),

            Row(children: [
              _typeCard('cleaner', '🧹', 'عامل نظافة', 'Cleaner', _C.green),
              const SizedBox(width: 12),
              _typeCard('driver', '🚛', 'سائق', 'Driver', _C.blue),
            ]),

            const SizedBox(height: 28),

            // ── Submit ──
            GestureDetector(
              onTap: _isLoading ? null : _createWorker,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoading
                        ? [_C.card, _C.card2]
                        : [_C.blue, _C.blueSoft],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _isLoading
                      ? []
                      : [
                          BoxShadow(
                              color: _C.blue.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6)),
                        ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: _C.textSub, strokeWidth: 2.5),
                        )
                      : const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.person_add_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text('إنشاء العامل',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                        ]),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }

  // ── Worker type card ──────────────────────────
  Widget _typeCard(
      String value, String emoji, String labelAr, String labelEn, Color color) {
    final active = _selectedType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    colors: [color.withOpacity(0.22), color.withOpacity(0.06)])
                : null,
            color: active ? null : _C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? color.withOpacity(0.5) : _C.divider,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(labelAr,
                style: TextStyle(
                    color: active ? color : _C.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text(labelEn,
                style: const TextStyle(color: _C.textSub, fontSize: 11)),
          ]),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: const TextStyle(
                color: _C.textSub,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
      );
}
