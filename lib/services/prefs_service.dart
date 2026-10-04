import 'package:shared_preferences/shared_preferences.dart';
import 'sla_service.dart';

/// SharedPreferences = small key/value settings (session + SLA thresholds).
/// Tasks, members and activity are relational, so they live in SQLite instead.
class PrefsService {
  static late SharedPreferences _p;

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    SlaRules.current = SlaRules(
      highHours: _p.getInt('sla_high') ?? 72,
      mediumHours: _p.getInt('sla_medium') ?? 48,
      lowHours: _p.getInt('sla_low') ?? 24,
      notStartedBonusHours: _p.getInt('sla_bonus') ?? 24,
    );
  }

  // --- "Signed in" member ---
  static int? get currentUserId => _p.getInt('current_user_id');
  static Future<void> setCurrentUser(int id) async => _p.setInt('current_user_id', id);
  static Future<void> signOut() async => _p.remove('current_user_id');

  // --- SLA thresholds ---
  static Future<void> saveSlaRules(SlaRules r) async {
    await _p.setInt('sla_high', r.highHours);
    await _p.setInt('sla_medium', r.mediumHours);
    await _p.setInt('sla_low', r.lowHours);
    await _p.setInt('sla_bonus', r.notStartedBonusHours);
    SlaRules.current = r;
  }
}
