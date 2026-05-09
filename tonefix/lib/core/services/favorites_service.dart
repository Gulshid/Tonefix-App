import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:tonefix/shared/models/tone_models.dart';

/// Manages Favorite Phrases stored in Firestore.
/// Path: users/{uid}/favorites/{phraseId}
///
/// Phase 3 – Task 5 (Favorite Phrases)
class FavoritesService {
  FavoritesService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final _logger = Logger();

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _favRef {
    final uid = _uid;
    if (uid == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(uid).collection('favorites');
  }

  /// Load all favorites, optionally filtered by [category].
  Future<List<FavoritePhrase>> loadFavorites({
    FavoriteCategory? category,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _favRef.orderBy('createdAt', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      final snap = await query.get();
      return snap.docs
          .map((d) => FavoritePhrase.fromMap(d.data()))
          .toList();
    } catch (e) {
      _logger.e('FavoritesService: Load error', error: e);
      return [];
    }
  }

  /// Save or update a favorite phrase.
  Future<void> saveFavorite(FavoritePhrase phrase) async {
    try {
      await _favRef.doc(phrase.id).set(phrase.toMap());
      _logger.d('FavoritesService: Saved ${phrase.id}');
    } catch (e) {
      _logger.e('FavoritesService: Save error', error: e);
      rethrow;
    }
  }

  /// Delete a favorite phrase by ID.
  Future<void> deleteFavorite(String id) async {
    try {
      await _favRef.doc(id).delete();
      _logger.d('FavoritesService: Deleted $id');
    } catch (e) {
      _logger.e('FavoritesService: Delete error', error: e);
      rethrow;
    }
  }
}
