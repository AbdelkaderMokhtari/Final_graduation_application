import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String selectedRole = 'citizen';
  bool isLoading = false;

  Future<void> register() async {
  try {
    UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    User? user = userCredential.user;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .set({
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'role': "citizen", // 🔥 ثابت
      'workerType': null,
      'createdBy': user.uid,
      'createdAt': Timestamp.now(),
    });

    Navigator.pop(context);
  } catch (e) {
    print(e);
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
      appBar: AppBar(title: const Text("إنشاء حساب جديد")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                /// الاسم
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "الاسم الكامل"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "أدخل الاسم";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                /// الإيميل
                TextFormField(
                  controller: emailController,
                  decoration:
                      const InputDecoration(labelText: "البريد الإلكتروني"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "أدخل البريد الإلكتروني";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                /// كلمة المرور
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "كلمة المرور"),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return "كلمة المرور يجب أن تكون 6 أحرف على الأقل";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                /// اختيار الدور
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: "اختر الدور"),
                  items: const [
                    DropdownMenuItem(
                      value: 'citizen',
                      child: Text("مواطن"),
                    ),
                    DropdownMenuItem(
                      value: 'worker',
                      child: Text("عامل"),
                    ),
                    DropdownMenuItem(
                      value: 'administration',
                      child: Text("إدارة"),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                ),

                const SizedBox(height: 30),

                /// زر التسجيل
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: register,
                        child: const Text("تسجيل"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
