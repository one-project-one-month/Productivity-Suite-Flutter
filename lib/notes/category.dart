
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';
import 'package:productivity_suite_flutter/notes/notes_screen.dart';
import 'package:productivity_suite_flutter/notes/provider/cat_sync_provider.dart';
import 'package:productivity_suite_flutter/notes/widgets/color_picker.dart';
import 'package:productivity_suite_flutter/notes/widgets/folder_shape.dart';


class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  late final CategorySyncService _syncService;
  final Box<Category> _categoriesBox = Hive.box<Category>('categoriesBox');

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
        _syncCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category "${category.name}" deleted')),
        );
      } catch (e) {
        _showError('Delete failed: ${e.toString()}');
      }
    }
  }

  void _showCategoryDialog({Category? category}) {
    String categoryName = category?.name ?? '';
    Color selectedColor =
        category != null ? Color(category.colorValue) : const Color(0xff0045F3);
    final nameController = TextEditingController(text: categoryName);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xff0045F3)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: () async {
                  if (categoryName.isEmpty) return;

                  if (!mounted) return;
                  Navigator.pop(
                    context,
                  ); // Close immediately (loading indicator would go here)

                  try {
                    final newCat = Category(
                      id: category?.id,
                      name: categoryName,
                      colorValue: selectedColor.value,
                    );
                    category == null
                        ? await _syncService.createCategory(newCat)
                        : await _syncService.updateCategory(newCat);
                  } catch (e) {
                    _showError('Failed: ${e.toString()}');
                  }
                  if (mounted) {
                    _syncCategories(); // 🔁 Refresh category list after success
                  }
                },
                child: Text(
                  category == null ? 'Create' : 'Save',
                  style: const TextStyle(color: Color(0xff0045F3)),
                ),
              ),
            ],
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.0),
            child: Text(
              "Note Categories",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _categoriesBox.listenable(),
              builder: (ctx, Box<Category> box, _) {
                final categories = box.values.toList();
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3 / 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (ctx, idx) {
                    final cat = categories[idx];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) =>
                                            CategoryNotesScreen(category: cat),
                                  ),
                                );
                                if (mounted) _syncCategories();
                              },
                              child: FolderShapeWithBorder(
                                label: cat.name,
                                catID: cat.id,
                                iconData: cat.name,
                                color: Color(cat.colorValue),
                                borderColor: Color(cat.colorValue),
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
                                  _showCategoryDialog(category: cat);
                                } else if (value == 'delete') {
                                  _deleteCategory(cat);
                                }
                              },
                              itemBuilder:
                                  (_) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
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
