import 'package:shared_preferences/shared_preferences.dart';
import 'sla_service.dart';

/// SharedPreferences = small key/value settings (session + SLA thresholds).
/// Tasks, members and activity are relational, so they live in SQLite instead.
class PrefsService {
  static late SharedPreferences _p;

  static const _kUser = 'current_user_id';
  static const _kHigh = 'sla_high';
  static const _kMedium = 'sla_medium';
  static const _kLow = 'sla_low';
  static const _kBonus = 'sla_bonus';

  /// Call once from main(). Also loads the saved SLA thresholds into SlaRules.current.
  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    const d = SlaRules.defaults;
    SlaRules.current = SlaRules(
      highHours: _p.getInt(_kHigh) ?? d.highHours,
      mediumHours: _p.getInt(_kMedium) ?? d.mediumHours,
      lowHours: _p.getInt(_kLow) ?? d.lowHours,
      notStartedBonusHours: _p.getInt(_kBonus) ?? d.notStartedBonusHours,
    );
  }

  // --- "Signed in" member ---
  static int? get currentUserId => _p.getInt(_kUser);
  static Future<void> setCurrentUser(int id) async => _p.setInt(_kUser, id);
  static Future<void> signOut() async => _p.remove(_kUser);

  // --- SLA thresholds ---
  /// Persists the rules, then updates the in-memory copy every screen reads.
  static Future<void> saveSlaRules(SlaRules r) async {
    await _p.setInt(_kHigh, r.highHours);
    await _p.setInt(_kMedium, r.mediumHours);
    await _p.setInt(_kLow, r.lowHours);
    await _p.setInt(_kBonus, r.notStartedBonusHours);
    SlaRules.current = r;
  }

  static Future<void> resetSlaRules() => saveSlaRules(SlaRules.defaults);
}