class UserProfile {
  final String id;
  final String name;
  final String rt;
  final int points;
  final List<String> badges;

  UserProfile({
    required this.id,
    required this.name,
    required this.rt,
    required this.points,
    required this.badges,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'rt': rt,
        'points': points,
        'badges': badges,
      };

  factory UserProfile.fromJson(String id, Map<String, dynamic>? data) {
    final d = data ?? {};
    return UserProfile(
      id: id,
      name: d['name'] ?? 'Warga',
      rt: d['rt'] ?? '-',
      points: (d['points'] as num?)?.toInt() ?? 0,
      badges: (d['badges'] as List?)?.cast<String>() ?? <String>[],
    );
  }

  UserProfile copyWith({String? name, String? rt, int? points, List<String>? badges}) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      rt: rt ?? this.rt,
      points: points ?? this.points,
      badges: badges ?? this.badges,
    );
  }
}
