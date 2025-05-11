import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

part 'note.g.dart'; // Ensure this line exists if you're using code generation

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

  @HiveField(6)
  int? colorValue;

  @HiveField(7)
  bool? isPinned;

  @HiveField(8)
  DateTime? updatedAt;

  // Custom getter and setter for color
  Color? get color => colorValue != null ? Color(colorValue!) : null;
  set color(Color? value) => colorValue = value?.value;

  Note({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    this.attachmentPath,
    this.colorValue,
    this.isPinned = false,
    this.updatedAt,
  });

  factory Note.create({
    required String id,
    required String title,
    required String description,
    required NoteType type,
    String? attachmentPath,
    Color? color,
    bool isPinned = false,
  }) {
    final now = DateTime.now();
    return Note(
      id: id,
      title: title,
      description: description,
      date: now,
      updatedAt: now,
      type: type,
      attachmentPath: attachmentPath,
      colorValue: color?.value,
      isPinned: isPinned,
    );
  }

  Note copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    NoteType? type,
    String? attachmentPath,
    int? colorValue,
    bool? isPinned,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      colorValue: colorValue ?? this.colorValue,
      isPinned: isPinned ?? this.isPinned,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
