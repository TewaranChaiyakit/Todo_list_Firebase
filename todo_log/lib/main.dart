import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,  // เลือกการตั้งค่าตาม platform
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 30, 226, 233),
        ),
        useMaterial3: true,
      ),
      home: const TodoApp(),
    );
  }
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late TextEditingController _taskController;
  late TextEditingController _descriptionController;

  final CollectionReference _tasksCollection =
      FirebaseFirestore.instance.collection('tasks'); // ใช้ Firestore collection

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  // เพิ่มงานใหม่ไปยัง Firestore
  Future<void> addTodoHandle(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add new task"),
          content: SizedBox(
            width: 120,
            height: 140,
            child: Column(
              children: [
                TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Input your task",
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Description",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_taskController.text.isNotEmpty) {
                  await _tasksCollection.add({
                    'task': _taskController.text,
                    'description': _descriptionController.text,
                    'completed': false
                  });
                  _taskController.clear();
                  _descriptionController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // แก้ไขงานใน Firestore
  Future<void> editTodoHandle(BuildContext context, DocumentSnapshot doc) async {
    _taskController.text = doc['task'];
    _descriptionController.text = doc['description'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit task"),
          content: SizedBox(
            width: 120,
            height: 180,
            child: Column(
              children: [
                TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Task",
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Description",
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Completed: "),
                    Switch(
                      value: doc['completed'],
                      onChanged: (value) async {
                        await _tasksCollection
                            .doc(doc.id)
                            .update({'completed': value});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _tasksCollection.doc(doc.id).update({
                  'task': _taskController.text,
                  'description': _descriptionController.text,
                });
                _taskController.clear();
                _descriptionController.clear();
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // ลบงานใน Firestore
  Future<void> deleteTodoHandle(String id) async {
    await _tasksCollection.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Todo-Homework!!!"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _tasksCollection.snapshots(), // ดึงข้อมูลแบบเรียลไทม์
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var tasks = snapshot.data!.docs;

          if (tasks.isEmpty) {
            return const Center(
              child: Text('No tasks added yet!'),
            );
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              var task = tasks[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text("Title: ${task['task']}"),
                  subtitle: Text("Detail: ${task['description']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => editTodoHandle(context, task),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteTodoHandle(task.id),
                      ),
                    ],
                  ),
                  leading: Checkbox(
                    value: task['completed'],
                    onChanged: (bool? value) {
                      _tasksCollection
                          .doc(task.id)
                          .update({'completed': value ?? false});
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addTodoHandle(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
