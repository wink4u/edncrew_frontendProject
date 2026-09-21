import 'package:flutter/material.dart';

import '../../domain/candle.dart';
import '../../theme/theme.dart';
import '../atoms/candle_chart_painter.dart';

// 캔들 차트. 높이 200 고정, 너비는 주어진 만큼 꽉 채운다.
class CandleChart extends StatelessWidget {
  const CandleChart({super.key, required this.candles});

  final List<Candle> candles;

  static const double height = 200;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      label: '캔들 차트',   // 화면 읽기 프로그램에 무엇인지 알림
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: CandleChartPainter(
            candles: candles,
            upColor: colors.chartLineUp,
            downColor: colors.chartLineDown,
            flatColor: colors.chartLineFlat,
          ),
        ),
      ),
    );
  }
}