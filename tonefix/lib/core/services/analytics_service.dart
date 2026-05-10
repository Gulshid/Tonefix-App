import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonefix/shared/models/tone_models.dart';

/// Persists and queries tone-usage analytics locally.
/// Data is stored in SharedPreferences as JSON — no cloud required.
class AnalyticsService {
  AnalyticsService({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const _kUsageKey = 'analytics_tone_usage';
  static const _kDailyKey = 'analytics_daily_usage';
  static const _kTotalKey = 'analytics_total_rewrites';

  // ── Record ────────────────────────────────────────────────────────────────

  /// Records a completed rewrite for [tone].
  Future<void> recordRewrite(ToneType tone) async {
    await _incrementToneCount(tone);
    await _incrementDailyCount();
    await _incrementTotal();
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  /// Returns a map of ToneType → total usage count across all time.
  Map<ToneType, int> getToneUsageCounts() {
    final raw = _prefs.getString(_kUsageKey);
    if (raw == null) return {for (final t in ToneType.values) t: 0};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final t in ToneType.values) t: (decoded[t.name] as int?) ?? 0,
    };
  }

  /// Returns daily rewrite counts for the last [days] days.
  /// Key = 'yyyy-MM-dd', value = count.
  Map<String, int> getDailyUsage({int days = 7}) {
    final raw = _prefs.getString(_kDailyKey);
    final Map<String, int> all = raw == null
        ? {}
        : (jsonDecode(raw) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as int?) ?? 0));

    final today = DateTime.now();
    final result = <String, int>{};
    for (int i = days - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final key = _dateKey(date);
      result[key] = all[key] ?? 0;
    }
    return result;
  }

  /// Total rewrites ever performed.
  int getTotalRewrites() => _prefs.getInt(_kTotalKey) ?? 0;

  /// The most-used tone, or null if no data.
  ToneType? getMostUsedTone() {
    final counts = getToneUsageCounts();
    if (counts.values.every((v) => v == 0)) return null;
    return counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  /// Usage percentage (0.0–1.0) for [tone] relative to all rewrites.
  double getTonePercentage(ToneType tone) {
    final counts = getToneUsageCounts();
    final total = counts.values.fold(0, (a, b) => a + b);
    if (total == 0) return 0.0;
    return (counts[tone] ?? 0) / total;
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await _prefs.remove(_kUsageKey);
    await _prefs.remove(_kDailyKey);
    await _prefs.remove(_kTotalKey);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _incrementToneCount(ToneType tone) async {
    final raw = _prefs.getString(_kUsageKey);
    final Map<String, dynamic> map = raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
    map[tone.name] = ((map[tone.name] as int?) ?? 0) + 1;
    await _prefs.setString(_kUsageKey, jsonEncode(map));
  }

  Future<void> _incrementDailyCount() async {
    final raw = _prefs.getString(_kDailyKey);
    final Map<String, dynamic> map = raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
    final key = _dateKey(DateTime.now());
    map[key] = ((map[key] as int?) ?? 0) + 1;
    await _prefs.setString(_kDailyKey, jsonEncode(map));
  }

  Future<void> _incrementTotal() async {
    final current = _prefs.getInt(_kTotalKey) ?? 0;
    await _prefs.setInt(_kTotalKey, current + 1);
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
