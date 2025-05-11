import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';
import 'package:productivity_suite_flutter/notes/note_detail_screen.dart';
import 'package:productivity_suite_flutter/notes/note_search.dart';
import 'package:productivity_suite_flutter/notes/create_note_screen.dart';
import 'package:intl/intl.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final Box<Note> notesBox = Hive.box<Note>('notesBox');
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {}); // Trigger UI rebuild for search
  }

  void _deleteNoteById(String noteId) {
    final index = notesBox.values.toList().indexWhere((n) => n.id == noteId);
    if (index != -1) {
      notesBox.deleteAt(index);
    }
  }

  void _togglePin(Note note) async {
    final index = notesBox.values.toList().indexWhere((n) => n.id == note.id);
    if (index != -1) {
      final updatedNote = note.copyWith(
        isPinned: !(note.isPinned ?? false),
        updatedAt: DateTime.now(),
      );
      await notesBox.putAt(index, updatedNote);
      setState(() {}); // Refresh UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NotesSearchDelegate(notesBox.values.toList()),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: notesBox.listenable(),
        builder: (context, Box<Note> box, _) {
          final query = searchController.text.toLowerCase();
          final allNotes = box.values.toList();

          final filteredNotes =
              query.isEmpty
                  ? allNotes
                  : allNotes.where((note) {
                    final title = note.title.toLowerCase();
                    final desc = note.description.toLowerCase();
                    return title.contains(query) || desc.contains(query);
                  }).toList();

          final pinnedNotes =
              filteredNotes.where((note) => note.isPinned ?? false).toList();
          final otherNotes =
              filteredNotes.where((note) => !(note.isPinned ?? false)).toList();

          if (filteredNotes.isEmpty) {
            return const Center(child: Text('No notes found.'));
          }

          final combinedNotes = [...pinnedNotes, ...otherNotes];

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount:
                combinedNotes.length +
                (pinnedNotes.isNotEmpty ? 1 : 0) +
                (otherNotes.isNotEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              int pinnedHeaderIndex = 0;
              int othersHeaderIndex =
                  pinnedNotes.length + (pinnedNotes.isNotEmpty ? 1 : 0);

              // Show pinned header
              if (pinnedNotes.isNotEmpty && index == pinnedHeaderIndex) {
                return const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(
                    '📌 Pinned',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }

              // Show others header
              if (otherNotes.isNotEmpty && index == othersHeaderIndex) {
                return const Padding(
                  padding: EdgeInsets.only(left: 8, top: 12, bottom: 4),
                  child: Text(
                    '📝 Others',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }

              final realIndex =
                  index -
                  (pinnedNotes.isNotEmpty && index > 0 ? 1 : 0) -
                  (otherNotes.isNotEmpty && index > othersHeaderIndex ? 1 : 0);

              final note = combinedNotes[realIndex];
              return _buildNoteCard(note);
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateNoteScreen(notesBox: notesBox),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final formattedDate = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(note.updatedAt ?? note.date);

    return Dismissible(
      
      key: Key(note.id),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNoteById(note.id),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        color: Color(note.colorValue ?? Colors.white.value),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          trailing: IconButton(
            icon: Icon(
              note.isPinned == true ? Icons.push_pin : Icons.push_pin_outlined,
              color: note.isPinned == true ? Colors.blue : Colors.grey,
            ),
            onPressed: () => _togglePin(note),
          ),
          title: Text(
            note.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                note.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Updated: $formattedDate',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
          onTap: () {
            final index = notesBox.values.toList().indexWhere(
              (n) => n.id == note.id,
            );
            if (index != -1) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => NoteDetailScreen(noteIndex: index, note: note),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
