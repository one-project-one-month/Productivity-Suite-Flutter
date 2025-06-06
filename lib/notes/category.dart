import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';
import 'package:productivity_suite_flutter/notes/notes_screen.dart';
import 'package:productivity_suite_flutter/notes/provider/cat_sync_provider.dart';
import 'package:productivity_suite_flutter/notes/provider/note_sync_provider.dart';
import 'package:productivity_suite_flutter/notes/repository/category_repository.dart';
import 'package:productivity_suite_flutter/notes/widgets/color_picker.dart';
import 'package:productivity_suite_flutter/notes/widgets/folder_shape.dart';

final categoryListProvider = FutureProvider<List<Category>>((ref) async {
  final syncService = ref.read(categorySyncProvider);
  return await syncService.getCategories();
});
final noteListProvider = FutureProvider.family<List<Note>, String?>((
  ref,
  categoryId,
) async {
  final syncService = ref.watch(noteSyncProvider);
  return syncService.getNotesByCategory(categoryId);
});

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  late final CategorySyncService _syncService;
  bool _isloading = false;
  //final Box<Category> _categoriesBox = Hive.box<Category>('categoriesBox');

  @override
  void initState() {
    super.initState();
    _syncService = ref.read(categorySyncProvider);
    _syncCategories();
  }

  Future<void> _syncCategories() async {
    try {
      await _syncService.syncCategories();
    } catch (e) {
      _showError('Sync failed: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteCategory(Category category) async {
    setState(() => _isloading = true);
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Delete "${category.name}"?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              TextButton(
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      try {
        await _syncService.deleteCategory(category.id);
        ref.invalidate(categoryListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category "${category.name}" deleted')),
        );
      } catch (e) {
        _showError('Delete failed: [31m${e.toString()}[0m');
      }
    }
    if (mounted) setState(() => _isloading = false); // Hide loading
  }

  void _showCategoryDialog({Category? category}) {
    String categoryName = category?.name ?? '';
    Color selectedColor =
        category != null ? Color(category.colorValue) : const Color(0xff0045F3);
    final nameController = TextEditingController(text: categoryName);
    bool isLoading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(
                    category == null ? 'Create New Category' : 'Edit Category',
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => categoryName = value,
                      ),
                      const SizedBox(height: 16),
                      ColorPicker(
                        initialColor: selectedColor,
                        onColorChanged: (color) => selectedColor = color,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xff0045F3)),
                      ),
                    ),
                    isLoading
                        ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                        : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          onPressed: () async {
                            if (categoryName.isEmpty) return;
                            setState(() => isLoading = true);
                            if (!mounted) return;
                            try {
                              final newCat = Category(
                                id: category?.id,
                                name: categoryName,
                                colorValue: selectedColor.value,
                              );

                              if (category == null) {
                                await _syncService.createCategory(newCat);
                              } else {
                                await _syncService.updateCategory(newCat);
                              }

                              ref.invalidate(
                                categoryListProvider,
                              ); // 🔁 Re-fetch categories
                              if (mounted) Navigator.pop(context);
                            } catch (e) {
                              if (mounted)
                                _showError('Failed: [31m${e.toString()}[0m');
                            } finally {
                              if (mounted) setState(() => isLoading = false);
                            }
                          },
                          child: Text(
                            category == null ? 'Create' : 'Save',
                            style: const TextStyle(color: Color(0xff0045F3)),
                          ),
                        ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notes'),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.0),
                child: Text(
                  "Note Categories",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                ),
              ),
              // Expanded(
              //   child: ValueListenableBuilder(
              //   //  valueListenable:// _categoriesBox.listenable(),
              //     builder: (ctx, Box<Category> box, _) {
              //       final categories = box.values.toList();
              //       if (categories.isEmpty) {
              //         return const Center(
              //           child: Text(
              //             'No categories yet.\nTap + to create your first folder!',
              //             textAlign: TextAlign.center,
              //             style: TextStyle(color: Colors.grey),
              //           ),
              //         );
              //       }

              //       return GridView.builder(
              //         padding: const EdgeInsets.all(10),
              //         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              //           crossAxisCount: 2,
              //           childAspectRatio: 3 / 2,
              //           crossAxisSpacing: 10,
              //           mainAxisSpacing: 10,
              //         ),
              //         itemCount: categories.length,
              //         itemBuilder: (ctx, idx) {
              //           final cat = categories[idx];
              //           return Card(
              //             elevation: 2,
              //             shape: RoundedRectangleBorder(
              //               borderRadius: BorderRadius.circular(12),
              //             ),
              //             child: Stack(
              //               children: [
              //                 Positioned.fill(
              //                   child: InkWell(
              //                     borderRadius: BorderRadius.circular(12),
              //                     onTap: () async {
              //                       await Navigator.push(
              //                         context,
              //                         MaterialPageRoute(
              //                           builder:
              //                               (_) =>
              //                                   CategoryNotesScreen(category: cat),
              //                         ),
              //                       );
              //                       if (mounted) _syncCategories();
              //                     },
              //                     child: FolderShapeWithBorder(
              //                       label: cat.name,
              //                       catID: cat.id,
              //                       iconData: cat.name,
              //                       color: Color(cat.colorValue),
              //                       borderColor: Color(cat.colorValue),
              //                     ),
              //                   ),
              //                 ),
              //                 Positioned(
              //                   top: 24,
              //                   right: 0,
              //                   child: PopupMenuButton<String>(
              //                     icon: const Icon(
              //                       Icons.more_vert,
              //                       color: Colors.white,
              //                     ),
              //                     onSelected: (value) {
              //                       if (value == 'edit') {
              //                         _showCategoryDialog(category: cat);
              //                       } else if (value == 'delete') {
              //                         _deleteCategory(cat);
              //                       }
              //                     },
              //                     itemBuilder:
              //                         (_) => [
              //                           const PopupMenuItem(
              //                             value: 'edit',
              //                             child: Text('Edit'),
              //                           ),
              //                           const PopupMenuItem(
              //                             value: 'delete',
              //                             child: Text(
              //                               'Delete',
              //                               style: TextStyle(color: Colors.red),
              //                             ),
              //                           ),
              //                         ],
              //                   ),
              //                 ),
              //               ],
              //             ),
              //           );
              //         },
              //       );
              //     },
              //   ),
              // ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(categoryListProvider);

                    await ref.read(categoryListProvider.future);
                  },
                  child: Consumer(
                    builder: (context, ref, _) {
                      final asyncCategories = ref.watch(categoryListProvider);

                      return asyncCategories.when(
                        data: (categories) {
                          if (categories.isEmpty) {
                            return const Center(
                              child: Text(
                                'No categories yet.\nTap + to create your first folder!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(10),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 3 / 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: categories.length,
                            itemBuilder: (ctx, idx) {
                              final cat = categories[idx];

                              final notesAsync = ref.watch(
                                noteListProvider(cat.id),
                              );

                              return notesAsync.when(
                                data: (notes) {
                                  final noteCount = notes.length;
                                  return Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) =>
                                                          CategoryNotesScreen(
                                                            category: cat,
                                                          ),
                                                ),
                                              );
                                              if (mounted) {
                                                ref.invalidate(
                                                  noteListProvider(cat.id),
                                                );
                                                ref.invalidate(
                                                  categoryListProvider,
                                                );
                                              }
                                            },
                                            child: FolderShapeWithBorder(
                                              label: cat.name,
                                              catID: cat.id,
                                              countNotesInCategory: noteCount,
                                              iconData: cat.name,
                                              color: Color(cat.colorValue),
                                              borderColor: Color(
                                                cat.colorValue,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 24,
                                          right: 0,
                                          child: PopupMenuButton<String>(
                                            icon: const Icon(
                                              Icons.more_vert,
                                              color: Colors.white,
                                            ),
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _showCategoryDialog(
                                                  category: cat,
                                                );
                                              } else if (value == 'delete') {
                                                _deleteCategory(cat);
                                              }
                                            },
                                            itemBuilder:
                                                (_) => const [
                                                  PopupMenuItem(
                                                    value: 'edit',
                                                    child: Text('Edit'),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                loading:
                                    () => Card(
                                      elevation: 2,
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child:
                                            CircularProgressIndicator.adaptive(),
                                      ),
                                    ),
                                error:
                                    (error, _) => Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text('Error: $error'),
                                      ),
                                    ),
                              );
                            },
                          );
                        },
                        loading:
                            () => const Center(
                              child: CircularProgressIndicator.adaptive(),
                            ),
                        error:
                            (err, stack) => Center(child: Text('Error: $err')),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_isloading)
            const Center(child: CircularProgressIndicator.adaptive()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create New Category',
        onPressed: () => _showCategoryDialog(),
        backgroundColor: const Color(0xff0045F3),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class CategoryNotesScreen extends StatelessWidget {
  final Category category;
  const CategoryNotesScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return NotesScreen(
      notesBox: Hive.box<Note>('notesBox'),
      filterCategoryId: category.id,
      appBarTitle: category.name,
    );
  }
}
