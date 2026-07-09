import 'package:cloud_firestore/cloud_firestore.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<QueryDocumentSnapshot>> searchProviders({
    required String service,
    required String district,
    required String parish,
    required String landmark,
  }) async {


    QuerySnapshot snapshot = await _firestore
        .collection('providers')
        .where('service', isEqualTo: service)
        .where('district', isEqualTo: district)
        .where('available', isEqualTo: true)
        .get();

    List<QueryDocumentSnapshot> providers = snapshot.docs;

    if (providers.isEmpty) {
      QuerySnapshot fallbackSnapshot = await _firestore
          .collection('providers')
          .where('service', isEqualTo: service)
          .where('available', isEqualTo: true)
          .get();

      providers = fallbackSnapshot.docs;
    }

    providers.sort((a, b) {
      double scoreA = calculateScore(
        a.data() as Map<String, dynamic>,
        district,
        parish,
        landmark,
      );

      double scoreB = calculateScore(
        b.data() as Map<String, dynamic>,
        district,
        parish,
        landmark,
      );

      return scoreB.compareTo(scoreA);
    });

    return providers;
  }

  double calculateScore(
    Map<String, dynamic> provider,
    String userDistrict,
    String userParish,
    String userLandmark,
  ) {
    double score = 0;

    if ((provider['district'] ?? '').toString().toLowerCase() ==
        userDistrict.toLowerCase()) {
      score += 20;
    }

    if ((provider['parish'] ?? '').toString().toLowerCase() ==
        userParish.toLowerCase()) {
      score += 10;
    }

    if ((provider['landmark'] ?? '').toString().toLowerCase() ==
        userLandmark.toLowerCase()) {
      score += 5;
    }

    score += ((provider['rating'] ?? 0).toDouble()) * 5;

    score += (provider['completedJobs'] ?? 0) * 0.2;

    score += (provider['responseRate'] ?? 0) * 0.1;

    return score;
  }
}