import 'package:flutter/foundation.dart';
import 'package:productivity_suite_flutter/budgets/models/category_model.dart';
import 'package:productivity_suite_flutter/budgets/network_service.dart';

class CategoryProvider extends ChangeNotifier {
  List<CategoryModel> categories = [];

  Future<void> getCategories() async {
    final _categories = await ApiService.get(ApiEndPoints.category, 3);
    categories =
        (_categories.data['data'] as Iterable)
            .map((json) => CategoryModel.fromJson(json))
            .toList();
    notifyListeners();
  }

  Future<void> post(String category) async {
    Map<String, dynamic> request = {
      "name": category,
      "description": category,
      "type": 3,
    };
    await ApiService.post(request, ApiEndPoints.category)
        .then((newCategory) async {
          await getCategories();
        })
        .catchError((error) {
          print("Error adding category: $error");
        });
    notifyListeners();
  }

  Future<void> removeCategory(int id) async {
    await ApiService.delete(id, ApiEndPoints.category)
        .then((success) async {
          await getCategories();
        })
        .catchError((error) {
          print("Error deleting category: $error");
        });
    notifyListeners();
  }

  Future<void> edit(int index, String newCategory) async {
    Map<String, dynamic> request = {
      "name": newCategory,
      "description": newCategory,
      "type": 3,
    };

    await ApiService.edit(index.toString(), request, ApiEndPoints.category)
        .then((success) async {
          if (success) {
            await getCategories();
          }
        })
        .catchError((error) {
          print("Error editing category: $error");
        });

    notifyListeners();
  }
}
