import 'dart:io' as io;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../state/customer_profile_controller.dart';
import 'package:flutter/material.dart';
import 'provider_detail_screen.dart';
import 'package:ur_plug/views/auth/login_screen.dart';
import 'chat_screen.dart';

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

  // Bottom Navigation Index State
  int _currentIndex = 0;
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

     // Realistic mock tracking data for booking history
  final List<Map<String, dynamic>> _bookingHistory = [
    {
      'provider': 'Sarah\'s Tech Sparks',
      'category': 'Electrician',
      'date': '12 July, 2026',
      'rating': '4.9',
      'status': 'Completed',
      'icon': Icons.bolt,
      'statusColor': Colors.green,
    },
    {
      'provider': 'Kla Clean Plugs',
      'category': 'Plumber',
      'date': 'In Progress',
      'rating': '',
      'status': 'Active',
      'icon': Icons.water_drop,
      'statusColor': Colors.orange,
    },
    {
      'provider': 'Kimuli Decorators',
      'category': 'Event Decor',
      'date': '04 June, 2026',
      'rating': '5.0',
      'status': 'Completed',
      'icon': Icons.celebration,
      'statusColor': Colors.green,
    },
    {
      'provider': 'Express Repairs',
      'category': 'Mechanic',
      'date': '20 May, 2026',
      'rating': '',
      'status': 'Cancelled',
      'icon': Icons.car_repair,
      'statusColor': Colors.red,
    },
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

  // Helper builder method to manage dynamic screen views

  Widget _buildBodyContent() {
    switch (_currentIndex) {
      case 1:
        return const ActiveChatsDashboard();
      case 2:
        return const AccountDetailsScreen();
      case 3:
        return  BookingHistoryScreen(bookings: _bookingHistory);
      case 0:
      default:
        return SingleChildScrollView(
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
                                      color: brandSecondary.withValues(alpha: 0.12),
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
                                      Expanded(
                                        child: Text(
                                          '${provider['rating']} (${provider['jobs']})',
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

              // Browse General Services Trade Categories
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
                            child: Icon(cat['icon'], color: brandPrimary),
                          ),
                          title: Text(
                            cat['name'], 
                            style: const TextStyle(fontWeight: FontWeight.w600, color: brandPrimary)
                          ),
                          trailing: const Icon(Icons.chevron_right, color: brandSecondary),
                          onTap: () {
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
                  MaterialPageRoute(builder: (context) => const LoginScreen()), 
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),


      // Injects the dynamic screen content depending on current tab index
      body: _buildBodyContent(),

      // Core bottom navigation replacing the old hamburger drawer
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

class BookingHistoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;
  
  const BookingHistoryScreen({super.key, required this.bookings});

  @override
  Widget build(BuildContext context) {
    const Color brandPrimary = Color(0xFF005F73);

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        
        // Safety Fallback Checks for state evaluation
        final String status = booking['status']?.toString() ?? '';
        final String rating = booking['rating']?.toString() ?? '';
        final bool isCompleted = status == 'Completed';
        final bool hasRating = rating.isNotEmpty && rating != '0' && rating != '0.0';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: brandPrimary.withValues(alpha: 0.1),
                child: Icon(booking['icon'], color: brandPrimary),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking['provider'] ?? 'Unknown Provider',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // FIXED: Simplified conditional block ensures ratings render if completed
                  if (isCompleted && hasRating)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: brandPrimary),
                        ),
                      ],
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${booking['category'] ?? ''} • ${booking['date'] ?? ''}', 
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (booking['statusColor'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: booking['statusColor'],
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}



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

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    // Pre-populate text controllers with live values from your new controller state
    final profile = context.read<CustomerProfileController>().profile;
    _nameController = TextEditingController(text: profile.name);
    _phoneController = TextEditingController(text: profile.phone);
    _locationController = TextEditingController(text: profile.location);
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
      builder: (context) => SafeArea(
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

  @override
  Widget build(BuildContext context) {
    // Watches the customer profile state to automatically re-render when a photo changes
    final profile = context.watch<CustomerProfileController>().profile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Clickable avatar stack configured to load the path dynamically
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
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: brandSecondary,
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
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
                    // Saves inputs to state repository
                    context.read<CustomerProfileController>().updateProfileDetails(
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          location: _locationController.text.trim(),
                        );
                        
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile details updated successfully!'),
                        backgroundColor: brandSecondary,
                      ),
                    );
                  }
                },
                child: const Text('Save Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class ActiveChatsDashboard extends StatelessWidget {
  const ActiveChatsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandPrimary = Color(0xFF005F73);
    const Color brandSecondary = Color(0xFF0A9396);

    // Realistic simulation data mimicking real client provider threads
    final List<Map<String, dynamic>> mockThreads = [
      {
        'name': 'Sarah\'s Tech Sparks',
        'message': 'Web connection sorted! Let me know if you need...',
        'time': '10:42 AM',
        'isUnread': true, // Displays notification status indicator bubble
        'icon': Icons.bolt,
      },
      {
        'name': 'Kla Clean Plugs',
        'message': 'I am arriving at Kirinya Centre near the station now.',
        'time': 'Yesterday',
        'isUnread': false,
        'icon': Icons.water_drop,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: mockThreads.length,
      itemBuilder: (context, index) {
        final thread = mockThreads[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: brandPrimary.withValues(alpha: 0.1),
              child: Icon(thread['icon'], color: brandPrimary),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  thread['name'], 
                  style: TextStyle(
                    fontWeight: thread['isUnread'] ? FontWeight.bold : FontWeight.w600,
                    color: brandPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  thread['time'], 
                  style: TextStyle(
                    fontSize: 11, 
                    color: thread['isUnread'] ? brandSecondary : Colors.grey,
                    fontWeight: thread['isUnread'] ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                thread['message'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: thread['isUnread'] ? Colors.black87 : Colors.grey,
                  fontWeight: thread['isUnread'] ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            trailing: thread['isUnread'] 
              ? const CircleAvatar(radius: 5, backgroundColor: brandSecondary) // Unread Alert Dot!
              : const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    providerName: thread['name'] ?? 'Provider', // Fallback for safety
                  ),
                 ),
              );
            },
          ),
        );
      },
    );
  }
}


