import 'package:flutter/material.dart';

import '../../domain/quote.dart';

// 등락 방향 삼각형 (▲ / ▼). 보합이면 아무것도 그리지 않는다.
class DirectionTriangle extends StatelessWidget {
  const DirectionTriangle({
    super.key,
    required this.direction,
    required this.color,
    this.size = 15,
  });

  final PriceDirection direction;
  final Color color;
  final double size;   // 아이콘 영역 (정사각형)

  @override
  Widget build(BuildContext context) {
    if (direction == PriceDirection.flat) return const SizedBox.shrink();

    // 화면 읽기 프로그램에는 글자(등락 값)가 이미 있으니 그림은 읽지 않게 한다.
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _TrianglePainter(up: direction == PriceDirection.up, color: color),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.up, required this.color});

  final bool up;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // 영역 안에서 가로 80%, 세로 60% 크기의 삼각형을 가운데에 놓는다.
    final w = size.width * 0.8;
    final h = size.height * 0.6;
    final left = (size.width - w) / 2;
    final top = (size.height - h) / 2;

    final path = Path();
    if (up) {
      path
        ..moveTo(left + w / 2, top)
        ..lineTo(left + w, top + h)
        ..lineTo(left, top + h);
    } else {
      path
        ..moveTo(left, top)
        ..lineTo(left + w, top)
        ..lineTo(left + w / 2, top + h);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.up != up || old.color != color;
}
