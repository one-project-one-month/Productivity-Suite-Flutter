import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';
import 'package:productivity_suite_flutter/notes/note_detail_screen.dart';
import 'package:productivity_suite_flutter/notes/create_note_screen.dart';
import 'package:intl/intl.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final Box<Note> notesBox = Hive.box<Note>('notesBox');
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  final FocusNode searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();

      _debounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          if (searchController.text.isEmpty) {
            searchFocusNode.unfocus();
          }
          setState(() {});
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _togglePin(Note note) async {
    note
      ..isPinned = !(note.isPinned ?? false)
      ..updatedAt = DateTime.now();
    await note.save();
  }

  Future<void> _deleteNote(Note note) async {
    await note.delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ValueListenableBuilder<Box<Note>>(
        valueListenable: notesBox.listenable(),
        builder: (context, box, _) {
          final query = searchController.text.toLowerCase();
          final allNotes = box.values;
          final filtered =
              query.isEmpty
                  ? allNotes
                  : allNotes.where((note) {
                    final lowerTitle = note.title.toLowerCase();
                    final lowerDesc = note.description.toLowerCase();
                    return lowerTitle.contains(query) ||
                        lowerDesc.contains(query);
                  });
          final pinnedNotes =
              filtered.where((n) => n.isPinned == true).toList();
          final otherNotes = filtered.where((n) => n.isPinned != true).toList();

          return GestureDetector(
            onTap: () => searchFocusNode.unfocus(),
            child: CustomScrollView(
              // key: ValueKey('${pinnedNotes.length}-${otherNotes.length}-$query'),
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.white,
                  title: const Text('Notes'),
                  centerTitle: true,
                  pinned: true,
                  elevation: 1,
                ),
                // Floating search bar
                SliverPersistentHeader(
                  floating: true,
                  pinned: false,
                  delegate: _SearchHeader(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Material(
                        color: Colors.white,
                        elevation: 2,
                        borderRadius: BorderRadius.circular(8),
                        child: TextField(
                          controller: searchController,
                          focusNode: searchFocusNode,
                          decoration: InputDecoration(
                            hintText: 'Search notes...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon:
                                searchController.text.isNotEmpty
                                    ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => searchController.clear(),
                                    )
                                    : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    maxExtent: 64,
                    minExtent: 64,
                  ),
                ),
                if (pinnedNotes.isNotEmpty) ...[
                  SliverPersistentHeader(
                    pinned: true,

                    delegate: _HeaderDelegate('📌 Pinned'),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, idx) => NoteListItem(
                        note: pinnedNotes[idx],
                        onTap: () => _openDetail(pinnedNotes[idx]),
                        onPin: () => _togglePin(pinnedNotes[idx]),
                        onDelete: () => _deleteNote(pinnedNotes[idx]),
                      ),
                      childCount: pinnedNotes.length,
                    ),
                  ),
                ],
                if (otherNotes.isNotEmpty) ...[
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _HeaderDelegate('📝 Others'),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, idx) => NoteListItem(
                        note: otherNotes[idx],
                        onTap: () => _openDetail(otherNotes[idx]),
                        onPin: () => _togglePin(otherNotes[idx]),
                        onDelete: () => _deleteNote(otherNotes[idx]),
                      ),
                      childCount: otherNotes.length,
                    ),
                  ),
                ],

                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Note',
        onPressed:
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateNoteScreen(notesBox: notesBox),
              ),
            ),
        elevation: 3,
        backgroundColor: Colors.blueAccent,
        mini: false,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  void _openDetail(Note note) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)));
  }
}

class _SearchHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  @override
  final double maxExtent;
  @override
  final double minExtent;

  _SearchHeader({
    required this.child,
    required this.maxExtent,
    required this.minExtent,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: shrinkOffset < maxExtent ? 1.0 : 0.0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

class NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const NoteListItem({
    super.key,
    required this.note,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'MMMM d, h:mm a',
    ).format(note.updatedAt ?? note.date);

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showActions(context),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (note.colorValue != null
                    ? Color(note.colorValue!).withOpacity(0.2)
                    : Colors.grey.shade100),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Pin Icon
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      note.isPinned! ? Icons.push_pin : Icons.push_pin_outlined,
                      color:
                          note.isPinned!
                              ? const Color.fromARGB(255, 8, 0, 248)
                              : Colors.grey,
                    ),
                    onPressed: onPin,
                  ),
                ],
              ),

              Text(
                note.description,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _action(ctx, Icons.edit, 'Edit', onTap),
                _action(
                  ctx,
                  Icons.push_pin,
                  note.isPinned! ? 'Unpin' : 'Pin',
                  onPin,
                ),
                _action(ctx, Icons.delete, 'Delete', onDelete),
              ],
            ),
          ),
    );
  }

  Widget _action(
    BuildContext ctx,
    IconData icon,
    String label,
    VoidCallback cb,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(ctx).primaryColor.withOpacity(0.1),
          child: IconButton(
            icon: Icon(icon, color: Theme.of(ctx).primaryColor),
            onPressed: () {
              Navigator.of(ctx).pop();
              cb();
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  const _HeaderDelegate(this.title);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    alignment: Alignment.centerLeft,
    child: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  );

  @override
  double get maxExtent => 40;
  @override
  double get minExtent => 40;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
