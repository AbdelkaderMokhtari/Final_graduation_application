import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerRegisterScreen extends StatefulWidget {
  const WorkerRegisterScreen({super.key});

  @override
  State<WorkerRegisterScreen> createState() => _WorkerRegisterScreenState();
}

class _WorkerRegisterScreenState extends State<WorkerRegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> registerWorker() async {
    try {
      setState(() => isLoading = true);

      // 1️⃣ إنشاء الحساب
      UserCredential credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User user = credential.user!;

      // 2️⃣ البحث عن طلب مسبق
      QuerySnapshot pending = await FirebaseFirestore.instance
          .collection('pending_workers')
          .where('email', isEqualTo: emailController.text.trim())
          .get();

      if (pending.docs.isEmpty) {
        throw Exception("لا يوجد طلب إنشاء لهذا العامل");
      }

      var data = pending.docs.first.data() as Map<String, dynamic>;

      // 3️⃣ إنشاء حساب worker رسمي
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': data['name'],
        'email': data['email'],
        'role': 'worker',
        'workerType': data['workerType'],
        'createdAt': Timestamp.now(),
      });

      // 4️⃣ حذف الطلب المؤقت
      await FirebaseFirestore.instance
          .collection('pending_workers')
          .doc(pending.docs.first.id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم إنشاء الحساب بنجاح")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تسجيل عامل")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "الاسم"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "الإيميل"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "كلمة المرور"),
            ),
            const SizedBox(height: 30),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: registerWorker,
                    child: const Text("تسجيل"),
                  ),
          ],
        ),
      ),
    );
  }
}
