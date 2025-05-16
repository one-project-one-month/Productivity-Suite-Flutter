class TranscationModel {
  String id;
  String type;
  String usage;
  String description;
  DateTime createDate;
  int amount;
  TranscationModel({
    required this.id,
    required this.type,
    required this.usage,
    required this.description,
    required this.createDate,
    required this.amount,
  });

  factory TranscationModel.fromMap(Map<String, dynamic> data) {
    return TranscationModel(
      id: data['id'] ?? '',
      type: data['type'] ?? '',
      usage: data['usage'] ?? '',
      description: data['description'] ?? '',
      createDate: DateTime.parse(data['createDate']),
      amount: data['amount'] ?? 0,
    );
  }
}
