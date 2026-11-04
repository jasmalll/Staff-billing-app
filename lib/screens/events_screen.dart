import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/catering_bill.dart';
import '../models/staff_item.dart';
import '../services/storage_service.dart';

class EventsScreen extends StatefulWidget {
  final ValueChanged<CateringBill>? onOpenBill;
  const EventsScreen({super.key, this.onOpenBill});

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


  Future<void> _showEventSummary(CateringBill event) async {
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
        'TOTAL TA: ${_money(event.getAllTotalTa(event.taMultiplier))}';
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Event Details'),
        content: SelectableText(summary, style: const TextStyle(height: 1.55, fontSize: 14, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: summary));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event details copied')));
            },
            icon: const Icon(Icons.copy_rounded, size: 17),
            label: const Text('Copy'),
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
              TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Event Name', hintText: 'Wedding')),
              const SizedBox(height: 12),
              TextField(controller: site, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Site', hintText: 'Auditorium name')),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_rounded),
                title: const Text('Date'),
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
              TextField(controller: hosting, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Hosting Count', hintText: '0')),
              const SizedBox(height: 6),
              Text('Boys, SP and CP counts are taken automatically from the saved bill.', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save Event')),
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
        title: const Text('Delete Event?'),
        content: Text('Delete "${event.eventName.isEmpty ? event.auditoriumName : event.eventName}" and its linked bill?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
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
        onTap: () => _showEventSummary(event),
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
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.2),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEventEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Event'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.event_note_rounded, size: 58, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    const Text('No events yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text('Create an event to track staff counts and total TA.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                  ]),
                ))
              : RefreshIndicator(
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
                ),
    );
  }
}
