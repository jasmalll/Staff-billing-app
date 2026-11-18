import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/catering_bill.dart';
import '../models/staff_item.dart';
import '../services/storage_service.dart';

class EventsScreen extends StatefulWidget {
  final ValueChanged<CateringBill>? onOpenBill;
  final ValueChanged<CateringBill>? onSelectBill;
  const EventsScreen({super.key, this.onOpenBill, this.onSelectBill});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<CateringBill> _events = [];
  bool _loading = true;

  String _money(num value) => '₹${NumberFormat('#,##,##0.##').format(value)}';
  String _date(DateTime value) => DateFormat('dd MMM yyyy').format(value);

  @override
  void initState() {
    super.initState();
    _load();
    StorageService.billsRevision.addListener(_load);
  }

  @override
  void dispose() {
    StorageService.billsRevision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final bills = await StorageService.getAllBills();
    bills.sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    setState(() {
      _events = bills;
      _loading = false;
    });
  }


  Future<void> _showEventOptions(CateringBill event) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Event Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _eventOptionTile(
              context: dialogContext,
              icon: Icons.description_outlined,
              title: 'Event Details',
              subtitle: 'Complete event information',
              onTap: () {
                Navigator.pop(dialogContext);
                _showEventDetails(event);
              },
            ),
            const SizedBox(height: 10),
            _eventOptionTile(
              context: dialogContext,
              icon: Icons.payments_outlined,
              title: 'SP / CP Wage Breakdown',
              subtitle: 'Staff-wise wage, Other Expenses and Settings Bill',
              onTap: () {
                Navigator.pop(dialogContext);
                _showSpCpWageBreakdown(event);
              },
            ),
            const SizedBox(height: 10),
            _eventOptionTile(
              context: dialogContext,
              icon: Icons.summarize_outlined,
              title: 'Short Event Details',
              subtitle: 'Wage and bill summary',
              onTap: () {
                Navigator.pop(dialogContext);
                _showShortEventDetails(event);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _eventOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withOpacity(0.55),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary, size: 25),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }


  String _staffBreakdownKey(StaffItem staff) =>
      '${staff.role}-${staff.index}-${staff.phone}-${staff.name}';

