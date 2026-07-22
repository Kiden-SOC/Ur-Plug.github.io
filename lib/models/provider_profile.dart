/// Provider (business) profile model.
/// Mirrors the fields displayed on the customer-facing
/// provider_detail_screen.dart so both sides stay in sync.
class ProviderProfile {
  final String uid;
  final String businessName;
  final String tradeTitle;            // Profession / service, e.g. "Electrician" or a custom typed-in profession
  final int yearsOfExperience;
  final String bio;
  final String district;
  final String town;                  // Town / area within the district
  final String landmarkDescription;   // Smart landmark descriptor, e.g. "Kirinya Trading Centre, near the TotalEnergies Station"
  final double? latitude;             // Auto-picked up at sign up, editable afterwards
  final double? longitude;
  final String profilePhotoPath;      // Local file path / URL for the provider's profile photo
  final List<String> businessPhotoPaths; // Photos of the business/work customers can browse
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
      landmarkDescription: landmarkDescription ?? this.landmarkDescription,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      businessPhotoPaths: businessPhotoPaths ?? this.businessPhotoPaths,
      isAvailable: isAvailable ?? this.isAvailable,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
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
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      profilePhotoPath: json['profilePhotoPath'] ?? '',
      businessPhotoPaths:
          (json['businessPhotoPaths'] as List?)?.cast<String>() ?? const [],
      isAvailable: json['isAvailable'] ?? true,
      onboardingComplete: json['onboardingComplete'] ?? false,
    );
  }
}

/// A service listing the provider offers on the marketplace.
class ServiceListing {
  final String id;
  final String title;
  final String description;
  final bool isActive;

  const ServiceListing({
    required this.id,
    required this.title,
    required this.description,
    this.isActive = true,
  });

  ServiceListing copyWith({String? title, String? description, bool? isActive}) {
    return ServiceListing(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}

enum JobStatus { pending, accepted, declined, completed }

/// An incoming job request from a customer.
class JobRequest {
  final String id;
  final String customerUid;
  final String customerName;
  final String serviceNeeded;
  final String locationHint;
  final String requestedTime;
  JobStatus status;

  JobRequest({
    required this.id,
    required this.customerUid,
    required this.customerName,
    required this.serviceNeeded,
    required this.locationHint,
    required this.requestedTime,
    this.status = JobStatus.pending,
  });
}

/// A rating a customer left for this provider.
class ProviderRating {
  final String customerName;
  final double stars;
  final String comment;
  final String date;

  const ProviderRating({
    required this.customerName,
    required this.stars,
    required this.comment,
    required this.date,
  });
}

/// A conversation thread on the provider's inbox.
class ChatThread {
  final String id;
  final String customerName;
  final String lastMessage;
  final String time;
  final int unreadCount;

  const ChatThread({
    required this.id,
    required this.customerName,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
  });
}

/// A customer who has repeatedly booked this provider — surfaced on the
/// "Top Customers" screen so the provider can recognise their most loyal,
/// highest-value clients at a glance.
class TopCustomer {
  final String customerName;
  final int jobsCompleted;
  final double averageRatingGiven;
  final String lastServiceDate;

  const TopCustomer({
    required this.customerName,
    required this.jobsCompleted,
    required this.averageRatingGiven,
    required this.lastServiceDate,
  });
}

/// The kind of content carried by a [ChatMessage].
enum ChatMessageType { text, audio }

/// A single chat message (shared by customer and provider chat UIs).
/// Supports plain text as well as recorded voice notes.
class ChatMessage {
  final String text;
  final bool isMe;
  final ChatMessageType type;
  final String? audioPath;          // Local file path to the recorded voice note
  final int audioDurationSeconds;   // Length of the voice note, for display

  const ChatMessage({
    required this.text,
    required this.isMe,
    this.type = ChatMessageType.text,
    this.audioPath,
    this.audioDurationSeconds = 0,
  });

  /// Convenience constructor for a voice note message.
  const ChatMessage.audio({
    required this.audioPath,
    required this.isMe,
    this.audioDurationSeconds = 0,
    this.text = 'Voice note',
  }) : type = ChatMessageType.audio;
}