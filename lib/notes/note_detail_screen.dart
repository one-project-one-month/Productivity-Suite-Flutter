// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:productivity_suite_flutter/notes/data/note.dart';

// class NoteDetailScreen extends StatefulWidget {
//   final int noteIndex;
//   final Note note;

//   const NoteDetailScreen({
//     super.key,
//     required this.noteIndex,
//     required this.note,
//   });

//   @override
//   State<NoteDetailScreen> createState() => _NoteDetailScreenState();
// }

// class _NoteDetailScreenState extends State<NoteDetailScreen> {
//   late TextEditingController titleController;
//   late TextEditingController descriptionController;
//   final Box<Note> notesBox = Hive.box<Note>('notesBox');

//   Color selectedColor = Colors.blue;
//   String lastUpdated = '';

//   final List<Map<String, dynamic>> undoStack = [];
//   final List<Map<String, dynamic>> redoStack = [];
//   bool _isPerformingUndoRedo = false;

//   String _lastTitle = '';
//   String _lastDescription = '';

//   void _updateButtonStates() {
//     setState(() {});
//   }

//   @override
//   void initState() {
//     super.initState();
//     titleController = TextEditingController(text: widget.note.title);
//     descriptionController = TextEditingController(
//       text: widget.note.description,
//     );
//     selectedColor = widget.note.color ?? Colors.blue;
//     lastUpdated = DateFormat.yMMMd().add_jm().format(
//       widget.note.updatedAt ?? DateTime.now(),
//     );

//     _lastTitle = widget.note.title;
//     _lastDescription = widget.note.description;

//     titleController.addListener(() {
//       if (!_isPerformingUndoRedo) {
//         final current = titleController.text;
//         _trackChange('title', _lastTitle, current);
//         _lastTitle = current;
//         _updateButtonStates();
//       }
//     });

//     descriptionController.addListener(() {
//       if (!_isPerformingUndoRedo) {
//         final current = descriptionController.text;
//         _trackChange('description', _lastDescription, current);
//         _lastDescription = current;
//         _updateButtonStates();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     titleController.dispose();
//     descriptionController.dispose();
//     super.dispose();
//   }

//   void _trackChange(String field, dynamic oldValue, dynamic newValue) {
//     if (_isPerformingUndoRedo || oldValue == newValue) return;
//     undoStack.add({'field': field, 'old': oldValue, 'new': newValue});
//     redoStack.clear();
//   }

//   void _undo() {
//     if (undoStack.isEmpty) return;

//     final lastAction = undoStack.removeLast();
//     redoStack.add(lastAction);

//     _isPerformingUndoRedo = true;

//     setState(() {
//       switch (lastAction['field']) {
//         case 'title':
//           titleController.text = lastAction['old'];
//           titleController.selection = TextSelection.fromPosition(
//             TextPosition(offset: titleController.text.length),
//           );
//           _lastTitle = lastAction['old'];
//           break;
//         case 'description':
//           descriptionController.text = lastAction['old'];
//           descriptionController.selection = TextSelection.fromPosition(
//             TextPosition(offset: descriptionController.text.length),
//           );
//           _lastDescription = lastAction['old'];
//           break;
//         case 'color':
//           selectedColor = lastAction['old'];
//           break;
//       }
//     });

//     _isPerformingUndoRedo = false;
//     _updateButtonStates();
//   }

//   void _redo() {
//     if (redoStack.isEmpty) return;

//     final nextAction = redoStack.removeLast();
//     undoStack.add(nextAction);

//     _isPerformingUndoRedo = true;

//     setState(() {
//       switch (nextAction['field']) {
//         case 'title':
//           titleController.text = nextAction['new'];
//           titleController.selection = TextSelection.fromPosition(
//             TextPosition(offset: titleController.text.length),
//           );
//           _lastTitle = nextAction['new'];
//           break;
//         case 'description':
//           descriptionController.text = nextAction['new'];
//           descriptionController.selection = TextSelection.fromPosition(
//             TextPosition(offset: descriptionController.text.length),
//           );
//           _lastDescription = nextAction['new'];
//           break;
//         case 'color':
//           selectedColor = nextAction['new'];
//           break;
//       }
//     });

