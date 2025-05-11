import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
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

  Color selectedColor = Colors.blue;
  String lastUpdated = '';

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.title);
    descriptionController = TextEditingController(
      text: widget.note.description,
    );
    selectedColor = widget.note.color ?? Colors.blue;
    lastUpdated = DateFormat.yMMMd().add_jm().format(
      widget.note.updatedAt ?? DateTime.now(),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _updateNote() {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and description can't be empty")),
      );
      return;
    }

    final updatedNote =
        widget.note
          ..title = titleController.text.trim()
          ..description = descriptionController.text.trim()
          ..color = selectedColor
          ..updatedAt = DateTime.now()
          ..isPinned = widget.note.isPinned;

    notesBox.putAt(widget.noteIndex, updatedNote);
    Navigator.of(context).pop();
  }

  void _undoChanges() {
    setState(() {
      titleController.text = widget.note.title;
      descriptionController.text = widget.note.description;
      selectedColor = widget.note.color ?? Colors.blue;
    });
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          colors
              .map(
                (color) => GestureDetector(
                  onTap: () => setState(() => selectedColor = color),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: color,
                    child:
                        selectedColor == color
                            ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                            : null,
                  ),
                ),
              )
              .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: _undoChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 0,
          color: selectedColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Color Tag:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildColorPicker(),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Last updated: $lastUpdated",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _updateNote,
                  icon: Icon(Icons.save, color: Colors.white),
                  label: Text(
                    'Save Changes',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
