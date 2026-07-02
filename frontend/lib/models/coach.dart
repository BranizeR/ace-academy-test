class Coach {
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String phone;
  final String email;
  final int? sportId;
  final String sportName;
  final int experienceYears;
  final bool isActive;
  final String? password;

  Coach({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.phone,
    required this.email,
    this.sportId,
    required this.sportName,
    required this.experienceYears,
    required this.isActive,
    this.password,
  });

  factory Coach.fromJson(Map<String, dynamic> json) {
    final sportDetail = json['sport_detail'] as Map<String, dynamic>?;
    final sId = json['sport'] as int? ?? (sportDetail?['id'] as int?);
    final sName = sportDetail?['name'] as String? ?? 'No Specialization';

    return Coach(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      fullName: json['full_name'] as String? ?? "${json['first_name']} ${json['last_name']}",
      phone: json['phone'] as String,
      email: json['email'] as String,
      sportId: sId,
      sportName: sName,
      experienceYears: json['experience_years'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'sport': sportId,
      'experience_years': experienceYears,
      'is_active': isActive,
    };
    if (password != null && password!.isNotEmpty) {
      data['password'] = password;
    }
    return data;
  }
}
