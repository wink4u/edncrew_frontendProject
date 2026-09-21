import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/candle.dart';
import '../../domain/quote.dart';

// 캔들 차트를 그리는 CustomPainter
class CandleChartPainter extends CustomPainter {
  const CandleChartPainter({
    required this.candles,
    required this.upColor,
    required this.downColor,
    required this.flatColor,
  });

  final List<Candle> candles;
  final Color upColor;
  final Color downColor;
  final Color flatColor;

  static const double sidePadding = 0.8;
  static const double maxGap = 1.2;
  static const double wickWidth = 1;
  static const double minBodyHeight = 1;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final count = candles.length;
    final available = size.width - sidePadding * 2;

    // 캔들이 많아 칸이 좁아지면 간격이 몸통을 다 먹지 않도록 칸 너비의 30%까지만 쓴다.
    // (20개: 간격 1.2 그대로 / 245개: 간격 약 0.44)
    final slot = available / count;
    final gap = math.min(maxGap, slot * 0.3);
    final bodyWidth = (available - gap * (count - 1)) / count;

    // 이 기간의 최고가, 최저가 -> 세로 범위
    var highest = candles.first.high;
    var lowest = candles.first.low;
    for (final c in candles) {
      highest = math.max(highest, c.high);
      lowest = math.min(lowest, c.low);
    }
    final range = highest - lowest;

    // 가격 -> 화면 y 좌표. 높은 가격이 위쪽. 범위가 0이면 가운데 한 줄.
    double yOf(int price) =>
        range == 0 ? size.height / 2 : size.height * (highest - price) / range;

    for (var i = 0; i < count; i++) {
      final c = candles[i];
      final paint = Paint()
        ..color = switch (c.direction) {
          PriceDirection.up => upColor,
          PriceDirection.down => downColor,
          PriceDirection.flat => flatColor,
        };

      final left = sidePadding + i * (bodyWidth + gap);
      final centerX = left + bodyWidth / 2;

      // 꼬리: 고가에서 저가까지 가는 세로 막대
      canvas.drawRect(
        Rect.fromLTRB(
          centerX - wickWidth / 2, yOf(c.high),
          centerX + wickWidth / 2, yOf(c.low),
        ),
        paint,
      );

      // 몸통: 시가와 종가 사이
      var top = yOf(math.max(c.open, c.close));
      var bottom = yOf(math.min(c.open, c.close));
      if (bottom - top < minBodyHeight) {
        final middle = (top + bottom) / 2;
        top = middle - minBodyHeight / 2;
        bottom = middle + minBodyHeight / 2;
      }
      canvas.drawRect(Rect.fromLTRB(left, top, left + bodyWidth, bottom), paint);
    }
  }

  // 데이터나 색이 바뀔 때만 다시 그린다.
  @override
  bool shouldRepaint(CandleChartPainter old) =>
      old.candles != candles ||
          old.upColor != upColor ||
          old.downColor != downColor ||
          old.flatColor != flatColor;
}