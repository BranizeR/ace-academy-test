class Batch {
  final int id;
  final String name;
  final int sportId;
  final String sportName;
  final String startTime;
  final String endTime;
  final int capacity;

  Batch({
    required this.id,
    required this.name,
    required this.sportId,
    required this.sportName,
    required this.startTime,
    required this.endTime,
    required this.capacity,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    // Handle nested sport details if present from serializer
    final sportDetail = json['sport_detail'] as Map<String, dynamic>?;
    final sId = json['sport'] as int? ?? (sportDetail?['id'] as int? ?? 0);
    final sName = sportDetail?['name'] as String? ?? '';

    return Batch(
      id: json['id'] as int,
      name: json['name'] as String,
      sportId: sId,
      sportName: sName,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      capacity: json['capacity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sport': sportId,
      'start_time': startTime,
      'end_time': endTime,
      'capacity': capacity,
    };
  }
}
