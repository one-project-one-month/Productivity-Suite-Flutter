import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:productivity_suite_flutter/notes/repository/note_repository.dart';
import 'data/compress_data.dart';
import 'data/note.dart';
import 'note_detail_screen.dart';
import 'create_note_screen.dart';
import 'data/sync/sync_status.dart';
import 'data/sync/sync_provider.dart';
import 'provider/note_sync_provider.dart';
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
  //  late final Box<Note> box;
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  final FocusNode searchFocusNode = FocusNode();

  // Selection state
  final Set<String> _selectedKeys = {};
  bool _selectionMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // box = widget.notesBox;
    searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant NotesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterCategoryId != oldWidget.filterCategoryId) {
      // Reset any sync-related state or flags here
      // Re-fetch notes
      ref.invalidate(notesProvider(widget.filterCategoryId));

      // Rebuild to ensure sync icon & UI update
      setState(() {});
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      if (searchController.text.isEmpty) searchFocusNode.unfocus();
      setState(() {});
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
      final key = note.id;
      if (key != '') {
        _selectedKeys.add(key);
      }
    });
  }

  void _onTapNote(Note note) {
    if (_selectionMode) {
      final key = note.id;
      String? parsedKey;
      parsedKey = key;
      if (parsedKey != '') {
        setState(() {
          if (_selectedKeys.contains(parsedKey)) {
            _selectedKeys.remove(parsedKey);
            if (_selectedKeys.isEmpty) _selectionMode = false;
          } else {
            _selectedKeys.add(parsedKey!);
          }
        });
      }
    } else {
      _openDetail(note);
      setState(() {});
    }
  }

  void _selectAll(List<Note> notes) {
    setState(() {
      _selectedKeys.clear();
      for (final n in notes) {
        final key = n.id;
        String? parsedKey;
        parsedKey = key;
        if (parsedKey != '') {
          _selectedKeys.add(parsedKey);
        }
      }
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
      final noteRepository = ref.read(noteRepositoryProvider);

      // Directly delete notes by id
      await Future.wait(
        keysToDelete.map((id) async {
          await noteRepository.deleteNote(id);
          // Uncomment if you want to delete from server as well
          // if (widget.filterCategoryId != null) {
          //   final syncService = ref.read(noteSyncProvider);
          //   await syncService.deleteNote(id);
          // }
        }),
      );

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

  // Future<void> _deleteSelected() async {
  //   try {
  //     final keysToDelete = _selectedKeys.toList();
  //     final notesToDelete =
  //         keysToDelete.map((key) => box.get(key)).whereType<Note>().toList();

  //     // Delete from local storage
  //     await box.deleteAll(keysToDelete);

  //     // Delete from server if category has sync enabled
  //     if (widget.filterCategoryId != null) {
  //       final syncService = ref.read(noteSyncProvider);
  //       await Future.wait(
  //         notesToDelete.map((note) => syncService.deleteNote(note.id)),
  //       );
  //     }

  //     // Refresh the notes list
  //     ref.invalidate(notesProvider(widget.filterCategoryId));

  //     _clearSelection();
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text('Error deleting notes: $e')));
  //     }
  //   }
  // }

  Future<void> _togglePin(Note note) async {
    try {
      final syncService = ref.watch(noteRepositoryProvider);
      final newPinnedStatus = !note.isPinned;
      await syncService.pinnedNote(note.id);
      note.isPinned = newPinnedStatus;
      setState(() {});
    } catch (e) {
      print('Failed to pin/unpin note: $e');
    }
  }
  // Future<void> _togglePin(Note note) async {
  //   setState(() {
  //     note.isPinned = !(note.isPinned);
  //     note.updatedAt = DateTime.now();
  //   });
  //   await note.save();
  //   setState(() {});
  // }

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
      delegate: SliverChildBuilderDelegate((context, idx) {
        final note = pinnedNotes[idx];
        final key = note.id;
        final isSelected = key != '' && _selectedKeys.contains(key);
        return NoteListItem(
          note: note,
          onTap: () => _onTapNote(note),
          onPinAsync: () async => await _togglePin(note),
          onDelete: () => _deleteNote(note),
          selectionMode: _selectionMode,
          selected: isSelected,
          onLongPress: () => _onLongPressNote(note),
        );
      }, childCount: pinnedNotes.length),
    );
  }

  Widget _buildSyncButton() {
    final categoryId = widget.filterCategoryId;
    if (categoryId == null) return const SizedBox.shrink();

    final syncStatus = ref.watch(syncStatusProvider);

    return IconButton(
      icon: _syncIcon(syncStatus),
      onPressed:
          syncStatus == SyncStatus.syncing
              ? null
              : () async {
                final syncNotes = ref.read(syncNotesProvider);
                final result = await syncNotes(categoryId, context);

                if (result.success && mounted) {
                  ref.invalidate(notesProvider(categoryId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sync completed successfully'),
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sync failed: ${result.error}')),
                  );
                }
              },
      tooltip: _syncTooltip(syncStatus),
    );
  }

  String _syncTooltip(SyncStatus status) {
    switch (status) {
      case SyncStatus.error:
        return 'Sync error';
      case SyncStatus.syncing:
        return 'Synchronizing notes...';
      case SyncStatus.synced:
        return 'Notes are up to date';
      default:
        return 'Sync notes with cloud';
    }
  }

  Icon _syncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.notSynced:
        return const Icon(Icons.cloud_upload_outlined);
      case SyncStatus.syncing:
        return const Icon(Icons.sync, color: Colors.blue);
      case SyncStatus.synced:
        return const Icon(Icons.cloud_done, color: Colors.green);
      case SyncStatus.error:
        return const Icon(Icons.cloud_off, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider(widget.filterCategoryId));

    return notesAsync.when(
      loading:
          () => const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          ),
      error:
          (error, stack) => Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(widget.appBarTitle),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Failed to load notes: ${error.toString()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      // Refresh the data
                      ref.invalidate(notesProvider(widget.filterCategoryId));

                      // Optional: Force rebuild if needed
                      setState(() {});
                    },
                    tooltip: 'Retry',
                    iconSize: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap to refresh',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
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
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(notesProvider(widget.filterCategoryId));

                await Future.delayed(const Duration(milliseconds: 300));
              },
              child: CustomScrollView(
                slivers: [
                  if (!_selectionMode) _buildMainAppBar(),
                  if (allNotes.isNotEmpty) ...[
                    // SliverPersistentHeader(
                    //   floating: true,
                    //   pinned: false,
                    //   delegate: SearchHeader(
                    //     child: _buildSearchField(),
                    //     maxExtent: 60,
                    //     minExtent: 60,
                    //   ),
                    // ),
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
      // actions: [_buildSyncButton()],
    );
  }

  Widget _buildNotesList(List<Note> notes) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, idx) {
        final note = notes[idx];
        final key = note.id;
        final isSelected = key != '' && _selectedKeys.contains(key);
        return NoteListItem(
          note: note,
          onTap: () => _onTapNote(note),
          onPinAsync: () async => await _togglePin(note),
          onDelete: () => _deleteNote(note),
          selectionMode: _selectionMode,
          selected: isSelected,
          onLongPress: () => _onLongPressNote(note),
        );
      }, childCount: notes.length),
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
                  //   notesBox: box,
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
      MaterialPageRoute(
        builder:
            (_) => NoteDetailScreen(
              noteId: note.id,
              categoryId: note.categoryId ?? "",
            ),
      ),
    );
    // Refresh notes list after returning from detail screen
    ref.invalidate(notesProvider(widget.filterCategoryId));
  }
}
