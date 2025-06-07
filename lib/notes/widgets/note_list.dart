import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:productivity_suite_flutter/notes/data/compress_data.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';

class NoteListItem extends StatefulWidget {
  final Note note;
  final VoidCallback onTap;
  final Future<void> Function()? onPinAsync;
  final VoidCallback onDelete;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onLongPress;

  const NoteListItem({
    super.key,
    required this.note,
    required this.onTap,
    this.onPinAsync,
    required this.onDelete,
    this.selectionMode = false,
    this.selected = false,
    this.onLongPress,
  });

  @override
  State<NoteListItem> createState() => _NoteListItemState();
}

class _NoteListItemState extends State<NoteListItem> {
  bool isLoading = false;

  Future<void> _handlePin() async {
    if (widget.onPinAsync != null) {
      setState(() => isLoading = true);
      await widget.onPinAsync!();
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final formattedDate = DateFormat('MMMM d, h:mm a').format(note.updatedAt);

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side:
              widget.selectionMode && widget.selected
                  ? BorderSide(color: Color(0xff0045F3), width: 1.5)
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
                  if (widget.selectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        widget.selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color:
                            widget.selected
                                ? const Color(0xff0045F3)
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
                  isLoading
                      ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      )
                      : IconButton(
                        icon: Icon(
                          note.isPinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          color:
                              note.isPinned
                                  ? Color(0xff0045F3)
                                  : const Color.fromARGB(255, 83, 81, 81),
                        ),
                        onPressed: _handlePin,
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
