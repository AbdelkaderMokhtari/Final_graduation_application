import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'report_details_screen.dart';

// ─────────────────────────────────────────────
// 🎨 Design Tokens
// ─────────────────────────────────────────────
class _C {
  static const navy = Color(0xFF0A1628);
  static const blue = Color(0xFF1E6FFF);
  static const blueSoft = Color(0xFF4A90E2);
  static const orange = Color(0xFFFF8C42);
  static const green = Color(0xFF00D68F);
  static const red = Color(0xFFFF4D6A);
  static const card = Color(0xFF162040);
  static const card2 = Color(0xFF1A2848);
  static const divider = Color(0xFF1E2E50);
  static const textPrimary = Color(0xFFE8F0FF);
  static const textSub = Color(0xFF8899BB);
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _filter = 'all';

  // ── Helpers ──────────────────────────────────
  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(docId)
        .update({'status': status});
  }

  Future<void> _deleteReport(BuildContext ctx, String docId) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text('حذف البلاغ', style: TextStyle(color: _C.textPrimary)),
        content: const Text('هل أنت متأكد من حذف هذا البلاغ؟',
            style: TextStyle(color: _C.textSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: _C.textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: _C.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(docId)
          .delete();
    }
  }

  _StatusMeta _meta(String status) {
    switch (status) {
      case 'in_progress':
        return _StatusMeta(
            _C.blue, Icons.autorenew_rounded, 'جاري', 'In Progress');
      case 'done':
      case 'completed':
        return _StatusMeta(
            _C.green, Icons.check_circle_rounded, 'منجز', 'Completed');
      default:
        return _StatusMeta(
            _C.orange, Icons.hourglass_top_rounded, 'معلق', 'Pending');
    }
  }

  // ── ✅ Stream بدون orderBy+where معاً ────────
  Stream<QuerySnapshot> _stream() {
    final col = FirebaseFirestore.instance.collection('reports');

    if (_filter == 'all') {
      // كل البلاغات مرتبة بالوقت
      return col.orderBy('timestamp', descending: true).snapshots();
    }

    // فلتر بدون orderBy — نرتب في الكود
    if (_filter == 'completed') {
      return col.where('status', whereIn: ['completed', 'done']).snapshots();
    }

    return col.where('status', isEqualTo: _filter).snapshots();
  }

  // ── ✅ ترتيب يدوي بالوقت ─────────────────────
  List<DocumentSnapshot> _sorted(List<DocumentSnapshot> docs) {
    final sorted = List<DocumentSnapshot>.from(docs);
    sorted.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aTime = aData['timestamp'] as Timestamp?;
      final bTime = bData['timestamp'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime); // descending
    });
    return sorted;
  }

  // ── Filter Chips ─────────────────────────────
  Widget _filterBar() {
    final filters = [
      ('all', 'الكل', _C.blue),
      ('pending', 'معلق', _C.orange),
      ('in_progress', 'جاري', _C.blueSoft),
      ('completed', 'منجز', _C.green),
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: filters.map((f) {
          final active = _filter == f.$1;
          return GestureDetector(
            onTap: () => setState(() => _filter = f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? f.$3.withValues(alpha: 0.2) : _C.card,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: active ? f.$3.withValues(alpha: 0.6) : _C.divider,
                ),
              ),
              child: Text(
                f.$2,
                style: TextStyle(
                  color: active ? f.$3 : _C.textSub,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Report Card ──────────────────────────────
  Widget _reportCard(int index, DocumentSnapshot doc, Map<String, dynamic> data,
      String status, BuildContext ctx) {
    final meta = _meta(status);

    return TweenAnimationBuilder<double>(
      key: ValueKey(doc.id),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + index * 60),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child:
            Transform.translate(offset: Offset(0, 24 * (1 - v)), child: child),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => ReportDetailsScreen(docId: doc.id)),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.divider),
            boxShadow: [
              BoxShadow(
                color: meta.color.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(children: [
            // Top accent bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [meta.color, meta.color.withValues(alpha: 0.2)]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: meta.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                      border:
                          Border.all(color: meta.color.withValues(alpha: 0.25)),
                    ),
                    child: Icon(meta.icon, color: meta.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['description'] ?? '—',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _C.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(children: [
                          if (data['category'] != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _C.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(data['category'],
                                  style: const TextStyle(
                                      color: _C.blueSoft, fontSize: 11)),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: meta.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: meta.color.withValues(alpha: 0.25)),
                            ),
                            child: Text(meta.labelAr,
                                style: TextStyle(
                                    color: meta.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  // Menu
                  PopupMenuButton<String>(
                    color: _C.card2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    icon: const Icon(Icons.more_vert_rounded,
                        color: _C.textSub, size: 20),
                    onSelected: (val) {
                      if (val == 'delete') {
                        _deleteReport(ctx, doc.id);
                      } else {
                        _updateStatus(doc.id, val);
                      }
                    },
                    itemBuilder: (_) => [
                      _menuItem('pending', '⏳  معلق', _C.orange),
                      _menuItem('in_progress', '🔄  جاري', _C.blue),
                      _menuItem('completed', '✅  منجز', _C.green),
                      const PopupMenuDivider(),
                      _menuItem('delete', '🗑  حذف', _C.red),
                    ],
                  ),
                ],
              ),
            ),
            // Footer
            if (data['timestamp'] != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _C.card2,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                  border: Border(top: BorderSide(color: _C.divider)),
                ),
                child: Row(children: [
                  const Icon(Icons.access_time_rounded,
                      color: _C.textSub, size: 13),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate((data['timestamp'] as Timestamp).toDate()),
                    style: const TextStyle(color: _C.textSub, fontSize: 11),
                  ),
                  const Spacer(),
                  if (data['latitude'] != null)
                    const Row(children: [
                      Icon(Icons.location_on_rounded,
                          color: _C.textSub, size: 13),
                      SizedBox(width: 4),
                      Text('يحتوي على موقع',
                          style: TextStyle(color: _C.textSub, fontSize: 11)),
                    ]),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String val, String label, Color color) {
    return PopupMenuItem(
      value: val,
      child: Text(label, style: TextStyle(color: color, fontSize: 13)),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/'
        '${d.day.toString().padLeft(2, '0')}  '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  // ── Build ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.navy,
      child: Column(children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _C.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.blue.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: _C.blue, size: 18),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('البلاغات',
                    style: TextStyle(
                        color: _C.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                Text('Reports',
                    style: TextStyle(color: _C.textSub, fontSize: 11)),
              ],
            ),
          ]),
        ),

        _filterBar(),
        const SizedBox(height: 14),

        // List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _stream(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: _C.blue));
              }
              if (snap.hasError) {
                // ✅ رسالة خطأ مفصلة للـ debug
                debugPrint('ReportsScreen error: ${snap.error}');
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: _C.textSub, size: 48),
                      const SizedBox(height: 12),
                      const Text('تعذّر تحميل البلاغات',
                          style: TextStyle(
                              color: _C.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('تحقق من اتصال الإنترنت',
                          style: TextStyle(color: _C.textSub, fontSize: 13)),
                    ],
                  ),
                );
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox_rounded,
                          color: _C.textSub, size: 48),
                      const SizedBox(height: 12),
                      const Text('لا توجد بلاغات',
                          style: TextStyle(color: _C.textSub, fontSize: 15)),
                    ],
                  ),
                );
              }

              // ✅ ترتيب يدوي بالوقت
              final docs = _sorted(snap.data!.docs);

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final doc = docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'pending';
                  return _reportCard(i, doc, data, status, ctx);
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _StatusMeta {
  final Color color;
  final IconData icon;
  final String labelAr;
  final String labelEn;
  const _StatusMeta(this.color, this.icon, this.labelAr, this.labelEn);
}
