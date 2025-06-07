import 'package:flutter/cupertino.dart';
import 'package:productivity_suite_flutter/budgets/models/income_model.dart';
import 'package:productivity_suite_flutter/budgets/network_service.dart';

class IncomeProvider extends ChangeNotifier {
  IncomeProvider() {
    // getCombinedMessage();
  }
  List<IncomeModel> incomesList = [];
  TextEditingController txtAmount = TextEditingController();
  int? selecteCategoryId;

  // void getCombinedMessage() {
  //   final firstProvider = Provider.of<CategoryProvider>(context, listen: false);
  //   selecteCategoryId = firstProvider.categories.first.id;
  //   notifyListeners();
  // }

  Future<void> getIncomes() async {
    final _incomes = await ApiService.get(ApiEndPoints.income);
    incomesList =
        (_incomes.data['data'] as Iterable)
            .map((json) => IncomeModel.fromJson(json))
            .toList();

    notifyListeners();
  }

  Future<bool> post() async {
    if (selecteCategoryId == null || txtAmount.text.isEmpty) {
      print("Category or amount is not selected or empty");
      return false;
    }
    Map<String, dynamic> request = {
      "amount": int.tryParse(txtAmount.text ?? '0') ?? 0,
      "categoryId": selecteCategoryId,
    };
    return await ApiService.post(request, ApiEndPoints.income)
        .then((newCategory) async {
          await getIncomes();
          notifyListeners();
          return true;
        })
        .catchError((error) {
          print("Error adding Incomes: $error");
          return false;
        });
  }

  Future<bool> removeIncomes(int id) async {
    return await ApiService.delete(id, ApiEndPoints.income)
        .then((success) async {
          await getIncomes();
          notifyListeners();
          return true;
        })
        .catchError((error) {
          print("Error deleting Incomes: $error");
          return false;
        });
  }

  Future<void> edit(int index, String newCategory) async {
    Map<String, dynamic> request = {
      "name": newCategory,
      "description": newCategory,
      "type": 3,
    };

    await ApiService.edit(index.toString(), request, ApiEndPoints.income)
        .then((success) async {
          if (success) {
            await getIncomes();
          }
        })
        .catchError((error) {
          print("Error editing Incomes: $error");
        });

    notifyListeners();
  }
}
