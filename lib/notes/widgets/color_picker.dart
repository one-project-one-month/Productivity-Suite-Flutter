import 'package:flutter/material.dart';

class ColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  final List<Color>? colors;
  final double circleRadius;
  final double selectedCircleRadius;
  final double iconSize;

  const ColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.colors,
    this.circleRadius = 12,
    this.selectedCircleRadius = 14,
    this.iconSize = 18,
  });

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ?? _defaultColors;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children:
              colors.map((color) {
                final isSelected = color == selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() => selectedColor = color);
                    widget.onColorChanged(color);
                  },
                  child: CircleAvatar(
                    radius:
                        isSelected
                            ? widget.selectedCircleRadius
                            : widget.circleRadius,
                    backgroundColor: color,
                    child:
                        isSelected
                            ? Icon(
                              Icons.check,
                              color: Colors.white,
                              size: widget.iconSize,
                            )
                            : null,
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  static const List<Color> _defaultColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];
}
