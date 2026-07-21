/// Tracks which email addresses signed up as a Business Provider during
/// this app session.
///
/// The real backend will own this permanently once it's connected — an
/// account's role will just be a field on its server record, looked up
/// by email at login. Until then, this keeps sign-up and login
/// consistent without needing a hardcoded email like
/// "business@urplug.com": whatever address someone signs up with under
/// "Business Provider" is exactly the address that logs them in as one,
/// no matter what the address itself looks like.
class AccountRegistry {
  AccountRegistry._();
  static final AccountRegistry instance = AccountRegistry._();

  final Set<String> _businessEmails = {};

  /// Call this once a Business Provider sign-up completes.
  void registerBusiness(String email) {
    final normalized = _normalize(email);
    if (normalized.isNotEmpty) {
      _businessEmails.add(normalized);
    }
  }

  /// Whether [email] previously signed up as a Business Provider.
  bool isBusiness(String email) => _businessEmails.contains(_normalize(email));

  String _normalize(String email) => email.trim().toLowerCase();
}