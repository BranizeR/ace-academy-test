import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  Future<Student>? _studentProfileFuture;
  Student? _argumentsStudent;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Student) {
        _argumentsStudent = args;
      } else {
        final profileId = ApiService.profileId;
        if (profileId != null) {
          _studentProfileFuture = ApiService.getStudentProfile(profileId);
        }
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_argumentsStudent != null) {
      return _buildProfileContent(context, _argumentsStudent!, showDrawer: false);
    }

    final profileId = ApiService.profileId;
    if (profileId == null) {
      return const Scaffold(
        body: Center(child: Text('No profile ID found. Please log in again.')),
      );
    }

    return FutureBuilder<Student>(
      future: _studentProfileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Student Profile', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Student Profile', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Student Profile', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: Text('No student data found.')),
          );
        }
        return _buildProfileContent(context, snapshot.data!, showDrawer: true);
      },
    );
  }

  Widget _buildProfileContent(BuildContext context, Student student, {required bool showDrawer}) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      drawer: showDrawer ? const AppNavigationDrawer(currentRoute: '/student-profile') : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header Section
            Container(
              decoration: const BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Column(
                children: [
                  Hero(
                    tag: 'avatar_${student.id}',
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: student.gender == 'F' ? Colors.pink.shade50 : Colors.blue.shade50,
                        child: Text(
                          student.firstName[0] + student.lastName[0],
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: student.gender == 'F' ? Colors.pink : Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      student.isActive ? 'Active Student' : 'Inactive',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Profile details card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Training Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1.5,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.sports, 'Sport', student.sportName),
                          const Divider(),
                          _buildDetailRow(Icons.schedule, 'Training Batch', student.batchName),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Personal Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1.5,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.email_outlined, 'Email Address', student.email),
                          const Divider(),
                          _buildDetailRow(Icons.phone_android, 'Phone Number', student.phone),
                          const Divider(),
                          _buildDetailRow(Icons.calendar_month_outlined, 'Date of Birth', student.dob),
                          const Divider(),
                          _buildDetailRow(
                            Icons.transgender,
                            'Gender',
                            student.gender == 'M'
                                ? 'Male'
                                : student.gender == 'F'
                                    ? 'Female'
                                    : 'Other',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Mock Statistics Dashboard
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard('94%', 'Attendance Rate', Colors.green, Icons.trending_up),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard('A+', 'Performance', Colors.orange, Icons.insights),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal.shade700, size: 22),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String value, String label, Color color, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

