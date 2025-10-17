import 'package:cloud_firestore/cloud_firestore.dart';

class Poll {
  final String id;
  final String title;
  final List<String> options;
  final Map<String, int> votes; // userId -> optionIndex
  final DateTime? closesAt;

  Poll({
    required this.id,
    required this.title,
    required this.options,
    required this.votes,
    this.closesAt,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'options': options,
        'votes': votes.map((k, v) => MapEntry(k, v)),
        'closesAt': closesAt != null ? Timestamp.fromDate(closesAt!) : null,
      };

  factory Poll.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final rawVotes = (data['votes'] as Map?) ?? {};
    return Poll(
      id: doc.id,
      title: data['title'] ?? '',
      options: (data['options'] as List?)?.cast<String>() ?? <String>[],
      votes: rawVotes.map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
      closesAt: (data['closesAt'] as Timestamp?)?.toDate(),
    );
  }
}
