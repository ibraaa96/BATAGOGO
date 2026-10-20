class Session {
  static int? userId;
  static String? nama;
  static String? email;
  static String? role;

  static bool get isLoggedIn {
    return userId != null;
  }

  static bool get isAdmin {
    return role == 'admin';
  }

  static void login({
    required int id,
    required String userName,
    required String userEmail,
    required String userRole,
  }) {
    userId = id;
    nama = userName;
    email = userEmail;
    role = userRole;
  }

  static void logout() {
    userId = null;
    nama = null;
    email = null;
    role = null;
  }
}