import 'package:flutter/material.dart';
import '../models/batch.dart';
import '../models/sport.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class BatchesScreen extends StatefulWidget {
  const BatchesScreen({super.key});

  @override
  State<BatchesScreen> createState() => _BatchesScreenState();
}

class _BatchesScreenState extends State<BatchesScreen> {
  List<Batch> _batches = [];
  List<Sport> _sports = [];
  bool _isLoading = false;
  String _errorMessage = '';

  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  
  int? _selectedSportId;
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _fetchBatchesAndSports();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _fetchBatches(query: _searchController.text);
  }

  Future<void> _fetchBatchesAndSports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final batchesData = await ApiService.getBatches();
      final sportsData = await ApiService.getSports();
      setState(() {
        _batches = batchesData;
        _sports = sportsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBatches({String? query}) async {
    try {
      final data = await ApiService.getBatches(search: query);
      setState(() => _batches = data);
    } catch (_) {}
  }

  void _showAddBatchDialog() {
    if (_sports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one sport first before creating batches.')),
      );
      return;
    }

    _nameController.clear();
    _capacityController.clear();
    _selectedSportId = _sports[0].id;
    _startTime = const TimeOfDay(hour: 6, minute: 0);
    _endTime = const TimeOfDay(hour: 8, minute: 0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create New Batch'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Batch Name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a batch name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedSportId,
                        decoration: const InputDecoration(labelText: 'Sport'),
                        items: _sports.map((sport) {
                          return DropdownMenuItem<int>(
                            value: sport.id,
                            child: Text(sport.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() => _selectedSportId = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Start: ${_startTime.format(context)}'),
                          OutlinedButton(
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: _startTime,
                              );
                              if (picked != null) {
                                setDialogState(() => _startTime = picked);
                              }
                            },
                            child: const Text('Choose'),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('End: ${_endTime.format(context)}'),
                          OutlinedButton(
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: _endTime,
                              );
                              if (picked != null) {
                                setDialogState(() => _endTime = picked);
                              }
                            },
                            child: const Text('Choose'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _capacityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max Capacity'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter capacity';
                          }
                          final numVal = int.tryParse(value);
                          if (numVal == null || numVal < 1) {
                            return 'Capacity must be at least 1';
                          }
                          return null;
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
                    final startMinutes = _startTime.hour * 60 + _startTime.minute;
                    final endMinutes = _endTime.hour * 60 + _endTime.minute;
                    
                    if (startMinutes >= endMinutes) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('End time must be after start time.')),
                      );
                      return;
                    }

                    if (_formKey.currentState!.validate()) {
                      final selectedSport = _sports.firstWhere((s) => s.id == _selectedSportId);
                      final newBatch = Batch(
                        id: 0,
                        name: _nameController.text.trim(),
                        sportId: _selectedSportId!,
                        sportName: selectedSport.name,
                        startTime: '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00',
                        endTime: '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00',
                        capacity: int.parse(_capacityController.text.trim()),
                      );
                      Navigator.pop(context);
                      setState(() => _isLoading = true);

                      try {
                        final savedBatch = await ApiService.createBatch(newBatch);
                        setState(() {
                          _batches.insert(0, savedBatch);
                          _isLoading = false;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${savedBatch.name} batch created!')),
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
                  child: const Text('Save'),
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
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Schedules', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      drawer: const AppNavigationDrawer(currentRoute: '/batches'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search batches...',
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
              child: _isLoading && _batches.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _batches.isEmpty
                      ? const Center(child: Text('No batches found.'))
                      : RefreshIndicator(
                          onRefresh: _fetchBatchesAndSports,
                          child: ListView.builder(
                            itemCount: _batches.length,
                            itemBuilder: (context, index) {
                              final batch = _batches[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 1.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              batch.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.sports, size: 16, color: Colors.teal),
                                                const SizedBox(width: 4),
                                                Text(batch.sportName, style: const TextStyle(color: Colors.grey)),
                                                const SizedBox(width: 16),
                                                const Icon(Icons.people_outline, size: 16, color: Colors.blue),
                                                const SizedBox(width: 4),
                                                Text('Cap: ${batch.capacity}', style: const TextStyle(color: Colors.grey)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          // Display substring to hide seconds if returned as HH:MM:SS
                                          batch.startTime.length >= 5 && batch.endTime.length >= 5
                                              ? '${batch.startTime.substring(0, 5)} - ${batch.endTime.substring(0, 5)}'
                                              : '${batch.startTime} - ${batch.endTime}',
                                          style: const TextStyle(
                                            color: Colors.teal,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: ApiService.userRole == 'admin'
          ? FloatingActionButton(
              onPressed: _showAddBatchDialog,
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              tooltip: 'Add Batch',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
