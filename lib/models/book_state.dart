class BookState {
  final String title;
  final List<String> chunks;
  final int currentIndex;
  final String filePath;

  const BookState({
    required this.title,
    required this.chunks,
    required this.currentIndex,
    required this.filePath,
  });

  BookState copyWith({int? currentIndex}) => BookState(
        title: title,
        chunks: chunks,
        currentIndex: currentIndex ?? this.currentIndex,
        filePath: filePath,
      );

  double get progress =>
      chunks.isEmpty ? 0 : (currentIndex + 1) / chunks.length;

  String get currentChunk =>
      (currentIndex >= 0 && currentIndex < chunks.length)
          ? chunks[currentIndex]
          : '';

  bool get isFirst => currentIndex <= 0;
  bool get isLast  => currentIndex >= chunks.length - 1;
}
