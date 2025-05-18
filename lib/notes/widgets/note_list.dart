import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:productivity_suite_flutter/notes/data/compress_data.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';

class NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onLongPress;

  const NoteListItem({
    super.key,
    required this.note,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
    this.selectionMode = false,
    this.selected = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'MMMM d, h:mm a',
    ).format(note.updatedAt ?? note.date);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side:
              selectionMode && selected
                  ? BorderSide(color: Colors.blueAccent, width: 1.5)
                  : BorderSide(
                    color: Color(note.colorValue!).withOpacity(0.2),
                    width: 1.5,
                  ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                if (note.colorValue != null)
                  Color(note.colorValue!).withOpacity(0.6)
                else
                  Colors.grey.shade200,
                if (note.colorValue != null)
                  Color(note.colorValue!).withOpacity(0.4)
                else
                  Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: Offset(2, 4),
              ),
            ],

            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (selectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color:
                            selected
                                ? const Color.fromARGB(255, 3, 106, 252)
                                : const Color.fromARGB(255, 51, 50, 50),
                      ),
                    ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      CompressString.decompressString(note.title),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      note.isPinned! ? Icons.push_pin : Icons.push_pin_outlined,
                      color:
                          note.isPinned!
                              ? const Color.fromARGB(255, 8, 0, 248)
                              : const Color.fromARGB(255, 83, 81, 81),
                    ),
                    onPressed: onPin,
                  ),
                ],
              ),
              Text(
                CompressString.decompressString(note.description),
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color.fromARGB(255, 58, 57, 57),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
