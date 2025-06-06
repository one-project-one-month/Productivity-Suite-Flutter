class TranscationModel {
  final int id;
  final int amount;
  final String description;
  final int transactionDate;
  final int categoryId;
  final String categoryName;
  final String categoryColor;
  final int createdAt;
  final int updatedAt;

  TranscationModel({
    required this.id,
    required this.amount,
    required this.description,
    required this.transactionDate,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create an instance from JSON
  factory TranscationModel.fromJson(Map<String, dynamic> json) {
    return TranscationModel(
      id: json['id'],
      amount: double.tryParse(json['amount'].toString())?.toInt() ?? 0,
      description: json['description'],
      transactionDate: json['transactionDate'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      categoryColor: json['categoryColor'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'transactionDate': transactionDate,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryColor': categoryColor,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
