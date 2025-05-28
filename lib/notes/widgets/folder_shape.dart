import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';


class FolderShapeWithBorder extends StatelessWidget {
  final String label;
  final Color color;
  final Color borderColor;
  final String iconData;
  final String catID;

  const FolderShapeWithBorder({
    super.key,
    required this.label,
    this.color = Colors.orange,
    this.borderColor = Colors.black,
    required this.iconData,
    required this.catID,
  });

  @override
  Widget build(BuildContext context) {
    int countNotesInCategory(String categoryId) {
      return Hive.box<Note>(
        'notesBox',
      ).values.where((note) => note.categoryId == categoryId).length;
    }

    final IconData resolvedIcon = getIconFromLabel(iconData);

    return CustomPaint(
      foregroundPainter: FolderBorderPainter(borderColor: borderColor),
      // painter: FolderBorderPainter(borderColor: borderColor),
      child: ClipPath(
        clipper: FolderShapeClipper(),
        child: Container(
          width: 160,
          height: 100,
          color: color.withOpacity(0.74),
          padding: const EdgeInsets.only(top: 30.0, left: 16.0, right: 12.0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(resolvedIcon, color: Colors.white, size: 30),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Notes: ${countNotesInCategory(catID)}',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FolderShapeClipper extends CustomClipper<Path> {
  final double radius = 10;

  @override
  Path getClip(Size size) {
    final tabHeight = size.height * 0.3;
    final tabWidth = size.width * 0.4;

    Path path = Path();

    // Start at top-left corner with radius
    path.moveTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);

    // Top edge before slant
    path.lineTo(size.width - (tabWidth + 10), 0);

    // Slanted tab
    path.lineTo(size.width - tabWidth, tabHeight);

    // Tab top edge with right corner
    path.lineTo(size.width - radius, tabHeight);
    path.quadraticBezierTo(
      size.width,
      tabHeight,
      size.width,
      tabHeight + radius,
    );

    // Right edge
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - radius,
      size.height,
    );

    // Bottom edge
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);

    // Close path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class FolderBorderPainter extends CustomPainter {
  final Color borderColor;
  final double radius = 10;

  FolderBorderPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final tabHeight = size.height * 0.3;
    final tabWidth = size.width * 0.4;

    final paint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    Path path = Path();

    // Start at top-left corner with radius
    path.moveTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);

    // Top edge before slant
    path.lineTo(size.width - (tabWidth + 10), 0);

    // Slanted tab
    path.lineTo(size.width - tabWidth, tabHeight);

    // Tab top edge with right corner
    path.lineTo(size.width - radius, tabHeight);
    path.quadraticBezierTo(
      size.width,
      tabHeight,
      size.width,
      tabHeight + radius,
    );

    // Right edge
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - radius,
      size.height,
    );

    // Bottom edge
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);

    // Close path
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FolderBorderPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor;
}

// Inside FolderShapeWithBorder class
IconData getIconFromLabel(String label) {
  const iconMap = {
    'personal': Icons.person,
    'account': Icons.account_balance_wallet,
    'education': Icons.school,
    'academic': Icons.school,
    'work': Icons.work_outline,
    'finance': Icons.attach_money,
    'music': Icons.music_note,
    'photos': Icons.photo_library,
    'docs': Icons.description,
    'trash': Icons.delete,
    'home': Icons.home,
    'settings': Icons.settings,
    'search': Icons.search,
    'calendar': Icons.calendar_today,
    'camera': Icons.camera_alt,
    'video': Icons.videocam,
    'chat': Icons.chat_bubble_outline,
    'message': Icons.message,
    'email': Icons.email,
    'contacts': Icons.contacts,
    'location': Icons.location_on,
    'map': Icons.map,
    'link': Icons.link,
    'download': Icons.download,
    'upload': Icons.upload,
    'notification': Icons.notifications_none,
    'favorite': Icons.favorite_border,
    'star': Icons.star_border,
    'share': Icons.share,
    'shopping': Icons.shopping_cart,
    'cart': Icons.shopping_bag,
    'health': Icons.health_and_safety,
    'fitness': Icons.fitness_center,
    'book': Icons.book,
    'bookmark': Icons.bookmark_border,
    'folder': Icons.folder,
    'tag': Icons.label_outline,
    'alarm': Icons.alarm,
    'timer': Icons.timer,
    'help': Icons.help_outline,
    'info': Icons.info_outline,
    'lock': Icons.lock_outline,
    'money': Icons.attach_money,
    'chatbot': Icons.smart_toy,
    'wifi': Icons.wifi,
    'battery': Icons.battery_unknown,
    'cloud': Icons.cloud_queue,
    'sun': Icons.wb_sunny,
    'moon': Icons.nights_stay,
  };

  // Case-insensitive lookup with a default
  return iconMap[label.toLowerCase()] ?? Icons.folder;
}
