// my_reports_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _C {
  static const navy = Color(0xFF0A1628);
  static const navyMid = Color(0xFF0F2044);
  static const blue = Color(0xFF1E6FFF);
  static const accent = Color(0xFF00E5FF);
  static const orange = Color(0xFFFF8C42);
  static const green = Color(0xFF00D68F);
  static const red = Color(0xFFFF4D6A);
  static const card = Color(0xFF162040);
  static const card2 = Color(0xFF1A2848);
  static const divider = Color(0xFF1E2E50);
  static const textPrimary = Color(0xFFE8F0FF);
  static const textSub = Color(0xFF8899BB);
}

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  _StatusMeta _meta(String status) {
    switch (status) {
      case 'in_progress':
        return _StatusMeta(_C.blue, Icons.autorenew_rounded, 'قيد المعالجة');
      case 'assigned':
        return _StatusMeta(_C.orange, Icons.engineering_rounded, 'مسندة');
      case 'completed':
      case 'done':
        return _StatusMeta(_C.green, Icons.check_circle_rounded, 'منجز');
      default:
        return _StatusMeta(_C.orange, Icons.hourglass_top_rounded, 'معلق');
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

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
              color: _C.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _C.blue.withOpacity(0.3)),
            ),
            child: const Icon(Icons.list_alt_rounded, color: _C.blue, size: 16),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('بلاغاتي',
                style: TextStyle(
                    color: _C.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            Text('My Reports',
                style: TextStyle(color: _C.textSub, fontSize: 10)),
          ]),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.divider),
        ),
      ),
      body: uid == null
          ? const Center(
              child: Text('غير مسجل', style: TextStyle(color: _C.textSub)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .where('userId', isEqualTo: uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _C.blue));
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _C.card,
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.divider),
                        ),
                        child: const Icon(Icons.inbox_rounded,
                            color: _C.textSub, size: 32),
                      ),
                      const SizedBox(height: 14),
                      const Text('لا توجد بلاغات بعد',
                          style: TextStyle(
                              color: _C.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      const Text('ستظهر بلاغاتك هنا بعد إرسالها',
                          style: TextStyle(color: _C.textSub, fontSize: 12)),
                    ]),
                  );
                }

                final docs = snap.data!.docs;
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'pending';
                    final meta = _meta(status);

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 240 + i * 60),
                      curve: Curves.easeOut,
                      builder: (_, v, child) => Opacity(
                        opacity: v,
                        child: Transform.translate(
                            offset: Offset(0, 18 * (1 - v)), child: child),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _C.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _C.divider),
                          boxShadow: [
                            BoxShadow(
                                color: meta.color.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Column(children: [
                          // top accent bar
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                meta.color,
                                meta.color.withOpacity(0.15)
                              ]),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // image thumbnail
                                if (data['beforeImageBase64'] != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      base64Decode(data['beforeImageBase64']),
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: _C.card2,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                        Icons.image_not_supported_rounded,
                                        color: _C.textSub,
                                        size: 26),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['description'] ?? '—',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: _C.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            height: 1.4),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: meta.color.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(7),
                                            border: Border.all(
                                                color: meta.color
                                                    .withOpacity(0.25)),
                                          ),
                                          child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(meta.icon,
                                                    color: meta.color,
                                                    size: 11),
                                                const SizedBox(width: 4),
                                                Text(meta.label,
                                                    style: TextStyle(
                                                        color: meta.color,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ]),
                                        ),
                                        if (data['category'] != null) ...[
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(data['category'],
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: _C.textSub,
                                                    fontSize: 10)),
                                          ),
                                        ],
                                      ]),
                                      const SizedBox(height: 5),
                                      if (data['timestamp'] != null)
                                        Text(
                                          _formatDate(
                                              (data['timestamp'] as Timestamp)
                                                  .toDate()),
                                          style: const TextStyle(
                                              color: _C.textSub, fontSize: 10),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    );
                  },
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
