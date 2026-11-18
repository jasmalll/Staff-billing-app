import 'dart:async';
import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'models/staff_item.dart';
import 'models/catering_bill.dart';
import 'services/storage_service.dart';
import 'screens/reporting_screen.dart';
import 'screens/outing_screen.dart';
import 'screens/other_screen.dart';
import 'services/supabase_service.dart';
import 'services/theme_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/events_screen.dart';
import 'screens/calendar_screen.dart';

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
    const deepTeal = Color(0xFF103B43);
    const accentMint = Color(0xFF8CE6C1);

    // Dark mode uses true black foundations with separate charcoal surfaces
    // so cards and editable fields remain clearly distinguishable.
    final background = dark ? const Color(0xFF000000) : AppColors.background;
    final surface = dark ? const Color(0xFF111111) : Colors.white;
    final inputSurface = dark ? const Color(0xFF202020) : const Color(0xFFF7FAF8);
    final border = dark ? const Color(0xFF414141) : AppColors.borderSubtle;
    final outlineVariant = dark ? const Color(0xFF303030) : AppColors.borderSubtle;

    final generatedScheme = ColorScheme.fromSeed(
      seedColor: dark ? accentMint : deepTeal,
      brightness: brightness,
      primary: dark ? accentMint : deepTeal,
      onPrimary: dark ? const Color(0xFF062016) : Colors.white,
      secondary: dark ? const Color(0xFF78DDB5) : AppColors.success,
      surface: surface,
      onSurface: dark ? const Color(0xFFF5F5F5) : AppColors.textPrimary,
      onSurfaceVariant: dark ? const Color(0xFFBDBDBD) : AppColors.textSecondary,
      error: dark ? const Color(0xFFFF777F) : AppColors.danger,
      outline: border,
      outlineVariant: outlineVariant,
    );
    final scheme = dark
        ? generatedScheme.copyWith(
            surfaceContainerLowest: const Color(0xFF080808),
            surfaceContainerLow: const Color(0xFF101010),
            surfaceContainer: const Color(0xFF181818),
            surfaceContainerHigh: const Color(0xFF222222),
            surfaceContainerHighest: const Color(0xFF292929),
          )
        : generatedScheme;
    final radius = BorderRadius.circular(20);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      primaryColor: scheme.primary,
      visualDensity: VisualDensity.standard,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? background : deepTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 68,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white, fontSize: 20,
          fontWeight: FontWeight.w800, letterSpacing: -.45,
        ),
      ),
      textTheme: Typography.material2021().black.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ).copyWith(
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.6, color: scheme.onSurface),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.35, color: scheme.onSurface),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: scheme.onSurface),
        bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: scheme.onSurface),
        bodySmall: TextStyle(fontSize: 12, height: 1.35, color: scheme.onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        hintStyle: TextStyle(
          color: dark ? const Color(0xFFAAAAAA) : scheme.onSurfaceVariant.withValues(alpha: .75),
          fontSize: 14,
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        floatingLabelStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: .28),
        selectionHandleColor: scheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary, elevation: 0,
        minimumSize: const Size(48, 50), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      )),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary, minimumSize: const Size(48, 50),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary, side: BorderSide(color: border), minimumSize: const Size(44, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      )),
      dividerTheme: DividerThemeData(color: outlineVariant, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF242424) : deepTeal,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface, surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface, surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary, linearTrackColor: outlineVariant,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? scheme.primary.withValues(alpha: .28) : outlineVariant),
      ),
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
  int _currentIndex = 1;
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
      _currentIndex = 1;
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

      _currentIndex = 2;
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


  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardScreen(
        onOpenEvents: () => setState(() => _currentIndex = 3),
        onOpenManage: () => setState(() => _currentIndex = 4),
        onOpenCalendar: () => setState(() => _currentIndex = 5),
      ),
      ReportingScreen(
        boysList: sharedBoysList,
        spList: sharedSpList,
        cpList: sharedCpList,
        onListParsed: _onListParsed,
        onDataChanged: _triggerAutoSave,
        onStartNewWork: _startNewWork,
        onSubmitToOuting: () {
          _triggerAutoSave();
          setState(() => _currentIndex = 2);
        },
      ),
      OutingScreen(
        billId: currentBillId,
        auditoriumName: auditoriumName,
        eventName: eventName,
        hostingCount: hostingCount,
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
      EventsScreen(
        onOpenBill: _loadExistingBillFromCalendar,
        onSelectBill: _loadExistingBillFromCalendar,
      ),
      OtherScreen(onOpenBill: _loadExistingBillFromCalendar),
      CalendarScreen(onSelectBill: _loadExistingBillFromCalendar),
    ];

    final selectedNavIndex = (_currentIndex == 4 || _currentIndex == 5) ? -1 : _currentIndex;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 82,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? .22 : .07), blurRadius: 24, offset: const Offset(0, 7))],
          ),
          child: Row(children: [
            _navItem(0, 0, Icons.dashboard_rounded, 'Dashboard', selectedNavIndex, prominent: true),
            _navItem(1, 1, Icons.edit_note_rounded, 'Reporting', selectedNavIndex),
            _navItem(2, 2, Icons.receipt_long_rounded, 'Outing', selectedNavIndex),
            _navItem(3, 3, Icons.event_note_rounded, 'Events', selectedNavIndex),
          ]),
        ),
      ),
    );
  }
}