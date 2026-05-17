import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// 🎨 Design Tokens (shared)
// ─────────────────────────────────────────────
class _C {
  static const navy     = Color(0xFF0A1628);
  static const navyMid  = Color(0xFF0F2044);
  static const blue     = Color(0xFF1E6FFF);
  static const blueSoft = Color(0xFF4A90E2);
  static const accent   = Color(0xFF00E5FF);
  static const orange   = Color(0xFFFF8C42);
  static const green    = Color(0xFF00D68F);
  static const red      = Color(0xFFFF4D6A);
  static const purple   = Color(0xFF8B5CF6);
  static const surface  = Color(0xFF111D35);
  static const card     = Color(0xFF162040);
  static const card2    = Color(0xFF1A2848);
  static const divider  = Color(0xFF1E2E50);
  static const textPrimary = Color(0xFFE8F0FF);
  static const textSub     = Color(0xFF8899BB);
}

class ReportDetailsScreen extends StatefulWidget {
  final String docId;
  const ReportDetailsScreen({super.key, required this.docId});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────
  Future<void> _updateStatus(String status) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(widget.docId)
        .update({'status': status});
  }

  Future<void> _deleteReport() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _C.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف البلاغ',
            style: TextStyle(color: _C.textPrimary, fontWeight: FontWeight.bold)),
        content: const Text('هل تريد حذف هذا البلاغ نهائياً؟',
            style: TextStyle(color: _C.textSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: _C.textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف',
                style: TextStyle(color: _C.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.docId)
          .delete();
      if (mounted) Navigator.pop(context);
    }
  }

  // ── Status meta ───────────────────────────────
  _StatusMeta _meta(String status) {
    switch (status) {
      case 'in_progress':
        return _StatusMeta(_C.blue, Icons.autorenew_rounded, 'قيد المعالجة');
      case 'done':
      case 'completed':
        return _StatusMeta(_C.green, Icons.check_circle_rounded, 'منجز');
      default:
        return _StatusMeta(_C.orange, Icons.hourglass_top_rounded, 'معلق');
    }
  }

  // ── Info Row ──────────────────────────────────
  Widget _infoRow(IconData icon, String label, String value, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: _C.card2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: _C.textSub, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: _C.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Action Button ─────────────────────────────
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
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.25), color.withOpacity(0.08)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ── Section Header ────────────────────────────
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(text,
          style: const TextStyle(
              color: _C.textSub,
              fontSize: 12,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600)),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/'
        '${d.day.toString().padLeft(2, '0')}  '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
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
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _C.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _C.blue.withOpacity(0.3)),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: _C.blue, size: 16),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تفاصيل البلاغ',
                    style: TextStyle(
                        color: _C.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                Text('Report Details',
                    style: TextStyle(color: _C.textSub, fontSize: 10)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: _C.red),
            onPressed: _deleteReport,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.divider),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .doc(widget.docId)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _C.blue));
          }
          if (snap.hasError || !snap.hasData || !snap.data!.exists) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.error_outline_rounded,
                      color: _C.red, size: 48),
                  SizedBox(height: 10),
                  Text('خطأ في تحميل البيانات',
                      style: TextStyle(color: _C.textSub)),
                ],
              ),
            );
          }

          final data = snap.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'pending';
          final meta = _meta(status);

          return FadeTransition(
            opacity: _fade,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image ──
                  if (data['beforeImageBase64'] != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Image.memory(
                            base64Decode(data['beforeImageBase64']),
                            width: double.infinity,
                            height: 230,
                            fit: BoxFit.cover,
                          ),
                          // Gradient overlay
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    _C.navy.withOpacity(0.8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Status Banner ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          meta.color.withOpacity(0.18),
                          meta.color.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: meta.color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: meta.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(meta.icon, color: meta.color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('الحالة الحالية',
                                style: TextStyle(
                                    color: _C.textSub, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(meta.label,
                                style: TextStyle(
                                    color: meta.color,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _C.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: _C.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.circle,
                                  color: _C.green, size: 6),
                              SizedBox(width: 5),
                              Text('Live',
                                  style: TextStyle(
                                      color: _C.green, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ── Details ──
                  _sectionLabel('تفاصيل البلاغ'),

                  _infoRow(
                    Icons.description_rounded,
                    'الوصف',
                    data['description'] ?? '—',
                    _C.blue,
                  ),
                  if (data['category'] != null)
                    _infoRow(
                      Icons.category_rounded,
                      'الفئة',
                      data['category'],
                      _C.purple,
                    ),
                  if (data['timestamp'] != null)
                    _infoRow(
                      Icons.access_time_rounded,
                      'التاريخ',
                      _formatDate(
                          (data['timestamp'] as Timestamp).toDate()),
                      _C.accent,
                    ),
                  if (data['latitude'] != null)
                    _infoRow(
                      Icons.location_on_rounded,
                      'الموقع',
                      '${data['latitude'].toStringAsFixed(4)}, '
                          '${data['longitude'].toStringAsFixed(4)}',
                      _C.orange,
                    ),

                  const SizedBox(height: 24),

                  // ── Actions ──
                  _sectionLabel('تحديث الحالة'),

                  if (status != 'in_progress')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _actionBtn(
                        icon: Icons.autorenew_rounded,
                        label: 'تحويل إلى قيد المعالجة',
                        color: _C.blue,
                        onTap: () => _updateStatus('in_progress'),
                      ),
                    ),

                  if (status != 'done' && status != 'completed')
                    _actionBtn(
                      icon: Icons.check_circle_rounded,
                      label: 'تعليم كمنجز',
                      color: _C.green,
                      onTap: () => _updateStatus('completed'),
                    ),

                  if (status == 'completed' || status == 'done')
                    _actionBtn(
                      icon: Icons.undo_rounded,
                      label: 'إعادة إلى معلق',
                      color: _C.orange,
                      onTap: () => _updateStatus('pending'),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
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