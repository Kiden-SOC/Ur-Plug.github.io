class ProviderRating {
  final String id;
  final String customerName;
  final String date;
  final double stars;
  final String comment;

  const ProviderRating({
    required this.id,
    required this.customerName,
    required this.date,
    required this.stars,
    required this.comment,
  });

  factory ProviderRating.fromJson(Map<String, dynamic> json) {
    return ProviderRating(
      id: json['id'].toString(),
      customerName: json['customer_name'] ?? '',
      date: json['date'] ?? '',
      stars: (json['stars'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
    );
  }
}