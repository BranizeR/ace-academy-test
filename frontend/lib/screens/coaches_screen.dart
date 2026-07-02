import 'package:flutter/material.dart';
import '../models/coach.dart';
import '../models/sport.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class CoachesScreen extends StatefulWidget {
  const CoachesScreen({super.key});

  @override
  State<CoachesScreen> createState() => _CoachesScreenState();
}

class _CoachesScreenState extends State<CoachesScreen> {
  List<Coach> _coaches = [];
  List<Sport> _sports = [];
  bool _isLoading = false;
  String _errorMessage = '';

  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _expController = TextEditingController();
  int? _selectedSportId;

  @override
  void initState() {
    super.initState();
    _fetchCoachesAndSports();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _fetchCoaches(query: _searchController.text);
  }

  Future<void> _fetchCoachesAndSports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final coachesData = await ApiService.getCoaches();
      final sportsData = await ApiService.getSports();
      setState(() {
        _coaches = coachesData;
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

  Future<void> _fetchCoaches({String? query}) async {
    try {
      final data = await ApiService.getCoaches(search: query);
      setState(() => _coaches = data);
    } catch (_) {}
  }

  void _showAddCoachDialog() {
    if (_sports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one sport first.')),
      );
      return;
    }

    _firstNameController.clear();
    _lastNameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _expController.clear();
    _selectedSportId = _sports[0].id;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Assistant Coach'),
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
                        decoration: const InputDecoration(labelText: 'Phone (e.g. 9876543210)'),
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
                      DropdownButtonFormField<int>(
                        value: _selectedSportId,
                        decoration: const InputDecoration(labelText: 'Sport Specialization'),
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
                      TextFormField(
                        controller: _expController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Experience (Years)'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final parsed = int.tryParse(value);
                          if (parsed == null || parsed < 0) {
                            return 'Invalid number';
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
                    if (_formKey.currentState!.validate()) {
                      final selectedSport = _sports.firstWhere((s) => s.id == _selectedSportId);
                      final newCoach = Coach(
                        id: 0,
                        firstName: _firstNameController.text.trim(),
                        lastName: _lastNameController.text.trim(),
                        fullName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
                        phone: _phoneController.text.trim(),
                        email: _emailController.text.trim(),
                        sportId: _selectedSportId,
                        sportName: selectedSport.name,
                        experienceYears: int.parse(_expController.text.trim()),
                        isActive: true,
                      );
                      Navigator.pop(context);
                      setState(() => _isLoading = true);

                      try {
                        final savedCoach = await ApiService.createCoach(newCoach);
                        setState(() {
                          _coaches.insert(0, savedCoach);
                          _isLoading = false;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${savedCoach.fullName} added!')),
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _expController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Coaches', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      drawer: const AppNavigationDrawer(currentRoute: '/coaches'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search coaches...',
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
              child: _isLoading && _coaches.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _coaches.isEmpty
                      ? const Center(child: Text('No coaches found.'))
                      : RefreshIndicator(
                          onRefresh: _fetchCoachesAndSports,
                          child: ListView.builder(
                            itemCount: _coaches.length,
                            itemBuilder: (context, index) {
                              final coach = _coaches[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 1.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor: Colors.teal.shade50,
                                        child: Text(
                                          coach.firstName.isNotEmpty && coach.lastName.isNotEmpty
                                              ? coach.firstName[0] + coach.lastName[0]
                                              : '?',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              coach.fullName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Speciality: ${coach.sportName}',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Exp: ${coach.experienceYears} Years  |  ${coach.phone}',
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                            ),
                                          ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCoachDialog,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        tooltip: 'Add Coach',
        child: const Icon(Icons.add),
      ),
    );
  }
}
