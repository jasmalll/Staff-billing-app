import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billing/main.dart';
import 'package:billing/models/calculation_model.dart';
import 'package:billing/models/other_models.dart';
import 'package:billing/services/storage_service.dart';
import 'package:billing/services/theme_service.dart';
import 'package:billing/models/catering_bill.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bill totals include other expenses and setting bill with correct TA separation', () {
    final bill = CateringBill(
      id: 'qa-total',
      auditoriumName: 'QA Hall',
      date: DateTime(2026, 11, 3),
      otherExpenses: 120,
      settingExpenses: 80,
      staffList: const [],
      groupGpay: const {},
    );
    expect(bill.getAllTotalBill(3), 200);
    // Other expenses are included in TA total; setting bill is not.
    expect(bill.getAllTotalTa(3), 120);
  });

  test('event metadata is preserved in bill serialization and legacy defaults', () {
    final bill = CateringBill(
      id: 'event-1',
      auditoriumName: 'C & P Auditorium',
      eventName: 'Wedding',
      hostingCount: 5,
      date: DateTime(2026, 11, 4),
      staffList: const [],
      groupGpay: const {},
    );
    final restored = CateringBill.fromJson(bill.toJson());
    expect(restored.eventName, 'Wedding');
    expect(restored.hostingCount, 5);
    final legacy = CateringBill.fromMap({'id': 'legacy', 'auditoriumName': 'Hall', 'staffList': [], 'groupGpay': {}});
    expect(legacy.eventName, '');
    expect(legacy.hostingCount, 0);
  });

  test('settlement balances deduct allowances from the selected source', () {
    final settlement = EventSettlement(
      eventDate: '2026-10-14',
      originalOtherExpenses: 500,
      originalSettingBill: 300,
      allowances: const [
        StaffAllowance(id: '1', staffName: 'Nihal', role: 'sp', basePay: 450, amount: 100, sourceCategory: 'Other Expenses', auditTag: 'Reporting charge'),
        StaffAllowance(id: '2', staffName: 'Akhil', role: 'cp', basePay: 430, amount: 50, sourceCategory: 'Setting Bill', auditTag: 'Setup'),
      ],
    );
    expect(settlement.remainingOther, 400);
    expect(settlement.remainingSetting, 250);
    expect(settlement.totalDisbursed, 1030);
  });

  test('phone normalization treats Indian country code and local number equally', () {
    expect(StorageService.normalizePhone('+91 98765-43210'), '9876543210');
    expect(StorageService.normalizePhone('09876543210'), '9876543210');
  });

  test('master wage lookup requires both normalized name and phone', () async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.saveMasterStaff({
      'name': 'Nihal Kumar',
      'phone': '+91 98765-43210',
      'defaultWage': 460,
      'category': 'BOY',
    });
    expect((await StorageService.findExactMasterStaff('  Nihal   Kumar ', '09876543210'))?['defaultWage'], 460);
    expect(await StorageService.findExactMasterStaff('Nihal Kumar', ''), isNull);
    expect(await StorageService.findExactMasterStaff('Nihal Kumar', '9876500000'), isNull);
  });

  test('inventory state serializes master items and counter allocations', () {
    final state = InventoryState(
      masterItems: [InventoryItem(id: 'dish', name: 'Dish', totalQuantity: 25)],
      stations: [CounterStation(id: 'c1', name: 'Counter 1', allocations: [StationAllocation(itemId: 'dish', itemName: 'Dish', quantity: 10)])],
    );
    final restored = InventoryState.fromJson(state.toJson());
    expect(restored.masterItems.single.totalQuantity, 25);
    expect(restored.stations.single.allocations.single.quantity, 10);
  });

  test('legacy bill-only backup and v2 full backup are both accepted', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await StorageService.restoreBackupJson('[]'), isTrue);
    expect(await StorageService.restoreBackupJson('{"schemaVersion":2,"bills":[],"settlements":[],"masterStaff":[]}'), isTrue);
  });

  test('corrupt full backup is rejected before changing saved records', () async {
    SharedPreferences.setMockInitialValues({});
    const validBill = '{"id":"existing","auditoriumName":"Hall","date":"2026-10-14T00:00:00.000","staffList":[],"groupGpay":{}}';
    expect(await StorageService.restoreBackupJson('[$validBill]'), isTrue);
    final before = jsonDecode(await StorageService.exportBackupJson()) as Map<String, dynamic>;

    const invalidBackup = '{"schemaVersion":2,"bills":["not valid json"],"settlements":[],"masterStaff":[]}';
    expect(await StorageService.restoreBackupJson(invalidBackup), isFalse);
    final after = jsonDecode(await StorageService.exportBackupJson()) as Map<String, dynamic>;
    // exportedAt is generated on every export, so compare the saved records only.
    expect(after..remove('exportedAt'), before..remove('exportedAt'));
  });

  test('theme defaults to premium dark and persists explicit light/dark modes', () async {
    SharedPreferences.setMockInitialValues({});
    await ThemeService.load();
    expect(ThemeService.mode.value, ThemeMode.dark);
    await ThemeService.setMode(ThemeMode.dark);
    expect(ThemeService.mode.value, ThemeMode.dark);
    await ThemeService.load();
    expect(ThemeService.mode.value, ThemeMode.dark);
    await ThemeService.setMode(ThemeMode.light);
    await ThemeService.load();
    expect(ThemeService.mode.value, ThemeMode.light);
  });

  testWidgets('dashboard is the initial selected destination', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const StaffBillingApp());
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsAtLeastNWidgets(1));
    expect(find.byTooltip('Manage staff'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('four primary destinations and integrated event calendar are accessible', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const StaffBillingApp());
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsAtLeastNWidgets(1));
    expect(find.text('Reporting'), findsOneWidget);
    expect(find.text('Outing'), findsOneWidget);
    expect(find.text('Events'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('Events').last);
    await tester.pumpAndSettle();
    expect(find.text('Event List'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);

    await tester.tap(find.text('Dashboard').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Manage staff'));
    await tester.pumpAndSettle();
    expect(find.text('Staff Directory'), findsOneWidget);
  });
}
