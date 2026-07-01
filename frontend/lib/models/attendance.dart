class Attendance {
  final int id;
  final int studentId;
  final String studentName;
  final int batchId;
  final String batchName;
  final int? coachId;
  final String coachName;
  final String date;
  final String status;
  final String remarks;

  Attendance({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.batchId,
    required this.batchName,
    this.coachId,
    required this.coachName,
    required this.date,
    required this.status,
    required this.remarks,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    final studentDetail = json['student_detail'] as Map<String, dynamic>?;
    final sId = json['student'] as int? ?? (studentDetail?['id'] as int? ?? 0);
    final sName = studentDetail != null ? "${studentDetail['first_name']} ${studentDetail['last_name']}" : '';

    final batchDetail = json['batch_detail'] as Map<String, dynamic>?;
    final bId = json['batch'] as int? ?? (batchDetail?['id'] as int? ?? 0);
    final bName = batchDetail?['name'] as String? ?? '';

    final coachDetail = json['coach_detail'] as Map<String, dynamic>?;
    final cId = json['coach'] as int? ?? (coachDetail?['id'] as int?);
    final cName = coachDetail != null ? "${coachDetail['first_name']} ${coachDetail['last_name']}" : 'Unspecified';

    return Attendance(
      id: json['id'] as int,
      studentId: sId,
      studentName: sName,
      batchId: bId,
      batchName: bName,
      coachId: cId,
      coachName: cName,
      date: json['date'] as String,
      status: json['status'] as String,
      remarks: (json['remarks'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student': studentId,
      'batch': batchId,
      'coach': coachId,
      'date': date,
      'status': status,
      'remarks': remarks,
    };
  }
}
