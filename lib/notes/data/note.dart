import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

part 'note.g.dart';

// Improved enum with better documentation
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

// Enhanced Note model with better organization
@HiveType(typeId: 1)
class Note extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  NoteType type;

  @HiveField(5)
  String? attachmentPath;

  @HiveField(6)
  int? colorValue;

  @HiveField(7)
  bool isPinned;

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9)
  String? categoryId; // Reference to Category

  // Improved color handling
  Color get color => colorValue != null ? Color(colorValue!) : Colors.blue;
  set color(Color value) => colorValue = value.value;

  Note({
    required this.id,
    required this.title,
    required this.description,
    DateTime? createdAt,
    required this.type,
    this.attachmentPath,
    this.colorValue,
    this.isPinned = false,
    DateTime? updatedAt,
    this.categoryId,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Factory constructor with better defaults
  factory Note.create({
    required String title,
    required String description,
    required NoteType type,
    String? attachmentPath,
    Color? color,
    bool isPinned = false,
    String? categoryId,
  }) {
    return Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      type: type,
      attachmentPath: attachmentPath,
      colorValue: color?.value,
      isPinned: isPinned,
      categoryId: categoryId,
    );
  }

  // Enhanced copyWith with null checks
  Note copyWith({
    String? title,
    String? description,
    NoteType? type,
    String? attachmentPath,
    int? colorValue,
    bool? isPinned,
    String? categoryId,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      type: type ?? this.type,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      colorValue: colorValue ?? this.colorValue,
      isPinned: isPinned ?? this.isPinned,
      updatedAt: DateTime.now(),
      categoryId: categoryId ?? this.categoryId,
    );
  }

  // Helper methods
  bool get hasAttachment =>
      attachmentPath != null && attachmentPath!.isNotEmpty;
  bool get isTextNote => type == NoteType.text;
  void togglePin() => isPinned = !isPinned;
}

// Enhanced Category model with more functionality
@HiveType(typeId: 2)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  String? iconCodePoint; // For Material icons

  Category({
    String? id,
    required this.name,
    this.colorValue = 0xFF2196F3,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.iconCodePoint,
  }) : id = id  ?? DateTime.now().millisecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Color handling
  Color get color => Color(colorValue);
  set color(Color value) => colorValue = value.value;

  // Icon handling
  IconData? get icon =>
      iconCodePoint != null
          ? IconData(int.parse(iconCodePoint!), fontFamily: 'MaterialIcons')
          : null;

  // Factory constructor
  factory Category.create({
    required String name,
    Color? color,
    String? iconCodePoint,
  }) {
    return Category(
      name: name,
      colorValue: color?.value ?? 0xFF2196F3,
      iconCodePoint: iconCodePoint,
    );
  }

  // Copy with
  Category copyWith({String? name, int? colorValue, String? iconCodePoint}) {
    return Category(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }
}
