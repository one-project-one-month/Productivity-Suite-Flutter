class IncomeModel {
  final int? id; // Assuming the API uses an ID for each category
  final int amount;
  final int categoryId;
  final String? categoryName;
  final String? categoryColor;

  IncomeModel({
    this.id,
    required this.amount,
    required this.categoryId,
    this.categoryName,
    this.categoryColor,
  });

  // Factory method to create a Category from JSON
  factory IncomeModel.fromJson(Map<String, dynamic> json) {
    return IncomeModel(
      id: json['id'],
      amount: int.parse(json['amount'].toString()),
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      categoryColor: json['categoryColor'],
    );
  }

  // Convert a Category to JSON for API requests
  Map<String, dynamic> toJson() {
    return {"amount": amount, "categoryId": categoryId};
  }
}


/**
 *  {
      "id": 82,
      "amount": 50000,
      "categoryId": 73,
      "categoryName": "food",
      "categoryColor": "food"
    },

   
 */