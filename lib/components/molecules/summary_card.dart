import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../atoms/skeleton_box.dart';
import '../atoms/text_styles.dart';

// 요약 카드 한개 component
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String? value;

  static const double _labelValueGap = 3;
  static const double _valueLineHeight = 20;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;
    final value = this.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(dimens.radiusMd),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            style: TextStyles.summaryLabel.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: _labelValueGap),
          if (value == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: (_valueLineHeight - 14) / 2),
              child: SkeletonBox(width: 72, height: 14),

            )
          else
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.summaryValue.copyWith(color: colors.textPrimary)
            )
        ],
      )
    );
  }
}