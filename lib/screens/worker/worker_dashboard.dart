import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerScreen extends StatefulWidget {
  const WorkerScreen({super.key});

  @override
  State<WorkerScreen> createState() => _WorkerScreenState();
}

class _WorkerScreenState extends State<WorkerScreen> {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  /// تسجيل الخروج
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  /// تغيير الحالة إلى قيد المعالجة
  Future<void> markInProgress(String reportId) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .update({'status': 'in_progress'});
  }

  /// رفع صورة بعد التنظيف وإنهاء المهمة
  Future<void> uploadAfterImage(String reportId) async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(imageBytes);

    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .update({
      'afterImageBase64': base64Image,
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ تم إكمال المهمة بنجاح")),
      );
    }
  }

  /// فتح الموقع في Google Maps
  Future<void> openMap(double lat, double lng) async {
    final Uri url =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("خطأ في تسجيل الدخول")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("مهام العامل"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('assignedTo', isEqualTo: currentUser!.uid)
            .where('status', whereIn: ['assigned', 'in_progress']).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("لا توجد مهام حالياً"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String status = data['status'] ?? '';

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// صورة قبل
                      if (data['beforeImageBase64'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(data['beforeImageBase64']),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                      const SizedBox(height: 10),

                      Text("الوصف: ${data['description'] ?? ''}"),
                      Text("الفئة: ${data['category'] ?? ''}"),

                      const SizedBox(height: 5),

                      /// الموقع
                      if (data['latitude'] != null && data['longitude'] != null)
                        TextButton.icon(
                          onPressed: () => openMap(
                            (data['latitude'] as num).toDouble(),
                            (data['longitude'] as num).toDouble(),
                          ),
                          icon: const Icon(Icons.location_on),
                          label: const Text("فتح الموقع على الخريطة"),
                        ),

                      const SizedBox(height: 5),

                      /// الحالة
                      Row(
                        children: [
                          const Text("الحالة: "),
                          Text(
                            status,
                            style: TextStyle(
                              color: getStatusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// بدء العمل
                      if (status == 'assigned')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => markInProgress(doc.id),
                            child: const Text("🔄 بدء العمل"),
                          ),
                        ),

                      if (status == 'in_progress')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => uploadAfterImage(doc.id),
                            child: const Text(
                                "📸 تصوير بعد التنظيف وإنهاء المهمة"),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
