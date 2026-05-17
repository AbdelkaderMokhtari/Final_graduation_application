import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  static const purple      = Color(0xFF8B5CF6);
  static const card        = Color(0xFF162040);
  static const card2       = Color(0xFF1A2848);
  static const divider     = Color(0xFF1E2E50);
  static const textPrimary = Color(0xFFE8F0FF);
  static const textSub     = Color(0xFF8899BB);
}

class WorkerTasksScreen extends StatelessWidget {
  const WorkerTasksScreen({super.key});

  // ─── Status Helpers ──────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return _C.green;
      case 'in_progress': return _C.blue;
      case 'pending': return _C.orange;
      default: return _C.textSub;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed': return Icons.check_circle_rounded;
      case 'in_progress': return Icons.autorenew_rounded;
      case 'pending': return Icons.hourglass_top_rounded;
      default: return Icons.circle_outlined;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed': return 'منجز';
      case 'in_progress': return 'جاري';
      case 'pending': return 'معلق';
      default: return status;
    }
  }

  Color _workerColor(int index) {
    final colors = [_C.blue, _C.purple, _C.green, _C.orange, _C.accent];
    return colors[index % colors.length];
  }

  // ─── Build ───────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: _C.navy,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'worker')
              .snapshots(),
          builder: (context, snapshot) {
            // Loading
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _C.blue),
              );
            }

            final workers = snapshot.data!.docs;

            // Empty
            if (workers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: _C.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: _C.divider),
                      ),
                      child: const Icon(Icons.engineering_rounded,
                          color: _C.textSub, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text('لا يوجد عمال مسجلون',
                        style: TextStyle(
                            color: _C.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('أضف عمالاً من لوحة التحكم',
                        style: TextStyle(color: _C.textSub, fontSize: 13)),
                  ],
                ),
              );
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: workers.length,
              itemBuilder: (context, index) {
                final worker     = workers[index];
                final workerData = worker.data() as Map<String, dynamic>;
                final workerId   = worker.id;
                final workerName = workerData['name'] ?? 'عامل';
                final workerType = workerData['workerType'] ?? '';
                final color      = _workerColor(index);
                final initial    = workerName.isNotEmpty
                    ? workerName[0].toUpperCase()
                    : 'W';

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + index * 80),
                  curve: Curves.easeOut,
                  builder: (_, val, child) => Opacity(
                    opacity: val,
                    child: Transform.translate(
                      offset: Offset(0, 24 * (1 - val)),
                      child: child,
                    ),
                  ),
                  child: _WorkerCard(
                    workerName: workerName,
                    workerType: workerType,
                    workerId: workerId,
                    color: color,
                    initial: initial,
                    statusColor: _statusColor,
                    statusIcon: _statusIcon,
                    statusLabel: _statusLabel,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 🧩 Worker Card Widget
// ─────────────────────────────────────────────
class _WorkerCard extends StatefulWidget {
  final String workerName;
  final String workerType;
  final String workerId;
  final Color color;
  final String initial;
  final Color Function(String) statusColor;
  final IconData Function(String) statusIcon;
  final String Function(String) statusLabel;

  const _WorkerCard({
    required this.workerName,
    required this.workerType,
    required this.workerId,
    required this.color,
    required this.initial,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
  });

  @override
  State<_WorkerCard> createState() => _WorkerCardState();
}

class _WorkerCardState extends State<_WorkerCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnim =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _expanded
              ? widget.color.withValues(alpha: 0.4)
              : _C.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: _expanded
                ? widget.color.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.color,
                          widget.color.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(widget.initial,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.workerName,
                            style: const TextStyle(
                                color: _C.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(height: 4),
                        if (widget.workerType.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: widget.color.withValues(alpha: 0.25)),
                            ),
                            child: Text(widget.workerType,
                                style: TextStyle(
                                    color: widget.color, fontSize: 11)),
                          ),
                      ],
                    ),
                  ),

                  // Task counter badge + chevron
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reports')
                        .where('assignedTo', isEqualTo: widget.workerId)
                        .snapshots(),
                    builder: (_, snap) {
                      final count = snap.data?.docs.length ?? 0;
                      return Row(
                        children: [
                          if (count > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color:
                                        widget.color.withValues(alpha: 0.3)),
                              ),
                              child: Text('$count مهمة',
                                  style: TextStyle(
                                      color: widget.color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          const SizedBox(width: 10),
                          RotationTransition(
                            turns: Tween(begin: 0.0, end: 0.5)
                                .animate(_expandAnim),
                            child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: _C.textSub,
                                size: 22),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded Tasks ───────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(
              children: [
                Container(height: 1, color: _C.divider),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reports')
                      .where('assignedTo', isEqualTo: widget.workerId)
                      .snapshots(),
                  builder: (context, taskSnapshot) {
                    if (!taskSnapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: _C.blue, strokeWidth: 2),
                        ),
                      );
                    }

                    final tasks = taskSnapshot.data!.docs;

                    if (tasks.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_rounded,
                                color: _C.textSub.withValues(alpha: 0.5),
                                size: 32),
                            const SizedBox(height: 8),
                            const Text('لا توجد مهام مسندة',
                                style: TextStyle(
                                    color: _C.textSub, fontSize: 13)),
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: tasks.asMap().entries.map((entry) {
                          final i    = entry.key;
                          final task = entry.value.data()
                              as Map<String, dynamic>;
                          final status = task['status'] ?? 'pending';
                          final sColor = widget.statusColor(status);
                          final sIcon  = widget.statusIcon(status);
                          final sLabel = widget.statusLabel(status);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _C.card2,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _C.divider),
                            ),
                            child: Row(
                              children: [
                                // Number
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color:
                                        sColor.withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text('${i + 1}',
                                        style: TextStyle(
                                            color: sColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Icon
                                Icon(sIcon, color: sColor, size: 18),
                                const SizedBox(width: 10),
                                // Text
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task['description'] ?? '—',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: _C.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      if ((task['category'] ?? '')
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(task['category'],
                                            style: const TextStyle(
                                                color: _C.textSub,
                                                fontSize: 11)),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: sColor.withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                        color: sColor
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Text(sLabel,
                                      style: TextStyle(
                                          color: sColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}