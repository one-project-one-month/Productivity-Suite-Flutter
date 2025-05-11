import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';

class CreateNoteScreen extends StatefulWidget {
  final Box<Note> notesBox;

  const CreateNoteScreen({super.key, required this.notesBox});

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}
class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final FocusNode titleFocusNode = FocusNode();
  final FocusNode descriptionFocusNode = FocusNode();

  Color selectedColor = Colors.blue;
  DateTime createDate = DateTime.now();

  final List<Map<String, dynamic>> undoStack = [];
  final List<Map<String, dynamic>> redoStack = [];

  String _lastTitle = '';
  String _lastDescription = '';

  bool _isPerformingUndoRedo = false;

  void _trackChange(String field, dynamic oldValue, dynamic newValue) {
    if (_isPerformingUndoRedo || oldValue == newValue) return;
    undoStack.add({'field': field, 'old': oldValue, 'new': newValue});
    redoStack.clear();
  }

  void _undo() {
    if (undoStack.isEmpty) return;

    final lastAction = undoStack.removeLast();
    redoStack.add(lastAction);

    _isPerformingUndoRedo = true;

    setState(() {
      switch (lastAction['field']) {
        case 'title':
          titleController.text = lastAction['old'];
          titleController.selection = TextSelection.fromPosition(TextPosition(offset: titleController.text.length));
          _lastTitle = lastAction['old'];
          break;
        case 'description':
          descriptionController.text = lastAction['old'];
          descriptionController.selection = TextSelection.fromPosition(TextPosition(offset: descriptionController.text.length));
          _lastDescription = lastAction['old'];
          break;
        case 'color':
          selectedColor = lastAction['old'];
          break;
      }
    });

    _isPerformingUndoRedo = false;
  }

  void _redo() {
    if (redoStack.isEmpty) return;

    final nextAction = redoStack.removeLast();
    undoStack.add(nextAction);

    _isPerformingUndoRedo = true;

    setState(() {
      switch (nextAction['field']) {
        case 'title':
          titleController.text = nextAction['new'];
          titleController.selection = TextSelection.fromPosition(TextPosition(offset: titleController.text.length));
          _lastTitle = nextAction['new'];
          break;
        case 'description':
          descriptionController.text = nextAction['new'];
          descriptionController.selection = TextSelection.fromPosition(TextPosition(offset: descriptionController.text.length));
          _lastDescription = nextAction['new'];
          break;
        case 'color':
          selectedColor = nextAction['new'];
          break;
      }
    });

    _isPerformingUndoRedo = false;
  }

  @override
  void initState() {
    super.initState();
    _lastTitle = titleController.text;
    _lastDescription = descriptionController.text;

    titleController.addListener(() {
      if (!_isPerformingUndoRedo) {
        final current = titleController.text;
        _trackChange('title', _lastTitle, current);
        _lastTitle = current;
      }
    });

    descriptionController.addListener(() {
      if (!_isPerformingUndoRedo) {
        final current = descriptionController.text;
        _trackChange('description', _lastDescription, current);
        _lastDescription = current;
      }
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    titleFocusNode.dispose();
    descriptionFocusNode.dispose();
    super.dispose();
  }

  Widget _buildColorPicker() {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: colors.map((color) {
        return GestureDetector(
          onTap: () {
            if (color != selectedColor) {
              _trackChange('color', selectedColor, color);
              setState(() => selectedColor = color);
            }
          },
          child: CircleAvatar(
            radius: 14,
            backgroundColor: color,
            child: selectedColor == color ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
        );
      }).toList(),
    );
  }

  void _saveNote() {
    if (titleController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and description can't be empty")),
      );
      return;
    }

    final note = Note(
      id: DateTime.now().toIso8601String(),
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      date: DateTime.now(),
      updatedAt: DateTime.now(),
      type: NoteType.text,
      isPinned: false,
      colorValue: selectedColor.value,
    );

    widget.notesBox.add(note);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final totalLength = titleController.text.length + descriptionController.text.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Note'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.undo), tooltip: 'Undo', onPressed: _undo),
          IconButton(icon: const Icon(Icons.redo), tooltip: 'Redo', onPressed: _redo),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: titleController,
            focusNode: titleFocusNode,
            decoration: InputDecoration(labelText: 'Title', suffixText: '$totalLength characters'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descriptionController,
            focusNode: descriptionFocusNode,
            maxLines: 5,
            decoration: InputDecoration(labelText: 'Description', suffixText: '$totalLength characters'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text('Color Tag:', style: TextStyle(fontWeight: FontWeight.bold)), _buildColorPicker()],
          ),
          const SizedBox(height: 16),
          Text('Created on: ${createDate.toLocal().toString().split(".").first}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _saveNote, icon: const Icon(Icons.save), label: const Text('Save Note')),
        ]),
      ),
    );
  }
}
