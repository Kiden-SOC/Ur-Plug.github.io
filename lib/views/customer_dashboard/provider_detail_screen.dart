import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ProviderDetailScreen extends StatelessWidget {
  final String providerName;
  const ProviderDetailScreen({super.key, required this.providerName});

  // App Palette Configuration
  static const Color brandPrimary = Color(0xFF005F73);      // Deep Ocean Teal
  static const Color brandSecondary = Color(0xFF0A9396);    // Rich Turquoise       
  static const Color screenBackground = Color(0xFFE0F2F1);  // Turquoise Ice Canvas

  @override
  Widget build(BuildContext context) {
    // Dynamic fallback details based on trade for maximum presentation realism
    final bool isElectrician = providerName.contains('Sparks') || providerName.contains('Power') || providerName.contains('Tech');
    final String tradeTitle = isElectrician ? 'Certified Electrician' : 'Master Plumber & Pipefitter';
    final String experienceText = isElectrician ? '6 Years' : '4 Years';
    final String completedJobsText = isElectrician ? '42 Jobs' : '56 Jobs';
    final String bioText = isElectrician 
      ? 'Specialized in domestic house wiring, solar system installations, and emergency short-circuit fault finding across Kampala.'
      : 'Expert in fixing broken pipes, water pump maintenance, toilet installations, and clearing clogged drainage systems.';

    // Ur Plug Innovation: Smart landmark descriptors instead of raw device GPS
    final String smartLocationMarker = isElectrician
      ? 'Kirinya Trading Centre, near the TotalEnergies Station'
      : 'Bweyogerere Stage, opposite the Mandela National Stadium area';

    final List<String> specializations = isElectrician 
      ? ['House Wiring', 'Fault Finding', 'Inverter Setup', 'Appliance Repair']
      : ['Leak Detection', 'Drain Unclogging', 'Pump Service', 'Tap Installation'];

    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        title: const Text(
          'Provider Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. RICH PROFILE PROFILE CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45, 
                    backgroundColor: brandPrimary.withValues(alpha: 0.1), 
                    child: Icon(isElectrician ? Icons.bolt : Icons.plumbing, size: 45, color: brandPrimary)
                  ),
                  const SizedBox(height: 12),
                  Text(
                    providerName, 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandPrimary),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    tradeTitle, 
                    style: const TextStyle(fontSize: 15, color: brandSecondary, fontWeight: FontWeight.w600)
                  ),
                  const SizedBox(height: 12),
                  
                  // Verification Badge & Availability Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: brandSecondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified, size: 14, color: brandSecondary),
                            SizedBox(width: 4),
                            Text('Verified Plug', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: brandPrimary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            CircleAvatar(radius: 4, backgroundColor: Colors.green),
                            SizedBox(width: 6),
                            Text('Available Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Core Metrics Layout (Completely Stripped Financial Pricing Feature)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricItem(Icons.history_toggle_off, 'Experience', experienceText),
                      _buildMetricItem(Icons.task_alt, 'Completed', completedJobsText),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // 2. SMART LOCATION TECH HIGHLIGHT BLOCK
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.near_me, color: brandSecondary, size: 20),
                      SizedBox(width: 8),
                      Text('Smart Matched Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandPrimary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    smartLocationMarker,
                    style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.3, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Matched using Ur Plug smart matching technique.',
                    style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. SPECIALIZATIONS CHIP LAYOUT
            const Text('Specializations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: specializations.map((spec) {
                return Chip(
                  label: Text(spec, style: const TextStyle(fontSize: 12, color: brandPrimary, fontWeight: FontWeight.w500)),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: brandPrimary.withValues(alpha: 0.15)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 4. BUSINESS BIOGRAPHY
            const Text('About Provider', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandPrimary)),
            const SizedBox(height: 6),
            Text(bioText, style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4)),
            const SizedBox(height: 24),
            
            // 5. PRIMARY CONTACT ACTION TRIGGER
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatScreen(providerName: providerName)),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                label: const Text('Message Provider', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 28),
            
            // 6. PUBLIC RATINGS FEED LOG
            const Text('Verified Client Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandPrimary)),
            const SizedBox(height: 12),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildReviewCard(
                  clientName: 'Atim Grace',
                  reviewText: 'Arrived perfectly on time and sorted my wiring fault immediately. Highly recommended!',
                  starRating: '5.0',),
                  
                _buildReviewCard(
                  clientName: 'Nakyiwa Eleanor',
                  reviewText: 'Fair pricing structure, prompt responses in-app, and professional behavior.',
                  starRating: '4.8',),
              ],
            ),
          ],
        ),
      ),
    );
  }

Widget _buildMetricItem(IconData icon, String label, String value) {
  return Column(
    children: [Icon(icon, color: brandSecondary, size: 24),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandPrimary)),
    ],
  );
}
Widget 
_buildReviewCard({required String clientName, required String reviewText, required String starRating}) {
  return Container(margin: const EdgeInsets.only(bottom: 12),
  decoration: BoxDecoration(color: Colors.white, 
  borderRadius: BorderRadius.circular(16)),
  child: Padding(padding: const EdgeInsets.all(14.0),
  child: 
  Column(crossAxisAlignment: CrossAxisAlignment.start,
  children: [Row(children: [CircleAvatar(radius: 16,backgroundColor: brandPrimary.withValues(alpha: 0.1),child: const Icon(Icons.person_outline, size: 16, color: brandPrimary),),
  const SizedBox(width: 10),
  Column(crossAxisAlignment: CrossAxisAlignment.start,children: [Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold, color: brandPrimary, fontSize: 13)),
  const Row(children: [Icon(Icons.check_circle, size: 11, color: brandSecondary),
  SizedBox(width: 4),Text('Hired Order Match', style: TextStyle(fontSize: 10, color: Colors.grey)),],),],),
  const Spacer(),Row(
    children: [const Icon(Icons.star, color: Colors.amber, size: 14),const SizedBox(width: 4),Text(starRating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),],),],),const SizedBox(height: 8),Text(reviewText, style: const TextStyle(color: Colors.black87, fontSize: 12.5, height: 1.4)),
  ],
  ),
  ),
  );
  }
  }

