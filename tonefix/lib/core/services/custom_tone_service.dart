import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:tonefix/shared/models/tone_models.dart';

/// Manages user-created Custom Tone Profiles in Firestore.
/// Path: users/{uid}/custom_tones/{toneId}
///
/// Phase 3 – Task 2 (Custom Tone Builder)
class CustomToneService {
  CustomToneService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final _logger = Logger();

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _tonesRef {
    final uid = _uid;
    if (uid == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(uid).collection('custom_tones');
  }

  /// Fetch all custom tone profiles, newest first.
  Future<List<CustomToneProfile>> loadProfiles() async {
    try {
      final snap = await _tonesRef
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) => CustomToneProfile.fromMap(d.data()))
          .toList();
    } catch (e) {
      _logger.e('CustomToneService: Load error', error: e);
      return [];
    }
  }

  /// Save or update a custom tone profile.
  Future<void> saveProfile(CustomToneProfile profile) async {
    try {
      await _tonesRef.doc(profile.id).set(profile.toMap());
      _logger.d('CustomToneService: Saved profile ${profile.id}');
    } catch (e) {
      _logger.e('CustomToneService: Save error', error: e);
      rethrow;
    }
  }

  /// Delete a custom tone profile by ID.
  Future<void> deleteProfile(String id) async {
    try {
      await _tonesRef.doc(id).delete();
      _logger.d('CustomToneService: Deleted profile $id');
    } catch (e) {
      _logger.e('CustomToneService: Delete error', error: e);
      rethrow;
    }
  }
}
