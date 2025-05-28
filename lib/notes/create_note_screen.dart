import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import 'package:productivity_suite_flutter/notes/data/compress_data.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';
import 'package:productivity_suite_flutter/notes/widgets/color_picker.dart';

class CreateNoteScreen extends StatefulWidget {
  final Box<Note> notesBox;
  final String? categoryId;

  const CreateNoteScreen({super.key, required this.notesBox, this.categoryId});

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final FocusNode titleFocusNode = FocusNode();
  final FocusNode descriptionFocusNode = FocusNode();

  Color selectedColor = Colors.white;
  DateTime createDate = DateTime.now();

  final List<Map<String, dynamic>> undoStack = [];
  final List<Map<String, dynamic>> redoStack = [];

  String _lastTitle = '';
  String _lastDescription = '';

  bool _isPerformingUndoRedo = false;
  bool _isEditing = false;

  void _trackChange(String field, dynamic oldValue, dynamic newValue) {
    if (_isPerformingUndoRedo || oldValue == newValue) return;
    undoStack.add({'field': field, 'old': oldValue, 'new': newValue});
    redoStack.clear();
  }

  void _updateButtonStates() {
    setState(() {});
  }

  void _updateEditingState() {
    setState(() {
      _isEditing =
          (titleController.text.isNotEmpty ||
              descriptionController.text.isNotEmpty ||
              undoStack.isNotEmpty) &&
          (titleController.text.trim().isNotEmpty ||
              descriptionController.text.trim().isNotEmpty);
    });
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
          titleController.selection = TextSelection.fromPosition(
            TextPosition(offset: titleController.text.length),
          );
          _lastTitle = lastAction['old'];
          break;
        case 'description':
          descriptionController.text = lastAction['old'];
          descriptionController.selection = TextSelection.fromPosition(
            TextPosition(offset: descriptionController.text.length),
          );
          _lastDescription = lastAction['old'];
          break;
        case 'color':
          selectedColor = lastAction['old'];
          break;
      }
    });

    _isPerformingUndoRedo = false;
    _updateButtonStates();
    _updateEditingState();
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
          titleController.selection = TextSelection.fromPosition(
            TextPosition(offset: titleController.text.length),
          );
          _lastTitle = nextAction['new'];
          break;
        case 'description':
          descriptionController.text = nextAction['new'];
          descriptionController.selection = TextSelection.fromPosition(
            TextPosition(offset: descriptionController.text.length),
          );
          _lastDescription = nextAction['new'];
          break;
        case 'color':
          selectedColor = nextAction['new'];
          break;
      }
    });

    _isPerformingUndoRedo = false;
    _updateButtonStates();
    _updateEditingState();
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
        _updateButtonStates();
        _updateEditingState();
      }
    });

    descriptionController.addListener(() {
      if (!_isPerformingUndoRedo) {
        final current = descriptionController.text;
        _trackChange('description', _lastDescription, current);
        _lastDescription = current;
        _updateButtonStates();
        _updateEditingState();
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
    return ColorPicker(
      initialColor: selectedColor,
      onColorChanged: (color) {
        _trackChange('color', selectedColor, color);
        setState(() => selectedColor = color);
      },
      // Optional customizations:
      circleRadius: 14,
      selectedCircleRadius: 16,
      iconSize: 18,
    );
  }

  void _saveNote() {
    final titleText = titleController.text.trim();
    final descriptionText = descriptionController.text.trim();

    if (titleText.isEmpty && descriptionText.isEmpty) {
      return;
    }

    final compressedTitle =
        titleText.isEmpty
            ? titleText
            : 'CMP:${CompressString.compressString(titleText)}';

    final compressedDescription =
        descriptionText.isEmpty
            ? descriptionText
            : 'CMP:${CompressString.compressString(descriptionText)}';

    final note = Note(
      id: DateTime.now().toIso8601String(),
      title: compressedTitle,
      categoryId: widget.categoryId,
      description: compressedDescription,
      createdAt: DateTime.now(),
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
    var formatDate = DateFormat('MMMM d, h:mm a').format(createDate);
    final totalLength =
        titleController.text.length + descriptionController.text.length;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: selectedColor.withOpacity(0.25),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(_isEditing ? Icons.check : Icons.arrow_back),
          onPressed:
              _isEditing ? _saveNote : () => Navigator.of(context).pop(),
        ),
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
        ],
      ),
      body: Container(
        color: selectedColor.withOpacity(0.25),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                focusNode: titleFocusNode,
                maxLines: 1,
                decoration: InputDecoration(
                  border: InputBorder.none,
    
                  hintText: 'Title...',
                  hintStyle: TextStyle(
                    color: const Color.fromARGB(255, 107, 107, 107),
                  ),
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
                  focusNode: descriptionFocusNode,
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
            
                     const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
