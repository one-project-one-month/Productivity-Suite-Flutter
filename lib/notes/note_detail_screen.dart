import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:productivity_suite_flutter/notes/data/compress_data.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';
import 'package:productivity_suite_flutter/notes/widgets/color_picker.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  Color selectedColor = Colors.white;

  final List<Map<String, dynamic>> undoStack = [];
  final List<Map<String, dynamic>> redoStack = [];
  bool _isPerformingUndoRedo = false;
  String _lastTitle = '';
  String _lastDescription = '';
  late DateTime lastUpdate;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(
      text: CompressString.decompressString(widget.note.title),
    );
    descriptionController = TextEditingController(
      text: CompressString.decompressString(widget.note.description),
    );
    selectedColor = widget.note.color ?? Colors.white;
    lastUpdate = widget.note.updatedAt ?? DateTime.now();
    _lastTitle = widget.note.title;
    _lastDescription = widget.note.description;

    titleController.addListener(_onTitleChanged);
    descriptionController.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    titleController.removeListener(_onTitleChanged);
    descriptionController.removeListener(_onDescriptionChanged);
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    if (_isPerformingUndoRedo) return;
    final current = titleController.text;
    _trackChange('title', _lastTitle, current);
    _lastTitle = current;
    setState(() {});
  }

  void _onDescriptionChanged() {
    if (_isPerformingUndoRedo) return;
    final current = descriptionController.text;
    _trackChange('description', _lastDescription, current);
    _lastDescription = current;
    setState(() {});
  }

  void _trackChange(String field, dynamic oldValue, dynamic newValue) {
    if (oldValue == newValue) return;
    undoStack.add({'field': field, 'old': oldValue, 'new': newValue});
    redoStack.clear();
  }

  Widget _buildColorPicker() {
    return ColorPicker(
      initialColor: selectedColor,
      onColorChanged: (color) {
        _trackChange('color', selectedColor, color);
        setState(() => selectedColor = color);
      },

      circleRadius: 14,
      selectedCircleRadius: 16,
      iconSize: 18,
    );
  }

  void _undo() {
    if (undoStack.isEmpty) return;
    final action = undoStack.removeLast();
    redoStack.add(action);
    _isPerformingUndoRedo = true;
    switch (action['field']) {
      case 'title':
        titleController.text = action['old'];
        titleController.selection = TextSelection.collapsed(
          offset: action['old'].length,
        );
        _lastTitle = action['old'];
        break;
      case 'description':
        descriptionController.text = action['old'];
        descriptionController.selection = TextSelection.collapsed(
          offset: action['old'].length,
        );
        _lastDescription = action['old'];
        break;
      case 'color':
        selectedColor = action['old'];
        break;
    }
    _isPerformingUndoRedo = false;
    setState(() {});
  }

  void _redo() {
    if (redoStack.isEmpty) return;
    final action = redoStack.removeLast();
    undoStack.add(action);
    _isPerformingUndoRedo = true;
    switch (action['field']) {
      case 'title':
        titleController.text = action['new'];
        titleController.selection = TextSelection.collapsed(
          offset: action['new'].length,
        );
        _lastTitle = action['new'];
        break;
      case 'description':
        descriptionController.text = action['new'];
        descriptionController.selection = TextSelection.collapsed(
          offset: action['new'].length,
        );
        _lastDescription = action['new'];
        break;
      case 'color':
        selectedColor = action['new'];
        break;
    }
    _isPerformingUndoRedo = false;
    setState(() {});
  }

  Future<void> _saveNote() async {
    final trimmedTitle = titleController.text.trim();
    final trimmedDesc = descriptionController.text.trim();

    final compressedTitle =
        'CMP:${CompressString.compressString(trimmedTitle)}';

    final compressedDescription =
        'CMP:${CompressString.compressString(trimmedDesc)}';
    final hasChanges =
        compressedTitle != widget.note.title ||
        compressedDescription != widget.note.description ||
        selectedColor.value != widget.note.colorValue;

    if (!hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    widget.note
      ..title = compressedTitle
      ..description = compressedDescription
      ..colorValue = selectedColor.value
      ..updatedAt = DateTime.now();

    await widget.note.save();

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSaveEnabled =
        undoStack.isNotEmpty ||
        titleController.text.trim() != widget.note.title ||
        descriptionController.text.trim() != widget.note.description;
    var formatDate = DateFormat('MMMM d, h:mm a').format(lastUpdate);
    final totalLength =
        titleController.text.length + descriptionController.text.length;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: selectedColor.withOpacity(0.25),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: undoStack.isNotEmpty ? _undo : null,
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Redo',
              onPressed: redoStack.isNotEmpty ? _redo : null,
            ),
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Save Note',
              onPressed: isSaveEnabled ? _saveNote : null,
            ),
          ],
        ),
        body: Container(
          color: selectedColor.withOpacity(0.25),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleController,

                  maxLines: 1,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: const Color.fromARGB(255, 107, 107, 107),
                    ),
                    hintText: 'Title...',
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "$formatDate | $totalLength characters",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 72, 72, 72),
                      ),
                    ),
                  ],
                ),
                Divider(color: Color.fromARGB(255, 72, 72, 72)),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: descriptionController,

                    maxLines: 500,
                    decoration: InputDecoration(
                      hintText: 'Start typing...',
                      hintStyle: TextStyle(
                        color: const Color.fromARGB(255, 107, 107, 107),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Expanded(child: _buildColorPicker())],
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
