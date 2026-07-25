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