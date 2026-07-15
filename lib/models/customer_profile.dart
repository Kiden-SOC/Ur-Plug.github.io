class CustomerProfile {
  final String id;
  final String name;
  final String phone;
  final String location;
  final String profilePhotoPath;

  CustomerProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
    this.profilePhotoPath = '',
  });

  CustomerProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? location,
    String? profilePhotoPath,
  }) {
    return CustomerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
    );
  }
}