import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

// ─────────────────────────────────────────────
// 🎨 Design Tokens (shared with AdminDashboard)
// ─────────────────────────────────────────────
class _C {
  static const navy = Color(0xFF0A1628);
  static const navyMid = Color(0xFF0F2044);
  static const blue = Color(0xFF1E6FFF);
  static const blueSoft = Color(0xFF4A90E2);
  static const accent = Color(0xFF00E5FF);
  static const orange = Color(0xFFFF8C42);
  static const green = Color(0xFF00D68F);
  static const purple = Color(0xFF8B5CF6);
  static const surface = Color(0xFF111D35);
  static const card = Color(0xFF162040);
  static const card2 = Color(0xFF1A2848);
  static const divider = Color(0xFF1E2E50);
  static const textPrimary = Color(0xFFE8F0FF);
  static const textSub = Color(0xFF8899BB);
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // ─── Streams ─────────────────────────────────
  Stream<int> getCount(String? status) {
    final col = FirebaseFirestore.instance.collection('reports');
    if (status == null) return col.snapshots().map((e) => e.docs.length);
    return col
        .where('status', isEqualTo: status)
        .snapshots()
        .map((e) => e.docs.length);
  }

  // ─── Pie Chart ───────────────────────────────
  Widget buildPieChart(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (context, snapshot) {
        int pending = 0, inProgress = 0, completed = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final s = doc['status'];
            if (s == 'pending') pending++;
            if (s == 'in_progress') inProgress++;
            if (s == 'completed') completed++;
          }
        }
        final total = pending + inProgress + completed;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.divider),
            boxShadow: [
              BoxShadow(
                color: _C.blue.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: total == 0
                    ? const Center(
                        child: Text('لا توجد بيانات',
                            style: TextStyle(color: _C.textSub)))
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 55,
                              sections: [
                                if (pending > 0)
                                  PieChartSectionData(
                                    value: pending.toDouble(),
                                    color: _C.orange,
                                    title: '$pending',
                                    radius: 55,
                                    titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                if (inProgress > 0)
                                  PieChartSectionData(
                                    value: inProgress.toDouble(),
                                    color: _C.blue,
                                    title: '$inProgress',
                                    radius: 55,
                                    titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                if (completed > 0)
                                  PieChartSectionData(
                                    value: completed.toDouble(),
                                    color: _C.green,
                                    title: '$completed',
                                    radius: 55,
                                    titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$total',
                                  style: const TextStyle(
                                      color: _C.textPrimary,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold)),
                              const Text('إجمالي',
                                  style: TextStyle(
                                      color: _C.textSub, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendItem(_C.orange, 'معلق', pending),
                  const SizedBox(width: 20),
                  _legendItem(_C.blue, 'جاري', inProgress),
                  const SizedBox(width: 20),
                  _legendItem(_C.green, 'منجز', completed),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legendItem(Color color, String label, int count) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label ($count)',
            style: const TextStyle(color: _C.textSub, fontSize: 12)),
      ],
    );
  }

  // ─── Stat Card ───────────────────────────────
  Widget statCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Stream<int> stream,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.divider),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.25), color.withOpacity(0.08)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            const TextStyle(color: _C.textSub, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('$count',
                        style: const TextStyle(
                            color: _C.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5)),
                    Text(subtitle,
                        style: TextStyle(
                            color: color.withOpacity(0.8), fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _C.green.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.trending_up_rounded, color: _C.green, size: 12),
                    SizedBox(width: 3),
                    Text('Live',
                        style: TextStyle(color: _C.green, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Recent Reports ──────────────────────────
  Widget recentReports() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: _C.blue),
            ),
          );
        }
        if (snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.divider),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded, color: _C.textSub, size: 40),
                  SizedBox(height: 10),
                  Text('لا توجد بلاغات بعد',
                      style: TextStyle(color: _C.textSub)),
                ],
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.asMap().entries.map((entry) {
            final i = entry.key;
            final doc = entry.value;
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';

            Color statusColor;
            IconData statusIcon;
            String statusLabel;
            switch (status) {
              case 'completed':
                statusColor = _C.green;
                statusIcon = Icons.check_circle_rounded;
                statusLabel = 'منجز';
                break;
              case 'in_progress':
                statusColor = _C.blue;
                statusIcon = Icons.autorenew_rounded;
                statusLabel = 'جاري';
                break;
              default:
                statusColor = _C.orange;
                statusIcon = Icons.hourglass_top_rounded;
                statusLabel = 'معلق';
            }

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + i * 80),
              curve: Curves.easeOut,
              builder: (_, val, child) => Opacity(
                opacity: val,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - val)),
                  child: child,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _C.card2,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _C.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['description'] ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: _C.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            data['category'] ?? '',
                            style: const TextStyle(
                                color: _C.textSub, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ─── Build ───────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.navy,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _C.blue.withOpacity(0.2),
                    _C.accent.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.blue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('نظرة عامة على النظام',
                            style: TextStyle(
                                color: _C.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('تابع البلاغات والإحصائيات في الوقت الفعلي',
                            style: TextStyle(color: _C.textSub, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(colors: [_C.blue, _C.accent]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _C.blue.withOpacity(0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.insights_rounded,
                        color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            statCard(
              title: 'جميع البلاغات',
              subtitle: 'All Reports',
              icon: Icons.bar_chart_rounded,
              color: _C.blue,
              stream: getCount(null),
            ),
            const SizedBox(height: 12),
            statCard(
              title: 'البلاغات المعلقة',
              subtitle: 'Pending Reports',
              icon: Icons.hourglass_top_rounded,
              color: _C.orange,
              stream: getCount('pending'),
            ),
            const SizedBox(height: 12),
            statCard(
              title: 'البلاغات المنجزة',
              subtitle: 'Completed Reports',
              icon: Icons.check_circle_rounded,
              color: _C.green,
              stream: getCount('completed'),
            ),

            const SizedBox(height: 28),

            _sectionHeader(
              icon: Icons.donut_large_rounded,
              title: 'توزيع حالات البلاغات',
              subtitle: 'Status Distribution',
            ),
            const SizedBox(height: 14),
            buildPieChart(context),

            const SizedBox(height: 28),

            _sectionHeader(
              icon: Icons.receipt_long_rounded,
              title: 'آخر البلاغات',
              subtitle: 'Recent Reports',
            ),
            const SizedBox(height: 14),
            recentReports(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _C.blue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.blue.withOpacity(0.25)),
          ),
          child: Icon(icon, color: _C.blue, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: _C.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: const TextStyle(color: _C.textSub, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
