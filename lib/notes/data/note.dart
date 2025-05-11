import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 0)
enum NoteType {
  @HiveField(0)
  text,
  @HiveField(1)
  voice,
  @HiveField(2)
  image,
  @HiveField(3)
  video,
  @HiveField(4)
  sign,
}

@HiveType(typeId: 1)
class Note extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  NoteType type;

  @HiveField(5)
  String? attachmentPath;

  Note({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    this.attachmentPath,
  });
}
