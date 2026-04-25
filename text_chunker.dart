class TextChunker {
  static const int minWords = 150;
  static const int maxWords = 350;

  static List<String> chunk(String text) {
    text = _clean(text);
    final paras = text
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => _wc(p) >= 4)
        .toList();

    final chunks = <String>[];
    String buf = '';
    int bw = 0;

    for (final para in paras) {
      final pw = _wc(para);
      if (pw > maxWords) {
        if (buf.isNotEmpty) { chunks.add(buf.trim()); buf = ''; bw = 0; }
        chunks.addAll(_bySentence(para));
        continue;
      }
      buf = buf.isEmpty ? para : '$buf\n\n$para';
      bw += pw;
      if (bw >= minWords) { chunks.add(buf.trim()); buf = ''; bw = 0; }
    }
    if (buf.isNotEmpty) chunks.add(buf.trim());
    return chunks.where((c) => _wc(c) >= 10).toList();
  }

  static List<String> _bySentence(String para) {
    final result = <String>[];
    final sents = para.split(RegExp(r'(?<=[.!?])\s+'));
    String buf = ''; int bw = 0;
    for (final s in sents) {
      final w = _wc(s);
      if (bw + w > maxWords && buf.isNotEmpty) {
        result.add(buf.trim()); buf = s; bw = w;
      } else { buf = buf.isEmpty ? s : '$buf $s'; bw += w; }
    }
    if (buf.isNotEmpty) result.add(buf.trim());
    return result;
  }

  static String _clean(String t) {
    t = t.replaceAll(RegExp(r'(\w)-\n(\w)'), r'$1$2');
    t = t.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    t = t.replaceAll(RegExp(r'^\s*\d{1,4}\s*$', multiLine: true), '');
    t = t.replaceAll(RegExp(r'^\s*[*\-_=~]{3,}\s*$', multiLine: true), '');
    return t.trim();
  }

  static int _wc(String t) =>
      t.trim().isEmpty ? 0 : t.trim().split(RegExp(r'\s+')).length;
}
