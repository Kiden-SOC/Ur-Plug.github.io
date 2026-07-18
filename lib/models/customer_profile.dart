class CustomerProfile {
  final String id;
  final String name;
  final String phone;
  final String location;
  final String town; // Added dynamic town variable requested by supervisor
  final String profilePhotoPath;

  CustomerProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
    this.town = '', // Defaults to empty string for safety
    this.profilePhotoPath = '',
  });

  CustomerProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? location,
    String? town, // Added town field to copy method
    String? profilePhotoPath,
  }) {
    return CustomerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      town: town ?? this.town, // Maps town property safely
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
    );
  }
}