import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/catering_bill.dart';
import '../services/storage_service.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenEvents;
  const DashboardScreen({super.key, this.onOpenEvents});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<CateringBill> _bills = [];
  bool _loading = true;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _load();
    StorageService.dataRevision.addListener(_load);
  }

  @override
  void dispose() {
    StorageService.dataRevision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final bills = await StorageService.getAllBills();
    if (!mounted) return;
    setState(() { _bills = bills; _loading = false; });
  }

  String _money(num value) => '₹${NumberFormat('#,##,##0.##').format(value)}';
  bool _sameMonth(DateTime d) => d.year == _month.year && d.month == _month.month;
  List<CateringBill> get _monthly => _bills.where((b) => _sameMonth(b.date)).toList();
  double _sum(List<CateringBill> bills, double Function(CateringBill) value) => bills.fold(0, (s, b) => s + value(b));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthly = _monthly;
    final now = DateTime.now();
    final present = monthly.fold<int>(0, (s, b) => s + b.staffList.where((x) => x.isPresent).length);
    final billing = _sum(monthly, (b) => b.getAllTotalBill(b.taMultiplier));
    final wages = _sum(monthly, (b) => b.staffList.fold<double>(0, (s, x) => s + x.getEffectiveWage()));
    final ta = _sum(monthly, (b) => b.staffList.fold<double>(0, (s, x) => s + x.getCalculatedTa(b.taMultiplier)));
    final other = _sum(monthly, (b) => b.otherExpenses);
    final setting = _sum(monthly, (b) => b.settingExpenses);
    final previousMonth = DateTime(_month.year, _month.month - 1);
    final previousBills = _bills.where((b) => b.date.year == previousMonth.year && b.date.month == previousMonth.month).toList();
    final previousBilling = _sum(previousBills, (b) => b.getAllTotalBill(b.taMultiplier));
    final change = previousBilling <= 0 ? null : ((billing - previousBilling) / previousBilling) * 100;
    final recent = [..._bills]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Cater Pro', style: TextStyle(fontWeight: FontWeight.w800)),
          Text('Business overview', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70)),
        ]),
        actions: [IconButton(tooltip: 'Refresh dashboard', onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF17233D), Color(0xFF354D78)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('TOTAL BILLING', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(_money(billing), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -.8)),
                const SizedBox(height: 16),
                Row(children: [
                  _heroMetric('Events', '${monthly.length}'),
                  const SizedBox(width: 22),
                  _heroMetric('Present entries', '$present'),
                  const Spacer(),
                  const Icon(Icons.trending_up_rounded, color: Color(0xFF86EFAC), size: 30),
                ]),
              ]),
            ),
            const SizedBox(height: 18),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 42, height: 42, decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(.10), borderRadius: BorderRadius.circular(13)), child: Icon(Icons.event_available_rounded, color: theme.colorScheme.primary)),
                    const SizedBox(width: 11),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Event Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text('${_bills.length} saved events · Staff counts & Total TA', style: theme.textTheme.bodySmall),
                    ])),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _quickCount('Boys', _bills.fold<int>(0, (v, b) => v + b.boys.length))),
                    Expanded(child: _quickCount('SP', _bills.fold<int>(0, (v, b) => v + b.spList.length))),
                    Expanded(child: _quickCount('CP', _bills.fold<int>(0, (v, b) => v + b.cpList.length))),
                    Expanded(child: _quickCount('Hosting', _bills.fold<int>(0, (v, b) => v + b.hostingCount))),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 22),
            Row(children: [Text('Monthly analytics', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const Spacer(),
              IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)), icon: const Icon(Icons.chevron_left_rounded)),
              Text(DateFormat('MMM yyyy').format(_month), style: const TextStyle(fontWeight: FontWeight.w700)),
              IconButton(onPressed: _month.year == now.year && _month.month == now.month ? null : () => setState(() => _month = DateTime(_month.year, _month.month + 1)), icon: const Icon(Icons.chevron_right_rounded)),
            ]),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.75,
              children: [
                _metric('Staff wages', _money(wages), Icons.groups_2_rounded, const Color(0xFF2563EB)),
                _metric('Staff TA', _money(ta), Icons.directions_car_rounded, const Color(0xFF0D9488)),
                _metric('Other expenses', _money(other), Icons.receipt_long_rounded, const Color(0xFFD97706)),
                _metric('Setting bill', _money(setting), Icons.tune_rounded, const Color(0xFF7C3AED)),
              ],
            ),
            const SizedBox(height: 14),
            Card(child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [Icon(change == null || change >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: change == null || change >= 0 ? const Color(0xFF16A36A) : const Color(0xFFDC4545)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Compared with previous month', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), Text(change == null ? 'No previous month data' : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% billing', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))])), Text(_money(previousBilling), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12))]))),
            const SizedBox(height: 22),
            _sectionTitle('Monthly breakdown'),
            const SizedBox(height: 10),
            _breakdown('Staff wages', wages, billing),
            _breakdown('TA', ta, billing),
            _breakdown('Other expenses', other, billing),
            _breakdown('Setting bill', setting, billing),
            const SizedBox(height: 22),
            Row(children: [_sectionTitle('Recent events'), const Spacer(), Text('${_bills.length} total', style: theme.textTheme.bodySmall)]),
            const SizedBox(height: 10),
            if (recent.isEmpty)
              _emptyState()
            else
              ...recent.take(5).map((bill) => Card(
                margin: const EdgeInsets.only(bottom: 9),
                child: ListTile(
                  leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(.09), borderRadius: BorderRadius.circular(13)), child: Icon(Icons.event_note_rounded, color: theme.colorScheme.primary)),
                  title: Text(bill.eventName.isNotEmpty ? bill.eventName : (bill.auditoriumName.isEmpty ? 'Untitled event' : bill.auditoriumName), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(DateFormat('dd MMM yyyy').format(bill.date)),
                  trailing: Text(_money(bill.getAllTotalBill(bill.taMultiplier)), style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              )),
            const SizedBox(height: 14),
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withOpacity(.55), borderRadius: BorderRadius.circular(16)), child: Row(children: [Icon(Icons.cloud_done_outlined, color: theme.colorScheme.primary), const SizedBox(width: 10), const Expanded(child: Text('Your billing data is stored locally first. Cloud sync continues through the existing sync queue.', style: TextStyle(fontSize: 12, height: 1.4)))])),
          ],
        ),
      ),
    );
  }

  Widget _quickCount(String label, int value) => Padding(padding: const EdgeInsets.only(right: 4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), Text(label, style: Theme.of(context).textTheme.labelSmall)]));
  Widget _heroMetric(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))]);
  Widget _sectionTitle(String title) => Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800));
  Widget _metric(String title, String value, IconData icon, Color accent) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: accent), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11))])));
  Widget _breakdown(String label, double value, double total) { final ratio = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0); return Padding(padding: const EdgeInsets.only(bottom: 13), child: Column(children: [Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))), Text(_money(value), style: const TextStyle(fontWeight: FontWeight.w700))]), const SizedBox(height: 7), ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: ratio, minHeight: 7, backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest))])); }
  Widget _emptyState() => Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)), child: const Column(children: [Icon(Icons.event_available_rounded, size: 32, color: AppColors.textMuted), SizedBox(height: 8), Text('No saved events yet', style: TextStyle(fontWeight: FontWeight.w700)), Text('Create an event in Outing and it will appear here.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))]));
}
