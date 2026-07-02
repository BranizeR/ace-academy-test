import 'package:flutter/material.dart';
import '../models/sport.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class SportsScreen extends StatefulWidget {
  const SportsScreen({super.key});

  @override
  State<SportsScreen> createState() => _SportsScreenState();
}

class _SportsScreenState extends State<SportsScreen> {
  List<Sport> _sports = [];
  bool _isLoading = false;
  String _errorMessage = '';

  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchSports();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Perform debounced or direct search querying
    _fetchSports(query: _searchController.text);
  }

  Future<void> _fetchSports({String? query}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final data = await ApiService.getSports(search: query);
      setState(() {
        _sports = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showAddSportDialog() {
    _nameController.clear();
    _descController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Sport'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Sport Name (e.g. Badminton)'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a sport name';
                    }
                    if (value.length < 2) {
                      return 'Must be at least 2 characters';
                    }
                    if (!RegExp(r'^[A-Za-z\s]+$').hasMatch(value)) {
                      return 'Only letters and spaces are allowed';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
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
                  final newSport = Sport(
                    id: 0,
                    name: _nameController.text.trim(),
                    description: _descController.text.trim(),
                  );
                  Navigator.pop(context);
                  setState(() => _isLoading = true);

                  try {
                    final savedSport = await ApiService.createSport(newSport);
                    setState(() {
                      _sports.insert(0, savedSport);
                      _isLoading = false;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${savedSport.name} added successfully!')),
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
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sports Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      drawer: const AppNavigationDrawer(currentRoute: '/sports'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search sports...',
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
              child: _isLoading && _sports.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _sports.isEmpty
                      ? const Center(child: Text('No sports found.'))
                      : RefreshIndicator(
                          onRefresh: () => _fetchSports(query: _searchController.text),
                          child: ListView.builder(
                            itemCount: _sports.length,
                            itemBuilder: (context, index) {
                              final sport = _sports[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 1.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Text(
                                    sport.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      sport.description,
                                      style: TextStyle(color: Colors.grey.shade600, height: 1.3),
                                    ),
                                  ),
                                  trailing: const CircleAvatar(
                                    backgroundColor: Colors.tealAccent,
                                    child: Icon(Icons.sports, color: Colors.teal),
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
              onPressed: _showAddSportDialog,
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              tooltip: 'Add Sport',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
