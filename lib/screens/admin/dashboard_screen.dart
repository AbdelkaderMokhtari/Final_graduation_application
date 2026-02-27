import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  /// 🔢 حساب عدد حسب الحالة
  Stream<int> getCount(String? status) {
    if (status == null) {
      return FirebaseFirestore.instance
          .collection('reports')
          .snapshots()
          .map((event) => event.docs.length);
    }

    return FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((event) => event.docs.length);
  }

  /// 📊 Pie Chart
  Widget buildPieChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (context, snapshot) {
        int pending = 0;
        int inProgress = 0;
        int completed = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            String status = doc['status'];
            if (status == 'pending') pending++;
            if (status == 'in_progress') inProgress++;
            if (status == 'completed') completed++;
          }
        }

        return SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: pending.toDouble(),
                  color: Colors.orange,
                  title: "Pending\n$pending",
                  radius: 70,
                  titleStyle: const TextStyle(color: Colors.white),
                ),
                PieChartSectionData(
                  value: inProgress.toDouble(),
                  color: Colors.blue,
                  title: "Progress\n$inProgress",
                  radius: 70,
                  titleStyle: const TextStyle(color: Colors.white),
                ),
                PieChartSectionData(
                  value: completed.toDouble(),
                  color: Colors.green,
                  title: "Done\n$completed",
                  radius: 70,
                  titleStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🔲 Stat Card
  Widget statCard(String title, IconData icon, Stream<int> stream) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        int count = snapshot.data ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                color: Colors.black12,
              )
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.blue.shade50,
                child: Icon(icon, color: Colors.blue),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text(
                    "$count",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  /// 📋 آخر البلاغات
  Widget recentReports() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;

            return Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.report, color: Colors.blue),
                title: Text(data['description']),
                subtitle: Text("Status: ${data['status']}"),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6f9),
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "System Overview",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            /// 🔢 Stats
            statCard("All Reports", Icons.report, getCount(null)),
            const SizedBox(height: 15),
            statCard(
                "Pending Reports", Icons.hourglass_bottom, getCount('pending')),
            const SizedBox(height: 15),
            statCard(
                "Completed Reports", Icons.check_circle, getCount('completed')),

            const SizedBox(height: 30),

            /// 📊 Chart
            const Text(
              "Reports Status Distribution",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            buildPieChart(),

            const SizedBox(height: 30),

            /// 📋 Recent Reports
            const Text(
              "Recent Reports",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            recentReports(),
          ],
        ),
      ),
    );
  }
}
