class CategoryModel {
  final int id; // Assuming the API uses an ID for each category
  final String name;

  CategoryModel({required this.id, required this.name});

  // Factory method to create a Category from JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(id: json['id'], name: json['name']);
  }

  // Convert a Category to JSON for API requests
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