//     _isPerformingUndoRedo = false;
//     _updateButtonStates();
//   }

//   void _updateNote() {
//     final hasChanges =
//         titleController.text.trim() != widget.note.title.trim() ||
//         descriptionController.text.trim() != widget.note.description.trim() ||
//         selectedColor != (widget.note.color ?? Colors.blue);

//     if (!hasChanges) {
//       Navigator.of(context).pop();
//       return;
//     }

//     final updatedNote = widget.note.copyWith(
//       title: titleController.text.trim(),
//       description: descriptionController.text.trim(),
//       colorValue: selectedColor.value,
//       updatedAt: DateTime.now(),
//     );

//     notesBox.putAt(widget.noteIndex, updatedNote);
//     Navigator.of(context).pop();
//   }

//   Widget _buildColorPicker() {
//     final colors = [
//       Colors.blue,
//       Colors.green,
//       Colors.orange,
//       Colors.purple,
//       Colors.red,
//     ];
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children:
//           colors
//               .map(
//                 (color) => GestureDetector(
//                   onTap: () {
//                     _trackChange('color', selectedColor, color);
//                     setState(() => selectedColor = color);
//                   },
//                   child: CircleAvatar(
//                     radius: 14,
//                     backgroundColor: color,
//                     child:
//                         selectedColor == color
//                             ? const Icon(
//                               Icons.check,
//                               color: Colors.white,
//                               size: 16,
//                             )
//                             : null,
//                   ),
//                 ),
//               )
//               .toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         //title: const Text('Edit Note'),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.undo),
//             tooltip: 'Undo',
//             onPressed: undoStack.isNotEmpty ? _undo : null,
//           ),
//           IconButton(
//             icon: const Icon(Icons.redo),
//             tooltip: 'Redo',
//             onPressed: redoStack.isNotEmpty ? _redo : null,
//           ),
//           IconButton(
//             icon: const Icon(Icons.check),
//             tooltip: 'Upgrade Note',
//             onPressed: _updateNote,
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Card(
//           elevation: 0,
//           color: selectedColor.withOpacity(0.1),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: titleController,
//                   decoration: const InputDecoration(
//                     labelText: 'Title',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: descriptionController,
//                   maxLines: 8,
//                   decoration: const InputDecoration(
//                     labelText: 'Description',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       'Color Tag:',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     _buildColorPicker(),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   "Last updated: $lastUpdated",
//                   style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';

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
    titleController = TextEditingController(text: widget.note.title);
    descriptionController = TextEditingController(
      text: widget.note.description,
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
    final hasChanges =
        trimmedTitle != widget.note.title ||
        trimmedDesc != widget.note.description ||
        selectedColor != (widget.note.color ?? Colors.blue);

    if (!hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    widget.note
      ..title = trimmedTitle
      ..description = trimmedDesc
      ..colorValue = selectedColor.value
      ..updatedAt = DateTime.now();
    await widget.note.save();

    Navigator.of(context).pop();
  }

  Widget _buildColorPicker() {
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.brown,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          colors.map((c) {
            final isSelected = c == selectedColor;
            return GestureDetector(
              onTap: () {
                _trackChange('color', selectedColor, c);
                setState(() => selectedColor = c);
              },
              child: CircleAvatar(
                radius: isSelected ? 18 : 14,
                backgroundColor: c,
                child:
                    isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
              ),
            );
          }).toList(),
    );
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
    return Scaffold(
      appBar: AppBar(
        // title: const Text('Edit Note'),
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
        color: selectedColor.withOpacity(0.1),
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
                  hintStyle: TextStyle(color: Colors.grey),
                  hintText: 'Title...',
                ),
              ),
              Row(
                children: [
                  Text(
                    "$formatDate | $totalLength characters",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Divider(),

              Expanded(
                flex: 2,
                child: TextField(
                  controller: descriptionController,

                  maxLines: 500,
                  decoration: InputDecoration(
                    hintText: 'Start typing...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Color Tag:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildColorPicker(),
                  ],
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
