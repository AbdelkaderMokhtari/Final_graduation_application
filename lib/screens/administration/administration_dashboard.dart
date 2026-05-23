import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_worker_request_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

class AdministrationDashboard extends StatefulWidget {
  const AdministrationDashboard({super.key});

  @override
  State<AdministrationDashboard> createState() =>
      _AdministrationDashboardState();
}

class _AdministrationDashboardState extends State<AdministrationDashboard>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  String selectedCategory = "الكل";
  String selectedWasteType = "الكل";

  final List<String> categories = ["الكل", "نفايات", "إنارة", "طرقات"];
  final List<String> wasteTypes = ["الكل", "بلاستيك", "زجاج", "عضوي", "معادن"];

  // ── 🔔 لتتبع البلاغات الجديدة ──────────────
  final Set<String> _knownReportIds = {};
  bool _firstReportLoad = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _switchTab(int i) {
    if (i == _selectedIndex) return;
    setState(() => _selectedIndex = i);
    _animController.reset();
    _animController.forward();
  }

  // ── Actions ──────────────────────────────────
  Future<void> _logout() async => FirebaseAuth.instance.signOut();

  Future<void> _updateStatus(String id, String status) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(id)
        .update({'status': status});
  }

  Future<void> _assignWorker(String reportId, String workerId) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .update({'assignedTo': workerId, 'status': 'assigned'});
  }

  // ─────────────────────────────────────────────
  // 🔔 فحص البلاغات الجديدة وإرسال notification
  // ─────────────────────────────────────────────
  void _checkNewReports(List<DocumentSnapshot> docs) {
    // أول تحميل — سجل الموجودين بدون notification
    if (_firstReportLoad) {
      for (final doc in docs) {
        _knownReportIds.add(doc.id);
      }
      _firstReportLoad = false;
      return;
    }

    // تحقق من البلاغات الجديدة
    for (final doc in docs) {
      if (!_knownReportIds.contains(doc.id)) {
        _knownReportIds.add(doc.id);
        final data = doc.data() as Map<String, dynamic>;
        NotificationService().notifyAdmin(
          description: data['description'] ?? 'بلاغ جديد',
          category: data['category'] ?? '',
        );
      }
    }
  }

  // ─────────────────────────────────────────────
  // 📊 TAB 1 — Statistics
  // ─────────────────────────────────────────────
  Widget _buildStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: _C.blue));
        }

        // 🔔 فحص البلاغات الجديدة
        _checkNewReports(snap.data!.docs);

        final docs = snap.data!.docs;
        final total = docs.length;
        final pending = docs.where((d) => d['status'] == 'pending').length;
        final assigned = docs.where((d) => d['status'] == 'assigned').length;
        final inProgress =
            docs.where((d) => d['status'] == 'in_progress').length;
        final completed = docs.where((d) => d['status'] == 'completed').length;

        final items = [
          _StatItem('مجموع البلاغات', 'Total Reports', total,
              Icons.bar_chart_rounded, _C.blue),
          _StatItem('قيد الانتظار', 'Pending', pending,
              Icons.hourglass_top_rounded, _C.orange),
          _StatItem('مسندة', 'Assigned', assigned, Icons.engineering_rounded,
              _C.purple),
          _StatItem('قيد المعالجة', 'In Progress', inProgress,
              Icons.autorenew_rounded, _C.blueSoft),
          _StatItem('مكتملة', 'Completed', completed,
              Icons.check_circle_rounded, _C.green),
        ];

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final it = items[i];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 260 + i * 70),
              curve: Curves.easeOut,
              builder: (_, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                    offset: Offset(0, 20 * (1 - v)), child: child),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.divider),
                  boxShadow: [
                    BoxShadow(
                      color: it.color.withValues(alpha: 0.07),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        it.color.withValues(alpha: 0.25),
                        it.color.withValues(alpha: 0.08),
                      ]),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: it.color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(it.icon, color: it.color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.labelEn,
                              style: const TextStyle(
                                  color: _C.textSub, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(it.labelAr,
                              style: const TextStyle(
                                  color: _C.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ]),
                  ),
                  Text(
                    '${it.value}',
                    style: TextStyle(
                        color: it.color,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // 📋 TAB 2 — Reports
  // ─────────────────────────────────────────────
  Widget _buildReports() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Row(children: [
          Expanded(
              child: _filterDropdown(
            value: selectedCategory,
            items: categories,
            icon: Icons.category_rounded,
            color: _C.purple,
            onChanged: (v) => setState(() => selectedCategory = v!),
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _filterDropdown(
            value: selectedWasteType,
            items: wasteTypes,
            icon: Icons.recycling_rounded,
            color: _C.green,
            onChanged: (v) => setState(() => selectedWasteType = v!),
          )),
        ]),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reports')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: _C.blue));
            }

            // 🔔 فحص البلاغات الجديدة أيضاً من تاب الريبورتس
            _checkNewReports(snap.data!.docs);

            final docs = snap.data!.docs.where((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final matchCat = selectedCategory == "الكل" ||
                  d['category'] == selectedCategory;
              final matchWaste = selectedWasteType == "الكل" ||
                  d['wasteType'] == selectedWasteType;
              return matchCat && matchWaste;
            }).toList();

            if (docs.isEmpty) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.inbox_rounded, color: _C.textSub, size: 48),
                  SizedBox(height: 12),
                  Text('لا توجد تقارير',
                      style: TextStyle(color: _C.textSub, fontSize: 15)),
                ]),
              );
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final doc = docs[i];
                final data = doc.data() as Map<String, dynamic>;
                return _reportCard(i, doc.id, data);
              },
            );
          },
        ),
      ),
    ]);
  }

  Widget _filterDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required Color color,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: _C.card2,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 18),
          isExpanded: true,
          style: const TextStyle(color: _C.textPrimary, fontSize: 13),
          items: items
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Row(children: [
                      Icon(icon, color: color, size: 14),
                      const SizedBox(width: 6),
                      Text(s),
                    ]),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _reportCard(int idx, String id, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    final hasWorker = data['assignedTo'] != null;
    final meta = _statusMeta(status);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + idx * 55),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child:
            Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.divider),
          boxShadow: [
            BoxShadow(
                color: meta.color.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [meta.color, meta.color.withValues(alpha: 0.15)]),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (data['beforeImageBase64'] != null) ...[
                _imageLabel('📷 صورة المواطن'),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    base64Decode(data['beforeImageBase64']),
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (data['afterImageBase64'] != null) ...[
                _imageLabel('🧹 صورة العامل'),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    base64Decode(data['afterImageBase64']),
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Text(data['description'] ?? '—',
                  style: const TextStyle(
                      color: _C.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4)),
              const SizedBox(height: 8),

              Wrap(spacing: 8, runSpacing: 6, children: [
                if (data['category'] != null)
                  _tag(data['category'], _C.purple, Icons.category_rounded),
                if (data['wasteType'] != null)
                  _tag(data['wasteType'], _C.green, Icons.recycling_rounded),
                _tag(meta.label, meta.color, meta.icon),
              ]),

              const SizedBox(height: 14),

              // Status dropdown
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.card2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: status,
                    dropdownColor: _C.card2,
                    isExpanded: true,
                    style: const TextStyle(color: _C.textPrimary, fontSize: 13),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _C.textSub, size: 18),
                    items: const [
                      DropdownMenuItem(
                          value: 'pending', child: Text('⏳  معلق')),
                      DropdownMenuItem(
                          value: 'assigned', child: Text('👷  مسندة')),
                      DropdownMenuItem(
                          value: 'in_progress', child: Text('🔄  جاري')),
                      DropdownMenuItem(
                          value: 'completed', child: Text('✅  منجز')),
                    ],
                    onChanged: (v) {
                      if (v != null) _updateStatus(id, v);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Assign worker button
              GestureDetector(
                onTap: () => _showWorkerDialog(id),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      _C.blue.withValues(alpha: 0.22),
                      _C.blue.withValues(alpha: 0.07),
                    ]),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.blue.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasWorker
                              ? Icons.edit_rounded
                              : Icons.engineering_rounded,
                          color: _C.blue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasWorker ? 'تعديل العامل' : 'تعيين عامل',
                          style: const TextStyle(
                              color: _C.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _imageLabel(String t) => Text(t,
      style: const TextStyle(
          color: _C.textSub, fontSize: 12, fontWeight: FontWeight.w600));

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

  // ─────────────────────────────────────────────
  // 🗺️ TAB 3 — Map
  // ─────────────────────────────────────────────
  Widget _buildMap() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: _C.blue));
        }

        final markers = <Marker>[];
        for (final doc in snap.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['latitude'] == null) continue;
          final lat = (data['latitude'] as num).toDouble();
          final lng = (data['longitude'] as num).toDouble();
          final meta = _statusMeta(data['status'] ?? 'pending');

          markers.add(Marker(
            width: 42,
            height: 42,
            point: LatLng(lat, lng),
            child: GestureDetector(
              onTap: () => _showReportPopup(ctx, data),
              child: Container(
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: meta.color, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: meta.color.withValues(alpha: 0.4), blurRadius: 8)
                  ],
                ),
                child: Icon(meta.icon, color: meta.color, size: 20),
              ),
            ),
          ));
        }

        return FlutterMap(
          options: MapOptions(
            initialCenter: markers.isNotEmpty
                ? markers.first.point
                : const LatLng(34.8888, -1.3167),
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  "https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.ecocity.app',
            ),
            MarkerLayer(markers: markers),
          ],
        );
      },
    );
  }

  Future<void> _showReportPopup(
      BuildContext ctx, Map<String, dynamic> data) async {
    String workerName = "غير معين";
    if (data['assignedTo'] != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(data['assignedTo'])
          .get();
      if (doc.exists) workerName = doc['name'] ?? 'عامل';
    }
    final status = data['status'] ?? 'pending';
    final meta = _statusMeta(status);

    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _C.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: _C.blue, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('تفاصيل البلاغ',
                      style: TextStyle(
                          color: _C.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 14),
                if (data['beforeImageBase64'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      base64Decode(data['beforeImageBase64']),
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 12),
                _popupRow(Icons.description_rounded, 'الوصف',
                    data['description'] ?? '—', _C.blue),
                _popupRow(Icons.category_rounded, 'الفئة',
                    data['category'] ?? '—', _C.purple),
                if (data['wasteType'] != null)
                  _popupRow(Icons.recycling_rounded, 'النوع', data['wasteType'],
                      _C.green),
                _popupRow(meta.icon, 'الحالة', meta.label, meta.color),
                _popupRow(
                    Icons.engineering_rounded, 'العامل', workerName, _C.orange),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _C.divider,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('إغلاق',
                          style: TextStyle(
                              color: _C.textSub, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  Widget _popupRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: _C.textSub, fontSize: 12)),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: _C.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  // 👷 Worker Dialog — مع notification للعامل
  // ─────────────────────────────────────────────
  Future<void> _showWorkerDialog(String reportId) async {
    // جلب بيانات البلاغ لإرسالها في الـ notification
    final reportDoc = await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .get();
    final reportData = reportDoc.data() as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _C.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.engineering_rounded,
                        color: _C.orange, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('اختر عامل',
                      style: TextStyle(
                          color: _C.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.maxFinite,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'worker')
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (!snap.hasData) {
                        return const Center(
                            child: CircularProgressIndicator(color: _C.blue));
                      }
                      final workers = snap.data!.docs;
                      if (workers.isEmpty) {
                        return const Text('لا يوجد عمال',
                            style: TextStyle(color: _C.textSub));
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: workers.length,
                        itemBuilder: (ctx, i) {
                          final wd = workers[i].data() as Map<String, dynamic>;
                          final wid = workers[i].id;
                          return GestureDetector(
                            onTap: () async {
                              // 1 — إسناد البلاغ للعامل
                              await _assignWorker(reportId, wid);

                              // 2 — 🔔 notification للعامل
                              NotificationService().notifyWorker(
                                description:
                                    reportData['description'] ?? 'مهمة جديدة',
                                category: reportData['category'] ?? '',
                              );

                              Navigator.pop(ctx);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: _C.card2,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _C.divider),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: [_C.blue, _C.blueSoft]),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (wd['name'] ?? '?')
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(wd['name'] ?? '—',
                                          style: const TextStyle(
                                              color: _C.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                      Text(wd['workerType'] ?? '',
                                          style: const TextStyle(
                                              color: _C.textSub, fontSize: 11)),
                                    ])),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    color: _C.textSub, size: 14),
                              ]),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────
  _StatusMeta _statusMeta(String status) {
    switch (status) {
      case 'assigned':
        return _StatusMeta(_C.orange, Icons.engineering_rounded, 'مسندة');
      case 'in_progress':
        return _StatusMeta(_C.blue, Icons.autorenew_rounded, 'جاري');
      case 'completed':
        return _StatusMeta(_C.green, Icons.check_circle_rounded, 'منجز');
      default:
        return _StatusMeta(_C.textSub, Icons.hourglass_top_rounded, 'معلق');
    }
  }

  // ─── Build ───────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final pages = [_buildStats(), _buildReports(), _buildMap()];
    final navItems = [
      _NavItem(Icons.bar_chart_rounded, 'إحصائيات', 'Stats'),
      _NavItem(Icons.receipt_long_rounded, 'التقارير', 'Reports'),
      _NavItem(Icons.map_rounded, 'الخريطة', 'Map'),
    ];

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
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Eco City',
                style: TextStyle(
                    color: _C.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            Text(navItems[_selectedIndex].labelAr,
                style: const TextStyle(color: _C.textSub, fontSize: 10)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: _C.accent),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CreateWorkerScreen())),
          ),
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
      body: FadeTransition(opacity: _fadeAnim, child: pages[_selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _C.navyMid,
          border: Border(top: BorderSide(color: _C.divider)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: navItems.asMap().entries.map((e) {
                final i = e.key;
                final item = e.value;
                final active = _selectedIndex == i;
                return GestureDetector(
                  onTap: () => _switchTab(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 230),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: active
                          ? LinearGradient(colors: [
                              _C.blue.withValues(alpha: 0.25),
                              _C.blue.withValues(alpha: 0.07),
                            ])
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      border: active
                          ? Border.all(color: _C.blue.withValues(alpha: 0.4))
                          : null,
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(item.icon,
                          color: active ? _C.blue : _C.textSub, size: 20),
                      if (active) ...[
                        const SizedBox(width: 8),
                        Text(item.labelAr,
                            style: const TextStyle(
                                color: _C.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ],
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data classes ──────────────────────────────
class _StatItem {
  final String labelAr, labelEn;
  final int value;
  final IconData icon;
  final Color color;
  const _StatItem(
      this.labelAr, this.labelEn, this.value, this.icon, this.color);
}

class _StatusMeta {
  final Color color;
  final IconData icon;
  final String label;
  const _StatusMeta(this.color, this.icon, this.label);
}

class _NavItem {
  final IconData icon;
  final String labelAr, labelEn;
  const _NavItem(this.icon, this.labelAr, this.labelEn);
}
