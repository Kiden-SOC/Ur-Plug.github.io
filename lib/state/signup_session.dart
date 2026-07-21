/// Carries the details a person entered on the Sign Up screen forward to
/// wherever they're needed next in the app — so nobody has to type the
/// same information twice.
///
/// Today the backend for this project is still a local simulation (see
/// [ApiService]), so there's nowhere durable yet to persist an account
/// between the Sign Up screen and the first login. This lightweight
/// in-memory singleton fills that gap for the current app session: as
/// soon as a business finishes the sign-up form, we remember their
/// business name, district and town here. When that same email logs in
/// for the first time, the provider-onboarding wizard reads it back and
/// pre-fills those fields instead of asking again.
///
/// When a real backend is connected, this can be removed — the saved
/// account record returned by the API will carry the same information.
class SignupSession {
  SignupSession._();
  static final SignupSession instance = SignupSession._();

  String? _email;
  String businessName = '';
  String district = '';
  String town = '';
  String phone = '';
  String businessCategory = '';

  /// Call this right after a business account finishes the sign-up form.
  void saveBusinessSignup({
    required String email,
    required String businessName,
    required String district,
    required String town,
    required String phone,
    required String businessCategory,
  }) {
    _email = _normalize(email);
    this.businessName = businessName.trim();
    this.district = district.trim();
    this.town = town.trim();
    this.phone = phone.trim();
    this.businessCategory = businessCategory.trim();
  }

  /// Returns the details saved for [email] during sign-up, or null if
  /// this session has nothing on file for that address yet (e.g. the
  /// app was restarted, or this account never went through sign-up in
  /// this session).
  SignupSession? forEmail(String email) {
    if (_email != null && _email == _normalize(email)) {
      return this;
    }
    return null;
  }

  String _normalize(String email) => email.trim().toLowerCase();
}