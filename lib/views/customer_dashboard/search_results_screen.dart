import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'provider_detail_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  final String category;
  final String town;
  final Map<String, dynamic> result;

  const SearchResultsScreen({
    super.key,
    required this.category,
    required this.town,
    required this.result,
  });

  static const Color brandPrimary = Color(0xFF005F73);
  static const Color screenBackground = Color(0xFFE0F2F1);

  @override
  Widget build(BuildContext context) {
    final List<QueryDocumentSnapshot> providers =
    List<QueryDocumentSnapshot>.from(result['providers'] ?? []);
    final String message = result['message'] ?? '';

    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        title: Text('$category near $town', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(message, style: const TextStyle(color: Colors.grey)),
            ),
          Expanded(
            child: providers.isEmpty
                ? const Center(
              child: Text('No providers found.', style: TextStyle(color: Colors.grey)),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: providers.length,
              itemBuilder: (context, index) {
                final data = providers[index].data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(data['businessName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${data['businessCategory'] ?? ''} · ${data['town'] ?? ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text('${data['rating'] ?? 0}'),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProviderDetailScreen(provider: {
                            'id': providers[index].id,
                            'name': data['businessName'] ?? '',
                            'category': data['businessCategory'] ?? '',
                          }),
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
    );
  }
}