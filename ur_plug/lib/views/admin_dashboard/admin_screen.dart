import 'package:flutter/material.dart';
import '../auth/login_screen.dart'; // Adjust path if needed

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Brand Color Palette Configured Precisely
  static const Color brandPrimary = Color(0xFF005F73);      // Deep Ocean Teal
  static const Color brandSecondary = Color(0xFF0A9396);    // Rich Turquoise       
  static const Color screenBackground = Color(0xFFE0F2F1);  // Turquoise Ice Canvas

  // State flag to handle live category filtering on the dashboard
  String _currentFilter = 'All'; 

  final List<Map<String, dynamic>> _appUsers = [
    {
      'name': 'Sarah\'s Tech Sparks',
      'role': 'Business (Producer)',
      'category': 'Electrician',
      'status': 'Verified',
      'rating': '4.9',
      'reports': 0,
      'location': 'Kirinya',
    },
    {
      'name': 'Express Repairs',
      'role': 'Business (Producer)',
      'category': 'Mechanic',
      'status': 'Pending Approval',
      'rating': 'N/A',
      'reports': 0,
      'location': 'Bweyogerere',
    },
    {
      'name': 'Kiden Sarah Ruth',
      'role': 'Customer',
      'category': 'N/A',
      'status': 'Verified',
      'rating': 'N/A',
      'reports': 0,
      'location': 'Kireka',
    },
    {
      'name': 'Unreliable Handyman Co.',
      'role': 'Business (Producer)',
      'category': 'Plumber',
      'status': 'Suspended',
      'rating': '2.3',
      'reports': 4,
      'location': 'Ntinda',
    },
  ];

  void _approveUser(int index) {
    setState(() {
      _appUsers[index]['status'] = 'Verified';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Provider successfully approved and deployed live.'),
        backgroundColor: brandSecondary,
      ),
    );
  }

  void _toggleSuspendUser(int index) {
    setState(() {
      if (_appUsers[index]['status'] == 'Suspended') {
        _appUsers[index]['status'] = 'Verified';
      } else {
        _appUsers[index]['status'] = 'Suspended';
      }
    });
  }

  // Dashboard Executive Metric Box UI Template
  Widget _buildMetricBlock(String label, String value, IconData icon, Color backgroundSurface) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: backgroundSurface, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  // Segment Filter Toggle Component Layout
  Widget _buildFilterButton(String label, String targetKey, IconData icon) {
    final bool isActive = _currentFilter == targetKey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentFilter = targetKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? brandPrimary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: isActive ? null : Border.all(color: brandPrimary.withValues(alpha: 0.15), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isActive ? Colors.white : brandPrimary),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? Colors.white : brandPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  // Color Coding Status Micro-Badge Layout
  Widget _buildStatusBadge(String status) {
    Color labelColor = Colors.orange;
    if (status == 'Verified') labelColor = Colors.green;
    if (status == 'Suspended') labelColor = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: labelColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: labelColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic counters
    int totalCount = _appUsers.length;
    int pendingCount = _appUsers.where((u) => u['status'] == 'Pending Approval').length;
    int flaggedCount = _appUsers.where((u) => (u['reports'] as int) > 0).length;

    // Filter logic routine
    List<Map<String, dynamic>> displayedUsers = _appUsers;
    if (_currentFilter == 'Pending') {
      displayedUsers = _appUsers.where((u) => u['status'] == 'Pending Approval').toList();
    } else if (_currentFilter == 'Flagged') {
      displayedUsers = _appUsers.where((u) => (u['reports'] as int) > 0).toList();
    }

    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ur Plug Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text('Platform Command Center', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w300)),
          ],
        ),
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Secure Sign Out',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. EXECUTIVE ANALYTICS BANNER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: brandPrimary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                _buildMetricBlock('Total Users', '$totalCount', Icons.people_outline, Colors.white24),
                _buildMetricBlock('Pending Vetting', '$pendingCount', Icons.gavel, Colors.orangeAccent.withValues(alpha: 0.2)),
                _buildMetricBlock('Flagged Active', '$flaggedCount', Icons.report_problem_outlined, Colors.redAccent.withValues(alpha: 0.2)),
              ],
            ),
          ),
          
          // 2. INTERACTIVE SUB-NAVIGATION ROW FILTERS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                _buildFilterButton('All Directory', 'All', Icons.dns_outlined),
                const SizedBox(width: 8),
                _buildFilterButton('Pending Vetting', 'Pending', Icons.hourglass_empty),
                const SizedBox(width: 8),
                _buildFilterButton('Flags', 'Flagged', Icons.flag_outlined),
              ],
            ),
          ),

          // 3. MAIN DYNAMIC VETTING LOG
          Expanded(
            child: displayedUsers.isEmpty
                ? const Center(child: Text('No directory data records matching selection.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: displayedUsers.length,
                    itemBuilder: (context, index) {
                      final user = displayedUsers[index];
                      final int rawIndex = _appUsers.indexOf(user); 
                      final bool isProducer = user['role'].contains('Business');
                      final String status = user['status'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 3))
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isProducer ? brandSecondary.withValues(alpha: 0.1) : brandPrimary.withValues(alpha: 0.1),
                                    child: Icon(isProducer ? Icons.engineering_outlined : Icons.person_outline, size: 20, color: isProducer ? brandSecondary : brandPrimary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['name'], 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: brandPrimary)
                                      ),
                                      Text(
                                        '${user['role']} • ${user['location']}', 
                                        style: const TextStyle(color: Colors.grey, fontSize: 12)
                                      ),
                                    ],
                                  ),
                                  ),
                                  _buildStatusBadge(status),
                                  ],
                                  ),
                                  const Divider(height: 24, thickness: 0.5),
                                  Row(
                                    children: [
                                      if (isProducer) ...[
                                        Icon(Icons.work_outline, size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          user['category'], 
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)
                                        ),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.star_outline, size: 14, color: Colors.amber),
                                        const SizedBox(width: 4),
                                        Text(
                                          user['rating'], 
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)
                                        ),
                                      ] else ...[
                                        Icon(Icons.verified_user_outlined, size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Verified Consumer Access', 
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700)
                                        ),
                                      ],
                                      const Spacer(),
                                      if (status == 'Pending Approval')
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: brandSecondary,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          ),
                                          onPressed: () => _approveUser(rawIndex),
                                          child: const Text('Approve Live', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        )
                                      else if (user['role'].contains('Business'))
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: status == 'Suspended' ? Colors.green : Colors.redAccent,
                                            side: BorderSide(color: status == 'Suspended' ? Colors.green : Colors.redAccent.withValues(alpha: 0.4)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          ),
                                          onPressed: () => _toggleSuspendUser(rawIndex),
                                          child: Text(
                                            status == 'Suspended' ? 'Lift Ban' : 'Suspend', 
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                                          ),
                                        ),
                                    ],
                                  ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

                                   

                                  
                                 