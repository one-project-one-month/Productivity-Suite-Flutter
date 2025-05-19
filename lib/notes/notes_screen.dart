
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:productivity_suite_flutter/notes/data/compress_data.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';
import 'package:productivity_suite_flutter/notes/note_detail_screen.dart';
import 'package:productivity_suite_flutter/notes/create_note_screen.dart';
import 'package:productivity_suite_flutter/notes/widgets/header_delegate.dart';
import 'package:productivity_suite_flutter/notes/widgets/note_list.dart';
import 'package:productivity_suite_flutter/notes/widgets/search_header.dart';

class NotesScreen extends StatefulWidget {
  final Box<Note> notesBox;
  final String? filterCategoryId;
  final String appBarTitle;

  const NotesScreen({
    super.key,
    required this.notesBox,
    this.filterCategoryId,
    required this.appBarTitle,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  // Reuse widget.notesBox instead of opening again
  late final Box<Note> box;
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  final FocusNode searchFocusNode = FocusNode();

  // Selection state
  final Set<int> _selectedKeys = {};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    box = widget.notesBox;

    // Debounce search input
    searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        if (searchController.text.isEmpty) searchFocusNode.unfocus();
        setState(
          () {},
        ); // Consider only calling setState when query actually changes
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void _onLongPressNote(Note note) {
    setState(() {
      _selectionMode = true;
      _selectedKeys.add(note.key as int);
    });
  }

  void _onTapNote(Note note) {
    if (_selectionMode) {
      final key = note.key as int;
      setState(() {
        if (_selectedKeys.contains(key)) {
          _selectedKeys.remove(key);
          if (_selectedKeys.isEmpty) _selectionMode = false;
        } else {
          _selectedKeys.add(key);
        }
      });
    } else {
      _openDetail(note);
      setState(() {}); // Ensure _openDetail is defined below
    }
  }

  void _selectAll(List<Note> notes) {
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

  Future<void> _deleteSelected() async {
    // Use deleteAll for batch performance
    final keysToDelete = _selectedKeys.toList();
    await box.deleteAll(keysToDelete);
    _clearSelection();
  }

  Future<void> _togglePin(Note note) async {
    setState(() {
      note.isPinned = !(note.isPinned);
      note.updatedAt = DateTime.now();
    });
    await note.save();
  }

  Future<void> _deleteNote(Note note) async {
    await note.delete();
  }

  Widget _buildPinnedHeader(List<Note> allNotes) {
    final hasPinned = allNotes.any((n) => n.isPinned == true);
    return hasPinned
        ? SliverPersistentHeader(
          pinned: true,
          delegate: HeaderDelegate('📌 Pinned'),
        )
        : const SliverToBoxAdapter();
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

  @override
  Widget build(BuildContext context) {
    final allNotes =
        box.values
            .where(
              (n) =>
                  widget.filterCategoryId == null ||
                  n.categoryId == widget.filterCategoryId,
            )
            .toList();

    final query = searchController.text.toLowerCase();
    final filtered =
        query.isEmpty
            ? allNotes
            : allNotes.where((note) {
              // Decompress once per note and cache if dataset is large
              final title =
                  CompressString.decompressString(note.title).toLowerCase();
              final desc =
                  CompressString.decompressString(
                    note.description,
                  ).toLowerCase();
              return title.contains(query) || desc.contains(query);
            }).toList();

    final pinnedNotes = filtered.where((n) => n.isPinned == true).toList();
    final otherNotes = filtered.where((n) => n.isPinned != true).toList();

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
                          _selectedKeys.length == filtered.length
                              ? Color(0xff0045F3)
                              : null,
                    ),
                    tooltip:
                        _selectedKeys.length == filtered.length
                            ? 'Deselect All'
                            : 'Select All',
                    onPressed: () {
                      if (_selectedKeys.length == filtered.length) {
                        _clearSelection();
                      } else {
                        _selectAll(filtered);
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
      body: GestureDetector(
        onTap: () => searchFocusNode.unfocus(),
        child: CustomScrollView(
          slivers: [
            if (!_selectionMode)
              SliverAppBar(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                title: Text(widget.appBarTitle),
                centerTitle: true,
                pinned: true,
                elevation: 1,
              ),
            if (allNotes.isNotEmpty) ...[
              SliverPersistentHeader(
                floating: true,
                pinned: false,
                delegate: SearchHeader(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Material(
                      elevation: 2,
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xff0045F3)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.search,
                              size: 24,
                              color: Color(0xff0045F3),
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
                                ),
                              ),
                            ),
                            if (searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
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
                  maxExtent: 60,
                  minExtent: 60,
                ),
              ),
              _buildPinnedHeader(filtered),
              if (pinnedNotes.isNotEmpty) _buildPinnedNotes(pinnedNotes),
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
            if (allNotes.isEmpty)
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
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to create your first note',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Note',
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (_) => CreateNoteScreen(
                    notesBox: box,
                    categoryId: widget.filterCategoryId,
                  ),
            ), // pass category
          );
          setState(() {});
        },
        backgroundColor: Color(0xff0045F3),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  void _openDetail(Note note) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)));
    setState(() {}); 
  }
}
