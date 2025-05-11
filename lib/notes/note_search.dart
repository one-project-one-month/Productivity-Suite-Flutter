import 'package:flutter/material.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';
import 'package:productivity_suite_flutter/notes/note_detail_screen.dart';

class NotesSearchDelegate extends SearchDelegate {
  final List<Note> allNotes;

  NotesSearchDelegate(this.allNotes);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) {
    final filtered = allNotes.where((note) =>
        note.title.toLowerCase().contains(query.toLowerCase()) ||
        note.description.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: filtered.map((note) => ListTile(
        title: Text(note.title),
        subtitle: Text(note.description, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () {
          close(context, null);
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => NoteDetailScreen(noteIndex: allNotes.indexOf(note), note: note),
          ));
        },
      )).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}
