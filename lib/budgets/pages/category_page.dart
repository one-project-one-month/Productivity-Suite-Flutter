import 'package:flutter/material.dart';
import 'package:productivity_suite_flutter/budgets/providers/category_provider.dart';
import 'package:provider/provider.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Category",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final TextEditingController controller =
                      TextEditingController();
                  return AlertDialog(
                    title: const Text("Add Category"),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Enter category name",
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          if (controller.text.isNotEmpty) {
                            await categoryProvider.post(controller.text);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Add"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder:
            (context, provider, child) =>
                categoryProvider.categories.isEmpty
                    ? const Center(child: Text("No categories available"))
                    : ListView.separated(
                      separatorBuilder: (context, index) => const Divider(),
                      itemCount: provider.categories.length,
                      itemBuilder: (context, index) {
                        final category = provider.categories[index];
                        return Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(child: Text(category.name)),
                              IconButton(
                                onPressed: () {
                                  final TextEditingController controller =
                                      TextEditingController(
                                        text: category.name,
                                      );
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text("Edit Category"),
                                        content: TextField(
                                          controller: controller,
                                          decoration: const InputDecoration(
                                            hintText: "Enter new name",
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              if (controller.text.isNotEmpty) {
                                                categoryProvider.edit(
                                                  category.id,
                                                  controller.text,
                                                );
                                                Navigator.pop(context);
                                              }
                                            },
                                            child: const Text("Update"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                onPressed: () {
                                  categoryProvider.removeCategory(category.id);
                                },
                                icon: const Icon(Icons.delete),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
      ),
    );
  }
}
