import 'package:flutter/material.dart';
import '../widgets/stat_card.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalStudents = 0;
  int _totalCoaches = 0;
  int _totalBatches = 0;
  int _presentToday = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    WebSocketService.addListener(_onWebSocketEvent);
  }

  @override
  void dispose() {
    WebSocketService.removeListener(_onWebSocketEvent);
    super.dispose();
  }

  void _onWebSocketEvent(String event) {
    if (mounted) {
      _fetchStats();
    }
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await ApiService.getDashboardStats();
      setState(() {
        _totalStudents = stats['total_students'] ?? 0;
        _totalCoaches = stats['total_coaches'] ?? 0;
        _totalBatches = stats['total_batches'] ?? 0;
        _presentToday = stats['present_today'] ?? 0;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStats,
          ),
        ],
      ),
      drawer: const AppNavigationDrawer(currentRoute: '/dashboard'),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back, ${ApiService.userName ?? 'User'}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Here is the status of the academy today.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    // Statistics Grid Layout
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 1.3,
                      children: [
                        StatCard(
                          title: 'Total Students',
                          value: _totalStudents.toString(),
                          icon: Icons.people,
                          gradientColors: const [Colors.teal, Colors.tealAccent],
                        ),
                        if (ApiService.userRole == 'admin')
                          StatCard(
                            title: 'Total Coaches',
                            value: _totalCoaches.toString(),
                            icon: Icons.person,
                            gradientColors: const [Colors.indigo, Colors.purple],
                          ),
                        StatCard(
                          title: 'Total Batches',
                          value: _totalBatches.toString(),
                          icon: Icons.schedule,
                          gradientColors: const [Colors.orange, Colors.amber],
                        ),
                        StatCard(
                          title: 'Present Today',
                          value: _presentToday.toString(),
                          icon: Icons.check_circle_outline,
                          gradientColors: const [Colors.green, Colors.lightGreen],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    // Quick action card actions
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12.0,
                      mainAxisSpacing: 12.0,
                      childAspectRatio: 2.2,
                      children: [
                        _buildQuickActionCard(
                          context,
                          title: 'Mark Attendance',
                          icon: Icons.how_to_reg,
                          color: Colors.teal.shade50,
                          iconColor: Colors.teal,
                          route: '/attendance',
                        ),
                        if (ApiService.userRole == 'admin')
                          _buildQuickActionCard(
                            context,
                            title: 'Register Student',
                            icon: Icons.person_add_alt_1,
                            color: Colors.blue.shade50,
                            iconColor: Colors.blue,
                            route: '/students',
                          ),
                        _buildQuickActionCard(
                          context,
                          title: 'View Batches',
                          icon: Icons.layers,
                          color: Colors.orange.shade50,
                          iconColor: Colors.orange,
                          route: '/batches',
                        ),
                        if (ApiService.userRole == 'admin')
                          _buildQuickActionCard(
                            context,
                            title: 'Manage Coaches',
                            icon: Icons.badge,
                            color: Colors.purple.shade50,
                            iconColor: Colors.purple,
                            route: '/coaches',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required String route,
  }) {
    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(context, route);
        _fetchStats();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppNavigationDrawer extends StatelessWidget {
  final String currentRoute;

  const AppNavigationDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final role = ApiService.userRole;
    final name = ApiService.userName ?? 'User';
    final roleDisplay = role != null ? role[0].toUpperCase() + role.substring(1) : 'Guest';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.teal,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(Icons.sports_soccer, size: 40, color: Colors.teal),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  roleDisplay,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (role == 'admin' || role == 'coach')
            _buildDrawerItem(context, 'Dashboard', Icons.dashboard, '/dashboard'),
          if (role == 'admin')
            _buildDrawerItem(context, 'Sports', Icons.sports, '/sports'),
          if (role == 'admin' || role == 'coach')
            _buildDrawerItem(context, 'Batches', Icons.schedule, '/batches'),
          if (role == 'admin')
            _buildDrawerItem(context, 'Coaches', Icons.badge, '/coaches'),
          if (role == 'admin' || role == 'coach')
            _buildDrawerItem(context, 'Students', Icons.people, '/students'),
          if (role == 'student')
            _buildDrawerItem(context, 'Profile', Icons.person, '/student-profile'),
          _buildDrawerItem(context, 'Attendance', Icons.how_to_reg, '/attendance'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await ApiService.logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    final isSelected = currentRoute == route;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.teal : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.teal : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.teal.shade50,
      onTap: () {
        if (isSelected) {
          Navigator.pop(context); // Close drawer
        } else {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
