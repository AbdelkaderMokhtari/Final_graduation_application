import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// ─────────────────────────────────────────────
// 🎨 Design Tokens
// ─────────────────────────────────────────────
class _C {
  static const navy = Color(0xFF0A1628);
  static const navyMid = Color(0xFF0F2044);
  static const blue = Color(0xFF1E6FFF);
  static const accent = Color(0xFF00E5FF);
  static const green = Color(0xFF00D68F);
  static const red = Color(0xFFFF4D6A);
  static const card = Color(0xFF162040);
  static const card2 = Color(0xFF1A2848);
  static const divider = Color(0xFF1E2E50);
  static const inputBg = Color(0xFF111D35);
  static const textPrimary = Color(0xFFE8F0FF);
  static const textSub = Color(0xFF8899BB);
}

class CreateAdministrationScreen extends StatefulWidget {
  const CreateAdministrationScreen({super.key});

  @override
  State<CreateAdministrationScreen> createState() =>
      _CreateAdministrationScreenState();
}

class _CreateAdministrationScreenState extends State<CreateAdministrationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _success = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─── Logic ───────────────────────────────────
  Future<void> createAdministration() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => isLoading = true);

      final adminUser = FirebaseAuth.instance.currentUser;
      if (adminUser == null) throw Exception("يجب أن يكون الأدمين مسجل دخول");

      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );
      FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      UserCredential credential =
          await secondaryAuth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': "administration",
        'workerType': null,
        'createdBy': adminUser.uid,
        'createdAt': Timestamp.now(),
      });

      await secondaryAuth.signOut();
      await secondaryApp.delete();

      if (!mounted) return;

      setState(() {
        _success = true;
        isLoading = false;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showError(_parseError(e.toString()));
    }
  }

  String _parseError(String e) {
    if (e.contains('email-already-in-use'))
      return 'البريد الإلكتروني مستخدم بالفعل';
    if (e.contains('weak-password'))
      return 'كلمة المرور ضعيفة جداً (6 أحرف على الأقل)';
    if (e.contains('invalid-email')) return 'صيغة البريد الإلكتروني غير صحيحة';
    return 'حدث خطأ، حاول مجدداً';
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: _C.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Build ───────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
                gradient: const LinearGradient(colors: [_C.blue, _C.accent]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_add_rounded,
                  color: Colors.white, size: 17),
            ),
            const SizedBox(width: 10),
            const Text('إنشاء مسؤول إدارة',
                style: TextStyle(
                    color: _C.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
          ]),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _C.divider),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: _success ? _buildSuccessState() : _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Success State ───────────────────────────
  Widget _buildSuccessState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: _C.green.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _C.green.withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(Icons.check_rounded, color: _C.green, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('تم إنشاء الحساب بنجاح!',
                style: TextStyle(
                    color: _C.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(emailController.text,
                style: const TextStyle(color: _C.textSub, fontSize: 13)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: _C.blue, strokeWidth: 2),
          ],
        ),
      ),
    );
  }

  // ─── Form ────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero Card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _C.blue.withValues(alpha: 0.25),
                  _C.accent.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _C.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_C.blue, _C.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _C.blue.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('مسؤول إدارة جديد',
                          style: TextStyle(
                              color: _C.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('سيتمكن من إدارة البلاغات والعمال',
                          style: TextStyle(color: _C.textSub, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Section Label ──
          _sectionLabel(Icons.person_rounded, 'المعلومات الشخصية'),
          const SizedBox(height: 14),

          // Name
          _buildField(
            controller: nameController,
            label: 'الاسم الكامل',
            hint: 'مثال: محمد الأمين',
            icon: Icons.badge_rounded,
            color: _C.blue,
            validator: (v) => (v == null || v.trim().length < 3)
                ? 'الاسم يجب أن يكون 3 أحرف على الأقل'
                : null,
          ),

          const SizedBox(height: 28),

          // ── Section Label ──
          _sectionLabel(Icons.lock_rounded, 'بيانات الدخول'),
          const SizedBox(height: 14),

          // Email
          _buildField(
            controller: emailController,
            label: 'البريد الإلكتروني',
            hint: 'example@email.com',
            icon: Icons.email_rounded,
            color: _C.accent,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            validator: (v) {
              if (v == null || v.isEmpty) return 'أدخل البريد الإلكتروني';
              if (!v.contains('@') || !v.contains('.')) {
                return 'صيغة البريد غير صحيحة';
              }
              return null;
            },
          ),

          const SizedBox(height: 14),

          // Password
          _buildField(
            controller: passwordController,
            label: 'كلمة المرور',
            hint: '••••••••',
            icon: Icons.lock_rounded,
            color: _C.green,
            obscure: _obscurePassword,
            textDirection: TextDirection.ltr,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: _C.textSub,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
              if (v.length < 6)
                return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Password strength hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.divider),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: _C.textSub, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'يُنصح باستخدام كلمة مرور تحتوي على أحرف وأرقام ورموز',
                  style: TextStyle(color: _C.textSub, fontSize: 11),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 32),

          // ── Permissions Preview ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.verified_user_rounded, color: _C.accent, size: 18),
                  SizedBox(width: 8),
                  Text('صلاحيات المسؤول',
                      style: TextStyle(
                          color: _C.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ]),
                const SizedBox(height: 14),
                _permissionRow(Icons.receipt_long_rounded,
                    'إدارة البلاغات ومتابعتها', true),
                _permissionRow(
                    Icons.engineering_rounded, 'تعيين مهام للعمال', true),
                _permissionRow(
                    Icons.bar_chart_rounded, 'الاطلاع على الإحصائيات', true),
                _permissionRow(Icons.admin_panel_settings_rounded,
                    'إنشاء مسؤولين جدد', false),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Submit Button ──
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: isLoading ? null : createAdministration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: isLoading
                      ? LinearGradient(
                          colors: [
                            _C.blue.withValues(alpha: 0.5),
                            _C.accent.withValues(alpha: 0.5),
                          ],
                        )
                      : const LinearGradient(
                          colors: [_C.blue, _C.accent],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: _C.blue.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text('إنشاء الحساب',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────
  Widget _sectionLabel(IconData icon, String label) {
    return Row(children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _C.blue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _C.blue.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: _C.blue, size: 16),
      ),
      const SizedBox(width: 10),
      Text(label,
          style: const TextStyle(
              color: _C.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    bool obscure = false,
    TextInputType? keyboardType,
    TextDirection? textDirection,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textDirection: textDirection,
      validator: validator,
      style: const TextStyle(color: _C.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            TextStyle(color: color.withValues(alpha: 0.8), fontSize: 13),
        hintStyle: const TextStyle(color: _C.textSub, fontSize: 13),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _C.inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _C.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _C.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _C.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _C.red, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _C.red, fontSize: 11),
      ),
    );
  }

  Widget _permissionRow(IconData icon, String label, bool allowed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: allowed
                ? _C.green.withValues(alpha: 0.12)
                : _C.red.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            allowed ? Icons.check_rounded : Icons.close_rounded,
            color: allowed ? _C.green : _C.red,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: _C.textSub, size: 16),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: _C.textSub, fontSize: 12)),
      ]),
    );
  }
}
