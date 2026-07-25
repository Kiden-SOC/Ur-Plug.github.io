class ProviderProfile {
  final String uid;
  final String businessName;
  final String tradeTitle;
  final int yearsOfExperience;
  final String bio;
  final String district;
  final String town;
  final String landmarkDescription;
  
  final List<String> keywords;
  final double rating;
  final int reviewCount;
  final int completedJobs;
  final double responseRate;

  final double? latitude;
  final double? longitude;
  final String profilePhotoPath;
  final List<String> businessPhotoPaths;
  final bool isAvailable;
  final bool onboardingComplete;

  const ProviderProfile({
    this.uid = '',
    this.businessName = '',
    this.tradeTitle = '',
    this.yearsOfExperience = 0,
    this.bio = '',
    this.district = '',
    this.town = '',
    this.landmarkDescription = '',

    
    this.keywords = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.completedJobs = 0,
    this.responseRate = 100,

    this.latitude,
    this.longitude,
    this.profilePhotoPath = '',
    this.businessPhotoPaths = const [],
    this.isAvailable = true,
    this.onboardingComplete = false,
  });

  ProviderProfile copyWith({
    String? uid,
    String? businessName,
    String? tradeTitle,
    int? yearsOfExperience,
    String? bio,
    String? district,
    String? town,
    String? landmarkDescription,

    List<String>? keywords,
    double? rating,
    int? reviewCount,
    int? completedJobs,
    double? responseRate,

    double? latitude,
    double? longitude,
    String? profilePhotoPath,
    List<String>? businessPhotoPaths,
    bool? isAvailable,
    bool? onboardingComplete,
  }) {
    return ProviderProfile(
      uid: uid ?? this.uid,
      businessName: businessName ?? this.businessName,
      tradeTitle: tradeTitle ?? this.tradeTitle,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      bio: bio ?? this.bio,
      district: district ?? this.district,
      town: town ?? this.town,
      landmarkDescription:
          landmarkDescription ?? this.landmarkDescription,

      keywords: keywords ?? this.keywords,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      completedJobs:
          completedJobs ?? this.completedJobs,
      responseRate:
          responseRate ?? this.responseRate,

      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      profilePhotoPath:
          profilePhotoPath ?? this.profilePhotoPath,
      businessPhotoPaths:
          businessPhotoPaths ??
              this.businessPhotoPaths,
      isAvailable:
          isAvailable ?? this.isAvailable,
      onboardingComplete:
          onboardingComplete ??
              this.onboardingComplete,
    );
  }
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'businessName': businessName,
        'tradeTitle': tradeTitle,
        'yearsOfExperience': yearsOfExperience,
        'bio': bio,
        'district': district,
        'town': town,
        'landmarkDescription': landmarkDescription,

        // Matching fields
        'keywords': keywords,
        'rating': rating,
        'reviewCount': reviewCount,
        'completedJobs': completedJobs,
        'responseRate': responseRate,

        'latitude': latitude,
        'longitude': longitude,
        'profilePhotoPath': profilePhotoPath,
        'businessPhotoPaths': businessPhotoPaths,
        'isAvailable': isAvailable,
        'onboardingComplete': onboardingComplete,
      };

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    return ProviderProfile(
      uid: json['uid'] ?? '',
      businessName: json['businessName'] ?? '',
      tradeTitle: json['tradeTitle'] ?? '',
      yearsOfExperience: json['yearsOfExperience'] ?? 0,
      bio: json['bio'] ?? '',
      district: json['district'] ?? '',
      town: json['town'] ?? '',
      landmarkDescription: json['landmarkDescription'] ?? '',

      // Matching fields
      keywords:
          (json['keywords'] as List?)
                  ?.cast<String>() ??
              const [],

      rating:
          (json['rating'] as num?)
                  ?.toDouble() ??
              0.0,

      reviewCount:
          json['reviewCount'] ?? 0,

      completedJobs:
          json['completedJobs'] ?? 0,

      responseRate:
          (json['responseRate'] as num?)
                  ?.toDouble() ??
              100,

      latitude:
          (json['latitude'] as num?)
              ?.toDouble(),

      longitude:
          (json['longitude'] as num?)
              ?.toDouble(),

      profilePhotoPath:
          json['profilePhotoPath'] ?? '',

      businessPhotoPaths:
          (json['businessPhotoPaths']
                      as List?)
                  ?.cast<String>() ??
              const [],

      isAvailable:
          json['isAvailable'] ?? true,

      onboardingComplete:
          json['onboardingComplete'] ??
              false,
    );
  }
}
