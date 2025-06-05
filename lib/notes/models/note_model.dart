import 'package:productivity_suite_flutter/notes/data/note.dart';

class NoteDTO {
  final int id;
  final String title;
  final String body;
  final int? colorValue;
  final bool isPinned;
  final String categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteDTO({
    required this.id,
    required this.title,
    required this.body,
    required this.categoryId,

    this.colorValue,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteDTO.fromJson(Map<String, dynamic> json, {String? categoryId}) {
    final colorStr = json['color']?.toString() ?? '';
    final cleanedColor =
        colorStr.startsWith('#') ? colorStr.substring(1) : colorStr;
    final colorValue = int.tryParse('0xFF$cleanedColor');

    return NoteDTO(
      id: json['id'],
      title: json['title'].toString(),
      body: json['body'].toString(),
      categoryId: categoryId ?? '',

      colorValue: colorValue,
      isPinned: json['pinned'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'colorValue': colorValue,
    'isPinned': isPinned,
    'categoryId': categoryId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NoteDTO.fromNote(Note note) => NoteDTO(
    id: int.parse(note.id),
    title: note.title,
    body: note.description,
    colorValue: note.colorValue,
    isPinned: note.isPinned,
    categoryId: note.categoryId ?? '',

    createdAt: note.createdAt,
    updatedAt: note.updatedAt,
  );

  Note toNote() => Note(
    id: id.toString(),
    title: title,
    description: body,
    type: NoteType.text,
    colorValue: colorValue,
    isPinned: isPinned,
    createdAt: createdAt,
    updatedAt: updatedAt,
    categoryId: categoryId,
  );



  factory NoteDTO.fromNoteDetailsJson(Map<String, dynamic> json) {
    final colorStr = json['noteColor']?.toString() ?? '';
    final cleanedColor =
        colorStr.startsWith('#') ? colorStr.substring(1) : colorStr;
    final colorValue = int.tryParse('0xFF$cleanedColor');
    return NoteDTO(
      id: json['noteId'],
      title: json['noteTitle'].toString(),
      body: json['noteBody'].toString(),
      categoryId: json['categoryId'].toString(),
      colorValue: colorValue,
      isPinned: json['pinned'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
    );
  }
}

class CategoryWithNotes {
  final String categoryId;
  final String categoryName;
  final List<Note> notes;

  CategoryWithNotes({
    required this.categoryId,
    required this.categoryName,
    required this.notes,
  });

  factory CategoryWithNotes.fromJson(Map<String, dynamic> json) {
    final String catId = json['categoryId'].toString();
    final String catName = json['categoryName'] ?? '';

    return CategoryWithNotes(
      categoryId: catId,
      categoryName: catName,
      notes:
          (json['notes'] as List<dynamic>)
              .map(
                (noteJson) =>
                    NoteDTO.fromJson(noteJson, categoryId: catId).toNote(),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'notes': notes.map((note) => NoteDTO.fromNote(note).toJson()).toList(),
    };
  }
}
