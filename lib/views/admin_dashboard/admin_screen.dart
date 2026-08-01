import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Live data, merged from the separate `users` and `providers` collections.
  // Each entry keeps a `docRef` so actions write back to the correct doc.
  // NOTE: every provider also has a doc in `users` (base profile created at
  // signup), so we track provider doc IDs and exclude them from the
  // consumer list to avoid double-counting the same person twice.
  List<Map<String, dynamic>> _providerUsers = [];
  List<Map<String, dynamic>> _consumerUsers = [];
  Set<String> _providerIds = {};
  List<QueryDocumentSnapshot>? _latestUserDocs;
  StreamSubscription<QuerySnapshot>? _providersSub;
  StreamSubscription<QuerySnapshot>? _usersSub;

  @override
  void initState() {
    super.initState();

    // Fields on providers/{id}: businessName, category, location, rating
    // (optional). isAvailable is the provider's own online/offline toggle
    // and is left untouched here. isApproved / isSuspended are
    // admin-controlled and default to false when absent (new providers
    // start unapproved).
    _providersSub = FirebaseFirestore.instance
        .collection('providers')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _providerIds = snapshot.docs.map((d) => d.id).toSet();
        _providerUsers = snapshot.docs.map((doc) {
          final data = doc.data();
          final suspended = data['isSuspended'] == true;
          final approved = data['isApproved'] == true;
          return {
            'docRef': doc.reference,
            'role': 'Business',
            'name': data['businessName'] ?? '',
            'location': data['location'] ?? '',
            'category': data['category'] ?? '',
            'rating': (data['rating'] ?? '—').toString(),
            'status': suspended
                ? 'Suspended'
                : (approved ? 'Verified' : 'Pending Approval'),
          };
        }).toList();
        // Provider IDs may have changed — recompute the consumer list so
        // any provider's base user-doc gets excluded.
        if (_latestUserDocs != null) _rebuildConsumerUsers();
      });
    });

    // ASSUMED fields on users/{id}: name, location, suspended (bool,
    // optional). Consumers don't go through a verification queue, so
    // status is just Verified/Suspended. Adjust if your field name differs.
    _usersSub = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _latestUserDocs = snapshot.docs;
        _rebuildConsumerUsers();
      });
    });
  }

  void _rebuildConsumerUsers() {
    _consumerUsers = _latestUserDocs!
    // Exclude any user doc that's actually a provider's base profile.
        .where((doc) => !_providerIds.contains(doc.id))
        .map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final suspended = data['suspended'] == true;
      return {
        'docRef': doc.reference,
        'role': 'Consumer',
        'name': data['fullName'] ?? '',
        'location': data['location'] ?? '',
        'status': suspended ? 'Suspended' : 'Verified',
      };
    }).toList();
  }

  @override
  void dispose() {
    _providersSub?.cancel();
    _usersSub?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get _appUsers =>
      [..._providerUsers, ..._consumerUsers];

  Future<void> _approveUser(DocumentReference docRef) async {
    await docRef.update({'isApproved': true, 'isSuspended': false});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Provider successfully approved and deployed live.'),
        backgroundColor: brandSecondary,
      ),
    );
  }

  Future<void> _toggleSuspendUser(
      DocumentReference docRef, bool currentlySuspended) async {
    // Works for both providers (isSuspended) and consumers (suspended) —
    // see the role check at the call site below.
    await docRef.update({
      if (docRef.parent.id == 'providers') 'isSuspended': !currentlySuspended,
      if (docRef.parent.id == 'users') 'suspended': !currentlySuspended,
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
    final appUsers = _appUsers;

    // Dynamic counters calculated on live data
    int totalCount = appUsers.length;
    int pendingCount = appUsers.where((u) => u['status'] == 'Pending Approval').length;

    // Filter logic routine
    List<Map<String, dynamic>> displayedUsers = appUsers;
    if (_currentFilter == 'Pending') {
      displayedUsers = appUsers.where((u) => u['status'] == 'Pending Approval').toList();
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
                MaterialPageRoute(builder: (_) => const LoginScreen()),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome, Admin 👋",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Manage users, providers, and platform activity.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildMetricBlock('Total Users', '$totalCount', Icons.people_outline, Colors.white24),
                    _buildMetricBlock('Pending Vetting', '$pendingCount', Icons.gavel, Colors.orangeAccent.withValues(alpha: 0.2)),
                  ],
                ),
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
                final DocumentReference docRef = user['docRef'];
                final bool isBusiness = user['role'] == 'Business';
                final String status = user['status'] ?? '';

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
                              backgroundColor: isBusiness ? brandSecondary.withValues(alpha: 0.1) : brandPrimary.withValues(alpha: 0.15),
                              child: Icon(isBusiness ? Icons.engineering_outlined : Icons.person_outline, size: 20, color: isBusiness ? brandSecondary : brandPrimary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      user['name'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: brandPrimary)
                                  ),
                                  Text(
                                      '${user['role'] ?? ''} • ${user['location'] ?? ''}',
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
                            if (isBusiness) ...[
                              Icon(Icons.work_outline, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                  user['category'] ?? '',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.star_outline, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                  user['rating'] ?? '',
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
                                onPressed: () => _approveUser(docRef),
                                child: const Text('Approve Live', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              )
                            else if (user['role'] == 'Business')
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: status == 'Suspended' ? Colors.green : Colors.redAccent,
                                  side: BorderSide(color: status == 'Suspended' ? Colors.green : Colors.redAccent, width: 1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                onPressed: () => _toggleSuspendUser(docRef, status == 'Suspended'),
                                child: Text(
                                  status == 'Suspended' ? 'Lift Ban' : 'Suspend',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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