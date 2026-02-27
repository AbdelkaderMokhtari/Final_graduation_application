import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'reports/reports_screen.dart';
import 'worker_tasks_screen.dart';
import 'settings_screen.dart';
import 'create_administration_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  /// ✅ الصفحات المتبقية فقط
  final List<Widget> pages = const [
    DashboardScreen(),
    ReportsScreen(),
    WorkerTasksScreen(),
    SettingsScreen(),
  ];

  void changePage(int index) {
    setState(() {
      selectedIndex = index;
    });
    Navigator.pop(context);
  }

  /// ⭐ Drawer Item Builder
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    bool selected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1C3B70) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? Colors.white : Colors.black87,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => changePage(index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة تحكم الأدمين"),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1C3B70),
                Color(0xFF4A90E2),
              ],
            ),
          ),
        ),
      ),

      /// ✅ الصفحات
      body: pages[selectedIndex],

      drawer: Drawer(
        backgroundColor: const Color(0xFFF4F7FC),
        child: Column(
          children: [
            /// Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1C3B70),
                    Color(0xFF4A90E2),
                  ],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.admin_panel_settings,
                      size: 50, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    "Admin Panel",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// Menu List
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_business),
                    title: const Text("Create Administration"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateAdministrationScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(),

                  /// ✅ Drawer Items (indexes مهمة جداً)

                  _buildDrawerItem(
                      icon: Icons.dashboard, title: "Dashboard", index: 0),

                  _buildDrawerItem(
                      icon: Icons.report, title: "Reports", index: 1),

                  _buildDrawerItem(
                      icon: Icons.engineering,
                      title: "Workers Tasks",
                      index: 2),

                  _buildDrawerItem(
                      icon: Icons.settings, title: "Settings", index: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
