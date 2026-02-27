import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import 'my_reports_screen.dart';
import 'login_screen.dart';

class CitizenScreen extends StatefulWidget {
  const CitizenScreen({super.key});

  @override
  State<CitizenScreen> createState() => _CitizenScreenState();
}

class _CitizenScreenState extends State<CitizenScreen> {
  final descriptionController = TextEditingController();

  String selectedCategory = "نفايات";
  String selectedWasteType = "بلاستيك";

  File? selectedImage;
  double? latitude;
  double? longitude;
  bool isLoading = false;

  User? user;

  @override
  void initState() {
    super.initState();
    signInAnonymous();
  }

  Future<void> signInAnonymous() async {
    final current = FirebaseAuth.instance.currentUser;

    if (current == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    user = FirebaseAuth.instance.currentUser;
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 25,
      maxWidth: 800,
    );

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });
  }

  Future<void> submitReport() async {
    if (descriptionController.text.isEmpty ||
        selectedImage == null ||
        latitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("أكمل جميع البيانات")),
      );
      return;
    }

    if (user == null) return;

    try {
      setState(() => isLoading = true);

      List<int> imageBytes = await selectedImage!.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      await FirebaseFirestore.instance.collection('reports').add({
        'userId': user!.uid,
        'description': descriptionController.text.trim(),
        'category': selectedCategory,
        'wasteType': selectedCategory == "نفايات" ? selectedWasteType : null,
        'beforeImageBase64': base64Image,
        'status': 'pending',
        'latitude': latitude,
        'longitude': longitude,
        'assignedTo': null,
        'timestamp': Timestamp.now(),
      });

      descriptionController.clear();

      setState(() {
        selectedImage = null;
        latitude = null;
        longitude = null;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ تم إرسال البلاغ بنجاح")),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: $e")),
      );
    }
  }

  Widget buildCategorySelector() {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      items: const [
        DropdownMenuItem(value: "نفايات", child: Text("نفايات")),
        DropdownMenuItem(value: "إنارة", child: Text("إنارة عمومية")),
        DropdownMenuItem(value: "طرقات", child: Text("طرقات")),
      ],
      onChanged: (value) {
        setState(() {
          selectedCategory = value!;
        });
      },
      decoration: const InputDecoration(
        labelText: "نوع البلاغ",
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget buildWasteSelector() {
    if (selectedCategory != "نفايات") return const SizedBox();

    return Column(
      children: [
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: selectedWasteType,
          items: const [
            DropdownMenuItem(value: "بلاستيك", child: Text("بلاستيك")),
            DropdownMenuItem(value: "زجاج", child: Text("زجاج")),
            DropdownMenuItem(value: "عضوي", child: Text("عضوي")),
            DropdownMenuItem(value: "معادن", child: Text("معادن")),
          ],
          onChanged: (value) {
            setState(() {
              selectedWasteType = value!;
            });
          },
          decoration: const InputDecoration(
            labelText: "نوع النفايات",
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      /// =========================
      /// Modern AppBar Design
      /// =========================
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4A90E2),
                Color(0xFF357ABD),
              ],
            ),
          ),
        ),
        title: const Text(
          "تقديم بلاغ",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          /// My Reports
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            tooltip: "بلاغاتي",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyReportsScreen(),
                ),
              );
            },
          ),

          /// Admin Login
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            tooltip: "لوحة الإدارة",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),

      /// =========================
      /// Body Container
      /// =========================
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF7F9FC),
              Color(0xFFEAF0F9),
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Title Section
              const Text(
                "📢 تقديم بلاغ جديد",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),

              const SizedBox(height: 35),

              /// ---- Content UI (Your existing UI) ----
              /// Keep your widgets exactly as they are:

              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "اكتب وصف المشكلة هنا...",
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              buildCategorySelector(),
              buildWasteSelector(),

              const SizedBox(height: 30),

              Row(
                children: const [
                  Icon(Icons.camera_alt, size: 26),
                  SizedBox(width: 10),
                  Text(
                    "صورة البلاغ",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Center(
                child: selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          selectedImage!,
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Text("لم يتم اختيار صورة بعد"),
              ),

              const SizedBox(height: 15),

              Center(
                child: ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.camera),
                  label: const Text("التقاط صورة"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: const [
                  Icon(Icons.location_on, size: 26),
                  SizedBox(width: 10),
                  Text(
                    "الموقع",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                latitude != null
                    ? "📍 $latitude , $longitude"
                    : "لم يتم تحديد الموقع",
              ),

              const SizedBox(height: 15),

              Center(
                child: ElevatedButton.icon(
                  onPressed: getLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text("تحديد الموقع"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: submitReport,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          "إرسال البلاغ",
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
