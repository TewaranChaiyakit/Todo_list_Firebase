import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E9BE9)),
        useMaterial3: true,
      ),
      home: const TodaApp(),
    );
  }
}

class TodaApp extends StatefulWidget {
  const TodaApp({super.key});

  @override
  State<TodaApp> createState() => _TodaAppState();
}

class _TodaAppState extends State<TodaApp> {
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  bool _status = false; // ตัวแปรสำหรับสถานะ
  bool _isLoading = false; // ตัวแปรสำหรับแสดงสถานะการโหลดข้อมูล

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ฟังก์ชันตรวจสอบค่าก่อนบันทึก
  bool validateFields() {
    if (_nameController.text.isEmpty || _noteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return false;
    }
    return true;
  }

  void addTodoHandle(BuildContext context) {
    _nameController.clear();
    _noteController.clear();
    setState(() {
      _status = false;
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add new task"),
          content: SizedBox(
            width: 300,
            height: 240,
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Task Name",
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Note",
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<bool>(
                  value: _status,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Status",
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: true,
                      child: Text("True"),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text("False"),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _status = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (!validateFields()) return; // ตรวจสอบค่าก่อนบันทึก

                setState(() {
                  _isLoading = true; // เริ่มแสดง progress indicator
                });

                try {
                  CollectionReference tasks =
                      FirebaseFirestore.instance.collection("Task");
                  await tasks.add({
                    'name': _nameController.text,
                    'note': _noteController.text,
                    'status': _status,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task added successfully')),
                  );
                } catch (onError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add task: $onError')),
                  );
                } finally {
                  setState(() {
                    _isLoading = false; // ยกเลิก progress indicator
                  });
                  Navigator.pop(context);
                }
              },
              child: _isLoading
                  ? const CircularProgressIndicator() // แสดง progress ระหว่างบันทึก
                  : const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void editTodoHandle(BuildContext context, DocumentSnapshot task) {
    _nameController.text = task['name'];
    _noteController.text = task['note'];
    _status = task['status'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit task"),
          content: SizedBox(
            width: 300,
            height: 240,
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Task Name",
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Note",
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<bool>(
                  value: _status,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Status",
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: true,
                      child: Text("True"),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text("False"),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _status = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (!validateFields()) return; // ตรวจสอบค่าก่อนบันทึก

                setState(() {
                  _isLoading = true;
                });

                try {
                  CollectionReference tasks =
                      FirebaseFirestore.instance.collection("Task");
                  await tasks.doc(task.id).update({
                    'name': _nameController.text,
                    'note': _noteController.text,
                    'status': _status,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task updated successfully')),
                  );
                } catch (onError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update task: $onError')),
                  );
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                  Navigator.pop(context);
                }
              },
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void deleteTodoHandle(BuildContext context, DocumentSnapshot task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete task"),
          content: const Text("Are you sure you want to delete this task?"),
          actions: [
            TextButton(
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                });

                try {
                  FirebaseFirestore.instance
                      .collection("Task")
                      .doc(task.id)
                      .delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task deleted successfully')),
                  );
                } catch (onError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete task: $onError')),
                  );
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                  Navigator.pop(context);
                }
              },
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Delete"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Todo"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("Task").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data?.docs.length,
              itemBuilder: (context, index) {
                var task = snapshot.data?.docs[index];
                return Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task?["name"] ?? '',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                task?["note"] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            editTodoHandle(context, task!);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            deleteTodoHandle(context, task!);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading tasks"));
          }
          return const Center(child: CircularProgressIndicator());
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
}
