import 'package:flutter/material.dart';

class TextFieldWidget extends StatelessWidget {
  const TextFieldWidget({
    super.key,
    required this.txtController,
    required this.hintText,
    this.maxLine = 1,
    this.keyboardType = TextInputType.text,
  });
  final TextEditingController txtController;
  final String hintText;
  final int maxLine;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: maxLine,
      controller: txtController,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
}
