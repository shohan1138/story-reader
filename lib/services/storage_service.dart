import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _prog    = 'progress';
  static const _recents = 'recents';

  static Future<void> saveProgress(String path, int idx) async {
    final p = await SharedPreferences.getInstance();
    final m = await _all(p);
    m[path] = idx;
    await p.setString(_prog, jsonEncode(m));
  }

  static Future<int> loadProgress(String path) async {
    final p = await SharedPreferences.getInstance();
    return (await _all(p))[path] ?? 0;
  }

  static Future<void> addRecent(String path, String title) async {
    final p = await SharedPreferences.getInstance();
    final r = await loadRecents();
    r.removeWhere((e) => e['path'] == path);
    r.insert(0, {'path': path, 'title': title});
    await p.setString(_recents, jsonEncode(r.take(10).toList()));
  }

  static Future<List<Map<String, String>>> loadRecents() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_recents);
    if (s == null) return [];
    try {
      return (jsonDecode(s) as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    } catch (_) { return []; }
  }

  static Future<Map<String, int>> _all(SharedPreferences p) async {
    final s = p.getString(_prog);
    if (s == null) return {};
    try { return Map<String, int>.from(jsonDecode(s)); }
    catch (_) { return {}; }
  }
}
