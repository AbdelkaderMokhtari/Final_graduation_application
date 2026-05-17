import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// 🎨 Design Tokens
// ─────────────────────────────────────────────
class _C {
  static const navy = Color(0xFF0A1628);
  static const navyMid = Color(0xFF0F2044);
  static const blue = Color(0xFF1E6FFF);
  static const blueSoft = Color(0xFF4A90E2);
  static const accent = Color(0xFF00E5FF);
  static const orange = Color(0xFFFF8C42);
  static const green = Color(0xFF00D68F);
  static const red = Color(0xFFFF4D6A);
  static const purple = Color(0xFF8B5CF6);
  static const card = Color(0xFF162040);
  static const card2 = Color(0xFF1A2848);
  static const divider = Color(0xFF1E2E50);
  static const textPrimary = Color(0xFFE8F0FF);
  static const textSub = Color(0xFF8899BB);
}

class WorkerRegisterScreen extends StatefulWidget {
  const WorkerRegisterScreen({super.key});

  @override
  State<WorkerRegisterScreen> createState() => _WorkerRegisterScreenState();
}

class _WorkerRegisterScreenState extends State<WorkerRegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

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

  // ── Register ──────────────────────────────────
  Future<void> _register() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      _snack('يرجى ملء جميع الحقول', _C.orange);
      return;
    }

    try {
      setState(() => _isLoading = true);

      // 1️⃣ Create account
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      final user = cred.user!;

      // 2️⃣ Find pending request
      final pending = await FirebaseFirestore.instance
          .collection('pending_workers')
          .where('email', isEqualTo: _emailCtrl.text.trim())
          .get();

      if (pending.docs.isEmpty) {
        throw Exception('لا يوجد طلب إنشاء لهذا العامل');
      }

      final data = pending.docs.first.data();

      // 3️⃣ Save official worker doc
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': data['name'],
        'email': data['email'],
        'role': 'worker',
        'workerType': data['workerType'],
        'createdAt': Timestamp.now(),
      });

      // 4️⃣ Delete pending request
      await FirebaseFirestore.instance
          .collection('pending_workers')
          .doc(pending.docs.first.id)
          .delete();

      _snack('تم إنشاء الحساب بنجاح ✅', _C.green);
      if (mounted) Navigator.pop(context);
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
              color: _C.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _C.green.withOpacity(0.3)),
            ),
            child:
                const Icon(Icons.how_to_reg_rounded, color: _C.green, size: 16),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('تسجيل عامل',
                style: TextStyle(
                    color: _C.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            Text('Worker Registration',
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
            // ── Hero banner ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  _C.green.withOpacity(0.16),
                  _C.green.withOpacity(0.04),
                ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.green.withOpacity(0.22)),
              ),
              child: Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_C.green, Color(0xFF00B87A)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: _C.green.withOpacity(0.35),
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
                        Text('انضم كعامل',
                            style: TextStyle(
                                color: _C.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 3),
                        Text('أدخل بياناتك للوصول إلى مهامك',
                            style: TextStyle(color: _C.textSub, fontSize: 11)),
                      ]),
                ),
              ]),
            ),

            const SizedBox(height: 24),

            // ── Info note ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _C.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.blue.withOpacity(0.2)),
              ),
              child: Row(children: const [
                Icon(Icons.info_outline_rounded, color: _C.blueSoft, size: 16),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'يجب أن يكون الإيميل مسجلاً مسبقاً من قِبل الإدارة',
                    style: TextStyle(color: _C.textSub, fontSize: 12),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 24),

            // ── Section label ──
            _sectionLabel('بيانات الدخول'),

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

            const SizedBox(height: 30),

            // ── Submit button ──
            GestureDetector(
              onTap: _isLoading ? null : _register,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoading
                        ? [_C.card, _C.card2]
                        : [_C.green, const Color(0xFF00B87A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _isLoading
                      ? []
                      : [
                          BoxShadow(
                              color: _C.green.withOpacity(0.38),
                              blurRadius: 16,
                              offset: const Offset(0, 6))
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
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.how_to_reg_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text('تسجيل الحساب',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Back to login ──
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'لديك حساب بالفعل؟ تسجيل الدخول',
                  style: TextStyle(
                      color: _C.textSub,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                      decorationColor: _C.textSub),
                ),
              ),
            ),

            const SizedBox(height: 30),
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
