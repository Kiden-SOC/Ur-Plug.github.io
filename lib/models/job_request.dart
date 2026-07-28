enum JobStatus { pending, accepted, declined, completed }

/// A service request a customer has sent to a provider.
/// Populated from the `bookings` collection in Firestore.
class JobRequest {
  final String id;
  final String customerUid;
  final String customerName;
  final String customerPhone;
  final String serviceNeeded;
  final String description;
  final String district;
  final String landmark;
  final String date;
  final String time;
  final String startDate;
  final String endDate;
  final String deadline;
  final String requestedTime;
  JobStatus status;

  JobRequest({
    required this.id,
    required this.customerUid,
    required this.customerName,
    this.customerPhone = '',
    required this.serviceNeeded,
    this.description = '',
    this.district = '',
    this.landmark = '',
    this.date = '',
    this.time = '',
    this.startDate = '',
    this.endDate = '',
    this.deadline = '',
    required this.requestedTime,
    required this.status,
  });
}
