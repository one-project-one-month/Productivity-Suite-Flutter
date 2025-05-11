import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';

class NoteDetailScreen extends StatefulWidget {
  final int noteIndex;
  final Note note;

  const NoteDetailScreen({
    super.key,
    required this.noteIndex,
    required this.note,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  final Box<Note> notesBox = Hive.box<Note>('notesBox');

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.title);
    descriptionController = TextEditingController(
      text: widget.note.description,
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _updateNote() {
    final updatedNote =
        widget.note
          ..title = titleController.text
          ..description = descriptionController.text;

    notesBox.putAt(widget.noteIndex, updatedNote);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Note Details'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateNote,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
