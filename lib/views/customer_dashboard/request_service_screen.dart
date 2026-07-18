import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/customer_profile_controller.dart';

class RequestServiceScreen extends StatefulWidget {
  const RequestServiceScreen({super.key});

  @override
  State<RequestServiceScreen> createState() => _RequestServiceScreenState();
}

class _RequestServiceScreenState extends State<RequestServiceScreen> {
  // Brand Color Palette Configured Precisely
  static const Color brandPrimary = Color(0xFF005F73);      // Deep Ocean Teal
  static const Color brandSecondary = Color(0xFF0A9396);    // Rich Turquoise       
  static const Color screenBackground = Color(0xFFE0F2F1);  // Turquoise Ice Canvas

  final _formKey = GlobalKey<FormState>();
  
  // State variables for form tracking
  String? _selectedCategory;
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _townController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();

  // Categories list matching your app's service layout
  final List<String> _categories = [
    'Plumbers',
    'Electricians',
    'Carpenters',
    'Catering & Decor',
    'Mechanics',
    'Other Services',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populates the district input with the user's registration region
    final profile = context.read<CustomerProfileController>().profile;
    _districtController.text = profile.location;
  }

  @override
  void dispose() {
    _districtController.dispose();
    _townController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        title: const Text(
          'Request a Service',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Where do you need the service?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Change these fields if you need a service outside your home area.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // 1. Service Type Selector Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                hint: const Text('Select service category'),
                decoration: InputDecoration(
                  labelText: 'Service Type',
                  prefixIcon: const Icon(Icons.handyman_outlined, color: brandPrimary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) => value == null ? 'Please select a service type' : null,
              ),

              if (_selectedCategory == 'Other Services') ...[
                const SizedBox(height: 18),
                TextFormField(
                  controller: _customCategoryController,
                  decoration: InputDecoration(
                    labelText: 'Specify Service Needed',
                    hintText: 'e.g., Painter, Tailor, AC Repair',
                    prefixIcon: const Icon(Icons.edit_note_outlined, color: brandPrimary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter the specific service name' : null,
                ),
              ],

              const SizedBox(height: 18),

              // 2. Custom Target District Input
              TextFormField(
                controller: _districtController,
                decoration: InputDecoration(
                  labelText: 'District',
                  prefixIcon: const Icon(Icons.map_outlined, color: brandPrimary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => value!.isEmpty ? 'Please input a target district' : null,
              ),
              const SizedBox(height: 18),

              // 3. Custom Target Town Input
              TextFormField(
                controller: _townController,
                decoration: InputDecoration(
                  labelText: 'Town / Specific Area',
                  prefixIcon: const Icon(Icons.location_on_outlined, color: brandPrimary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => value!.isEmpty ? 'Please input a specific town' : null,
              ),
              const SizedBox(height: 18),

              // 4. Job Details Multi-line Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Describe what you need fixed...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => value!.isEmpty ? 'Please give details about your request' : null,
              ),
              const SizedBox(height: 32),

              // 5. Submit Request Action Button
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
                      // Extracted execution strings ready for your partner's network hook
                      final String category = _selectedCategory == 'Other Services' ? _customCategoryController.text.trim() : _selectedCategory!;
                      final String targetDistrict = _districtController.text.trim();
                      final String targetTown = _townController.text.trim();
                      final String details = _descriptionController.text.trim();

                      debugPrint('Request logged: Category: $category, District: $targetDistrict, Town: $targetTown, Details: $details');

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Searching for $category in $targetTown...'),
                          backgroundColor: brandSecondary,
                        ),
                      );

                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Find Service Providers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}