import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:tonefix/shared/models/tone_models.dart';

/// Manages rewrite history in Firestore.
/// Each user gets their own subcollection: users/{uid}/history
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
  Future<List<RewriteResult>> loadHistory({int limit = 50}) async {
    try {
      final snapshot = await _historyRef
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => RewriteResult.fromMap(doc.data()))
          .toList();
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
}
