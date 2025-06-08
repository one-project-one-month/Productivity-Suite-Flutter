import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:productivity_suite_flutter/budgets/models/category_model.dart';
import 'package:productivity_suite_flutter/budgets/models/income_model.dart';
import 'package:productivity_suite_flutter/budgets/models/transcation_model.dart';
import 'package:productivity_suite_flutter/budgets/providers/category_provider.dart';
import 'package:productivity_suite_flutter/budgets/providers/income_provider.dart';
import 'package:productivity_suite_flutter/budgets/providers/transcation_provider.dart';
import 'package:provider/provider.dart';

class IncomePage extends StatelessWidget {
  const IncomePage({super.key});

  void _showCustomDialog(
    BuildContext context,
    TextEditingController txtController,
    List<CategoryModel> categories,
    String categoryId,
    void Function(String)? onTapCategories,
    void Function()? onTapConfirm,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create Income'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: txtController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Amount',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select a category',
                  border: OutlineInputBorder(),
                ),
                value: categoryId.toString(),
                items:
                    categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.id.toString(),
                        child: Text(category.name),
                      );
                    }).toList(),
                onChanged: (newValue) {
                  onTapCategories!(newValue!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                onTapConfirm!();
                Navigator.of(context).pop();
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final incomeProvider = Provider.of<IncomeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Income Update",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        actions: [
          Selector<CategoryProvider, List<CategoryModel>>(
            builder:
                (context, categoryList, child) => IconButton(
                  onPressed: () {
                    _showCustomDialog(
                      context,
                      incomeProvider.txtAmount,
                      categoryList,
                      incomeProvider.selecteCategoryId.toString(),
                      (value) {},
                      () {
                        incomeProvider.post();
                      },
                    );
                  },
                  icon: Icon(Icons.add),
                ),
            selector:
                (context, categoryProvider) => categoryProvider.categories,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Consumer<IncomeProvider>(
          builder:
              (context, provider, child) => ListView.separated(
                separatorBuilder: (context, index) => Divider(),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: provider.incomesList.length,
                itemBuilder: (context, index) {
                  IncomeModel obj = provider.incomesList[index];
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          flex: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                obj.categoryName ?? "No Category",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                obj.amount.toString(),
                                style: TextStyle(
                                  color: const Color.fromARGB(
                                    255,
                                    131,
                                    131,
                                    131,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Flexible(
                          flex: 2,
                          child: IconButton(
                            onPressed: () async {
                              final success = await provider.removeIncomes(
                                obj.id!,
                              );
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Income deleted!"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Income is not deleted!"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.delete),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
      ),
    );
  }
}
