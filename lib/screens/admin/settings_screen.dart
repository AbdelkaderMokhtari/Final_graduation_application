import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login_screen.dart';

// ─────────────────────────────────────────────
// 🎨 Design Tokens
// ─────────────────────────────────────────────
class _C {
  static const navy        = Color(0xFF0A1628);
  static const navyMid     = Color(0xFF0F2044);
  static const blue        = Color(0xFF1E6FFF);
  static const accent      = Color(0xFF00E5FF);
  static const green       = Color(0xFF00D68F);
  static const orange      = Color(0xFFFF8C42);
  static const red         = Color(0xFFFF4D6A);
  static const card        = Color(0xFF162040);
  static const card2       = Color(0xFF1A2848);
  static const divider     = Color(0xFF1E2E50);
  static const textPrimary = Color(0xFFE8F0FF);
  static const textSub     = Color(0xFF8899BB);
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─── Logout ──────────────────────────────────
  Future<void> _logout() async {
    final confirm = await _showLogoutDialog();
    if (!confirm) return;

    setState(() => _isLoggingOut = true);
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<bool> _showLogoutDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.7),
          builder: (_) => Dialog(
            backgroundColor: _C.card,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: _C.red.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _C.red.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.logout_rounded,
                        color: _C.red, size: 30),
                  ),
                  const SizedBox(height: 18),
                  const Text('تسجيل الخروج',
                      style: TextStyle(
                          color: _C.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'هل أنت متأكد من تسجيل الخروج من الحساب؟',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _C.textSub, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.textSub,
                          side: const BorderSide(color: _C.divider),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.red,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('خروج',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  // ─── Build ───────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'غير محدد';
    final initial =
        email.isNotEmpty ? email[0].toUpperCase() : 'A';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: _C.navy,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profile Card ──────────────────
                Container(
                  padding: const EdgeInsets.all(22),
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
                    border:
                        Border.all(color: _C.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_C.blue, _C.accent]),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _C.blue.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(initial,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('المسؤول',
                                style: TextStyle(
                                    color: _C.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(email,
                                style: const TextStyle(
                                    color: _C.textSub, fontSize: 12),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _C.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color:
                                        _C.green.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.circle,
                                      color: _C.green, size: 7),
                                  SizedBox(width: 5),
                                  Text('متصل الآن',
                                      style: TextStyle(
                                          color: _C.green, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Section: الحساب ───────────────
                _sectionLabel('الحساب'),
                const SizedBox(height: 12),

                _settingTile(
                  icon: Icons.email_rounded,
                  color: _C.blue,
                  title: 'البريد الإلكتروني',
                  subtitle: email,
                  trailing: const Icon(Icons.copy_rounded,
                      color: _C.textSub, size: 16),
                  onTap: () {},
                ),
                _settingTile(
                  icon: Icons.admin_panel_settings_rounded,
                  color: _C.accent,
                  title: 'الدور الوظيفي',
                  subtitle: 'مسؤول النظام (Admin)',
                  onTap: () {},
                ),
                _settingTile(
                  icon: Icons.lock_rounded,
                  color: _C.orange,
                  title: 'تغيير كلمة المرور',
                  subtitle: 'إعادة تعيين عبر البريد الإلكتروني',
                  onTap: _sendResetEmail,
                ),

                const SizedBox(height: 24),

                // ── Section: التطبيق ──────────────
                _sectionLabel('التطبيق'),
                const SizedBox(height: 12),

                _settingTile(
                  icon: Icons.info_rounded,
                  color: _C.textSub,
                  title: 'الإصدار',
                  subtitle: 'Eco City v1.0.0',
                  onTap: () {},
                ),
                _settingTile(
                  icon: Icons.eco_rounded,
                  color: _C.green,
                  title: 'عن التطبيق',
                  subtitle: 'منصة إدارة البيئة الحضرية',
                  onTap: () {},
                ),

                const SizedBox(height: 32),

                // ── Logout Button ─────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoggingOut ? null : _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: _C.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _C.red.withValues(alpha: 0.4)),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: _isLoggingOut
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: _C.red, strokeWidth: 2.5),
                              )
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout_rounded,
                                      color: _C.red, size: 20),
                                  SizedBox(width: 10),
                                  Text('تسجيل الخروج',
                                      style: TextStyle(
                                          color: _C.red,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Footer
                Center(
                  child: Text('© 2025 Eco City — جميع الحقوق محفوظة',
                      style: TextStyle(
                          color: _C.textSub.withValues(alpha: 0.5),
                          fontSize: 11)),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Reset Password ───────────────────────────
  Future<void> _sendResetEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: user!.email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('تم إرسال رابط إعادة التعيين'),
          ]),
          backgroundColor: _C.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('حدث خطأ، حاول مجدداً'),
          backgroundColor: _C.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ─── Helpers ─────────────────────────────────
  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(label,
          style: const TextStyle(
              color: _C.textSub,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5)),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: _C.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          color: _C.textSub, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.arrow_back_ios_rounded,
                    color: _C.textSub, size: 14),
          ],
        ),
      ),
    );
  }
}