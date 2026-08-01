import 'dart:io' as io;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ur_plug/services/auth_service.dart';
import '../../state/customer_profile_controller.dart';
import 'package:flutter/material.dart';
import 'provider_detail_screen.dart';
import 'package:ur_plug/views/auth/login_screen.dart';
import 'customer_chat_screen.dart';
import 'package:ur_plug/views/customer_dashboard/request_service_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/uganda_districts.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // greeting
  String username = "";

  @override
  void initState() {
    super.initState();
    _filteredProviders = _allProviders;
    _filteredCategories = _allCategories;
    loadUser();
    _loadProviders();
  }

  Future<void> loadUser() async {
    final user = await AuthService().getCurrentUser();

    if (user != null) {
      setState(() {
        username = user.fullName;
        _userDistrict = user.district ?? '';
        _userTown = user.town ?? '';
      });
      _computeHighRated();
    }
  }

  Future<void> _loadProviders() async {
    final snapshot = await FirebaseFirestore.instance.collection('providers').get();
    final providers = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['businessName'] ?? '',
        'category': data['businessCategory'] ?? '',
        'district': data['district'] ?? '',
        'town': data['town'] ?? '',
        'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
        'jobs': data['completedJobs'] ?? 0,
        'responseRate': (data['responseRate'] as num?)?.toDouble() ?? 0.0,
        'bio': data['bio'] ?? '',
        'yearsOfExperience': data['yearsOfExperience'] ?? 0,
        'phone': data['phone'] ?? '',
        'icon': Icons.person,
      };
    }).toList();

    setState(() {
      _allProviders.addAll(providers);
      _filteredProviders = _highRatedProviders.isEmpty ? _allProviders : _highRatedProviders;
    });
    _computeHighRated();
  }

  // Sorts all providers by score and keeps only the top 5 for the homepage strip
  void _computeHighRated() {
    final sorted = List<Map<String, dynamic>>.from(_allProviders);

    sorted.sort((a, b) {
      double scoreA = _score(a);
      double scoreB = _score(b);
      return scoreB.compareTo(scoreA);
    });

    setState(() {
      _highRatedProviders = sorted.take(5).toList();
      if (_searchController.text.isEmpty) {
        _filteredProviders = _highRatedProviders;
      }
    });
  }

  double _score(Map<String, dynamic> provider) {
    double score = 0;
    final String providerDistrict = (provider['district'] ?? '').toString().toLowerCase();
    final String userDistrictLower = _userDistrict.toLowerCase();

    if (providerDistrict == userDistrictLower) {
      score += 30; // exact district match
    } else if (subRegionOf(providerDistrict) != null &&
        subRegionOf(providerDistrict) == subRegionOf(_userDistrict)) {
      score += 15; // same sub-region, e.g. Wakiso ↔ Kampala
    }

    if ((provider['town'] ?? '').toString().toLowerCase() == _userTown.toLowerCase()) {
      score += 20;
    }
    score += (provider['rating'] as double? ?? 0.0) * 10;
    score += (provider['jobs'] as int? ?? 0) * 0.5;
    score += (provider['responseRate'] as double? ?? 0.0) * 5;
    return score;
  }

  // Brand Color Palette Configured Precisely
  static const Color brandPrimary = Color(0xFF005F73);      // Deep Ocean Teal
  static const Color brandSecondary = Color(0xFF0A9396);    // Rich Turquoise
  static const Color screenBackground = Color(0xFFE0F2F1);  // Turquoise Ice Canvas

  // Bottom Navigation Index State
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // FRONTEND HOOKS: Clean local placeholders ready for backend data binding
  final List<Map<String, dynamic>> _allProviders = [];
  final List<Map<String, dynamic>> _allCategories = [
    {'name': 'Plumbing', 'icon': Icons.plumbing},
    {'name': 'Electrician', 'icon': Icons.electrical_services},
    {'name': 'Mechanic', 'icon': Icons.car_repair},
    {'name': 'Carpenter', 'icon': Icons.carpenter},
    {'name': 'Cleaner', 'icon': Icons.cleaning_services},
  ];
  final List<Map<String, dynamic>> _bookingHistory = [];

  // Dynamic filter lists initialized on startup
  List<Map<String, dynamic>> _filteredProviders = [];
  List<Map<String, dynamic>> _filteredCategories = [];

  // High-rated / proximity scoring state
  List<Map<String, dynamic>> _highRatedProviders = [];
  String _userDistrict = '';
  String _userTown = '';

  // Shown above search results when we had to widen beyond the user's town/district
  String? _searchScopeNotice;

  // Aliases so "plumber" search still matches providers stored as "Plumbing", etc.
  final Map<String, List<String>> categorySearchAliases = {
    'plumbing': ['plumber', 'plumbers', 'plumbing', "toilet", "tap", "sink", "pipe", "drain", "leak", "leaking", "water", "flush", "shower", "sinks","sink fix"],
    'electrician': ['electrician', 'electricians', 'electrical',"socket", "switch", "wire", "wiring", "bulb", "power", "electricity", "generator", "lights", "light", "fix"],
    'mechanic': ['mechanic', 'mechanics',"car", "vehicle", "engine", "gearbox", "battery", "tyre", "brake", "oil", "breakdown"],
    'carpenter': ['carpenter', 'carpenters', 'carpentry'],
    'interior design': ['interior design', 'interior designer', 'decor',"decoration", "design", "painting", "wall", "ceiling", "tiles", "curtains", "furniture"],
    'cleaner': ['cleaner', 'cleaners', 'cleaning',"clean", "washing", "laundry", "compound", "office", "house"],
    'painter': ['painter', 'painters', 'painting',"paint", "painting", "wall", "colour", "house"],
    'welder': ['welder', 'welders', 'welding'],
    'handyman': ['handyman', 'handymen'],
  };

  String get _providerSectionTitle =>
      _searchController.text.isEmpty ? 'High Rated Services & Businesses' : 'Search Results';

  // Active search filtering routine running locally.
  // Scopes results to same town first, falls back to same district,
  // then falls back to nationwide as a last resort — matching MatchingService's tiered logic.
  void _runSearchFilter(String enteredKeyword) {
    List<Map<String, dynamic>> providerResults = [];
    List<Map<String, dynamic>> categoryResults = [];
    String? scopeNotice;

    if (enteredKeyword.isEmpty) {
      providerResults = _highRatedProviders;
      categoryResults = _allCategories;
    } else {
      final query = enteredKeyword.toLowerCase();

      bool matchesQuery(Map<String, dynamic> item) {
        final name = item['name'].toString().toLowerCase();
        final category = item['category'].toString().toLowerCase();
        final town = (item['town'] ?? '').toString().toLowerCase();

        if (name.contains(query) || category.contains(query) || town.contains(query)) {
          return true;
        }
        final aliases = categorySearchAliases[category];
        return aliases != null && aliases.any((alias) => query.contains(alias));
      }

      final allMatches = _allProviders.where(matchesQuery).toList();

      // Tier 1: same town
      final sameTown = allMatches.where((p) =>
      (p['town'] ?? '').toString().toLowerCase() == _userTown.toLowerCase()).toList();

      // Tier 2: same district (any town)
      final sameDistrict = allMatches.where((p) =>
      (p['district'] ?? '').toString().toLowerCase() == _userDistrict.toLowerCase()).toList();

      if (sameTown.isNotEmpty) {
        providerResults = sameTown;
      } else if (sameDistrict.isNotEmpty) {
        providerResults = sameDistrict;
        scopeNotice = 'No matches in $_userTown — showing results from $_userDistrict.';
      } else {
        // Tier 3: nationwide fallback
        providerResults = allMatches;
        if (allMatches.isNotEmpty) {
          scopeNotice = 'No matches in $_userDistrict — showing results from other districts.';
        }
      }

      providerResults.sort((a, b) => _score(b).compareTo(_score(a)));

      categoryResults = _allCategories.where((item) =>
          item['name'].toString().toLowerCase().contains(query)).toList();
    }

    setState(() {
      _filteredProviders = providerResults;
      _filteredCategories = categoryResults;
      _searchScopeNotice = scopeNotice;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper builder method to manage dynamic screen views
  Widget _buildBodyContent() {
    switch (_currentIndex) {
      case 1:
        return const ActiveChatsDashboard();
      case 2:
        return const AccountDetailsScreen();
      case 3:
        return const BookingHistoryScreen();
      case 0:
      default:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome, $username 👋",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Find trusted services near you.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              // Live Interactive Search Input Bar
              TextField(
                controller: _searchController,
                onChanged: (value) => _runSearchFilter(value),
                decoration: InputDecoration(
                  hintText: 'Search services, providers...',
                  hintStyle: TextStyle(color: brandPrimary.withValues(alpha: 0.5)),
                  prefixIcon: const Icon(Icons.search, color: brandPrimary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: brandPrimary),
                    onPressed: () {
                      _searchController.clear();
                      _runSearchFilter('');
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Supervisor Requirement Entry Route
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text(
                    'Find Providers Elsewhere',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RequestServiceScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              Text(
                _providerSectionTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandPrimary, letterSpacing: 0.3),
              ),
              if (_searchScopeNotice != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    _searchScopeNotice!,
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(height: 12),

              // The dynamic list remains completely unchanged...


              _filteredProviders.isEmpty
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text('No providers match your search.', style: TextStyle(color: Colors.grey)),
              )
                  : SizedBox(
                height: 175,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filteredProviders.length,
                  itemBuilder: (context, index) {
                    final provider = _filteredProviders[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProviderDetailScreen(provider: provider),
                          ),
                        );
                      },
                      child: Container(
                        width: 155,
                        margin: const EdgeInsets.only(right: 14, bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 52,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: brandSecondary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Icon(
                                    provider['icon'] is IconData ? provider['icon'] : Icons.person,
                                    color: brandPrimary,
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                provider['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                provider['category'] ?? '',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 15),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${provider['rating'] ?? '0.0'} (${provider['jobs'] ?? '0 jobs'})',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Browse Services',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandPrimary),
              ),
              const SizedBox(height: 12),

              _filteredCategories.isEmpty
                  ? const Text('No categories match your search.', style: TextStyle(color: Colors.grey))
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredCategories.length,
                itemBuilder: (context, index) {
                  final cat = _filteredCategories[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: brandPrimary.withValues(alpha: 0.1),
                        child: Icon(cat['icon'] is IconData ? cat['icon'] : Icons.category, color: brandPrimary),
                      ),
                      title: Text(
                          cat['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: brandPrimary)
                      ),
                      trailing: const Icon(Icons.chevron_right, color: brandSecondary),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FilteredServicesScreen(
                              categoryName: cat['name'] ?? '',
                              userDistrict: _userDistrict,
                              userTown: _userTown,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        title: const Text(
            'Ur Plug',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white)
        ),
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Tooltip(
            message: 'Logout from Ur Plug',
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: const Icon(Icons.logout, size: 20),
              label: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              },
            ),
          ),
        ],
      ),
      body: _buildBodyContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: brandPrimary,
        unselectedItemColor: brandSecondary.withValues(alpha: 0.6),
        showUnselectedLabels: true,
        selectedFontSize: 13,
        unselectedFontSize: 12,
        elevation: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            activeIcon: Icon(Icons.history_toggle_off),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class FilteredServicesScreen extends StatefulWidget {
  final String categoryName;
  final String userDistrict;
  final String userTown;

  const FilteredServicesScreen({
    super.key,
    required this.categoryName,
    required this.userDistrict,
    required this.userTown,
  });

  @override
  State<FilteredServicesScreen> createState() => _FilteredServicesScreenState();
}

class _FilteredServicesScreenState extends State<FilteredServicesScreen> {
  static const Color brandPrimary = Color(0xFF005F73);
  static const Color brandSecondary = Color(0xFF0A9396);
  static const Color screenBackground = Color(0xFFE0F2F1);

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _providers = [];

  double _score(Map<String, dynamic> provider) {
    double score = 0;
    final String providerDistrict = (provider['district'] ?? '').toString().toLowerCase();
    final String userDistrictLower = widget.userDistrict.toLowerCase();

    if (providerDistrict == userDistrictLower) {
      score += 30;
    } else if (subRegionOf(providerDistrict) != null &&
        subRegionOf(providerDistrict) == subRegionOf(widget.userDistrict)) {
      score += 15;
    }

    if ((provider['town'] ?? '').toString().toLowerCase() == widget.userTown.toLowerCase()) {
      score += 20;
    }
    score += (provider['rating'] as double? ?? 0.0) * 10;
    score += (provider['jobs'] as int? ?? 0) * 0.5;
    score += (provider['responseRate'] as double? ?? 0.0) * 5;
    return score;
  }

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    try {
      final categoryLower = widget.categoryName.toLowerCase();

      final snapshot = await FirebaseFirestore.instance
          .collection('providers')
          .where('businessCategoryLower', isEqualTo: categoryLower)
          .where('available', isEqualTo: true)
          .get();

      final providers = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['businessName'] ?? '',
          'category': data['businessCategory'] ?? '',
          'district': data['district'] ?? '',
          'town': data['town'] ?? '',
          'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
          'jobs': data['completedJobs'] ?? 0,
          'responseRate': (data['responseRate'] as num?)?.toDouble() ?? 0.0,
          'bio': data['bio'] ?? '',
          'yearsOfExperience': data['yearsOfExperience'] ?? 0,
          'phone': data['phone'] ?? '',
          'icon': Icons.person,
        };
      }).toList();

      providers.sort((a, b) => _score(b).compareTo(_score(a)));

      if (mounted) {
        setState(() {
          _providers = providers;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load providers. Please try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        title: Text(widget.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available ${widget.categoryName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandPrimary),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: brandPrimary))
                  : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)))
                  : _providers.isEmpty
                  ? const Center(
                child: Text(
                  'No providers available in this category right now.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              )
                  : ListView.builder(
                itemCount: _providers.length,
                itemBuilder: (context, index) {
                  final provider = _providers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(provider['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${provider['town'] ?? ''}, ${provider['district'] ?? ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text('${provider['rating'] ?? 0}'),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProviderDetailScreen(provider: provider),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  static const Color brandPrimary = Color(0xFF005F73);
  static const Color brandSecondary = Color(0xFF0A9396);

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  bool _updatingPhoto = false;

  // Toggle between read-only view and editable form
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;

  // Store last-saved values so Cancel can restore them
  String _savedName = '';
  String _savedPhone = '';
  String _savedLocation = '';

  bool _hasPrepopulated = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _loadLoggedInUserSession();
  }

  Future<void> _loadLoggedInUserSession() async {
    final user = await AuthService().getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _nameController.text = user.fullName;
        _phoneController.text = user.contact ?? '';
        _locationController.text = '${user.town ?? ''}, ${user.district ?? ''}';

        _savedName = _nameController.text;
        _savedPhone = _phoneController.text;
        _savedLocation = _locationController.text;

        _hasPrepopulated = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<ImageSource?> _askImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: brandPrimary),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: brandPrimary),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeProfilePhoto() async {
    final controller = context.read<CustomerProfileController>();
    final source = await _askImageSource();
    if (source == null) return;

    final file = await _picker.pickImage(source: source, imageQuality: 82);
    if (file == null) return;

    if (!mounted) return;
    setState(() => _updatingPhoto = true);

    final ok = await controller.setProfilePhoto(file.path);

    if (!mounted) return;
    setState(() => _updatingPhoto = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update your profile photo.')),
      );
    }
  }

  Widget _readOnlyField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: brandPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<CustomerProfileController>().profile;

    if (!_hasPrepopulated && (profile.name.isNotEmpty || profile.phone.isNotEmpty || profile.location.isNotEmpty)) {
      if (profile.name.isNotEmpty) _nameController.text = profile.name;
      if (profile.phone.isNotEmpty) _phoneController.text = profile.phone;
      if (profile.location.isNotEmpty) _locationController.text = profile.location;
      _savedName = _nameController.text;
      _savedPhone = _phoneController.text;
      _savedLocation = _locationController.text;
      _hasPrepopulated = true;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            GestureDetector(
              onTap: _updatingPhoto ? null : _changeProfilePhoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: brandPrimary.withValues(alpha: 0.15),
                    backgroundImage: profile.profilePhotoPath.isNotEmpty
                        ? FileImage(io.File(profile.profilePhotoPath)) as ImageProvider
                        : null,
                    child: _updatingPhoto
                        ? const CircularProgressIndicator(color: brandPrimary, strokeWidth: 3)
                        : profile.profilePhotoPath.isEmpty
                        ? const Icon(Icons.person, size: 65, color: brandPrimary)
                        : null,
                  ),
                  if (!_updatingPhoto)
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: brandSecondary,
                        child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandPrimary),
                      ),
                      if (!_isEditing)
                        TextButton.icon(
                          onPressed: () => setState(() => _isEditing = true),
                          icon: const Icon(Icons.edit, size: 16, color: brandSecondary),
                          label: const Text('Edit', style: TextStyle(color: brandSecondary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (_isEditing) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline, color: brandPrimary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value!.isEmpty ? 'Name cannot be empty' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_android, color: brandPrimary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value!.isEmpty ? 'Phone number required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Your Location',
                        prefixIcon: const Icon(Icons.location_on_outlined, color: brandPrimary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value!.isEmpty ? 'Location area required' : null,
                    ),
                  ] else ...[
                    _readOnlyField('Full Name', _nameController.text, Icons.person_outline),
                    _readOnlyField('Phone Number', _phoneController.text, Icons.phone_android),
                    _readOnlyField('Your Location', _locationController.text, Icons.location_on_outlined),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (_isEditing)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: brandPrimary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          setState(() {
                            _nameController.text = _savedName;
                            _phoneController.text = _savedPhone;
                            _locationController.text = _savedLocation;
                            _isEditing = false;
                          });
                        },
                        child: const Text('Cancel', style: TextStyle(color: brandPrimary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<CustomerProfileController>().updateProfileDetails(
                              name: _nameController.text.trim(),
                              phone: _phoneController.text.trim(),
                              location: _locationController.text.trim(),
                            );
                            _savedName = _nameController.text;
                            _savedPhone = _phoneController.text;
                            _savedLocation = _locationController.text;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile details updated successfully!'),
                                backgroundColor: brandSecondary,
                              ),
                            );
                            setState(() => _isEditing = false);
                          }
                        },
                        child: const Text('Save Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}


class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  static const Color brandPrimary = Color(0xFF005F73);
  static const Color brandSecondary = Color(0xFF0A9396);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('customerUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: brandPrimary));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading bookings: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No booking history found.', style: TextStyle(color: Colors.grey, fontSize: 14)));
        }

        final bookings = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final doc = bookings[index];
            final data = doc.data() as Map<String, dynamic>;
            final String status = data['status'] ?? 'pending';
            final bool isCompleted = status == 'completed';

            Color statusColor = Colors.orange;
            if (status == 'completed') statusColor = Colors.green;
            if (status == 'declined') statusColor = Colors.red;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(data['providerName'] ?? 'Unknown Provider', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(data['category'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (isCompleted) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: brandSecondary)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProviderDetailScreen(provider: {
                                  'id': data['providerUid'] ?? '',
                                  'name': data['providerName'] ?? '',
                                  'category': data['category'] ?? '',
                                }),
                              ),
                            );
                          },
                          child: const Text('Leave a Review', style: TextStyle(color: brandSecondary, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Shows every chat the logged-in customer is part of, sourced live from
/// Firestore's `chats` collection (filtered by participants array).
class ActiveChatsDashboard extends StatelessWidget {
  const ActiveChatsDashboard({super.key});

  static const Color brandPrimary = Color(0xFF005F73);
  static const Color brandSecondary = Color(0xFF0A9396);

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: myUid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: brandPrimary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12)),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('No active conversations yet.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final participants = List<String>.from(data['participants'] ?? []);
            final otherUid = participants.firstWhere((id) => id != myUid, orElse: () => '');

            // providerUid/providerName are written by ChatScreen when a
            // customer starts a conversation, so the business name shows
            // up here instead of a raw UID.
            final String businessName = (data['providerName'] ?? '').toString();
            final String displayName = businessName.isNotEmpty ? businessName : 'Provider';
            final String lastMessage = data['lastMessage'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: brandPrimary.withValues(alpha: 0.1),
                  child: const Icon(Icons.storefront, color: brandPrimary),
                ),
                title: Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: brandPrimary, fontSize: 14),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        providerUid: otherUid,
                        providerName: displayName,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}