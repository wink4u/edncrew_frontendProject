import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edencrew_assignment_starter/main.dart';

void main() {
  testWidgets('시작 화면은 다크 테마의 빈 관심 화면이다', (WidgetTester tester) async {
    await tester.pumpWidget(const EdencrewAssignmentApp());

    // 처음 보이는 것은 관심 탭이고, 관심 종목이 없으니 빈 상태가 나온다.
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
    expect(find.text('관심'), findsWidgets);   // 헤더 제목 + 하단 탭
    expect(find.text('검색'), findsOneWidget);   // 하단 탭

    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
  });

  testWidgets('하단의 검색 탭을 누르면 검색 화면으로 바뀐다', (WidgetTester tester) async {
    await tester.pumpWidget(const EdencrewAssignmentApp());

    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();

    expect(find.text('종목을 검색해 보세요'), findsOneWidget);
  });
}
