import 'dart:async';
import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'models/staff_item.dart';
import 'models/catering_bill.dart';
import 'services/storage_service.dart';
import 'screens/reporting_screen.dart';
import 'screens/outing_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/other_screen.dart';
import 'services/supabase_service.dart';
import 'services/theme_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/events_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Supabase is optional until the build is supplied with credentials.
  try { await SupabaseService.initialize(); } catch (_) { /* app remains usable offline */ }
  // If an authenticated session was restored, retry any locally queued cloud writes.
  unawaited(StorageService.flushPendingCloudSync());
  await ThemeService.load();
  runApp(const StaffBillingApp());
}

class StaffBillingApp extends StatelessWidget {
  const StaffBillingApp({Key? key}) : super(key: key);

  ThemeData _buildTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: dark ? const Color(0xFFA5B4FC) : AppColors.primary,
      brightness: brightness,
      primary: dark ? const Color(0xFFA5B4FC) : AppColors.primary,
      secondary: const Color(0xFF34D399),
      surface: dark ? const Color(0xFF151C2E) : Colors.white,
      error: dark ? const Color(0xFFF87171) : AppColors.danger,
    );
    final border = dark ? const Color(0xFF29344D) : AppColors.borderSubtle;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF080B14) : AppColors.background,
      primaryColor: scheme.primary,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? const Color(0xFF10182D) : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
        titleSpacing: 20, toolbarHeight: 66,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -.3),
      ),
      cardTheme: CardThemeData(color: scheme.surface, elevation: 0, margin: EdgeInsets.zero, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: border))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: dark ? const Color(0xFF151C2E) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: dark ? const Color(0xFF94A3B8) : AppColors.textMuted, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: scheme.primary, width: 1.6)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: scheme.primary, foregroundColor: dark ? const Color(0xFF0B1220) : Colors.white, elevation: 0, minimumSize: const Size(48, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)))),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: scheme.primary, foregroundColor: dark ? const Color(0xFF0B1220) : Colors.white, minimumSize: const Size(48, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)))),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: dark ? const Color(0xFF293B60) : AppColors.primarySurface, contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      dialogTheme: DialogThemeData(backgroundColor: scheme.surface, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary, linearTrackColor: border),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.mode,
      builder: (context, mode, _) => MaterialApp(
        title: 'Cater Pro', debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: mode,
        home: const MainNavigationShell(),
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({Key? key}) : super(key: key);

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 3;
  Timer? _debounceSaveTimer;

  String currentBillId = DateTime.now().millisecondsSinceEpoch.toString();
  String auditoriumName = '';
  String eventName = '';
  int hostingCount = 0;
  DateTime eventDate = DateTime.now();
  double otherExpenses = 0.0;
  double settingExpenses = 0.0;
  List<Map<String, dynamic>> otherExpenseItems = [];
  double taMultiplier = 3.0;
  int groupSize = 10;
  final Map<int, String> groupGpay = {};

  final List<StaffItem> sharedBoysList = [];
  final List<StaffItem> sharedSpList = [];
  final List<StaffItem> sharedCpList = [];

  @override
  void initState() {
    super.initState();
    _restoreActiveBillFromStorage();
    StorageService.dataRevision.addListener(_onRestoredDataChanged);
  }

  void _onRestoredDataChanged() {
    _debounceSaveTimer?.cancel();
    _restoreActiveBillFromStorage();
  }

  Future<void> _restoreActiveBillFromStorage() async {
    final active = await StorageService.getActiveBill();
    if (!mounted) return;
    if (active != null) {
      setState(() {
        currentBillId = active.id;
        auditoriumName = active.auditoriumName;
        eventName = active.eventName;
        hostingCount = active.hostingCount;
        eventDate = active.date;
        otherExpenses = active.otherExpenses;
        settingExpenses = active.settingExpenses;
        otherExpenseItems = active.otherExpenseItems.map((e) => Map<String, dynamic>.from(e)).toList();
        taMultiplier = active.taMultiplier;
        groupSize = active.groupSize;
        groupGpay.clear();
        groupGpay.addAll(active.groupGpay);

        sharedBoysList.clear();
        sharedBoysList.addAll(active.boys);
        sharedSpList.clear();
        sharedSpList.addAll(active.spList);
        sharedCpList.clear();
        sharedCpList.addAll(active.cpList);
      });
    } else if (mounted) {
      setState(() {
        currentBillId = DateTime.now().millisecondsSinceEpoch.toString();
        auditoriumName = '';
        eventName = '';
        hostingCount = 0;
        eventDate = DateTime.now();
        otherExpenses = 0;
        settingExpenses = 0;
        otherExpenseItems = [];
        taMultiplier = 3.0;
        groupSize = 10;
        groupGpay.clear();
        sharedBoysList.clear();
        sharedSpList.clear();
        sharedCpList.clear();
      });
    }
  }

  void _triggerAutoSave() {
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = Timer(const Duration(milliseconds: 300), () async {
      final bill = CateringBill(
        id: currentBillId,
        auditoriumName: auditoriumName.trim(),
        eventName: eventName.trim(),
        hostingCount: hostingCount,
        date: eventDate,
        otherExpenses: otherExpenses,
        settingExpenses: settingExpenses,
        otherExpenseItems: otherExpenseItems,
        taMultiplier: taMultiplier,
        groupSize: groupSize,
        staffList: [...sharedBoysList, ...sharedSpList, ...sharedCpList],
        groupGpay: groupGpay,
      );
      await StorageService.saveBill(bill);
    });
  }

  void _onListParsed(List<StaffItem> boys, List<StaffItem> sp, List<StaffItem> cp) {
    setState(() {
      sharedBoysList.clear();
      sharedBoysList.addAll(boys);
      sharedSpList.clear();
      sharedSpList.addAll(sp);
      sharedCpList.clear();
      sharedCpList.addAll(cp);
      currentBillId = DateTime.now().millisecondsSinceEpoch.toString();
    });
    _triggerAutoSave();
  }

  void _startNewWork() async {
    await StorageService.clearActiveBillTracking();
    setState(() {
      currentBillId = DateTime.now().millisecondsSinceEpoch.toString();
      auditoriumName = '';
      eventName = '';
      hostingCount = 0;
      eventDate = DateTime.now();
      otherExpenses = 0.0;
      settingExpenses = 0.0;
      otherExpenseItems = [];
      taMultiplier = 3.0;
      groupSize = 10;
      groupGpay.clear();
      sharedBoysList.clear();
      sharedSpList.clear();
      sharedCpList.clear();
      _currentIndex = 0;
    });
  }

  void _loadExistingBillFromCalendar(CateringBill bill) {
    setState(() {
      currentBillId = bill.id;
      auditoriumName = bill.auditoriumName;
      eventName = bill.eventName;
      hostingCount = bill.hostingCount;
      eventDate = bill.date;
      otherExpenses = bill.otherExpenses;
      settingExpenses = bill.settingExpenses;
      otherExpenseItems = bill.otherExpenseItems.map((e) => Map<String, dynamic>.from(e)).toList();
      taMultiplier = bill.taMultiplier;
      groupSize = bill.groupSize;
      groupGpay.clear();
      groupGpay.addAll(bill.groupGpay);

      sharedBoysList.clear();
      sharedBoysList.addAll(bill.boys);
      sharedSpList.clear();
      sharedSpList.addAll(bill.spList);
      sharedCpList.clear();
      sharedCpList.addAll(bill.cpList);

      _currentIndex = 1;
    });
    _triggerAutoSave();
  }

  @override
  void dispose() {
    StorageService.dataRevision.removeListener(_onRestoredDataChanged);
    _debounceSaveTimer?.cancel();
    super.dispose();
  }

  Widget _navItem(int navIndex, int pageIndex, IconData icon, String label, int selectedIndex, {bool prominent = false}) {
    final selected = selectedIndex == navIndex;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _triggerAutoSave();
          setState(() => _currentIndex = pageIndex);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary.withValues(alpha: .15) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: prominent ? 24 : 22, color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const SizedBox(height: 3),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9.5, fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }

  Future<void> _showMoreMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('More', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: const CircleAvatar(child: Icon(Icons.calendar_month_rounded)),
              title: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('View events by date and manage backups'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(sheetContext);
                _triggerAutoSave();
                setState(() => _currentIndex = 2);
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      ReportingScreen(
        boysList: sharedBoysList,
        spList: sharedSpList,
        cpList: sharedCpList,
        onListParsed: _onListParsed,
        onDataChanged: _triggerAutoSave,
        onStartNewWork: _startNewWork,
        onSubmitToOuting: () {
          _triggerAutoSave();
          setState(() => _currentIndex = 1);
        },
      ),
      OutingScreen(
        billId: currentBillId,
        auditoriumName: auditoriumName,
        eventDate: eventDate,
        otherExpenses: otherExpenses,
        settingExpenses: settingExpenses,
        otherExpenseItems: otherExpenseItems,
        multiplier: taMultiplier,
        groupSize: groupSize,
        groupGpay: groupGpay,
        boysList: sharedBoysList,
        spList: sharedSpList,
        cpList: sharedCpList,
        onUpdateAuditorium: (val) {
          auditoriumName = val;
          _triggerAutoSave();
        },
        onUpdateDate: (val) {
          setState(() => eventDate = val);
          _triggerAutoSave();
        },
        onUpdateOtherExp: (val) {
          otherExpenses = val;
          _triggerAutoSave();
        },
        onUpdateSettingExp: (val) {
          settingExpenses = val;
          _triggerAutoSave();
        },
        onUpdateOtherExpenseItems: (items) {
          setState(() {
            otherExpenseItems = items.map((e) => Map<String, dynamic>.from(e)).toList();
            otherExpenses = otherExpenseItems.fold<double>(0, (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0));
          });
          _triggerAutoSave();
        },
        onUpdateMultiplier: (val) {
          setState(() => taMultiplier = val);
          _triggerAutoSave();
        },
        onUpdateGroupSize: (val) {
          setState(() => groupSize = val);
          _triggerAutoSave();
        },
        onDataChanged: _triggerAutoSave,
      ),
      CalendarScreen(
        onSelectBill: _loadExistingBillFromCalendar,
      ),
      DashboardScreen(onOpenEvents: () => setState(() => _currentIndex = 5)),
      OtherScreen(onOpenBill: _loadExistingBillFromCalendar),
      EventsScreen(onOpenBill: _loadExistingBillFromCalendar),
    ];

    final selectedNavIndex = switch (_currentIndex) {
      0 => 0,
      1 => 1,
      3 => 2,
      4 => 3,
      5 => 4,
      _ => -1,
    };

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .65))),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 18, offset: const Offset(0, -5))],
          ),
          child: Row(children: [
            _navItem(0, 0, Icons.edit_note_rounded, 'Reporting', selectedNavIndex),
            _navItem(1, 1, Icons.receipt_long_rounded, 'Outing', selectedNavIndex),
            _navItem(2, 3, Icons.dashboard_rounded, 'Dashboard', selectedNavIndex, prominent: true),
            _navItem(3, 4, Icons.grid_view_rounded, 'Manage', selectedNavIndex),
            _navItem(4, 5, Icons.event_note_rounded, 'Events', selectedNavIndex),
            SizedBox(
              width: 42,
              child: IconButton(
                tooltip: 'More',
                onPressed: _showMoreMenu,
                icon: Icon(Icons.more_horiz_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 25),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}