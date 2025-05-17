import 'dart:convert';
import 'package:archive/archive.dart';

class CompressString {
  CompressString._();
  
  static String compressString(String input) {
    final bytes = utf8.encode(input);
    final compressed = GZipEncoder().encode(bytes);
    return base64Encode(compressed); 
  }

  static String decompressString(String input) {
    if (input.startsWith('CMP:')) {
      try {
        final compressedBytes = base64Decode(input.substring(4));
        final decompressedBytes = GZipDecoder().decodeBytes(compressedBytes);
        return utf8.decode(decompressedBytes);
      } catch (_) {
        return input;
      }
    }
    return input; 
  }
}