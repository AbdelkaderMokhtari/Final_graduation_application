import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/notification_service.dart';

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

class WorkerScreen extends StatefulWidget {
  const WorkerScreen({super.key});

  @override
  State<WorkerScreen> createState() => _WorkerScreenState();
}

class _WorkerScreenState extends State<WorkerScreen>
    with SingleTickerProviderStateMixin {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // ── لتتبع المهام السابقة باش نكتشف الجديدة ──
  final Set<String> _knownTaskIds = {};
  bool _firstLoad = true;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _markInProgress(String id) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(id)
        .update({'status': 'in_progress'});
  }

  Future<void> _uploadAfterImage(String id) async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 50);
    if (picked == null) return;

    final bytes = await File(picked.path).readAsBytes();
    final base64 = base64Encode(bytes);

    await FirebaseFirestore.instance.collection('reports').doc(id).update({
      'afterImageBase64': base64,
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('تم إكمال المهمة بنجاح ✅',
            style: TextStyle(color: Colors.white)),
        backgroundColor: _C.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── 🔔 فحص المهام الجديدة وإرسال notification ──
  void _checkNewTasks(List<DocumentSnapshot> docs) {
    // أول تحميل — نسجل المهام الموجودة بدون notification
    if (_firstLoad) {
      for (final doc in docs) {
        _knownTaskIds.add(doc.id);
      }
      _firstLoad = false;
      return;
    }

    // تحقق من المهام الجديدة
    for (final doc in docs) {
      if (!_knownTaskIds.contains(doc.id)) {
        _knownTaskIds.add(doc.id);
        final data = doc.data() as Map<String, dynamic>;
        // أرسل notification
        NotificationService().notifyWorker(
          description: data['description'] ?? 'مهمة جديدة',
          category: data['category'] ?? '',
        );
      }
    }
  }

  // ── Status meta ───────────────────────────────
  _StatusMeta _meta(String status) {
    switch (status) {
      case 'in_progress':
        return _StatusMeta(_C.blue, Icons.autorenew_rounded, 'قيد المعالجة');
      case 'completed':
        return _StatusMeta(_C.green, Icons.check_circle_rounded, 'منجز');
      default:
        return _StatusMeta(_C.orange, Icons.engineering_rounded, 'مسندة');
    }
  }

  // ── Task Card ─────────────────────────────────
  Widget _taskCard(int idx, DocumentSnapshot doc, Map<String, dynamic> data) {
    final status = data['status'] ?? 'assigned';
    final meta = _meta(status);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + idx * 70),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child:
            Transform.translate(offset: Offset(0, 22 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _C.divider),
          boxShadow: [
            BoxShadow(
              color: meta.color.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Accent bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [meta.color, meta.color.withValues(alpha: 0.15)]),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Status badge row
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: meta.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: meta.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(meta.icon, color: meta.color, size: 13),
                    const SizedBox(width: 5),
                    Text(meta.label,
                        style: TextStyle(
                            color: meta.color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _C.card2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _C.divider),
                  ),
                  child: Text('# ${idx + 1}',
                      style: const TextStyle(color: _C.textSub, fontSize: 11)),
                ),
              ]),

              const SizedBox(height: 14),

              // ── Before image
              if (data['beforeImageBase64'] != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(children: [
                    Image.memory(
                      base64Decode(data['beforeImageBase64']),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _C.navy.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_camera_rounded,
                                  color: _C.textSub, size: 12),
                              SizedBox(width: 4),
                              Text('قبل',
                                  style: TextStyle(
                                      color: _C.textSub, fontSize: 10)),
                            ]),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
              ],

              // ── Description
              Text(
                data['description'] ?? '—',
                style: const TextStyle(
                    color: _C.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.4),
              ),
              const SizedBox(height: 8),

              // ── Tags
              Wrap(spacing: 8, runSpacing: 6, children: [
                if (data['category'] != null)
                  _tag(data['category'], _C.purple, Icons.category_rounded),
                if (data['wasteType'] != null)
                  _tag(data['wasteType'], _C.green, Icons.recycling_rounded),
              ]),

              // ── Location button
              if (data['latitude'] != null) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _openMap(
                    (data['latitude'] as num).toDouble(),
                    (data['longitude'] as num).toDouble(),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: _C.card2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.divider),
                    ),
                    child: Row(children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _C.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            color: _C.red, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text('فتح الموقع على الخريطة',
                          style: TextStyle(color: _C.textSub, fontSize: 13)),
                      const Spacer(),
                      const Icon(Icons.open_in_new_rounded,
                          color: _C.textSub, size: 14),
                    ]),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // ── Action buttons
              if (status == 'assigned')
                _actionBtn(
                  icon: Icons.play_arrow_rounded,
                  label: 'بدء العمل',
                  color: _C.blue,
                  onTap: () => _markInProgress(doc.id),
                ),

              if (status == 'in_progress')
                _actionBtn(
                  icon: Icons.photo_camera_rounded,
                  label: 'تصوير بعد التنظيف وإنهاء المهمة',
                  color: _C.green,
                  onTap: () => _uploadAfterImage(doc.id),
                ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.07),
          ]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _tag(String label, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      );

  // ── Build ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: _C.navy,
        body: Center(
            child: Text('خطأ في تسجيل الدخول',
                style: TextStyle(color: _C.textSub))),
      );
    }

    return Scaffold(
      backgroundColor: _C.navy,
      appBar: AppBar(
        backgroundColor: _C.navyMid,
        elevation: 0,
        iconTheme: const IconThemeData(color: _C.textPrimary),
        title: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_C.blue, _C.accent]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.engineering_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('مهام العامل',
                style: TextStyle(
                    color: _C.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            Text('My Tasks', style: TextStyle(color: _C.textSub, fontSize: 10)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: _C.red),
            onPressed: _logout,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.divider),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reports')
              .where('assignedTo', isEqualTo: currentUser!.uid)
              .where('status',
                  whereIn: ['assigned', 'in_progress']).snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: _C.blue));
            }
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _C.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: _C.divider),
                    ),
                    child: const Icon(Icons.task_alt_rounded,
                        color: _C.textSub, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('لا توجد مهام حالياً',
                      style: TextStyle(
                          color: _C.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('ستظهر المهام المسندة إليك هنا',
                      style: TextStyle(color: _C.textSub, fontSize: 13)),
                ]),
              );
            }

            final docs = snap.data!.docs;

            // 🔔 فحص المهام الجديدة
            _checkNewTasks(docs);

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final doc = docs[i];
                final data = doc.data() as Map<String, dynamic>;
                return _taskCard(i, doc, data);
              },
            );
          },
        ),
      ),
    );
  }
}

class _StatusMeta {
  final Color color;
  final IconData icon;
  final String label;
  const _StatusMeta(this.color, this.icon, this.label);
}
