import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'data/compress_data.dart';
import 'data/note.dart';
import 'data/sync/note_sync_provider.dart';
import 'widgets/color_picker.dart';

// Provider for note details with local-first approach
final noteDetailProvider = FutureProvider.family<Note?, String>((
  ref,
  id,
) async {
  final syncService = ref.read(noteSyncProvider);

  // First try to get from local
  final box = await Hive.openBox<Note>('notesBox');
  final localNotes = box.values.where((note) => note.id == id);

  if (localNotes.isNotEmpty) {
    return localNotes.first;
  }

  // If not found locally, try server
  try {
    final serverNote = await syncService.getNoteById(id);
    if (serverNote != null) {
      // Store in local for future access
      await box.add(serverNote);
    }
    return serverNote;
  } catch (e) {
    print('Error fetching note from server: $e');
    return null;
  }
});

class NoteDetailScreen extends ConsumerStatefulWidget {
  final String noteId;
  final String categoryId;
  const NoteDetailScreen({
    super.key,
    required this.noteId,
    required this.categoryId,
  });

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  Note? currentNote;

  Color selectedColor = Colors.white;
  final List<Map<String, dynamic>> undoStack = [];
  final List<Map<String, dynamic>> redoStack = [];
  bool _isPerformingUndoRedo = false;
  String _lastTitle = '';
  String _lastDescription = '';
  DateTime? lastUpdate;
  bool _isInitialized = false;

  @override
  void dispose() {
    // Only remove listeners if we initialized them
    if (_isInitialized) {
      titleController.removeListener(_onTitleChanged);
      descriptionController.removeListener(_onDescriptionChanged);
    }
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _initializeControllers(Note note) {
    if (_isInitialized) return;

    try {
      titleController.text = CompressString.decompressString(note.title);
      descriptionController.text = CompressString.decompressString(
        note.description,
      );
      selectedColor = Color(note.colorValue ?? Colors.white.value);
      lastUpdate = note.updatedAt;
      _lastTitle = note.title;
      _lastDescription = note.description;
      currentNote = note;

      titleController.addListener(_onTitleChanged);
      descriptionController.addListener(_onDescriptionChanged);
      _isInitialized = true;
    } catch (e) {
      titleController.text = '';
      descriptionController.text = '';
      selectedColor = Colors.white;
    }
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

  //TODO: Check for server
  Future<void> _saveNote() async {
    if (currentNote == null) return;

    final trimmedTitle = titleController.text.trim();
    final trimmedDesc = descriptionController.text.trim();

    final compressedTitle =
        trimmedTitle.isEmpty
            ? ''
            : 'CMP:${CompressString.compressString(trimmedTitle)}';
    final compressedDescription =
        trimmedDesc.isEmpty
            ? ''
            : 'CMP:${CompressString.compressString(trimmedDesc)}';

    final hasChanges =
        compressedTitle != currentNote!.title ||
        compressedDescription != currentNote!.description ||
        selectedColor.value != currentNote!.colorValue;

    if (!hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    final updatedNote =
        currentNote!
          ..title = compressedTitle
          ..description = compressedDescription
          ..colorValue = selectedColor.value
          ..categoryId = widget.categoryId
          ..updatedAt = DateTime.now();

    // Update via sync service
    final syncService = ref.read(noteSyncProvider);
    await syncService.updateNote(updatedNote);

    if (mounted) {
      ref.invalidate(noteDetailProvider(widget.noteId));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(noteDetailProvider(widget.noteId));

    return noteAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading note: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(noteDetailProvider(widget.noteId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
      data: (note) {
        if (note == null) {
          return const Scaffold(body: Center(child: Text('Note not found')));
        }

        _initializeControllers(note);

        final isSaveEnabled =
            undoStack.isNotEmpty ||
            titleController.text.trim() !=
                CompressString.decompressString(currentNote!.title) ||
            descriptionController.text.trim() !=
                CompressString.decompressString(currentNote!.description);

        final formatDate =
            lastUpdate != null
                ? DateFormat('MMMM d, h:mm a').format(lastUpdate!)
                : 'Not saved';
        final totalLength =
            titleController.text.length + descriptionController.text.length;

        return Scaffold(
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
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Title...',
                      hintStyle: TextStyle(
                        color: Color.fromARGB(255, 107, 107, 107),
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
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Start typing...',
                        hintStyle: TextStyle(
                          color: Color.fromARGB(255, 107, 107, 107),
                        ),
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
      },
    );
  }
}
