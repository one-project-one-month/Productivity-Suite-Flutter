import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';
import 'package:productivity_suite_flutter/notes/note_detail_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final Box<Note> notesBox = Hive.box<Note>('notesBox');
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  void _addNote() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Add Note'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Content'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  final note = Note(
                    id: DateTime.now().toIso8601String(),
                    title: titleController.text,
                    description: contentController.text,
                    date: DateTime.now(),
                    type: NoteType.text,
                  );
                  notesBox.add(note);
                  titleController.clear();
                  contentController.clear();
                  setState(() {});
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _deleteNote(int index) {
    notesBox.deleteAt(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final notes = notesBox.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Notes'), centerTitle: true),
      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (_, index) {
          final note = notes[index];
          return ListTile(
            title: Text(note.title),
            subtitle: Text(note.description),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => NoteDetailScreen(noteIndex: index, note: note),
                ),
              );
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteNote(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}
