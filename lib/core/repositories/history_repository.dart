import 'package:hive_ce/hive.dart';

import '../../shared/models/protection_session.dart';

/// Local, offline history of protection sessions backed by Hive.
///
/// Only aggregate timings are stored: when the filter was on, for how long and
/// at which intensity. Screen content is never captured.
class HistoryRepository {
  HistoryRepository(this._box);

  final Box<dynamic> _box;

  static const String boxName = 'protection_history';

  List<ProtectionSession> all() {
    final sessions = <ProtectionSession>[];
    for (final value in _box.values) {
      if (value is Map) {
        try {
          sessions.add(ProtectionSession.fromJson(value));
        } catch (_) {
          // Skip malformed legacy entries instead of failing the whole list.
        }
      }
    }
    sessions.sort((a, b) => b.start.compareTo(a.start));
    return sessions;
  }

  List<ProtectionSession> since(DateTime from) =>
      all().where((s) => s.end.isAfter(from)).toList();

  Future<void> add(ProtectionSession session) async {
    if (session.duration.inSeconds < 15) return;
    await _box.add(session.toJson());
  }

  Future<void> prune({Duration retention = const Duration(days: 120)}) async {
    final cutoff = DateTime.now().subtract(retention);
    final staleKeys = <dynamic>[];
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value is Map && value['end'] is num) {
        final end = DateTime.fromMillisecondsSinceEpoch((value['end'] as num).toInt());
        if (end.isBefore(cutoff)) staleKeys.add(key);
      }
    }
    if (staleKeys.isNotEmpty) await _box.deleteAll(staleKeys);
  }

  Future<void> clear() => _box.clear();

  int get length => _box.length;
}
