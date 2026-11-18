import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/staff_item.dart';

class StaffRowItem extends StatefulWidget {
  final StaffItem item;
  final VoidCallback onDataChanged;
  final VoidCallback onEditDetails;
  final VoidCallback onEditWage;

  const StaffRowItem({
    Key? key,
    required this.item,
    required this.onDataChanged,
    required this.onEditDetails,
    required this.onEditWage,
  }) : super(key: key);

  @override
  State<StaffRowItem> createState() => _StaffRowItemState();
}

class _StaffRowItemState extends State<StaffRowItem> {
  late TextEditingController _taCtrl;
  late TextEditingController _minusCtrl;

  @override
  void initState() {
    super.initState();
    _taCtrl = TextEditingController(
      text: widget.item.baseTa > 0 ? (widget.item.baseTa % 1 == 0 ? widget.item.baseTa.toInt().toString() : widget.item.baseTa.toString()) : '',
    );
    _minusCtrl = TextEditingController(
      text: widget.item.minusAmount > 0 ? (widget.item.minusAmount % 1 == 0 ? widget.item.minusAmount.toInt().toString() : widget.item.minusAmount.toString()) : '',
    );
  }

  @override
  void didUpdateWidget(covariant StaffRowItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentTa = widget.item.baseTa > 0 ? (widget.item.baseTa % 1 == 0 ? widget.item.baseTa.toInt().toString() : widget.item.baseTa.toString()) : '';
    if (_taCtrl.text != currentTa && (double.tryParse(_taCtrl.text) ?? 0) != widget.item.baseTa) {
      _taCtrl.text = currentTa;
    }

    final currentMinus = widget.item.minusAmount > 0 ? (widget.item.minusAmount % 1 == 0 ? widget.item.minusAmount.toInt().toString() : widget.item.minusAmount.toString()) : '';
    if (_minusCtrl.text != currentMinus && (double.tryParse(_minusCtrl.text) ?? 0) != widget.item.minusAmount) {
      _minusCtrl.text = currentMinus;
    }
  }

  @override
  void dispose() {
    _taCtrl.dispose();
    _minusCtrl.dispose();
    super.dispose();
  }

  void _cycleAttendance() {
    setState(() {
      if (widget.item.attendance == '✅') {
        widget.item.attendance = '🔴';
      } else {
        widget.item.attendance = '✅';
      }
    });
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAbsent = widget.item.attendance != '✅';

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? .10 : .025), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          // Name & Phone
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: widget.onEditDetails,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${widget.item.index}. ${widget.item.name}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                            color: isAbsent ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurface,
                            decoration: isAbsent ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit_rounded, size: 11, color: Colors.grey.shade400),
                    ],
                  ),
                  if (widget.item.phone.isNotEmpty)
                    Text(
                      widget.item.phone,
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                    ),
                  if (widget.item.suggestedWage != null)
                    InkWell(
                      onTap: () {
                        setState(() {
                          widget.item.wage = widget.item.suggestedWage!;
                          widget.item.suggestedWage = null;
                        });
                        widget.onDataChanged();
                      },
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        margin: const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3C4),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFFE8C65A)),
                        ),
                        child: Text(
                          'Set ₹${widget.item.suggestedWage!.toStringAsFixed(widget.item.suggestedWage! % 1 == 0 ? 0 : 2)}',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF805B00)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Attendance Selector
          GestureDetector(
            onTap: _cycleAttendance,
            child: Container(
              width: 32,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.item.attendance == '✅'
                    ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF123A27) : AppColors.successLight)
                    : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3A171B) : AppColors.dangerLight),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.item.attendance == '✅' ? const Color(0xFF4ADE80) : const Color(0xFFFB7185),
                ),
              ),
              child: Text(isAbsent ? '🔴' : '✅', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(width: 8),

          // TA Input
          SizedBox(
            width: 48,
            height: 28,
            child: TextField(
              controller: _taCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (val) {
                widget.item.baseTa = double.tryParse(val.trim()) ?? 0.0;
                // A positive TA is an attendance signal. Only transition absent/blank
                // staff to present; repeated keystrokes do not create extra updates.
                if (widget.item.baseTa > 0 && !widget.item.isPresent) {
                  setState(() => widget.item.attendance = '✅');
                }
                widget.onDataChanged();
              },
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.successText(context)),
              decoration: InputDecoration(
                hintText: 'TA',
                hintStyle: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.outline),
                isDense: true,
                filled: true,
                fillColor: widget.item.baseTa > 0 ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF123A2D) : AppColors.successLight.withOpacity(0.4)) : Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: widget.item.baseTa > 0 ? const Color(0xFF86EFAC) : Theme.of(context).colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.successText(context), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Wage Button
          SizedBox(
            width: 48,
            height: 28,
            child: InkWell(
              onTap: widget.onEditWage,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Text(
                  '${widget.item.wage.toInt()}',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primaryText(context)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Deduction / Minus Input
          SizedBox(
            width: 52,
            height: 28,
            child: TextField(
              controller: _minusCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (val) {
                widget.item.minusAmount = double.tryParse(val.trim()) ?? 0.0;
                if (widget.item.attendance == '' && widget.item.minusAmount > 0) {
                  setState(() => widget.item.attendance = '✅');
                }
                widget.onDataChanged();
              },
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.dangerText(context)),
              decoration: InputDecoration(
                hintText: '−₹',
                hintStyle: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.outline),
                isDense: true,
                filled: true,
                fillColor: widget.item.minusAmount > 0 ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4A252C) : AppColors.dangerLight.withOpacity(0.4)) : Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: widget.item.minusAmount > 0 ? const Color(0xFFFCA5A5) : Theme.of(context).colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.dangerText(context), width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}