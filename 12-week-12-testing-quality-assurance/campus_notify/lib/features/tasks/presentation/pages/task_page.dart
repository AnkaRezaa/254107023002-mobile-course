import 'package:flutter/material.dart';
import '../../../../core/validators/task_validator.dart';

/// Halaman antarmuka pengelolaan tugas dan catatan praktikum kampus.
/// Dirancang dengan arsitektur testable dan Key eksplisit untuk mendukung widget testing.
class TaskPage extends StatefulWidget {
  const TaskPage({super.key, this.initialTasks = const []});

  final List<String> initialTasks;

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final List<String> _tasks;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _tasks = List.from(widget.initialTasks);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _tasks.add(_titleController.text.trim());
      });
      _titleController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tugas Kampus'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('task-title-field'),
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Tugas Baru',
                        hintText: 'Contoh: Baca materi Flutter',
                        border: OutlineInputBorder(),
                      ),
                      validator: TaskValidator.validateTaskTitle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    key: const Key('save-task-button'),
                    onPressed: _handleSave,
                    icon: const Icon(Icons.add),
                    label: const Text('Simpan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada tugas',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      key: const Key('task-list-view'),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            title: Text(task),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