  Future<double?> _editBreakdownAmount(double current, String title) async {
    final controller = TextEditingController(text: current.toStringAsFixed(current % 1 == 0 ? 0 : 2));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '₹ ', labelText: 'Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value != null && value >= 0) Navigator.pop(ctx, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }


  Future<void> _showSpCpWageBreakdown(CateringBill event) async {
    final staff = [...event.spList, ...event.cpList];
    if (staff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This event has no SP or CP staff.')),
      );
      return;
    }

    final rows = <String, Map<String, dynamic>>{};
    for (final person in staff) {
      final key = _staffBreakdownKey(person);
      final saved = event.spCpWageBreakdown.where((e) => e['staffKey'] == key).firstOrNull;
      rows[key] = saved == null
          ? {'staffKey': key, 'staffName': person.name, 'expenses': <Map<String, dynamic>>[], 'settingBillAmount': 0.0}
          : {
              ...saved,
              'expenses': (saved['expenses'] as List<dynamic>? ?? [])
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList(),
              'settingBillAmount': saved['settingBillSelected'] == true
                  ? ((saved['settingBillAmount'] as num?)?.toDouble() ?? 0.0)
                  : ((saved.containsKey('settingBillSelected'))
                      ? 0.0
                      : ((saved['settingBillAmount'] as num?)?.toDouble() ?? 0.0)),
            };
    }

    const background = Color(0xFF080B0A);
    const surface = Color(0xFF111614);
    const surfaceSoft = Color(0xFF171D1B);
    const mint = Color(0xFF70E7C0);
    const muted = Color(0xFFADB8B4);
    const border = Color(0xFF303A36);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          double settingAssigned() => rows.values.fold<double>(
                0,
                (sum, row) => sum + ((row['settingBillAmount'] as num?)?.toDouble() ?? 0),
              );
          double settingRemaining() => event.settingExpenses - settingAssigned();
          Set<String> assignedExpenseNames({String? exceptKey}) => rows.entries
              .where((entry) => entry.key != exceptKey)
              .expand((entry) => (entry.value['expenses'] as List).map((e) => e['name'].toString()))
              .toSet();
          double rowTotal(StaffItem person) {
            final row = rows[_staffBreakdownKey(person)]!;
            final extras = (row['expenses'] as List).fold<double>(
              0,
              (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0),
            );
            final setting = (row['settingBillAmount'] as num?)?.toDouble() ?? 0;
            return person.getEffectiveWage() + person.getCalculatedTa(event.taMultiplier) + extras + setting;
          }

          final grandTotal = staff.fold<double>(0, (sum, person) => sum + rowTotal(person));
          final screenHeight = MediaQuery.of(ctx).size.height;

          Widget staffCard(StaffItem person) {
            final key = _staffBreakdownKey(person);
            final row = rows[key]!;
            final expenses = row['expenses'] as List<Map<String, dynamic>>;
            final wage = person.getEffectiveWage();
            final ta = person.getCalculatedTa(event.taMultiplier);
            final wageTa = wage + ta;

            return Container(
              margin: const EdgeInsets.only(bottom: 11),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border, width: 1),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 13, 13, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 43,
                          height: 43,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: mint.withOpacity(.10),
                            border: Border.all(color: mint.withOpacity(.55), width: 1.2),
                          ),
                          child: const Icon(Icons.person_rounded, color: mint, size: 25),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                person.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Wage ${_money(wage)}  +  TA ${_money(ta)}',
                                style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _money(wageTa),
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  if (expenses.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(13, 0, 13, 9),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: expenses.map((expense) {
                          final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF080B0A),
                              border: Border.all(color: border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () async {
                                final edited = await _editBreakdownAmount(amount, '${expense['name']} · ${person.name}');
                                if (edited != null) setDialogState(() => expense['amount'] = edited);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('${expense['name']}  ${_money(amount)}',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 7),
                                    InkWell(
                                      onTap: () => setDialogState(() => expenses.remove(expense)),
                                      child: const Icon(Icons.close_rounded, color: muted, size: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  Container(height: 1, color: border.withOpacity(.75)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: event.otherExpenseItems.isEmpty
                                ? null
                                : () async {
                                    final unavailable = assignedExpenseNames(exceptKey: key);
                                    final available = event.otherExpenseItems
                                        .where((item) => !unavailable.contains(item['name']?.toString() ?? 'Expense'))
                                        .toList();
                                    final selected = expenses.map((e) => e['name'].toString()).toSet();
                                    final result = await showDialog<Set<String>>(
                                      context: ctx,
                                      builder: (pickCtx) => StatefulBuilder(
                                        builder: (pickCtx, pickSet) => AlertDialog(
                                          title: const Text('Select Other Expenses'),
                                          content: SizedBox(
                                            width: double.maxFinite,
                                            child: available.isEmpty
                                                ? const Text('All expenses are already assigned to other staff.')
                                                : ListView(
                                                    shrinkWrap: true,
                                                    children: available.map((item) {
                                                      final name = item['name']?.toString() ?? 'Expense';
                                                      final value = (item['amount'] as num?)?.toDouble() ?? 0;
                                                      return CheckboxListTile(
                                                        contentPadding: EdgeInsets.zero,
                                                        dense: true,
                                                        value: selected.contains(name),
                                                        title: Text(name),
                                                        subtitle: Text(_money(value)),
                                                        onChanged: (checked) => pickSet(() {
                                                          if (checked == true) {
                                                            selected.add(name);
                                                          } else {
                                                            selected.remove(name);
                                                          }
                                                        }),
                                                      );
                                                    }).toList(),
                                                  ),
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(pickCtx), child: const Text('Cancel')),
                                            FilledButton(onPressed: () => Navigator.pop(pickCtx, selected), child: const Text('Done')),
                                          ],
                                        ),
                                      ),
                                    );
                                    if (result != null) {
                                      setDialogState(() {
                                        expenses.removeWhere((e) => !result.contains(e['name'].toString()));
                                        for (final item in available) {
                                          final name = item['name']?.toString() ?? 'Expense';
                                          if (result.contains(name) && !expenses.any((e) => e['name'] == name)) {
                                            expenses.add({'name': name, 'amount': (item['amount'] as num?)?.toDouble() ?? 0});
                                          }
                                        }
                                      });
                                    }
                                  },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.add_circle_outline_rounded, color: mint, size: 20),
                                  const SizedBox(width: 7),
                                  Flexible(
                                    child: Text(
                                      'Other Expenses',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: event.otherExpenseItems.isEmpty ? muted : mint,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, height: 38, color: border),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 4,
                          child: TextFormField(
                            key: ValueKey('setting-$key'),
                            initialValue: ((row['settingBillAmount'] as num?)?.toDouble() ?? 0).toStringAsFixed(0),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.end,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                            decoration: InputDecoration(
                              isDense: true,
                              prefixText: '₹ ',
                              prefixStyle: const TextStyle(color: muted, fontWeight: FontWeight.w700),
                              labelText: 'Settings Bill',
                              labelStyle: const TextStyle(color: mint, fontSize: 11, fontWeight: FontWeight.w700),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              filled: true,
                              fillColor: surfaceSoft,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(color: border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(color: mint, width: 1.5),
                              ),
                            ),
                            onChanged: (value) => setDialogState(() {
                              final parsed = double.tryParse(value) ?? 0;
                              row['settingBillAmount'] = parsed < 0 ? 0.0 : parsed;
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(13, 8, 14, 9),
                    decoration: BoxDecoration(
                      color: mint.withOpacity(.055),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('TOTAL  ', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                        Text(_money(rowTotal(person)), style: const TextStyle(color: mint, fontSize: 15, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return Dialog(
            backgroundColor: background,
            surfaceTintColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27), side: const BorderSide(color: Color(0xFF202A26))),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: double.maxFinite,
              height: screenHeight * .91,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(17, 17, 15, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 43,
                          height: 43,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: mint.withOpacity(.12),
                            border: Border.all(color: mint.withOpacity(.65)),
                          ),
                          child: const Icon(Icons.calculate_rounded, color: mint, size: 23),
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SP / CP', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                              Text('Wage Breakdown', style: TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close_rounded, color: muted),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [mint.withOpacity(.15), const Color(0xFF101714)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: mint.withOpacity(.7)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.groups_rounded, color: mint, size: 27),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOTAL STAFF', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .8)),
                              Text('${staff.length}', style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Container(width: 1, height: 38, color: border),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('GRAND TOTAL', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .8)),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(_money(grandTotal), style: const TextStyle(color: mint, fontSize: 23, fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(17, 0, 17, 8),
                    child: Row(
                      children: [
                        const Text('STAFF BREAKDOWN', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                        const Spacer(),
                        Text('${staff.length} MEMBERS', style: const TextStyle(color: mint, fontSize: 10, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: staff.length,
                      itemBuilder: (context, index) => staffCard(staff[index]),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 11, 14, 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D1210),
                      border: Border(top: BorderSide(color: border)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined, color: mint, size: 16),
                            const SizedBox(width: 7),
                            const Expanded(child: Text('Settings Bill Remaining', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600))),
                            Text(_money(settingRemaining()), style: TextStyle(color: settingRemaining() < 0 ? Colors.redAccent : mint, fontSize: 12, fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: mint,
                                  side: const BorderSide(color: border),
                                  minimumSize: const Size(0, 49),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  if (settingAssigned() > event.settingExpenses + 0.0001) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Settings Bill exceeds available balance ${_money(event.settingExpenses)}.')),
                                    );
                                    return;
                                  }
                                  event.spCpWageBreakdown = rows.values.map((row) => Map<String, dynamic>.from(row)).toList();
                                  await StorageService.saveBill(event);
                                  final lines = <String>[];
                                  for (final person in staff) {
                                    lines.add('${person.name} :- ${_money(rowTotal(person)).replaceFirst('₹', '')}');
                                  }
                                  lines.add('');
                                  lines.add('Total Bill :- ${_money(grandTotal).replaceFirst('₹', '')}');
                                  lines.add('Settings Bill Remaining :- ${_money(settingRemaining()).replaceFirst('₹', '')}');
                                  await Clipboard.setData(ClipboardData(text: lines.join('\n')));
                                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Wage breakdown saved and copied.')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.copy_rounded, size: 19),
                                label: const Text('Save & Copy', style: TextStyle(fontWeight: FontWeight.w900)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: mint,
                                  foregroundColor: const Color(0xFF07110D),
                                  minimumSize: const Size(0, 49),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEventDetails(CateringBill event) async {
    final boys = event.boys.length;
    final sp = event.spList.length;
    final cp = event.cpList.length;
    final total = boys + sp + cp + event.hostingCount;
    final summary = 'EVENT DETAILS\n\n'
        'Site name : ${event.auditoriumName.isEmpty ? 'Site not set' : event.auditoriumName}\n'
        'Date: ${_date(event.date)}\n'
        'Event: ${event.eventName.isEmpty ? 'Event' : event.eventName}\n\n'
        'STAFF COUNT\n\n'
        'Boys: $boys\n'
        'SP: $sp\n'
        'CP: $cp\n'
        'Hosting: ${event.hostingCount}\n'
        'Total Staff: $total\n\n'
        'TOTAL TA: ${_money(event.getAllTotalTa(event.taMultiplier))}\n\n'
        'OTHER EXPENSES: ${_money(event.otherExpenses)}\n'
        '${event.otherExpenseItems.isEmpty ? 'No expense breakdown' : event.otherExpenseItems.map((item) => '${item['name']?.toString() ?? 'Expense'}: ${_money((item['amount'] as num?)?.toDouble() ?? 0)}').join('\n')}\n\n'
        'SETTINGS BILL: ${_money(event.settingExpenses)}\n\n'
        'TOTAL BILL: ${_money(event.getAllTotalBill(event.taMultiplier))}';
    await _showCopyDialog(title: 'Event Details', content: summary, successMessage: 'Event details copied');
  }

  Future<void> _showShortEventDetails(CateringBill event) async {
    final boysWage = event.boys.fold<double>(0, (sum, staff) => sum + staff.getEffectiveWage());
    final spCpWage = [...event.spList, ...event.cpList]
        .fold<double>(0, (sum, staff) => sum + staff.getEffectiveWage());
    final totalTa = event.getAllTotalTa(event.taMultiplier);
    final totalBill = event.getAllTotalBill(event.taMultiplier);
    final summary = '${event.auditoriumName.isEmpty ? 'Site not set' : event.auditoriumName}\n\n'
        'Date :- ${_date(event.date)}\n\n'
        'Boys total wage :- ${_money(boysWage)}\n\n'
        'SP and CP total wage :- ${_money(spCpWage)}\n\n'
        'Total TA :- ${_money(totalTa)}\n\n'
        'Other expenses :- ${_money(event.otherExpenses)}\n\n'
        'Setting bill :- ${_money(event.settingExpenses)}\n\n'
        'Total bill :- ${_money(totalBill)}';
    await _showCopyDialog(title: 'Short Event Details', content: summary, successMessage: 'Short event details copied');
  }

  Future<void> _showCopyDialog({
    required String title,
    required String content,
    required String successMessage,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: SelectableText(
            content,
            style: TextStyle(height: 1.55, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Close')),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
            },
            icon: Icon(Icons.copy_rounded, size: 17),
            label: Text('Copy'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEventEditor({CateringBill? existing}) async {
    final name = TextEditingController(text: existing?.eventName ?? '');
    final site = TextEditingController(text: existing?.auditoriumName ?? '');
    final hosting = TextEditingController(text: (existing?.hostingCount ?? 0).toString());
    var selectedDate = existing?.date ?? DateTime.now();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Create Event' : 'Edit Event'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: 'Event Name', hintText: 'Wedding')),
              const SizedBox(height: 12),
              TextField(controller: site, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: 'Site', hintText: 'Auditorium name')),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_month_rounded),
                title: Text('Date'),
                subtitle: Text(_date(selectedDate)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
              ),
              const SizedBox(height: 8),
              TextField(controller: hosting, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Hosting Count', hintText: '0')),
              const SizedBox(height: 6),
              Text('Boys, SP and CP counts are taken automatically from the saved bill.', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('Save Event')),
          ],
        ),
      ),
    );

    if (result == true) {
      final eventName = name.text.trim();
      final siteName = site.text.trim();
      final hostingCount = int.tryParse(hosting.text.trim());
      if (eventName.isEmpty || siteName.isEmpty || hostingCount == null || hostingCount < 0) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter Event Name, Site and a valid Hosting Count.')));
      } else {
        final sameDateEvent = existing == null
            ? _events.where((item) => item.date.year == selectedDate.year && item.date.month == selectedDate.month && item.date.day == selectedDate.day).firstOrNull
            : null;
        final bill = existing ?? sameDateEvent ?? CateringBill(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          auditoriumName: '',
          date: selectedDate,
          staffList: <StaffItem>[],
          groupGpay: <int, String>{},
        );
        bill.eventName = eventName;
        bill.auditoriumName = siteName;
        bill.date = selectedDate;
        bill.hostingCount = hostingCount;
        await StorageService.saveBill(bill);
        await _load();
      }
    }
    name.dispose();
    site.dispose();
    hosting.dispose();
  }

  Future<void> _deleteEvent(CateringBill event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Event?'),
        content: Text('Delete "${event.eventName.isEmpty ? event.auditoriumName : event.eventName}" and its linked bill?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await StorageService.deleteBill(event.id);
      await _load();
    }
  }

  Widget _eventCard(CateringBill event) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showEventOptions(event),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 13, 9, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(children: [
                Icon(Icons.location_on_rounded, size: 17, color: scheme.primary),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    event.auditoriumName.isEmpty ? 'Site not set' : event.auditoriumName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.2),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 180),
                  icon: Icon(Icons.more_vert_rounded, size: 19, color: scheme.onSurfaceVariant),
                  onSelected: (value) {
                    if (value == 'edit') _showEventEditor(existing: event);
                    if (value == 'delete') _deleteEvent(event);
                    if (value == 'bill' && widget.onOpenBill != null) widget.onOpenBill!(event);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'bill', child: Text('Open Bill / Manage Staff')),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ]),
              const SizedBox(height: 9),
              Row(children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_date(event.date), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
                ),
              ]),
              const SizedBox(height: 7),
              Text('Tap to view details', style: TextStyle(fontSize: 10, color: scheme.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_note_rounded, size: 58, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text('No events yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text('Create an event to track staff counts and total TA.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.35,
        ),
        itemCount: _events.length,
        itemBuilder: (context, index) => _eventCard(_events[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Event List')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEventEditor(),
        icon: Icon(Icons.add_rounded),
        label: Text('Add Event'),
      ),
      body: _buildEventList(),
    );
  }
}
