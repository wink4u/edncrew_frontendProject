import 'package:flutter/material.dart';

import '../../theme/theme.dart';

// 스텤레톤 박스 component
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.feedbackSkeleton,
          borderRadius: BorderRadius.circular(context.dimens.radiusSm),
        ),
      )
    );
  }
}