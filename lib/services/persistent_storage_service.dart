import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class RecentFileEntry {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime lastOpened;
  final bool isStarred;

  RecentFileEntry({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.lastOpened,
    this.isStarred = false,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'sizeBytes': sizeBytes,
        'lastOpened': lastOpened.toIso8601String(),
        'isStarred': isStarred,
      };

  factory RecentFileEntry.fromJson(Map<String, dynamic> json) => RecentFileEntry(
        path: json['path'] as String,
        name: json['name'] as String,
        sizeBytes: json['sizeBytes'] as int? ?? 0,
        lastOpened: DateTime.tryParse(json['lastOpened'] as String? ?? '') ?? DateTime.now(),
        isStarred: json['isStarred'] as bool? ?? false,
      );

  RecentFileEntry copyWith({bool? isStarred, DateTime? lastOpened, int? sizeBytes}) {
    return RecentFileEntry(
      path: path,
      name: name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      lastOpened: lastOpened ?? this.lastOpened,
      isStarred: isStarred ?? this.isStarred,
    );
  }
}

class PersistentStorageService {
  static const String _keyRecentFiles = 'fetchpdf_recent_files';
  static const String _keyRecentFolders = 'fetchpdf_recent_folders';
  static const String _keyThemeMode = 'fetchpdf_theme_mode';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<List<RecentFileEntry>> getRecentFiles() async {
    await init();
    final raw = _prefs?.getStringList(_keyRecentFiles) ?? [];
    final List<RecentFileEntry> entries = [];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        entries.add(RecentFileEntry.fromJson(decoded));
      } catch (_) {}
    }
    return entries;
  }

  static Future<void> addRecentFile(String filePath, {int? sizeBytes}) async {
    await init();
    final file = File(filePath);
    final exists = file.existsSync();
    final realSize = sizeBytes ?? (exists ? file.lengthSync() : 0);
    final name = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : filePath;

    final list = await getRecentFiles();
    final existingIdx = list.indexWhere((e) => e.path == filePath);
    final wasStarred = existingIdx != -1 ? list[existingIdx].isStarred : false;

    if (existingIdx != -1) {
      list.removeAt(existingIdx);
    }

    list.insert(
      0,
      RecentFileEntry(
        path: filePath,
        name: name,
        sizeBytes: realSize,
        lastOpened: DateTime.now(),
        isStarred: wasStarred,
      ),
    );

    // Keep top 20
    if (list.length > 20) {
      list.removeLast();
    }

    final raw = list.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs?.setStringList(_keyRecentFiles, raw);

    // Also track folder
    final folder = file.parent.path;
    if (folder.isNotEmpty) {
      await addRecentFolder(folder);
    }
  }

  static Future<void> toggleStarred(String filePath) async {
    await init();
    final list = await getRecentFiles();
    final idx = list.indexWhere((e) => e.path == filePath);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(isStarred: !list[idx].isStarred);
      final raw = list.map((e) => jsonEncode(e.toJson())).toList();
      await _prefs?.setStringList(_keyRecentFiles, raw);
    }
  }

  static Future<void> removeRecentFile(String filePath) async {
    await init();
    final list = await getRecentFiles();
    list.removeWhere((e) => e.path == filePath);
    final raw = list.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs?.setStringList(_keyRecentFiles, raw);
  }

  static Future<void> clearRecentFiles() async {
    await init();
    await _prefs?.remove(_keyRecentFiles);
  }

  static Future<List<String>> getRecentFolders() async {
    await init();
    return _prefs?.getStringList(_keyRecentFolders) ?? [];
  }

  static Future<void> addRecentFolder(String folderPath) async {
    await init();
    final list = (await getRecentFolders()).toList();
    list.remove(folderPath);
    list.insert(0, folderPath);
    if (list.length > 10) list.removeLast();
    await _prefs?.setStringList(_keyRecentFolders, list);
  }

  static Future<bool> isDarkMode() async {
    await init();
    return _prefs?.getBool(_keyThemeMode) ?? false;
  }

  static Future<void> setDarkMode(bool isDark) async {
    await init();
    await _prefs?.setBool(_keyThemeMode, isDark);
  }
}
