class TopCustomer {
  final String customerUid;
  final String customerName;
  final int jobsCompleted;
  final String lastServiceDate;
  final double averageRatingGiven;

  const TopCustomer({
    required this.customerUid,
    required this.customerName,
    required this.jobsCompleted,
    required this.lastServiceDate,
    required this.averageRatingGiven,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      customerUid: json['customer_uid'].toString(),
      customerName: json['customer_name'] ?? '',
      jobsCompleted: json['jobs_completed'] ?? 0,
      lastServiceDate: json['last_service_date'] ?? '',
      averageRatingGiven: (json['average_rating_given'] ?? 0).toDouble(),
    );
  }
}