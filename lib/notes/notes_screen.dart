import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:productivity_suite_flutter/notes/data/compress_data.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';
import 'package:productivity_suite_flutter/notes/note_detail_screen.dart';
import 'package:productivity_suite_flutter/notes/create_note_screen.dart';

import 'package:productivity_suite_flutter/notes/widgets/header_Delegate.dart';
import 'package:productivity_suite_flutter/notes/widgets/note_list.dart';
import 'package:productivity_suite_flutter/notes/widgets/search_header.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final Box<Note> notesBox = Hive.box<Note>('notesBox');
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  final FocusNode searchFocusNode = FocusNode();

  // Selection state
  final Set<int> _selectedKeys = {};
  bool _selectionMode = false;

  void _onLongPressNote(Note note) {
    setState(() {
      _selectionMode = true;
      _selectedKeys.add(note.key as int);
    });
  }

  void _onTapNote(Note note) {
    if (_selectionMode) {
      setState(() {
        final key = note.key as int;
        if (_selectedKeys.contains(key)) {
          _selectedKeys.remove(key);
          if (_selectedKeys.isEmpty) _selectionMode = false;
        } else {
          _selectedKeys.add(key);
        }
      });
    } else {
      _openDetail(note);
    }
  }

  void _selectAll(Iterable<Note> notes) {
    setState(() {
      _selectedKeys.addAll(notes.map((n) => n.key as int));
      _selectionMode = true;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedKeys.clear();
      _selectionMode = false;
    });
  }

  void _deleteSelected() async {
    final notesToDelete =
        notesBox.values
            .where((n) => _selectedKeys.contains(n.key as int))
            .toList();
    for (final note in notesToDelete) {
      await note.delete();
    }
    _clearSelection();
  }

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 200), () {
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
    setState(() {
      // Force rebuild immediately
      note.isPinned = !(note.isPinned ?? false);
      note.updatedAt = DateTime.now();
    });
    await note.save();
  }

  Future<void> _deleteNote(Note note) async {
    await note.delete();
  }

  Widget _buildPinnedNotes(List<Note> pinnedNotes) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, idx) => NoteListItem(
          note: pinnedNotes[idx],
          onTap: () => _onTapNote(pinnedNotes[idx]),
          onPin: () => _togglePin(pinnedNotes[idx]),
          onDelete: () => _deleteNote(pinnedNotes[idx]),
          selectionMode: _selectionMode,
          selected: _selectedKeys.contains(pinnedNotes[idx].key),
          onLongPress: () => _onLongPressNote(pinnedNotes[idx]),
        ),
        childCount: pinnedNotes.length,
      ),
    );
  }

  Widget _buildPinnedHeader() {
    return ValueListenableBuilder<Box<Note>>(
      valueListenable: notesBox.listenable(),
      builder: (context, box, _) {
        final hasPinnedNotes = box.values.any((n) => n.isPinned == true);
        return hasPinnedNotes
            ? SliverPersistentHeader(
              pinned: true,
              delegate: HeaderDelegate('📌 Pinned'),
            )
            : const SliverToBoxAdapter();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          _selectionMode
              ? AppBar(
                backgroundColor: Colors.white,
                title: Text('${_selectedKeys.length} selected'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.check_box,
                      color:
                          _selectedKeys.length == notesBox.length
                              ? Colors.blue
                              : null,
                    ),
                    tooltip:
                        _selectedKeys.length == notesBox.length
                            ? 'Deselect All'
                            : 'Select All',
                    onPressed: () {
                      if (_selectedKeys.length == notesBox.length) {
                        _clearSelection(); // Deselect all
                      } else {
                        _selectAll(notesBox.values); // Select all
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete Selected',
                    onPressed: _deleteSelected,
                  ),
                ],
              )
              : null,
      body: ValueListenableBuilder<Box<Note>>(
        valueListenable: notesBox.listenable(),
        builder: (context, box, _) {
          final query = searchController.text.toLowerCase();
          final allNotes =
              box.values.toList(); // Keep original Hive-managed notes

          final filtered =
              query.isEmpty
                  ? allNotes
                  : allNotes.where((note) {
                    final decompressedTitle =
                        CompressString.decompressString(
                          note.title,
                        ).toLowerCase();
                    final decompressedDesc =
                        CompressString.decompressString(
                          note.description,
                        ).toLowerCase();
                    return decompressedTitle.contains(query) ||
                        decompressedDesc.contains(query);
                  }).toList();

          final pinnedNotes =
              filtered.where((n) => n.isPinned == true).toList();
          final otherNotes = filtered.where((n) => n.isPinned != true).toList();
          ;
          return GestureDetector(
            onTap: () => searchFocusNode.unfocus(),
            child: CustomScrollView(
              slivers: [
                if (!_selectionMode)
                  SliverAppBar(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    title: const Text('Notes'),
                    centerTitle: true,
                    pinned: true,
                    elevation: 1,
                  ),
                if (notesBox.values.isNotEmpty)
                  // Floating search bar
                  SliverPersistentHeader(
                    floating: true,
                    pinned: false,
                    delegate: SearchHeader(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color.fromARGB(255, 0, 38, 255),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search,
                                    color: Color.fromARGB(255, 0, 38, 255),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: searchController,
                                      focusNode: searchFocusNode,
                                      decoration: const InputDecoration(
                                        hintText: "Search notes...",
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        hintStyle: TextStyle(
                                          color: Color.fromARGB(
                                            255,
                                            102,
                                            101,
                                            101,
                                          ),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (searchController.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      color: Colors.grey,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        searchController.clear();
                                        searchFocusNode.unfocus();
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      maxExtent: 60,
                      minExtent: 60,
                    ),
                  ),
                if (notesBox.values.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.note_add_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notes found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button to create your first note',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  _buildPinnedHeader(), //For Pin Header
                  if (pinnedNotes.isNotEmpty)
                    _buildPinnedNotes(pinnedNotes), //For Pin Note
                  if (otherNotes.isNotEmpty) ...[
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: HeaderDelegate('📝 Others'),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, idx) => NoteListItem(
                          note: otherNotes[idx],
                          onTap: () => _onTapNote(otherNotes[idx]),
                          onPin: () => _togglePin(otherNotes[idx]),
                          onDelete: () => _deleteNote(otherNotes[idx]),
                          selectionMode: _selectionMode,
                          selected: _selectedKeys.contains(otherNotes[idx].key),
                          onLongPress: () => _onLongPressNote(otherNotes[idx]),
                        ),
                        childCount: otherNotes.length,
                      ),
                    ),
                  ],
                  const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                ],
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
