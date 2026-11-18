import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/staff_item.dart';

class OutingRowItem extends StatelessWidget {
  final StaffItem item;
  final double multiplier;
  final VoidCallback onDataChanged;
  final VoidCallback onEditWage;

  const OutingRowItem({
    Key? key,
    required this.item,
    required this.multiplier,
    required this.onDataChanged,
    required this.onEditWage,
  }) : super(key: key);

  void _cycleOutingStatus() {
    if (item.outingStatus.isEmpty) {
      item.outingStatus = '✅';
    } else if (item.outingStatus == '✅') {
      item.outingStatus = '❎';
    } else {
      item.outingStatus = '';
    }
    onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (!item.isPresent) {
      return Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF351F25) : AppColors.dangerLight.withOpacity(.45),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.danger.withValues(alpha: .22)),
        ),
        child: Row(
          children: [
            Text('${item.index}. ${item.name}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: dark ? const Color(0xFF4A252C) : AppColors.dangerLight, borderRadius: BorderRadius.circular(4)),
              child: Text('🔴 Absent', style: TextStyle(color: AppColors.dangerText(context), fontWeight: FontWeight.w700, fontSize: 11)),
            ),
          ],
        ),
      );
    }

    double autoTa = item.getCalculatedTa(multiplier);
    double total = item.getTotal(multiplier);

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          // Staff Details
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.index}. ${item.name}',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: Theme.of(context).colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.phone.isNotEmpty)
                  Text(item.phone, style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 1),

                // Calculation Breakdown Equation
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InkWell(
                      onTap: onEditWage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 0.8),
                        ),
                        child: Text(
                          '₹${item.wage.toInt()}',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.primaryText(context)),
                        ),
                      ),
                    ),
                    if (item.minusAmount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '− ₹${item.minusAmount.toInt()}',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.dangerText(context)),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: InkWell(
                        onTap: onEditWage,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: dark ? const Color(0xFF123A2D) : AppColors.successLight,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
                          ),
                          child: Text(
                            '+ ₹${autoTa.toInt()} TA ✎',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.successText(context)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total Amount
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '= ₹${total.toInt()}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primaryText(context)),
            ),
          ),

          // Outing Verification Status Button
          GestureDetector(
            onTap: _cycleOutingStatus,
            child: Container(
              width: 30,
              height: 27,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.outingStatus == '✅'
                    ? (dark ? const Color(0xFF123A2D) : AppColors.successLight)
                    : (item.outingStatus == '❎' ? (dark ? const Color(0xFF4A252C) : AppColors.dangerLight) : Theme.of(context).colorScheme.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.outingStatus == '✅'
                      ? const Color(0xFF86EFAC)
                      : (item.outingStatus == '❎' ? const Color(0xFFFCA5A5) : Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              child: Text(
                item.outingStatus.isEmpty ? '—' : item.outingStatus,
                style: TextStyle(
                  fontSize: item.outingStatus.isEmpty ? 11 : 12,
                  fontWeight: FontWeight.bold,
                  color: item.outingStatus.isEmpty ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}