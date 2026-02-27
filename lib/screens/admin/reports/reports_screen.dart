import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'report_details_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  /// 🔄 تحديث الحالة
  Future<void> updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(docId)
        .update({'status': status});
  }

  /// ❌ حذف البلاغ
  Future<void> deleteReport(String docId) async {
    await FirebaseFirestore.instance.collection('reports').doc(docId).delete();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          /// ⏳ Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// ❌ Error
          if (snapshot.hasError) {
            return const Center(
              child: Text("حدث خطأ أثناء تحميل البلاغات"),
            );
          }

          /// 📭 Empty
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("لا يوجد بلاغات حالياً"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String status = data['status'] ?? "pending";

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: getStatusColor(status),
                    child: const Icon(Icons.report, color: Colors.white),
                  ),
                  title: Text(
                    data['description'] ?? "بدون وصف",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    "الحالة: $status",
                    style: TextStyle(
                      color: getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "delete") {
                        deleteReport(doc.id);
                      } else {
                        updateStatus(doc.id, value);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: "pending", child: Text("⏳ Pending")),
                      PopupMenuItem(
                          value: "in_progress", child: Text("🔄 In Progress")),
                      PopupMenuItem(value: "done", child: Text("✅ Done")),
                      PopupMenuItem(value: "delete", child: Text("🗑 Delete")),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportDetailsScreen(
                          docId: doc.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
