import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/compress_data.dart';
import 'data/note.dart';
import 'note_detail_screen.dart';
import 'create_note_screen.dart';
import 'data/sync/sync_status.dart';
import 'data/sync/sync_provider.dart';
import 'data/sync/note_sync_provider.dart';
import 'widgets/header_delegate.dart';
import 'widgets/note_list.dart';
import 'widgets/search_header.dart';

// Provider for notes with sync
final notesProvider = FutureProvider.family<List<Note>, String?>((
  ref,
  categoryId,
) async {
  final syncService = ref.read(noteSyncProvider);
  return syncService.getNotesByCategory(categoryId);
});

class NotesScreen extends ConsumerStatefulWidget {
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
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  late final Box<Note> box;
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  final FocusNode searchFocusNode = FocusNode();

  // Selection state
  final Set<int> _selectedKeys = {};
  bool _selectionMode = false;

<<<<<<< HEAD
  @override
  void initState() {
    super.initState();
    box = widget.notesBox;
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      if (searchController.text.isEmpty) searchFocusNode.unfocus();
      setState(() {});
=======
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
>>>>>>> origin/dev_pcoder
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.removeListener(_onSearchChanged);
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
      setState(() {});
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
    try {
      final keysToDelete = _selectedKeys.toList();
      final notesToDelete =
          keysToDelete.map((key) => box.get(key)).whereType<Note>().toList();

      // Delete from local storage
      await box.deleteAll(keysToDelete);

      // Delete from server if category has sync enabled
      if (widget.filterCategoryId != null) {
        final syncService = ref.read(noteSyncProvider);
        await Future.wait(
          notesToDelete.map((note) => syncService.deleteNote(note.id)),
        );
      }

      // Refresh the notes list
      ref.invalidate(notesProvider(widget.filterCategoryId));

      _clearSelection();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting notes: $e')));
      }
    }
  }

  Future<void> _togglePin(Note note) async {
    setState(() {
<<<<<<< HEAD
      note.isPinned = !(note.isPinned);
=======
      // Force rebuild immediately
      note.isPinned = !(note.isPinned ?? false);
>>>>>>> origin/dev_pcoder
      note.updatedAt = DateTime.now();
    });
    await note.save();
    setState(() {});
  }

  Future<void> _deleteNote(Note note) async {
    try {
      // Delete from local storage
      await note.delete();

      // Delete from server if category has sync enabled
      if (widget.filterCategoryId != null) {
        final syncService = ref.read(noteSyncProvider);
        await syncService.deleteNote(note.id);
      }

      // Refresh the notes list
      ref.invalidate(notesProvider(widget.filterCategoryId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting note: $e')));
      }
    }
  }

<<<<<<< HEAD
  Widget _buildPinnedHeader(List<Note> allNotes) {
    final hasPinned = allNotes.any((n) => n.isPinned == true);
    return hasPinned
        ? SliverPersistentHeader(
          pinned: true,
          delegate: HeaderDelegate('📌 Pinned'),
        )
        : const SliverToBoxAdapter();
  }

  Widget _buildOtherHeader(List<Note> allNotes) {
    final hasPinned = allNotes.any((n) => n.isPinned == true);
    return hasPinned
        ? const SliverToBoxAdapter()
        : SliverPersistentHeader(
          pinned: true,
          delegate: HeaderDelegate('📝 Others'),
        );
  }

=======
>>>>>>> origin/dev_pcoder
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

<<<<<<< HEAD
  Widget _buildSyncButton() {
    final syncStatus = ref.watch(syncStatusProvider);

    if (widget.filterCategoryId == null) {
      return const SizedBox.shrink();
    }

    IconData getIcon() {
      switch (syncStatus) {
        case SyncStatus.notSynced:
          return Icons.cloud_upload_outlined;
        case SyncStatus.syncing:
          return Icons.sync;
        case SyncStatus.synced:
          return Icons.cloud_done;
        case SyncStatus.error:
          return Icons.cloud_off;
      }
    }

    return IconButton(
      icon: Icon(getIcon()),
      onPressed:
          syncStatus == SyncStatus.syncing
              ? null
              : () async {
                try {
                  final syncNotes = ref.read(syncNotesProvider);
                  final result = await syncNotes(
                    widget.filterCategoryId!,
                    context,
                  );

                  if (result.success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Successfully synced ${result.syncedNoteIds.length} notes',
                        ),
                      ),
                    );
                    // Refresh notes after sync
                    ref.invalidate(notesProvider(widget.filterCategoryId));
                  }
                } catch (e) {
                  // Error already shown via dialog
                }
              },
      tooltip: ref.watch(syncErrorProvider) ?? 'Sync notes to cloud',
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider(widget.filterCategoryId));

    return notesAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, stack) => Scaffold(
            body: Center(child: Text('Error loading notes: $error')),
          ),
      data: (allNotes) {
        final query = searchController.text.toLowerCase();
        final filtered =
            query.isEmpty
                ? allNotes
                : allNotes.where((note) {
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
          appBar: _buildAppBar(filtered),
          body: GestureDetector(
            onTap: () => searchFocusNode.unfocus(),
            child: CustomScrollView(
              slivers: [
                if (!_selectionMode) _buildMainAppBar(),
                if (allNotes.isNotEmpty) ...[
                  SliverPersistentHeader(
                    floating: true,
                    pinned: false,
                    delegate: SearchHeader(
                      child: _buildSearchField(),
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

                    _buildNotesList(otherNotes),
                  ],
                  const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                ],
                if (allNotes.isEmpty) _buildEmptyState(),
              ],
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(List<Note> filtered) {
    if (_selectionMode) {
      return AppBar(
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
                      ? const Color(0xff0045F3)
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
      );
    }
    return PreferredSize(preferredSize: Size.zero, child: Container());
  }

  Widget _buildSearchField() {
    return Padding(
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
              const Icon(Icons.search, size: 24, color: Color(0xff0045F3)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  decoration: const InputDecoration(
                    hintText: "Search notes...",
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
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
    );
  }

  Widget _buildMainAppBar() {
    return SliverAppBar(
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      title: Text(widget.appBarTitle),
      centerTitle: true,
      pinned: true,
      elevation: 1,
      actions: [_buildSyncButton()],
    );
  }

  Widget _buildNotesList(List<Note> notes) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, idx) => NoteListItem(
          note: notes[idx],
          onTap: () => _onTapNote(notes[idx]),
          onPin: () => _togglePin(notes[idx]),
          onDelete: () => _deleteNote(notes[idx]),
          selectionMode: _selectionMode,
          selected: _selectedKeys.contains(notes[idx].key),
          onLongPress: () => _onLongPressNote(notes[idx]),
        ),
        childCount: notes.length,
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No notes found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tap + to create your first note',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      tooltip: 'Create Note',
      onPressed: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (_) => CreateNoteScreen(
                  notesBox: box,
                  categoryId: widget.filterCategoryId,
                ),
          ),
        );
        ref.invalidate(notesProvider(widget.filterCategoryId));
      },
      backgroundColor: const Color(0xff0045F3),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }

  void _openDetail(Note note) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteDetailScreen(noteId: note.id)),
    );
    // Refresh notes list after returning from detail screen
    ref.invalidate(notesProvider(widget.filterCategoryId));
=======
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
>>>>>>> origin/dev_pcoder
  }
}
