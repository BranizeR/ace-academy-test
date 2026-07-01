import 'package:flutter/material.dart';
import '../models/batch.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Batch> _batches = [];
  List<Student> _students = [];
  Map<int, String> _attendanceStatusMap = {}; // Maps Student ID to Status ('P', 'A', 'L', 'E')
  
  bool _isLoading = false;
  String _errorMessage = '';
  int? _selectedBatchId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final batchesData = await ApiService.getBatches();
      setState(() => _batches = batchesData);

      if (batchesData.isNotEmpty) {
        _selectedBatchId = batchesData[0].id;
        await _fetchStudentsAndAttendance();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStudentsAndAttendance() async {
    if (_selectedBatchId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _students = [];
      _attendanceStatusMap = {};
    });

    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    try {
      // 1. Fetch students for this batch (locally filtering from search/batch_id endpoint or query param)
      final allStudents = await ApiService.getStudents();
      final batchStudents = allStudents.where((s) => s.batchId == _selectedBatchId).toList();

      // 2. Fetch existing attendance for this batch and date to populate initial statuses
      final existingAttendanceList = await ApiService.getAttendance(
        batchId: _selectedBatchId,
        date: dateStr,
      );

      final statusMap = <int, String>{};
      // Populate defaults (Present)
      for (var student in batchStudents) {
        statusMap[student.id] = 'P';
      }
      // Overwrite with existing attendance status from API if present
      for (var att in existingAttendanceList) {
        statusMap[att.studentId] = att.status;
      }

      setState(() {
        _students = batchStudents;
        _attendanceStatusMap = statusMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      await _fetchStudentsAndAttendance();
    }
  }

  void _updateStatus(int studentId, String status) {
    setState(() {
      _attendanceStatusMap[studentId] = status;
    });
  }

  Future<void> _saveAttendance() async {
    setState(() => _isLoading = true);
    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    int savedCount = 0;
    try {
      for (var student in _students) {
        final status = _attendanceStatusMap[student.id] ?? 'P';
        final attendanceRecord = Attendance(
          id: 0,
          studentId: student.id,
          studentName: student.fullName,
          batchId: _selectedBatchId!,
          batchName: student.batchName,
          coachName: '',
          date: dateStr,
          status: status,
          remarks: 'Marked via mobile portal',
        );
        await ApiService.markAttendance(attendanceRecord);
        savedCount++;
      }

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance saved successfully for $savedCount students!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
      _fetchStudentsAndAttendance();
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

  @override
  Widget build(BuildContext context) {
    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      drawer: const AppNavigationDrawer(currentRoute: '/attendance'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _batches.isEmpty
                      ? const Text('Loading batches...')
                      : DropdownButtonFormField<int>(
                          value: _selectedBatchId,
                          decoration: const InputDecoration(
                            labelText: 'Batch',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          items: _batches.map((batch) {
                            return DropdownMenuItem<int>(
                              value: batch.id,
                              child: Text(batch.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedBatchId = val;
                            });
                            _fetchStudentsAndAttendance();
                          },
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () => _selectDate(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      dateStr,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Student Attendance Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
                      ? const Center(child: Text('No students in this batch.'))
                      : ListView.builder(
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final status = _attendanceStatusMap[student.id] ?? 'P';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 1.5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        student.fullName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        _buildStatusButton(student.id, 'P', 'Present', Colors.green, status == 'P'),
                                        const SizedBox(width: 8),
                                        _buildStatusButton(student.id, 'A', 'Absent', Colors.red, status == 'A'),
                                        const SizedBox(width: 8),
                                        _buildStatusButton(student.id, 'L', 'Late', Colors.orange, status == 'L'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _students.isEmpty || _isLoading ? null : _saveAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Submit Attendance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    int studentId,
    String statusCode,
    String label,
    Color activeColor,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => _updateStatus(studentId, statusCode),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          statusCode,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
