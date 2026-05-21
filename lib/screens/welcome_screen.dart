// welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_manager.dart';
import 'homescreen.dart';
import 'settings_manager.dart';

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
  static const card = Color(0xFF162040);
  static const card2 = Color(0xFF1A2848);
  static const divider = Color(0xFF1E2E50);
  static const textPrimary = Color(0xFFE8F0FF);
  static const textSub = Color(0xFF8899BB);
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  int totalReports = 0;
  int solvedReports = 0;
  int activeWorkers = 0;
  bool _statsLoaded = false;

  late AnimationController _bgCtrl;
  late AnimationController _contentCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  String tr(String k) => SettingsManager.tr(k);

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);
    _fadeAnim = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));

    _bgCtrl.forward();
    Future.delayed(
        const Duration(milliseconds: 300), () => _contentCtrl.forward());

    _loadSettings();
    _fetchStats();
  }

  Future<void> _loadSettings() async {
    await SettingsManager.load();
    if (mounted) setState(() {});
  }

  Future<void> _fetchStats() async {
    try {
      final rSnap =
          await FirebaseFirestore.instance.collection('reports').get();
      final solved = rSnap.docs.where((d) {
        final s = (d.data())['status'] ?? '';
        return s == 'completed' || s == 'done';
      }).length;
      final wSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'worker')
          .get();
      setState(() {
        totalReports = rSnap.docs.length;
        solvedReports = solved;
        activeWorkers = wSnap.docs.length;
        _statsLoaded = true;
      });
    } catch (_) {
      setState(() => _statsLoaded = true);
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // ── Stat card ─────────────────────────────────
  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            _statsLoaded ? value : '…',
            style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 5),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _C.textSub, fontSize: 11)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.navy,
      body: FadeTransition(
        opacity: _bgAnim,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.6),
              radius: 1.4,
              colors: [
                _C.blue.withOpacity(0.18),
                _C.navy,
              ],
            ),
          ),
          child: SafeArea(
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),

                      // ── Logo ──
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_C.blue, _C.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: _C.blue.withOpacity(0.45),
                                blurRadius: 30,
                                offset: const Offset(0, 10)),
                          ],
                        ),
                        child: const Icon(Icons.eco_rounded,
                            size: 48, color: Colors.white),
                      ),

                      const SizedBox(height: 24),

                      // ── App name ──
                      Text(
                        tr('welcomeTitle'),
                        style: const TextStyle(
                          color: _C.textPrimary,
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Slogan ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _C.accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: _C.accent.withOpacity(0.2)),
                        ),
                        child: Text(
                          tr('welcomeSlogan'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: _C.accent,
                              fontSize: 13,
                              fontStyle: FontStyle.italic),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // ── Impact label ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 30, height: 1, color: _C.divider),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(tr('welcomeImpact'),
                                style: const TextStyle(
                                    color: _C.textSub,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ),
                          Container(width: 30, height: 1, color: _C.divider),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Stats ──
                      Row(
                        children: [
                          _statCard('$totalReports', tr('totalReports'),
                              Icons.bar_chart_rounded, _C.blue),
                          const SizedBox(width: 10),
                          _statCard('$solvedReports', tr('solvedReports'),
                              Icons.check_circle_rounded, _C.green),
                          const SizedBox(width: 10),
                          _statCard('$activeWorkers', tr('activeWorkers'),
                              Icons.engineering_rounded, _C.orange),
                        ],
                      ),

                      const SizedBox(height: 56),

                      // ── CTA button ──
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_C.blue, _C.blueSoft],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: _C.blue.withOpacity(0.45),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tr('startNow'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.rocket_launch_rounded,
                                  color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
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
}
