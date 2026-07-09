import 'package:cloud_firestore/cloud_firestore.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<QueryDocumentSnapshot>> searchProviders({
    required String business category,
    required String district,
    required String town,
  }) async {


    QuerySnapshot snapshot = await _firestore
        .collection('providers')
        .where(' business category', isEqualTo:  business category)
        .where('district', isEqualTo: district)
        .where('available', isEqualTo: true)
        .get();

    List<QueryDocumentSnapshot> providers = snapshot.docs;

    if (providers.isEmpty) {
      QuerySnapshot fallbackSnapshot = await _firestore
          .collection('providers')
          .where(' business category', isEqualTo:  business category)
          .where('available', isEqualTo: true)
          .get();

      providers = fallbackSnapshot.docs;
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

    return providers;
  }

  double calculateScore(
    Map<String, dynamic> provider,
    String userDistrict,
    String town,
  ) {
    double score = 0;

    if ((provider['district'] ?? '').toString().toLowerCase() ==
        userDistrict.toLowerCase()) {
      score += 20;
    }

    if ((provider['town'] ?? '').toString().toLowerCase() ==
        usertown.toLowerCase()) {
      score += 15;
    }

   ;
    }

    score += ((provider['rating'] ?? 0).toDouble()) * 5;

    score += (provider['completedJobs'] ?? 0) * 0.2;

    score += (provider['responseRate'] ?? 0) * 0.1;

    return score;
  }
}
