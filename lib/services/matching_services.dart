import 'package:cloud_firestore/cloud_firestore.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, List<String>> serviceKeywords = {
    "Plumbing": [
      "toilet", "tap", "sink", "pipe", "drain", "leak", "leaking", "water", "flush", "shower",
    ],
    "Electrician": [
      "socket", "switch", "wire", "wiring", "bulb", "power", "electricity", "generator", "lights", "light",
    ],
    "Mechanic": [
      "car", "vehicle", "engine", "gearbox", "battery", "tyre", "brake", "oil", "breakdown",
    ],
    "Interior Design": [
      "decor", "design", "painting", "wall", "ceiling", "tiles", "curtains", "furniture",
    ],
    "Carpenter": [
      "door", "window", "chair", "table", "cabinet", "wood", "roof",
    ],
    "Welder": [
      "gate", "window", "metal", "welding", "steel", "grill", "burglar proofing",
    ],
    "Cleaner": [
      "clean", "washing", "laundry", "compound", "office", "house",
    ],
    "Painter": [
      "paint", "painting", "wall", "colour", "house",
    ],
    "Phone Repair": [
      "phone", "screen", "battery", "charging", "speaker", "camera",
    ],
    "Computer Repair": [
      "computer", "laptop", "printer", "keyboard", "software", "windows",
    ],
    "Handyman": [
      "repair", "fix", "maintenance", "general",
    ],
  };

  String identifyService(String description) {
    description = description.toLowerCase();

    for (var entry in serviceKeywords.entries) {
      for (String keyword in entry.value) {
        if (description.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return "";
  }

  Future<Map<String, dynamic>> searchProviders({
    String service = "",
    String description = "",
    required String district,
    required String town,
  }) async {
    if (service.isEmpty && description.isNotEmpty) {
      service = identifyService(description);
    }

    if (service.isEmpty) {
      return {
        "success": false,
        "message": "Unable to identify the required service from the description.",
        "count": 0,
        "providers": [],
      };
    }

    final String categoryLower = service.toLowerCase();
    final String districtLower = district.toLowerCase();
    final String townLower = town.toLowerCase();

    String message = "";
    List<QueryDocumentSnapshot> providers = [];

    try {
      QuerySnapshot townSnapshot = await _firestore
          .collection('providers')
          .where('businessCategoryLower', isEqualTo: categoryLower)
          .where('districtLower', isEqualTo: districtLower)
          .where('townLower', isEqualTo: townLower)
          .where('available', isEqualTo: true)
          .get();

      providers = townSnapshot.docs;

      if (providers.isNotEmpty) {
        message = "Providers found in your town.";
      } else {
        QuerySnapshot districtSnapshot = await _firestore
            .collection('providers')
            .where('businessCategoryLower', isEqualTo: categoryLower)
            .where('district', isEqualTo: district)
            .where('available', isEqualTo: true)
            .get();

        providers = districtSnapshot.docs;

        if (providers.isNotEmpty) {
          message = "No $service providers were found in $town. Showing providers from other towns in $district.";
        } else {
          if (description.isNotEmpty) {
            QuerySnapshot allProviders = await _firestore
                .collection('providers')
                .where('available', isEqualTo: true)
                .get();

            providers = allProviders.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              List keywords = data['keywords'] ?? [];

              return keywords.any((keyword) =>
                  description.toLowerCase().contains(keyword.toString().toLowerCase()));
            }).toList();
          }

          if (providers.isEmpty) {
            QuerySnapshot countrySnapshot = await _firestore
                .collection('providers')
                .where('businessCategoryLower', isEqualTo: categoryLower)
                .where('available', isEqualTo: true)
                .get();

            providers = countrySnapshot.docs;

            if (providers.isNotEmpty) {
              message = "No providers were found in your district. Showing the highest ranked providers from other districts.";
            } else {
              message = "No providers were found for this service.";
            }
          }
        }
      }
    } on FirebaseException catch (e) {
      // surfaces composite-index errors and permission errors instead of
      // hanging on a loading state forever
      return {
        "success": false,
        "message": "Search failed: ${e.message}",
        "count": 0,
        "providers": [],
      };
    }

    providers.sort((a, b) {
      double scoreA = calculateScore(a.data() as Map<String, dynamic>, district, town);
      double scoreB = calculateScore(b.data() as Map<String, dynamic>, district, town);
      return scoreB.compareTo(scoreA);
    });

    if (providers.length > 10) {
      providers = providers.take(10).toList();
    }

    return {
      "success": providers.isNotEmpty,
      "message": message,
      "count": providers.length,
      "providers": providers,
    };
  }

  double calculateScore(
      Map<String, dynamic> provider,
      String userDistrict,
      String userTown,
      ) {
    double score = 0;

    if ((provider['district'] ?? '').toString().toLowerCase() == userDistrict.toLowerCase()) {
      score += 30;
    }

    if ((provider['town'] ?? '').toString().toLowerCase() == userTown.toLowerCase()) {
      score += 20;
    }

    double rating = (provider['rating'] as num?)?.toDouble() ?? 0.0;
    score += rating * 10;

    int completedJobs = (provider['completedJobs'] ?? 0) as int;
    score += completedJobs * 0.5;

    double responseRate = (provider['responseRate'] as num?)?.toDouble() ?? 0.0;
    score += responseRate * 5;

    return score;
  }

  double updateRating({
    required double currentRating,
    required int reviewCount,
    required double newRating,
  }) {
    return ((currentRating * reviewCount) + newRating) / (reviewCount + 1);
  }

  int updateReviewCount(int reviewCount) {
    return reviewCount + 1;
  }

  int updateCompletedJobs(int completedJobs) {
    return completedJobs + 1;
  }
}