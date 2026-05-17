import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Dashboards
import 'admin/admin_dashboard.dart';
import 'administration/administration_dashboard.dart';
import 'worker/worker_dashboard.dart';
import 'citizen_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─── تسجيل الدخول ───────────────────────────
  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => isLoading = true);

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user == null) throw Exception("لم يتم العثور على المستخدم");

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) throw Exception("بيانات المستخدم غير موجودة");

      final data = doc.data() as Map<String, dynamic>;
      final role = data['role'] ?? "citizen";

      if (!mounted) return;

      switch (role) {
        case "admin":
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const AdminDashboard()));
          break;
        case "administration":
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdministrationDashboard()));
          break;
        case "worker":
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const WorkerScreen()));
          break;
        default:
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const CitizenScreen()));
      }
    } on FirebaseAuthException catch (e) {
      String message = "خطأ في تسجيل الدخول";
      if (e.code == 'user-not-found')
        message = "المستخدم غير موجود";
      else if (e.code == 'wrong-password')
        message = "كلمة المرور غير صحيحة";
      else if (e.code == 'invalid-email')
        message = "صيغة البريد غير صحيحة";
      else if (e.code == 'too-many-requests')
        message = "محاولات كثيرة، حاول لاحقاً";
      _showError(message);
    } catch (e) {
      _showError("خطأ: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ─── نسيت كلمة المرور ───────────────────────
  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showError("أدخل بريدك الإلكتروني أولاً");
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ تم إرسال رابط إعادة التعيين إلى بريدك"),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.code == 'user-not-found'
          ? "البريد غير مسجل"
          : "تعذّر الإرسال، تحقق من البريد");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Build ───────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1565C0), Color(0xFF4A90E2), Color(0xFF0D47A1)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // ─── Logo ─────────────────
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          size: 50,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        "Eco City",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "مرحباً بك — سجّل دخولك للمتابعة",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ─── Card ─────────────────
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "تسجيل الدخول",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Email
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                textDirection: TextDirection.ltr,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return "أدخل البريد الإلكتروني";
                                  }
                                  if (!v.contains('@')) {
                                    return "بريد إلكتروني غير صحيح";
                                  }
                                  return null;
                                },
                                decoration: _inputDecoration(
                                  label: "البريد الإلكتروني",
                                  icon: Icons.email_outlined,
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Password
                              TextFormField(
                                controller: passwordController,
                                obscureText: _obscurePassword,
                                textDirection: TextDirection.ltr,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return "أدخل كلمة المرور";
                                  }
                                  if (v.length < 6) {
                                    return "كلمة المرور قصيرة جداً";
                                  }
                                  return null;
                                },
                                decoration: _inputDecoration(
                                  label: "كلمة المرور",
                                  icon: Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // نسيت كلمة المرور
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: _forgotPassword,
                                  child: const Text(
                                    "نسيت كلمة المرور؟",
                                    style: TextStyle(
                                      color: Color(0xFF1565C0),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // زر الدخول
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1565C0),
                                    disabledBackgroundColor:
                                        const Color(0xFF1565C0)
                                            .withOpacity(0.6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.login_rounded,
                                                color: Colors.white),
                                            SizedBox(width: 10),
                                            Text(
                                              "تسجيل الدخول",
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // معلومات الأدوار
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _roleChip(Icons.admin_panel_settings, "أدمين"),
                            _divider(),
                            _roleChip(Icons.business, "إدارة"),
                            _divider(),
                            _roleChip(Icons.engineering, "عامل"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        "© 2025 Eco City — جميع الحقوق محفوظة",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      {required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF5F8FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFBBDEFB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFBBDEFB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFC62828)),
      ),
    );
  }

  Widget _roleChip(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 35,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }
}
