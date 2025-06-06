import 'package:flutter/widgets.dart';
import 'package:productivity_suite_flutter/budgets/models/category_model.dart';
import 'package:productivity_suite_flutter/budgets/models/transcation_model.dart';
import 'package:productivity_suite_flutter/budgets/network_service.dart';

class TranscationProvider extends ChangeNotifier {
  CategoryModel? category;
  TextEditingController txtDescription = TextEditingController();
  TextEditingController txtAmount = TextEditingController();

  List<TranscationModel> transcationsList = [];

  void changeCategory(CategoryModel? newCategory) {
    category = newCategory;
    notifyListeners();
  }

  Future<void> getTranscations() async {
    await ApiService.get(ApiEndPoints.transcation)
        .then((transcations) async {
          transcationsList.clear();
          Iterable list = transcations.data['data'] as Iterable;

          list.forEach((transcation) {
            transcationsList.add(TranscationModel.fromJson(transcation));
          });
        })
        .catchError((error) {
          print("Error adding category: $error");
        });
    notifyListeners();
  }

  Future<bool> postNewTranscation() async {
    if (category == null) {
      return false;
    }
    Map<String, dynamic> request = {
      "amount": int.tryParse(txtAmount.text) ?? 0,
      "description": txtDescription.text,
      "transactionDate": DateTime.now().millisecondsSinceEpoch ~/ 1000,
      "categoryId": category!.id,
    };
    return await ApiService.post(request, ApiEndPoints.transcation)
        .then((newCategory) async {
          txtAmount.clear();
          txtDescription.clear();
          category = null;
          await getTranscations();
          notifyListeners();
          return true;
        })
        .catchError((error) {
          print("Error adding transaction: $error");
          return false;
        });
  }

  Future<bool> removeTransaction(int id) async {
    final success = await ApiService.delete(id, ApiEndPoints.transcation);
    if (success) {
      await getTranscations();
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }
}
