import 'package:beacon_tracker/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('title: required, 3 to 60 characters', () {
    expect(Validators.title(''), isNotNull);
    expect(Validators.title('  '), isNotNull);
    expect(Validators.title('ab'), isNotNull);
    expect(Validators.title('abc'), isNull);
    expect(Validators.title('x' * 61), isNotNull);
  });
  test('description: optional, max 300', () {
    expect(Validators.description(null), isNull);
    expect(Validators.description('x' * 300), isNull);
    expect(Validators.description('x' * 301), isNotNull);
  });
  test('email format', () {
    expect(Validators.email('amara@team.com'), isNull);
    expect(Validators.email('amara@team'), isNotNull);
    expect(Validators.email(''), isNotNull);
  });
  test('due date cannot be in the past for new tasks', () {
    expect(Validators.dueDate(null), isNotNull);
    expect(Validators.dueDate(DateTime.now().subtract(const Duration(days: 2))), isNotNull);
    expect(Validators.dueDate(DateTime.now().subtract(const Duration(days: 2)), isNew: false), isNull);
    expect(Validators.dueDate(DateTime.now().add(const Duration(days: 1))), isNull);
  });
  test('sla hours: whole number from 1 to 240', () {
    expect(Validators.slaHours(''), isNotNull);
    expect(Validators.slaHours('abc'), isNotNull);
    expect(Validators.slaHours('0'), isNotNull);
    expect(Validators.slaHours('241'), isNotNull);
    expect(Validators.slaHours('1'), isNull);
    expect(Validators.slaHours('240'), isNull);
  });
  test('sla bonus: 0 is allowed', () {
    expect(Validators.slaBonus('0'), isNull);
    expect(Validators.slaBonus('-1'), isNotNull);
  });
  test('sla order: High >= Medium >= Low', () {
    expect(Validators.slaOrder(72, 48, 24), isNull);
    expect(Validators.slaOrder(48, 48, 48), isNull);
    expect(Validators.slaOrder(24, 48, 72), isNotNull);
  });
}
