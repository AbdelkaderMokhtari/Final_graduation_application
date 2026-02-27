import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_worker_request_screen.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const dashboardGradient = LinearGradient(
  colors: [Color(0xFF4A90E2), Color(0xFF1C3B70)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class AdministrationDashboard extends StatefulWidget {
  const AdministrationDashboard({super.key});

  @override
  State<AdministrationDashboard> createState() =>
      _AdministrationDashboardState();
}

class _AdministrationDashboardState extends State<AdministrationDashboard> {
  int _selectedIndex = 0;

  String selectedCategory = "الكل";
  String selectedWasteType = "الكل";

  final List<String> categories = [
    "الكل",
    "نفايات",
    "إنارة",
    "طرقات",
  ];

  final List<String> wasteTypes = [
    "الكل",
    "بلاستيك",
    "زجاج",
    "عضوي",
    "معادن",
  ];

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> updateStatus(String reportId, String status) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .update({'status': status});
  }

  Future<void> assignWorker(String reportId, String workerId) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .update({
      'assignedTo': workerId,
      'status': 'assigned',
    });
  }

  // =======================
  // 📊 الإحصائيات
  // =======================
  Widget buildStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data!.docs;

        int total = docs.length;
        int pending = docs.where((d) => d['status'] == 'pending').length;
        int assigned = docs.where((d) => d['status'] == 'assigned').length;
        int inProgress = docs.where((d) => d['status'] == 'in_progress').length;
        int completed = docs.where((d) => d['status'] == 'completed').length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            buildCard("📄 مجموع البلاغات", total),
            buildCard("⏳ قيد الانتظار", pending),
            buildCard("👷 مسندة", assigned),
            buildCard("🔄 قيد المعالجة", inProgress),
            buildCard("✅ مكتملة", completed),
          ],
        );
      },
    );
  }

  Widget buildCard(String title, int value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF6F9FF)],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text(value.toString(),
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C3B70))),
        ],
      ),
    );
  }

  // =======================
  // 📋 التقارير
  // =======================
  Widget buildReports() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            DropdownButton<String>(
              value: selectedCategory,
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                setState(() => selectedCategory = val!);
              },
            ),
            DropdownButton<String>(
              value: selectedWasteType,
              items: wasteTypes
                  .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                  .toList(),
              onChanged: (val) {
                setState(() => selectedWasteType = val!);
              },
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reports')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var docs = snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;

                bool matchCategory = selectedCategory == "الكل" ||
                    data['category'] == selectedCategory;

                bool matchWaste = selectedWasteType == "الكل" ||
                    data['wasteType'] == selectedWasteType;

                return matchCategory && matchWaste;
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text("لا توجد تقارير"));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var doc = docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  return buildReportCard(doc.id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildReportCard(String id, Map<String, dynamic> data) {
    String status = data['status'] ?? 'pending';
    bool hasWorker = data['assignedTo'] != null;

    Color statusColor;

    switch (status) {
      case "completed":
        statusColor = Colors.green;
        break;
      case "in_progress":
        statusColor = Colors.blue;
        break;
      case "assigned":
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            color: Colors.black.withOpacity(0.06),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ✅ صورة قبل (المواطن)
          if (data['beforeImageBase64'] != null) ...[
            const Text("📷 الصورة قبل (من المواطن)",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(
                base64Decode(data['beforeImageBase64']),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 15),
          ],

          /// ✅ صورة بعد (العامل)
          if (data['afterImageBase64'] != null) ...[
            const Text("🧹 الصورة بعد (من العامل)",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(
                base64Decode(data['afterImageBase64']),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 15),
          ],

          /// ✅ الوصف
          Text(
            "📝 ${data['description'] ?? ''}",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),

          const SizedBox(height: 8),

          Text("📂 ${data['category'] ?? ''}"),

          const SizedBox(height: 8),

          /// ✅ حالة البلاغ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 12),

          /// ✅ تعيين الحالة
          DropdownButton<String>(
            value: status,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'pending', child: Text("Pending")),
              DropdownMenuItem(value: 'assigned', child: Text("Assigned")),
              DropdownMenuItem(
                  value: 'in_progress', child: Text("In Progress")),
              DropdownMenuItem(value: 'completed', child: Text("Completed")),
            ],
            onChanged: (val) {
              if (val != null) updateStatus(id, val);
            },
          ),

          const SizedBox(height: 10),

          /// ✅ زر تعيين العامل
          ElevatedButton(
            onPressed: () => showWorkerDialog(id),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              hasWorker ? "✏️ تعديل العامل" : "👷 تعيين عامل",
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMapView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var reports = snapshot.data!.docs;

        List<Marker> markers = [];

        for (var doc in reports) {
          var data = doc.data() as Map<String, dynamic>;

          if (data['latitude'] != null && data['longitude'] != null) {
            double lat = (data['latitude'] as num).toDouble();
            double lng = (data['longitude'] as num).toDouble();

            markers.add(
              Marker(
                width: 45,
                height: 45,
                point: LatLng(lat, lng),
                child: GestureDetector(
                  onTap: () {
                    showReportPopup(context, data);
                  },
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 35,
                  ),
                ),
              ),
            );
          }
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

  Future<void> showReportPopup(
      BuildContext context, Map<String, dynamic> data) async {
    String status = data['status'] ?? "pending";

    String workerName = "غير معين";

    if (data['assignedTo'] != null) {
      var workerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(data['assignedTo'])
          .get();

      if (workerDoc.exists) {
        workerName = workerDoc['name'] ?? "عامل";
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("تفاصيل البلاغ"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['beforeImageBase64'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    base64Decode(data['beforeImageBase64']),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 10),
              Text("📝 الوصف: ${data['description'] ?? ''}"),
              Text("📂 الفئة: ${data['category'] ?? ''}"),
              if (data['wasteType'] != null)
                Text("♻️ نوع النفايات: ${data['wasteType']}"),
              Text("⚡ الحالة: $status"),
              Text("👷 العامل: $workerName"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إغلاق"),
          ),
        ],
      ),
    );
  }

  Widget buildImage(String base64String, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(base64String),
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // =======================
  // 👷 اختيار عامل صحيح
  // =======================
  Future<void> showWorkerDialog(String reportId) async {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("اختر عامل"),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'worker')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var workers = snapshot.data!.docs;

                if (workers.isEmpty) {
                  return const Text("لا يوجد عمال");
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: workers.length,
                  itemBuilder: (context, index) {
                    var workerDoc = workers[index];
                    var workerData = workerDoc.data() as Map<String, dynamic>;
                    String workerId = workerDoc.id;

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          workerData['name']?.substring(0, 1).toUpperCase() ??
                              "?",
                        ),
                      ),
                      title: Text(workerData['name'] ?? ""),
                      subtitle: Text(workerData['workerType'] ?? ""),
                      onTap: () async {
                        await assignWorker(reportId, workerId);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // =======================
  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      buildStats(),
      buildReports(),
      buildMapView(), // 🔥 الخريطة الجديدة
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة تحكم الإدارة"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateWorkerScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "إحصائيات",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: "التقارير",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "الخريطة",
          ),
        ],
      ),
    );
  }
}
