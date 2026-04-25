import 'package:flutter/material.dart';
import '../models/book_state.dart';
import '../services/tts_service.dart';
import '../services/storage_service.dart';

class ReaderScreen extends StatefulWidget {
  final BookState book;
  const ReaderScreen({super.key, required this.book});
  @override State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late TtsService _tts;
  late BookState  _book;
  bool  _busy        = false;   // navigation lock — prevents all crashes
  bool  _autoAdvance = true;
  double _rate       = 0.40;
  bool  _showSettings = false;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _tts  = TtsService();
    _tts.addListener(_onTts);
    _tts.onDone = _onChunkDone;
    _init();
  }

  Future<void> _init() async {
    await _tts.init();
    await _speakCurrent();
  }

  void _onTts() { if (mounted) setState(() {}); }

  void _onChunkDone() {
    if (!_autoAdvance || _busy || _book.isLast) return;
    _go(_book.currentIndex + 1);
  }

  // ── CRASH-FREE NAVIGATION ──────────────────────────────────────────
  // _busy flag ensures only one navigation runs at a time.
  // We ALWAYS stop TTS before changing index.
  Future<void> _go(int idx) async {
    if (_busy) return;                          // block concurrent calls
    _busy = true;
    try {
      final i = idx.clamp(0, _book.chunks.length - 1);
      await _tts.stop();                        // always stop first
      if (!mounted) return;
      setState(() => _book = _book.copyWith(currentIndex: i));
      await StorageService.saveProgress(_book.filePath, i);
      await _speakCurrent();
    } finally {
      _busy = false;
    }
  }

  Future<void> _speakCurrent() async {
    if (_book.currentChunk.isNotEmpty) await _tts.speak(_book.currentChunk);
  }

  Future<void> _togglePause() async {
    if (_busy) return;
    if (_tts.isPaused) {
      await _tts.resume(_book.currentChunk);
    } else if (_tts.isPlaying) {
      await _tts.pause();
    } else {
      await _speakCurrent();
    }
  }

  @override
  void dispose() {
    _tts.removeListener(_onTts);
    _tts.dispose();
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF11111B),
    appBar: AppBar(
      backgroundColor: const Color(0xFF181825),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () async { await _tts.stop(); if (mounted) Navigator.pop(context); },
      ),
      title: Text(_book.title,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [IconButton(
        icon: Icon(_showSettings ? Icons.tune : Icons.tune_outlined, color: const Color(0xFF89B4FA)),
        onPressed: () => setState(() => _showSettings = !_showSettings),
      )],
    ),
    body: Column(children: [
      _ProgressBar(progress: _book.progress, idx: _book.currentIndex + 1, total: _book.chunks.length),
      Expanded(child: _buildText()),
      if (_showSettings) _buildSettings(),
      _buildControls(),
      const SizedBox(height: 8),
    ]),
  );

  Widget _buildText() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Passage badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF89B4FA).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Passage ${_book.currentIndex + 1}  /  ${_book.chunks.length}',
          style: const TextStyle(color: Color(0xFF89B4FA), fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(height: 18),
      // Text
      _book.isLast && _tts.isIdle
        ? Center(child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(children: [
              const Text('🎉', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              const Text('The End', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('You finished the book!',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15)),
            ]),
          ))
        : SelectableText(
            _book.currentChunk,
            style: TextStyle(
              color: _tts.isPlaying ? Colors.white : Colors.white.withOpacity(0.6),
              fontSize: 18, height: 1.8, letterSpacing: 0.15,
            ),
          ),
    ]),
  );

  Widget _buildControls() => Container(
    padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
    decoration: const BoxDecoration(
      color: Color(0xFF181825),
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [

      // ← Previous
      _Btn(
        icon: Icons.skip_previous_rounded, size: 34,
        color: _book.isFirst || _busy ? Colors.white24 : const Color(0xFFCBA6F7),
        onTap: _book.isFirst || _busy ? null : () => _go(_book.currentIndex - 1),
        label: 'Previous',
      ),

      // Restart
      _Btn(
        icon: Icons.replay_rounded, size: 26,
        color: _busy ? Colors.white24 : Colors.white60,
        onTap: _busy ? null : () => _go(_book.currentIndex),
        label: 'Restart',
      ),

      // ▶ / ⏸  Main button
      GestureDetector(
        onTap: _busy ? null : _togglePause,
        child: Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            color: _busy ? const Color(0xFF89B4FA).withOpacity(0.3) : const Color(0xFF89B4FA),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: const Color(0xFF89B4FA).withOpacity(0.3),
              blurRadius: 18, spreadRadius: 2,
            )],
          ),
          child: Icon(
            _tts.isPaused ? Icons.play_arrow_rounded
              : _tts.isPlaying ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
            color: const Color(0xFF11111B), size: 38,
          ),
        ),
      ),

      // Stop
      _Btn(
        icon: Icons.stop_rounded, size: 26,
        color: (_tts.isPlaying || _tts.isPaused) ? Colors.white60 : Colors.white24,
        onTap: (_tts.isPlaying || _tts.isPaused) ? () => _tts.stop() : null,
        label: 'Stop',
      ),

      // → Next
      _Btn(
        icon: Icons.skip_next_rounded, size: 34,
        color: _book.isLast || _busy ? Colors.white24 : const Color(0xFFCBA6F7),
        onTap: _book.isLast || _busy ? null : () => _go(_book.currentIndex + 1),
        label: 'Next',
      ),
    ]),
  );

  Widget _buildSettings() => Container(
    color: const Color(0xFF181825),
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
    child: Column(children: [
      const Divider(color: Color(0xFF313244)),
      // Speed
      Row(children: [
        const Icon(Icons.speed_rounded, color: Color(0xFF89B4FA), size: 18),
        const SizedBox(width: 8),
        const Text('Speed', style: TextStyle(color: Color(0xFFCDD6F4))),
        const Spacer(),
        Text(
          _rate < 0.3 ? 'Very slow' : _rate < 0.45 ? 'Calm' : _rate < 0.6 ? 'Normal' : 'Fast',
          style: const TextStyle(color: Color(0xFF89B4FA), fontSize: 13),
        ),
      ]),
      Slider(
        value: _rate, min: 0.2, max: 0.8, divisions: 6,
        activeColor: const Color(0xFF89B4FA),
        inactiveColor: const Color(0xFF313244),
        onChanged: (v) async {
          setState(() => _rate = v);
          await _tts.setRate(v);
        },
      ),
      // Auto-advance
      Row(children: [
        const Icon(Icons.auto_mode_rounded, color: Color(0xFF89B4FA), size: 18),
        const SizedBox(width: 8),
        const Text('Auto-advance', style: TextStyle(color: Color(0xFFCDD6F4))),
        const Spacer(),
        Switch(
          value: _autoAdvance,
          activeColor: const Color(0xFF89B4FA),
          onChanged: (v) => setState(() => _autoAdvance = v),
        ),
      ]),
    ]),
  );
}

// ── Shared widgets ─────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double progress;
  final int idx, total;
  const _ProgressBar({required this.progress, required this.idx, required this.total});

  @override
  Widget build(BuildContext context) => Column(children: [
    LinearProgressIndicator(
      value: progress,
      backgroundColor: const Color(0xFF313244),
      valueColor: const AlwaysStoppedAnimation(Color(0xFF89B4FA)),
      minHeight: 3,
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('$idx / $total', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
        Text('${(progress * 100).toStringAsFixed(0)}%',
          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
      ]),
    ),
  ]);
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback? onTap;
  final String label;
  const _Btn({required this.icon, required this.size, required this.color,
               required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Tooltip(
      message: label,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: size, color: color),
      ),
    ),
  );
}
