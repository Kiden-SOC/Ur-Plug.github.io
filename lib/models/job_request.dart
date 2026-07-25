enum JobStatus { pending, accepted, declined, completed }

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
    required this.status,
  });
}