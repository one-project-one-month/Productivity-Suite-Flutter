import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';
import 'package:productivity_suite_flutter/notes/notes_screen.dart';
import 'package:productivity_suite_flutter/notes/widgets/color_picker.dart';

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

  int _countNotesInCategory(String categoryId) {
    return Hive.box<Note>(
      'notesBox',
    ).values.where((note) => note.categoryId == categoryId).length;
  }

  Widget _buildColorPicker() {
    Color selectedColor = Color(_categoriesBox.values.first.colorValue);
    return ColorPicker(
      initialColor: selectedColor,
      onColorChanged: (color) {
        setState(() => selectedColor = color);
      },
      // Optional customizations:
      circleRadius: 14,
      selectedCircleRadius: 16,
      iconSize: 18,
    );
  }

  void _showEditCategoryDialog(Category category) {
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
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (categoryName.isNotEmpty) {
                    category.name = categoryName;
                    category.colorValue = selectedColor.value;
                    category.save(); // Update existing category
                    Navigator.pop(context);
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showCreateCategoryDialog() {
    String categoryName = '';
    Color selectedColor = Color(0xFF2196F3);

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
                child: Text('Cancel'),
              ),
              ElevatedButton(
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
                child: Text('Create'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notes')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Text(
              "Category",
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
                      child: GestureDetector(
                        onLongPress: () => _showEditCategoryDialog(cat),
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => CategoryNotesScreen(category: cat),
                              ),
                            ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(cat.colorValue),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.folder_open, color: Colors.white70),
                              SizedBox(height: 8),
                              Text(
                                cat.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Notes: ${_countNotesInCategory(cat.id)}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
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
        onPressed: _showCreateCategoryDialog,
        child: Icon(Icons.add),
        tooltip: 'Create New Category',
      ),
    );
  }
}

class CategoryNotesScreen extends StatelessWidget {
  final Category category;
  CategoryNotesScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    return NotesScreen(
      notesBox: Hive.box<Note>('notesBox'),
      filterCategoryId: category.id,
      appBarTitle: category.name,
    );
  }
}
