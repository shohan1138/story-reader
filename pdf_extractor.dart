import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../utils/text_chunker.dart';

class PdfExtractor {
  static Future<(String, List<String>)> extract(String filePath) async {
    final ext = filePath.split('.').last.toLowerCase();
    String raw = '';

    if (ext == 'txt') {
      raw = await File(filePath).readAsString();
    } else if (ext == 'pdf') {
      raw = await compute(_extractPdf, filePath);
    } else {
      throw Exception('Unsupported file type: .$ext\nPlease use a PDF or TXT file.');
    }

    if (raw.trim().length < 100) {
      throw Exception(
        'No readable text found in this file.\n\n'
        'This PDF is likely a scanned book (image pages).\n'
        'Please use the desktop Python script to convert it\n'
        'to a .txt file first, then open the .txt here.',
      );
    }

    final chunks = TextChunker.chunk(raw);
    if (chunks.isEmpty) throw Exception('Could not split text into passages.');

    final title = _title(filePath);
    return (title, chunks);
  }

  static String _extractPdf(String path) {
    final bytes = File(path).readAsBytesSync();
    final doc   = PdfDocument(inputBytes: bytes);
    final buf   = StringBuffer();
    final ex    = PdfTextExtractor(doc);
    for (int i = 0; i < doc.pages.count; i++) {
      try {
        final t = ex.extractText(startPageIndex: i, endPageIndex: i);
        if (t.isNotEmpty) buf.write('$t\n\n');
      } catch (_) {}
    }
    doc.dispose();
    return buf.toString();
  }

  static String _title(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final base = name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
    return base.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
  }
}
