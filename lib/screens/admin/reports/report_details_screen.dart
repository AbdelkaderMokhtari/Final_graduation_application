import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportDetailsScreen extends StatefulWidget {
  final String docId;
  const ReportDetailsScreen({super.key, required this.docId});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  Future<void> updateStatus(String status) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(widget.docId)
        .update({'status': status});
  }

  Future<void> deleteReport() async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.docId)
          .delete();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ أثناء الحذف: $e")),
      );
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'done':
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),

      /// =========================
      /// AppBar Modern Style
      /// =========================
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF4A90E2),
                Color(0xFF357ABD),
              ],
            ),
          ),
        ),
        title: const Text(
          "تفاصيل البلاغ",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: deleteReport,
            icon: const Icon(Icons.delete, color: Colors.white),
          )
        ],
      ),

      /// =========================
      /// Stream Builder
      /// =========================
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .doc(widget.docId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text("حدث خطأ أثناء تحميل البيانات"),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String status = data['status'] ?? "pending";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ===== Image Section =====
                if (data['beforeImageBase64'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(
                      base64Decode(data['beforeImageBase64']),
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),

                const SizedBox(height: 25),

                /// ===== Description =====
                const Text(
                  "الوصف",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(
                  data['description'] ?? "بدون وصف",
                  style: const TextStyle(fontSize: 15),
                ),

                const SizedBox(height: 18),

                /// ===== Category =====
                Text(
                  "الفئة: ${data['category'] ?? "غير محدد"}",
                  style: const TextStyle(fontSize: 15),
                ),

                const SizedBox(height: 10),

                /// ===== Location =====
                if (data['latitude'] != null)
                  Text(
                    "📍 ${data['latitude']} , ${data['longitude']}",
                    style: const TextStyle(fontSize: 14),
                  ),

                const SizedBox(height: 10),

                /// ===== Date =====
                if (data['timestamp'] != null)
                  Text(
                    "📅 ${(data['timestamp'] as Timestamp).toDate()}",
                    style: const TextStyle(fontSize: 13),
                  ),

                const SizedBox(height: 20),

                /// ===== Status Badge =====
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: getStatusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "الحالة: $status",
                    style: TextStyle(
                      color: getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// ===== Action Buttons =====
                if (status != "in_progress")
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => updateStatus("in_progress"),
                      icon: const Icon(Icons.sync),
                      label: const Text("تحويل إلى قيد المعالجة"),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                if (status != "done" && status != "completed")
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => updateStatus("done"),
                      icon: const Icon(Icons.check_circle),
                      label: const Text("تعليم كمنجز"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
