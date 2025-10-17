import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/action_item.dart';
import '../models/poll.dart';
import '../models/user_profile.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get uid {
    final u = _auth.currentUser;
    if (u == null) {
      throw StateError('Not signed in');
    }
    return u.uid;
  }

  // Collections
  CollectionReference<Map<String, dynamic>> get _actions => _db.collection('actions');
  CollectionReference<Map<String, dynamic>> get _polls => _db.collection('polls');
  DocumentReference<Map<String, dynamic>> get _userDoc => _db.collection('users').doc(uid);

  // ----- Actions -----
  Stream<List<ActionItem>> streamActions() {
    return _actions.orderBy('date', descending: false).snapshots().map(
          (snap) => snap.docs.map(ActionItem.fromDoc).toList(),
        );
  }

  Future<void> createAction(ActionItem item) async {
    await _actions.add(item.toJson());
  }

  Future<void> joinAction(String actionId) async {
    final ref = _actions.doc(actionId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final userSnap = await tx.get(_userDoc);
      final data = snap.data() ?? {};
      final participants = (data['participants'] as List?)?.cast<String>() ?? <String>[];
      if (!participants.contains(uid)) {
        participants.add(uid);
        tx.update(ref, {'participants': participants});
        _incrementPointsLocked(tx, userSnap, 10); // +10 poin
      }
    });
  }

  // ----- Polls -----
  Stream<List<Poll>> streamPolls() {
    return _polls.orderBy('title').snapshots().map(
          (snap) => snap.docs.map(Poll.fromDoc).toList(),
        );
  }

  Future<void> createPoll(Poll poll) async {
    await _polls.add(poll.toJson());
  }

  Future<void> vote(String pollId, int optionIndex) async {
    final ref = _polls.doc(pollId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final userSnap = await tx.get(_userDoc);
      final data = snap.data() ?? {};
      final votes = Map<String, int>.from((data['votes'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ) ?? {});
      final alreadyVoted = votes.containsKey(uid);
      votes[uid] = optionIndex;
      tx.update(ref, {'votes': votes});
      if (!alreadyVoted) {
        _incrementPointsLocked(tx, userSnap, 5); // +5 poin untuk partisipasi musyawarah
      }
    });
  }

  // ----- Profile -----
  Stream<UserProfile> streamProfile() {
    return _userDoc.snapshots().map((snap) => UserProfile.fromJson(snap.id, snap.data()));
  }

  Future<void> upsertProfile(UserProfile profile) async {
    await _userDoc.set(profile.toJson(), SetOptions(merge: true));
  }

  // Transactional point increment
  void _incrementPointsLocked(Transaction tx, DocumentSnapshot<Map<String, dynamic>> userSnap, int delta) {
    final data = userSnap.data() ?? {};
    final points = (data['points'] as num?)?.toInt() ?? 0;
    tx.set(_userDoc, {'points': points + delta}, SetOptions(merge: true));
  }
}
