import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/batch.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<Student> _students = [];
  List<Batch> _batches = [];
  bool _isLoading = false;
  String _errorMessage = '';

  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  
  String _selectedGender = 'M';
  int? _selectedBatchId;

  @override
  void initState() {
    super.initState();
    _fetchStudentsAndBatches();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _fetchStudents(query: _searchController.text);
  }

  Future<void> _fetchStudentsAndBatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final studentsData = await ApiService.getStudents();
      final batchesData = await ApiService.getBatches();
      setState(() {
        _students = studentsData;
        _batches = batchesData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStudents({String? query}) async {
    try {
      final data = await ApiService.getStudents(search: query);
      setState(() => _students = data);
    } catch (_) {}
  }

  void _showAddStudentDialog() {
    if (_batches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create at least one batch first before enrolling students.')),
      );
      return;
    }

    _firstNameController.clear();
    _lastNameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _dobController.clear();
    _selectedGender = 'M';
    _selectedBatchId = _batches[0].id;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Enroll New Student'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'First Name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(labelText: 'Last Name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          if (!RegExp(r'^[1-9]\d{9}$').hasMatch(value)) {
                            return 'Enter valid 10-digit phone';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email Address'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Enter valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dobController,
                              readOnly: true,
                              decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                                firstDate: DateTime(1990),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text('Male')),
                          DropdownMenuItem(value: 'F', child: Text('Female')),
                          DropdownMenuItem(value: 'O', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => _selectedGender = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedBatchId,
                        decoration: const InputDecoration(labelText: 'Enroll in Batch'),
                        items: _batches.map((batch) {
                          return DropdownMenuItem<int>(
                            value: batch.id,
                            child: Text("${batch.name} (${batch.sportName})"),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() => _selectedBatchId = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final selectedBatch = _batches.firstWhere((b) => b.id == _selectedBatchId);
                      final newStudent = Student(
                        id: 0,
                        firstName: _firstNameController.text.trim(),
                        lastName: _lastNameController.text.trim(),
                        fullName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
                        phone: _phoneController.text.trim(),
                        email: _emailController.text.trim(),
                        dob: _dobController.text,
                        gender: _selectedGender,
                        batchId: _selectedBatchId,
                        batchName: selectedBatch.name,
                        sportName: selectedBatch.sportName,
                        isActive: true,
                      );
                      Navigator.pop(context);
                      setState(() => _isLoading = true);

                      try {
                        final enrolledStudent = await ApiService.enrollStudent(newStudent);
                        setState(() {
                          _students.insert(0, enrolledStudent);
                          _isLoading = false;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${enrolledStudent.fullName} enrolled successfully!')),
                          );
                        }
                      } catch (e) {
                        setState(() => _isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Enroll'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students Directory', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      drawer: const AppNavigationDrawer(currentRoute: '/students'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            Expanded(
              child: _isLoading && _students.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
                      ? const Center(child: Text('No students found.'))
                      : RefreshIndicator(
                          onRefresh: _fetchStudentsAndBatches,
                          child: ListView.builder(
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              final student = _students[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 1.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context, 
                                      '/student-profile',
                                      arguments: student,
                                    );
                                  },
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  leading: Hero(
                                    tag: 'avatar_${student.id}',
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: student.gender == 'F' ? Colors.pink.shade50 : Colors.blue.shade50,
                                      child: Text(
                                        student.firstName.isNotEmpty && student.lastName.isNotEmpty
                                            ? student.firstName[0] + student.lastName[0]
                                            : '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: student.gender == 'F' ? Colors.pink : Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    student.fullName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Batch: ${student.batchName} (${student.sportName})',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentDialog,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        tooltip: 'Enroll Student',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
