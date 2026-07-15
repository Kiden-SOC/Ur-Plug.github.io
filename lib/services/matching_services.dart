import 'package:cloud_firestore/cloud_firestore.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> searchProviders({
    required String service,
    required String district,
    required String town,
  }) async {

    String message = "";
    List<QueryDocumentSnapshot> providers = [];

    QuerySnapshot townSnapshot = await _firestore
        .collection('providers')
        .where('service', isEqualTo: service)
        .where('district', isEqualTo: district)
        .where('town', isEqualTo: town)
        .where('available', isEqualTo: true)
        .get();

    providers = townSnapshot.docs;

    if (providers.isNotEmpty) {
      message = "Providers found in your town.";
    } else {

      QuerySnapshot districtSnapshot = await _firestore
          .collection('providers')
          .where('service', isEqualTo: service)
          .where('district', isEqualTo: district)
          .where('available', isEqualTo: true)
          .get();

      providers = districtSnapshot.docs;

      if (providers.isNotEmpty) {
        message =
            "No $service providers were found in $town. Showing providers from other towns in $district District.";
      } else {


        QuerySnapshot countrySnapshot = await _firestore
            .collection('providers')
            .where('service', isEqualTo: service)
            .where('available', isEqualTo: true)
            .get();

        providers = countrySnapshot.docs;

        if (providers.isNotEmpty) {
          message =
              "No $service providers were found in $district District. Showing the highest-rated providers from other districts.";
        } else {
          message =
              "Sorry, there are currently no $service providers registered on the platform.";
        }
      }
    }


    providers.sort((a, b) {
      double scoreA = calculateScore(
        a.data() as Map<String, dynamic>,
        district,
        town,
      );

      double scoreB = calculateScore(
        b.data() as Map<String, dynamic>,
        district,
        town,
      );

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

    if ((provider['district'] ?? '').toString().toLowerCase() ==
        userDistrict.toLowerCase()) {
      score += 20;
    }

  
    if ((provider['town'] ?? '').toString().toLowerCase() ==
        userTown.toLowerCase()) {
      score += 10;
    }


    score += ((provider['rating'] ?? 0).toDouble()) * 5;

    
    score += (provider['completedJobs'] ?? 0) * 0.2;

  
    score += (provider['responseRate'] ?? 0) * 0.1;

    return score;
  }
}
