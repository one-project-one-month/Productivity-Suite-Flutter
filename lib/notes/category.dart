import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';
import 'package:productivity_suite_flutter/notes/notes_screen.dart';
import 'package:productivity_suite_flutter/notes/widgets/color_picker.dart';
import 'package:productivity_suite_flutter/notes/widgets/folder_shape.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final Box<Category> _categoriesBox = Hive.box<Category>('categoriesBox');

  @override
  void initState() {
    super.initState();
  }

  void _delete(Category category) async {
    final confirm = await showDialog<bool>(
      context: context, // outer screen context, for `showDialog`
      builder:
          (dialogContext) => // dialog’s own context
              AlertDialog(
            title: Text('Delete "${category.name}"?'),
            content: Text('This action cannot be undone.'),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed:
                    () =>
                    // THIS pops _only_ the dialog
                    Navigator.of(dialogContext).pop(false),
              ),
              TextButton(
                child: Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed:
                    () =>
                    // THIS pops _only_ the dialog
                    Navigator.of(dialogContext).pop(true),
              ),
            ],
          ),
    );
    if (confirm == true) {
      // Delete all notes in this category first
      final notesBox = Hive.box<Note>('notesBox');
      final notesToDelete =
          notesBox.values.where((n) => n.categoryId == category.id).toList();
      for (final note in notesToDelete) {
        await note.delete();
      }
      // Now delete the category
      await category.delete();
      if (mounted) {
        if (Navigator.canPop(context)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Category "${category.name}" deleted')),
          );
        }
      }
    }
  }

  void _showeditDialog(Category category) {
    String categoryName = category.name;
    Color selectedColor = Color(category.colorValue);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController.fromValue(
                    TextEditingValue(
                      text: categoryName,
                      selection: TextSelection.collapsed(
                        offset: categoryName.length,
                      ),
                    ),
                  ),
                  onChanged: (value) => categoryName = value,
                ),
                SizedBox(height: 20),
                ColorPicker(
                  initialColor: selectedColor,
                  onColorChanged: (color) => selectedColor = color,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
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
                onPressed: () {
                  if (categoryName.isNotEmpty) {
                    category.name = categoryName;
                    category.colorValue = selectedColor.value;
                    category.save(); // Update existing category
                    Navigator.pop(context);
                  }
                },
                child: Text('Save', style: TextStyle(color: Color(0xff0045F3))),
              ),
            ],
          ),
    );
  }

  void _showCreateCategoryDialog() {
    String categoryName = '';
    Color selectedColor = Color(0xff0045F3);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Create New Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Name',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(),
                  ),
                  onChanged: (value) => categoryName = value,
                ),
                SizedBox(height: 20),

                ColorPicker(
                  initialColor: selectedColor,
                  onColorChanged: (color) => selectedColor = color,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
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
                onPressed: () {
                  if (categoryName.isNotEmpty) {
                    final newCategory = Category(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: categoryName,
                      colorValue: selectedColor.value,
                    );
                    _categoriesBox.add(newCategory);
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  'Create',
                  style: TextStyle(color: Color(0xff0045F3)),
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
        title: Text('Notes'),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
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
                  return Center(
                    child: Text(
                      'No categories found\nTap + to create one',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return GridView.builder(
                  padding: EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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

                                if (mounted) {
                                  setState(() {});
                                }
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
                            top: 8,
                            bottom: 1,
                            right: 0,
                            child: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: Colors.white),
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _showeditDialog(cat);
                                    break;
                                  case 'delete':
                                    _delete(cat);
                                    break;
                                }
                              },
                              itemBuilder:
                                  (_) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
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
        onPressed: _showCreateCategoryDialog,

        backgroundColor: Color(0xff0045F3),
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
