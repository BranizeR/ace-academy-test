class Student {
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String phone;
  final String email;
  final String dob;
  final String gender;
  final int? batchId;
  final String batchName;
  final String sportName;
  final bool isActive;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.dob,
    required this.gender,
    this.batchId,
    required this.batchName,
    required this.sportName,
    required this.isActive,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    final batchDetail = json['batch_detail'] as Map<String, dynamic>?;
    final bId = json['batch'] as int? ?? (batchDetail?['id'] as int?);
    final bName = batchDetail?['name'] as String? ?? 'Unassigned';
    
    final sportDetail = batchDetail?['sport_detail'] as Map<String, dynamic>?;
    final sName = sportDetail?['name'] as String? ?? 'N/A';

    return Student(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      fullName: json['full_name'] as String? ?? "${json['first_name']} ${json['last_name']}",
      phone: json['phone'] as String,
      email: json['email'] as String,
      dob: json['dob'] as String,
      gender: json['gender'] as String,
      batchId: bId,
      batchName: bName,
      sportName: sName,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'dob': dob,
      'gender': gender,
      'batch': batchId,
      'is_active': isActive,
    };
  }
}
