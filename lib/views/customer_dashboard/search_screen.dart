import 'package:flutter/material.dart';
import 'provider_detail_screen.dart';
import 'package:ur_plug/views/auth/login_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Brand Color Palette Configured Precisely
  static const Color brandPrimary = Color(0xFF005F73);      // Deep Ocean Teal
  static const Color brandSecondary = Color(0xFF0A9396);    // Rich Turquoise       
  static const Color screenBackground = Color(0xFFE0F2F1);  // Turquoise Ice Canvas

  // Text processing controller for live filtering
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allProviders = [
    {'name': 'Sarah\'s Tech Sparks', 'category': 'Electrician', 'rating': '4.9', 'jobs': '42 jobs', 'icon': Icons.bolt},
    {'name': 'Kla Clean Plugs', 'category': 'Plumber', 'rating': '4.8', 'jobs': '56 jobs', 'icon': Icons.water_drop},
    {'name': 'Express Repairs', 'category': 'Mechanic', 'rating': '4.7', 'jobs': '31 jobs', 'icon': Icons.car_repair}, 
    {'name': 'Kimuli Decorators', 'category': 'Event Decor', 'rating': '5.0', 'jobs': '19 jobs', 'icon': Icons.celebration},
  ];

  final List<Map<String, dynamic>> _allCategories = [
    {'name': 'Plumbers', 'icon': Icons.plumbing},
    {'name': 'Electricians', 'icon': Icons.electric_bolt},
    {'name': 'Carpenters', 'icon': Icons.chair},
    {'name': 'Catering & Decor', 'icon': Icons.local_pizza},
  ];

  // Dynamic filter lists initialized on startup
  List<Map<String, dynamic>> _filteredProviders = [];
  List<Map<String, dynamic>> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _filteredProviders = _allProviders;
    _filteredCategories = _allCategories;
  }

  // Active search filtering routine
  void _runSearchFilter(String enteredKeyword) {
    List<Map<String, dynamic>> providerResults = [];
    List<Map<String, dynamic>> categoryResults = [];
    
    if (enteredKeyword.isEmpty) {
      providerResults = _allProviders;
      categoryResults = _allCategories;
    } else {
      providerResults = _allProviders.where((item) =>
          item['name'].toLowerCase().contains(enteredKeyword.toLowerCase()) ||
          item['category'].toLowerCase().contains(enteredKeyword.toLowerCase())).toList();

      categoryResults = _allCategories.where((item) =>
          item['name'].toLowerCase().contains(enteredKeyword.toLowerCase())).toList();
    }

    setState(() {
      _filteredProviders = providerResults;
      _filteredCategories = categoryResults;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground,
      
      // Top Bar Layout Header
      appBar: AppBar(
        title: const Text(
          'Ur Plug', 
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white)
        ),
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // Hamburger Drawer with Live Destination Redirect Functions
      drawer: Drawer(
        backgroundColor: screenBackground,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [brandPrimary, brandSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: brandPrimary, size: 42),
              ),
              accountName: Text(
                'Acen Sharon', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)
              ),
              accountEmail: Text(
                'acen.sharon@urplug.com', 
                style: TextStyle(color: Colors.white70)
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: brandPrimary),
              title: const Text('Home', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: brandPrimary),
              title: const Text('Account details', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Update profile information'),
              onTap: () {
                Navigator.pop(context); // Close Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountDetailsScreenPlaceholder()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: brandPrimary),
              title: const Text('My Booking History', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context); // Close Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookingHistoryScreenPlaceholder()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(context, 
                MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              },
            ),
          ],
        ),
      ),

      // Scrollable dashboard main view
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 24),

            const Text(
              'High Rated Services & Businesses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandPrimary, letterSpacing: 0.3),
            ),
            const SizedBox(height: 12),

            // Horizontal dynamic items display array
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
                              builder: (context) => ProviderDetailScreen(providerName: provider['name']),
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
                                    color: brandSecondary.withValues(alpha: 0.12),// FIXED: withValues
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(provider['icon'], color: brandPrimary, size: 26),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              provider['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              provider['category'],
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  '${provider['rating']} (${provider['jobs']})',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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

            // Secondary Exploration Area: Browse Categories
            const Text(
              'Browse Services',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: brandPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Vertical list styling to discover general trade providers
            _filteredCategories.isEmpty ? const Text('No categories match your search.', style: TextStyle(color: Colors.grey)) :
            ListView.builder(
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
                      child: Icon(cat['icon'], color: brandPrimary),
                    ),
                    title: Text(
                      cat['name'], 
                      style: const TextStyle(fontWeight: FontWeight.w600, color: brandPrimary)
                    ),
                    trailing: const Icon(Icons.chevron_right, color: brandSecondary),
                    onTap: () {
                      // FIXED: This now opens a dynamic filtered screen for your presentation!
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FilteredServicesScreen(categoryName: cat['name']),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),  
      ),
    );
  }
}


// Placeholder Destination for Booking Tracking Actions
class BookingHistoryScreenPlaceholder extends StatelessWidget {
  const BookingHistoryScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F1),
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: const Color(0xFF005F73),
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Booking history.')),
    );
  }
}


// Dynamic category screen to show the lady how filtering works
// Dynamic category screen to show the lady how filtering works
class FilteredServicesScreen extends StatelessWidget {
  final String categoryName;
  const FilteredServicesScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    // Shared theme colors
    const Color brandPrimary = Color(0xFF005F73);
    const Color screenBackground = Color(0xFFE0F2F1);

    // Dynamic names based on category for realism
    final String providerOne = categoryName == 'Plumbers' ? 'Musa Local Fixes' : 'Kintu Handyman Services';
    final String providerTwo = categoryName == 'Electricians' ? 'Kampala Power Plugs' : 'Katwe Trade Experts';

    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        title: Text(categoryName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available $categoryName Near Kirinya',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandPrimary),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 2, // Mocking two specific tradespeople
                itemBuilder: (context, index) {
                  final currentName = index == 0 ? providerOne : providerTwo;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: screenBackground,
                        child: Icon(Icons.person, color: brandPrimary),
                      ),
                      title: Text(
                        currentName, 
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('$categoryName • 4.8 Rating'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: brandPrimary),
                      onTap: () {
                        // FIXED: This now routes directly to the ProviderDetailScreen with the correct name!
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProviderDetailScreen(providerName: currentName),
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

class AccountDetailsScreenPlaceholder extends StatefulWidget {
  const AccountDetailsScreenPlaceholder({super.key});

  @override
  State<AccountDetailsScreenPlaceholder> createState() => _AccountDetailsScreenPlaceholderState();
}

class _AccountDetailsScreenPlaceholderState extends State<AccountDetailsScreenPlaceholder> {
  static const Color brandPrimary = Color(0xFF005F73);      
  static const Color brandSecondary = Color(0xFF0A9396);    
  static const Color screenBackground = Color(0xFFE0F2F1);  

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Acen Sharon');
  final _phoneController = TextEditingController(text: '+256 701 234567');
  final _locationController = TextEditingController(text: 'Kirinya, Bweyogerere');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        title: const Text('Account Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: brandPrimary.withValues(alpha: 0.15),
                    child: const Icon(Icons.person, size: 65, color: brandPrimary),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: brandSecondary,
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ],
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
                    const Text(
                      'Personal Information',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandPrimary),
                    ),
                    const SizedBox(height: 18),
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
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile details updated successfully!'),
                          backgroundColor: brandSecondary,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}