import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<dynamic> pickFile() async {
  final result = await FilePicker.platform.pickFiles(type: FileType.image);
  if (result != null && result.files.isNotEmpty) {
    return File(result.files.first.path!);
  } else {
    throw Exception('No file selected');
  }
}
