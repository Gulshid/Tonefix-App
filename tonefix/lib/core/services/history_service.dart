import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:tonefix/shared/models/tone_models.dart';

/// Manages rewrite history in Firestore.
/// Phase 3 additions:
///   • Filter by tone type
///   • Filter by date range
///   • Search by text
///   • Export history as formatted string (TXT/CSV)
class HistoryService {
  HistoryService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final _logger = Logger();

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _historyRef {
    final uid = _uid;
    if (uid == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(uid).collection('history');
  }

  /// Sign in anonymously so users can use the app without registration.
  Future<void> ensureAnonymousAuth() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
      _logger.d('HistoryService: Signed in anonymously');
    }
  }

  /// Save a rewrite result to Firestore history.
  Future<void> saveRewrite(RewriteResult result) async {
    try {
      await _historyRef.doc(result.id).set(result.toMap());
      _logger.d('HistoryService: Saved rewrite ${result.id}');
    } catch (e) {
      _logger.e('HistoryService: Save error', error: e);
      rethrow;
    }
  }

  /// Load all history, ordered by newest first.
  /// Phase 3: Optional filtering by [toneFilter] and [dateRange].
  Future<List<RewriteResult>> loadHistory({
    int limit = 100,
    ToneType? toneFilter,
    DateTimeRange? dateRange,
    String? searchQuery,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _historyRef.orderBy('createdAt', descending: true).limit(limit);

      // Firestore supports one inequality filter — apply tone server-side
      if (toneFilter != null) {
        query = query.where('tone', isEqualTo: toneFilter.name);
      }

      final snapshot = await query.get();
      List<RewriteResult> results = snapshot.docs
          .map((doc) => RewriteResult.fromMap(doc.data()))
          .toList();

      // ── Client-side filters (Firestore free tier avoids composite indexes) ──
      if (dateRange != null) {
        results = results.where((r) {
          return r.createdAt.isAfter(
                dateRange.start.subtract(const Duration(seconds: 1)),
              ) &&
              r.createdAt.isBefore(
                dateRange.end.add(const Duration(days: 1)),
              );
        }).toList();
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase();
        results = results.where((r) {
          return r.originalText.toLowerCase().contains(q) ||
              r.rewrittenText.toLowerCase().contains(q);
        }).toList();
      }

      return results;
    } catch (e) {
      _logger.e('HistoryService: Load error', error: e);
      return [];
    }
  }

  /// Delete a single history item.
  Future<void> deleteRewrite(String id) async {
    try {
      await _historyRef.doc(id).delete();
      _logger.d('HistoryService: Deleted rewrite $id');
    } catch (e) {
      _logger.e('HistoryService: Delete error', error: e);
      rethrow;
    }
  }

  /// Clear all history for the current user.
  Future<void> clearHistory() async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _historyRef.get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      _logger.d('HistoryService: Cleared all history');
    } catch (e) {
      _logger.e('HistoryService: Clear error', error: e);
      rethrow;
    }
  }

  // ── Phase 3 – Task 1: Export ─────────────────────────────────────────────

  /// Exports history to a plain-text string ready for sharing.
  Future<String> exportAsTxt() async {
    final items = await loadHistory(limit: 500);
    if (items.isEmpty) return 'No history to export.';

    final buf = StringBuffer();
    buf.writeln('ToneFix – Rewrite History Export');
    buf.writeln('Generated: ${DateTime.now()}');
    buf.writeln('Total rewrites: ${items.length}');
    buf.writeln('=' * 50);

    for (final item in items) {
      buf.writeln('\n[${item.tone.label}] • ${_formatDate(item.createdAt)} • ${item.intensity.label}');
      buf.writeln('ORIGINAL:  ${item.originalText}');
      buf.writeln('REWRITTEN: ${item.rewrittenText}');
      buf.writeln('-' * 40);
    }
    return buf.toString();
  }

  /// Exports history as a CSV string.
  Future<String> exportAsCsv() async {
    final items = await loadHistory(limit: 500);
    if (items.isEmpty) return 'id,tone,intensity,date,original,rewritten\n';

    final buf = StringBuffer();
    buf.writeln('id,tone,intensity,date,original,rewritten');
    for (final item in items) {
      final orig = _escapeCsv(item.originalText);
      final rew = _escapeCsv(item.rewrittenText);
      buf.writeln('${item.id},${item.tone.name},${item.intensity.name},'
          '${item.createdAt.toIso8601String()},$orig,$rew');
    }
    return buf.toString();
  }

  String _escapeCsv(String value) =>
      '"${value.replaceAll('"', '""').replaceAll('\n', ' ')}"';

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
