import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerTasksScreen extends StatelessWidget {
  const WorkerTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مهام العمال"),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            return const Center(child: Text("لا يوجد عمال"));
          }

          return ListView.builder(
            itemCount: workers.length,
            itemBuilder: (context, index) {
              var worker = workers[index];
              var workerData = worker.data() as Map<String, dynamic>;

              String workerId = worker.id;

              return Card(
                margin: const EdgeInsets.all(12),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ExpansionTile(
                  title: Text(
                    workerData['name'] ?? "عامل",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    workerData['workerType'] ?? "",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  children: [
                    /// ⭐ Tasks of Worker
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('reports')
                          .where('assignedTo', isEqualTo: workerId)
                          .snapshots(),
                      builder: (context, taskSnapshot) {
                        if (!taskSnapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          );
                        }

                        var tasks = taskSnapshot.data!.docs;

                        if (tasks.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text("لا توجد مهام"),
                          );
                        }

                        return Column(
                          children: tasks.map((taskDoc) {
                            var task = taskDoc.data() as Map<String, dynamic>;

                            return ListTile(
                              title: Text(
                                task['description'] ?? "",
                              ),
                              subtitle: Text(
                                "الحالة: ${task['status'] ?? ''}",
                              ),
                              leading: const Icon(Icons.task),
                            );
                          }).toList(),
                        );
                      },
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
