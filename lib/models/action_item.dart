import 'package:cloud_firestore/cloud_firestore.dart';

class ActionItem {
  final String id;
  final String title;
  final String category;
  final DateTime? date;
  final String location;
  final String needs;
  final String createdBy;
  final List<String> participants;
  final int capacity;

  ActionItem({
    required this.id,
    required this.title,
    required this.category,
    this.date,
    required this.location,
    required this.needs,
    required this.createdBy,
    required this.participants,
    required this.capacity,
  });

  int get participantCount => participants.length;

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'date': date != null ? Timestamp.fromDate(date!) : null,
        'location': location,
        'needs': needs,
        'createdBy': createdBy,
        'participants': participants,
        'capacity': capacity,
      };

  factory ActionItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ActionItem(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate(),
      location: data['location'] ?? '',
      needs: data['needs'] ?? '',
      createdBy: data['createdBy'] ?? '',
      participants: (data['participants'] as List?)?.cast<String>() ?? <String>[],
      capacity: (data['capacity'] as num?)?.toInt() ?? 10,
    );
  }
}
