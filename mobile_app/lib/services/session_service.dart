// lib\services\session_service.dart

import 'package:flutter/foundation.dart';

enum SessionStatus { guest, loggedIn }

class SessionService {
  SessionService._();

  static final ValueNotifier<SessionStatus> status = ValueNotifier(SessionStatus.guest);

  static bool get isGuest => status.value == SessionStatus.guest;
  static bool get isLoggedIn => status.value == SessionStatus.loggedIn;

  static void enterAsGuest() => status.value = SessionStatus.guest;

  static void markLoggedIn() => status.value = SessionStatus.loggedIn;

  static void signOut() => status.value = SessionStatus.guest;
}