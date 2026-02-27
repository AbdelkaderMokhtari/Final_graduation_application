import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class CreateAdministrationScreen extends StatefulWidget {
  const CreateAdministrationScreen({super.key});

  @override
  State<CreateAdministrationScreen> createState() =>
      _CreateAdministrationScreenState();
}

class _CreateAdministrationScreenState
    extends State<CreateAdministrationScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> createAdministration() async {
    try {
      setState(() => isLoading = true);

      final adminUser = FirebaseAuth.instance.currentUser;

      if (adminUser == null) {
        throw Exception("يجب أن يكون الأدمين مسجل دخول");
      }

      // إنشاء Firebase App ثانوي
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // إنشاء الحساب بدون تسجيل خروج الأدمين
      UserCredential credential =
          await secondaryAuth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // حفظ البيانات في Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': "administration",
        'workerType': null,
        'createdBy': adminUser.uid,
        'createdAt': Timestamp.now(),
      });

      await secondaryAuth.signOut();
      await secondaryApp.delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم إنشاء الحساب بنجاح")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),

      /// ===== AppBar =====
      appBar: AppBar(
        title: const Text("إنشاء مسؤول إدارة"),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1C3B70),
                Color(0xFF4A90E2),
              ],
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            /// ⭐ Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4A90E2),
                    Color(0xFF1C3B70),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    color: Colors.black.withOpacity(0.08),
                  )
                ],
              ),
              child: Column(
                children: const [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "إنشاء حساب مسؤول إدارة",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// ===== Input Fields =====
            _buildInputField(
              controller: nameController,
              label: "الاسم الكامل",
              icon: Icons.person,
            ),

            const SizedBox(height: 18),

            _buildInputField(
              controller: emailController,
              label: "البريد الإلكتروني",
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 18),

            _buildInputField(
              controller: passwordController,
              label: "كلمة المرور",
              icon: Icons.lock,
              obscure: true,
            ),

            const SizedBox(height: 30),

            /// ===== Button =====
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : createAdministration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C3B70),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 6,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "إنشاء الحساب",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⭐ Input Builder
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
