import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'reports/reports_screen.dart';
import 'worker_tasks_screen.dart';
import 'settings_screen.dart';
import 'create_administration_screen.dart';

// ─────────────────────────────────────────────
// 🎨 Design Tokens
// ─────────────────────────────────────────────
class _C {
  static const navy = Color(0xFF0A1628);
  static const navyMid = Color(0xFF0F2044);
  static const blue = Color(0xFF1E6FFF);
  static const blueSoft = Color(0xFF4A90E2);
  static const accent = Color(0xFF00E5FF);
  static const surface = Color(0xFF111D35);
  static const surfaceCard = Color(0xFF162040);
  static const textPrimary = Color(0xFFE8F0FF);
  static const textSub = Color(0xFF8899BB);
  static const divider = Color(0xFF1E2E50);
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  int selectedIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<Widget> pages = const [
    DashboardScreen(),
    ReportsScreen(),
    WorkerTasksScreen(),
    SettingsScreen(),
  ];

  final List<_NavItem> navItems = const [
    _NavItem(Icons.dashboard_rounded, 'لوحة التحكم', 'Dashboard'),
    _NavItem(Icons.receipt_long_rounded, 'البلاغات', 'Reports'),
    _NavItem(Icons.engineering_rounded, 'مهام العمال', 'Workers'),
    _NavItem(Icons.settings_rounded, 'الإعدادات', 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _changePage(int index) {
    if (index == selectedIndex) {
      Navigator.pop(context);
      return;
    }
    setState(() => selectedIndex = index);
    _animController.reset();
    _animController.forward();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.navy,

      // ── AppBar ──────────────────────────────
      appBar: AppBar(
        backgroundColor: _C.navyMid,
        elevation: 0,
        iconTheme: const IconThemeData(color: _C.textPrimary),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_C.blue, _C.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Eco City',
                  style: TextStyle(
                    color: _C.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  navItems[selectedIndex].labelAr,
                  style: const TextStyle(
                    color: _C.textSub,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Notification bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded,
                    color: _C.textPrimary),
                onPressed: () {},
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _C.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          // Avatar
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_C.blue, _C.blueSoft],
                ),
                shape: BoxShape.circle,
                border:
                    Border.all(color: _C.accent.withOpacity(0.4), width: 1.5),
              ),
              child: const Icon(Icons.person_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.divider),
        ),
      ),

      // ── Drawer ──────────────────────────────
      drawer: Drawer(
        backgroundColor: _C.surface,
        width: 280,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_C.navyMid, _C.surfaceCard],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_C.blue, _C.accent],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _C.blue.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Admin',
                                style: TextStyle(
                                    color: _C.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _C.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: _C.accent.withOpacity(0.3)),
                              ),
                              child: const Text('Super Admin',
                                  style: TextStyle(
                                      color: _C.accent, fontSize: 10)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Create Administration
              _drawerAction(
                icon: Icons.add_business_rounded,
                label: 'إنشاء إدارة',
                sublabel: 'Create Administration',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateAdministrationScreen()),
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(height: 1, color: _C.divider),
              ),

              // Nav Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: navItems.length,
                  itemBuilder: (_, i) {
                    final item = navItems[i];
                    final isSelected = selectedIndex == i;
                    return GestureDetector(
                      onTap: () => _changePage(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    _C.blue.withOpacity(0.25),
                                    _C.blue.withOpacity(0.08),
                                  ],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          border: isSelected
                              ? Border.all(color: _C.blue.withOpacity(0.4))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _C.blue.withOpacity(0.2)
                                    : _C.divider,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(item.icon,
                                  color: isSelected ? _C.blue : _C.textSub,
                                  size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.labelAr,
                                      style: TextStyle(
                                          color: isSelected
                                              ? _C.textPrimary
                                              : _C.textSub,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 14)),
                                  Text(item.labelEn,
                                      style: const TextStyle(
                                          color: _C.textSub, fontSize: 11)),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: _C.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Footer
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _C.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco_rounded, color: _C.accent, size: 20),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Eco City v1.0',
                            style: TextStyle(
                                color: _C.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        Text('Admin Panel',
                            style: TextStyle(color: _C.textSub, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ── Body ────────────────────────────────
      body: FadeTransition(
        opacity: _fadeAnim,
        child: pages[selectedIndex],
      ),
    );
  }

  Widget _drawerAction({
    required IconData icon,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _C.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: [_C.blue, _C.blueSoft]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: _C.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(sublabel,
                      style: const TextStyle(color: _C.textSub, fontSize: 11)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: _C.textSub, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String labelAr;
  final String labelEn;
  const _NavItem(this.icon, this.labelAr, this.labelEn);
}
