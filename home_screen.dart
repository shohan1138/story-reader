import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/book_state.dart';
import '../services/pdf_extractor.dart';
import '../services/storage_service.dart';
import 'reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = false;
  String _msg = '';
  List<Map<String, String>> _recents = [];

  @override
  void initState() { super.initState(); _loadRecents(); }

  Future<void> _loadRecents() async {
    final r = await StorageService.loadRecents();
    if (mounted) setState(() => _recents = r);
  }

  Future<void> _pickFile() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    }
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
    );
    if (r == null || r.files.single.path == null) return;
    await _open(r.files.single.path!);
  }

  Future<void> _open(String path) async {
    if (!File(path).existsSync()) {
      _err('File not found:\n$path'); return;
    }
    setState(() { _loading = true; _msg = 'Reading book…'; });
    try {
      final (title, chunks) = await PdfExtractor.extract(path);
      setState(() => _msg = 'Almost ready…');
      final saved = await StorageService.loadProgress(path);
      final start = saved.clamp(0, chunks.length - 1);
      await StorageService.addRecent(path, title);
      if (!mounted) return;
      setState(() => _loading = false);
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => ReaderScreen(book: BookState(
          title: title, chunks: chunks,
          currentIndex: start, filePath: path,
        )),
      ));
      _loadRecents();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _err(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _err(String msg) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E2E),
      title: const Text('Could not open book', style: TextStyle(color: Colors.white)),
      content: Text(msg, style: const TextStyle(color: Color(0xFFCDD6F4))),
      actions: [TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('OK', style: TextStyle(color: Color(0xFF89B4FA))),
      )],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF11111B),
    body: _loading ? _buildLoading() : _buildHome(),
  );

  Widget _buildLoading() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const CircularProgressIndicator(color: Color(0xFF89B4FA)),
      const SizedBox(height: 20),
      Text(_msg, style: const TextStyle(color: Color(0xFFCDD6F4), fontSize: 16)),
    ],
  ));

  Widget _buildHome() => SafeArea(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      Row(children: [
        const Text('📚', style: TextStyle(fontSize: 40)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Story Reader',
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          Text('Calm & passionate narrator',
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
        ]),
      ]),
      const SizedBox(height: 36),

      // Open button
      SizedBox(width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.folder_open_rounded),
          label: const Text('Open a Book', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF89B4FA),
            foregroundColor: const Color(0xFF11111B),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Center(child: Text('PDF or TXT files',
        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12))),
      const SizedBox(height: 32),

      if (_recents.isNotEmpty) ...[
        const Text('Recent Books',
          style: TextStyle(color: Color(0xFFCDD6F4), fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Expanded(child: ListView.separated(
          itemCount: _recents.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final b = _recents[i];
            final exists = File(b['path'] ?? '').existsSync();
            return Material(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: exists ? () => _open(b['path']!) : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    Icon(Icons.book_rounded,
                      color: exists ? const Color(0xFF89B4FA) : Colors.white.withOpacity(0.2),
                      size: 22),
                    const SizedBox(width: 12),
                    Expanded(child: Text(b['title'] ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: exists ? Colors.white : Colors.white.withOpacity(0.3),
                        fontSize: 14, fontWeight: FontWeight.w500))),
                    if (exists) Icon(Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(0.3)),
                  ]),
                ),
              ),
            );
          },
        )),
      ] else Expanded(child: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 72, color: Colors.white.withOpacity(0.07)),
          const SizedBox(height: 16),
          Text('No books yet\nTap "Open a Book" to start',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14)),
        ],
      ))),
    ]),
  ));
}
