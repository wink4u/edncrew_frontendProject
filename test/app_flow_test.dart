import 'dart:convert';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:edencrew_assignment_starter/components/molecules/candle_chart.dart';
import 'package:edencrew_assignment_starter/components/molecules/daily_price_row.dart';
import 'package:edencrew_assignment_starter/components/organisms/app_bottom_nav_bar.dart';
import 'package:edencrew_assignment_starter/core/network/api_client.dart';
import 'package:edencrew_assignment_starter/core/utils/formatters.dart';
import 'package:edencrew_assignment_starter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// 앱 전체 흐름 테스트 (오프라인).
// 진짜 서버 대신 "가짜 서버"가 네 endpoint(검색, 실시간 시세, 일별 시세)에 답한다.
// 그래서 인터넷이 없어도 돌고, 값이 매번 같다.
//
//   flutter test test/app_flow_test.dart

// ---------------------------------------------------------------------------
// 가짜 서버
// ---------------------------------------------------------------------------

const samsung = '삼성전자';
const rise = 'RISE 삼성전자SK하이닉스채권혼합50';
const kodex = 'KODEX 삼성전자SK하이닉스채권혼합50';
const etn = '미래에셋 레버리지 삼성전자 단일종목 ETN';

// 종목코드 -> (이름, 현재가, 전일 종가)
// 정렬 결과가 기준마다 다르도록 값을 골랐다.
//   현재가순:  삼성전자(273,500) > KODEX(14,610) > RISE(13,885)
//   등락률순:  RISE(+6.81%)     > 삼성전자(+5.19%) > KODEX(+1.56%)
//   가나다순:  KODEX < RISE < 삼성전자 (영문 이름이 한글보다 앞)
const _stocks = {
  '005930': (samsung, 273500, 260000),
  '0162Z0': (rise, 13885, 13000),
  '0177N0': (kodex, 14610, 14385),
  '520100': (etn, 9000, 9000),
};

class FakeServer {
  final requests = <Uri>[];
  bool failQuotes = false;
  bool failDaily = false;

  List<Uri> get searches => requests.where((u) => u.host.startsWith('ac.')).toList();
  List<Uri> get quotes => requests.where((u) => u.host.startsWith('polling')).toList();
  List<Uri> get daily => requests.where((u) => u.path.contains('/chart/')).toList();

  Future<http.Response> handle(http.Request request) async {
    final uri = request.url;
    requests.add(uri);

    // 1. 검색 자동완성
    if (uri.host.startsWith('ac.')) {
      final items = [
        for (final e in _stocks.entries)
          {
            'code': e.key,
            'name': e.value.$1,
            'typeCode': 'KOSPI',
            'typeName': '코스피',
            'url': '/domestic/stock/${e.key}',
            'nationCode': 'KOR',
            'category': 'stock',
          },
      ];
      return http.Response.bytes(utf8.encode(jsonEncode({'items': items})), 200);
    }

    // 2. 실시간 시세 (EUC-KR로 내려온다)
    if (uri.host.startsWith('polling')) {
      if (failQuotes) return http.Response('x', 500);
      final symbols = uri.queryParameters['query']!.replaceFirst('SERVICE_ITEM:', '').split(',');
      final datas = [
        for (final s in symbols)
          if (_stocks[s] != null)
            {
              'cd': s,
              'nv': _stocks[s]!.$2,
              'pcv': _stocks[s]!.$3,
              'ov': _stocks[s]!.$2 - 100,
              'hv': _stocks[s]!.$2 + 500,
              'lv': _stocks[s]!.$2 - 700,
              'aq': 29113345,
              'countOfListedStock': 5919637922,
            },
      ];
      final body = jsonEncode({'result': {'areas': [{'datas': datas}]}});
      return http.Response.bytes(cp949.encode(body), 200);
    }

    // 3. 일별 시세: 요청한 구간의 평일마다 한 행. 종가는 평일이 하루 지날 때마다 500씩 오른다.
    if (uri.path.contains('/chart/')) {
      if (failDaily) return http.Response('x', 500);
      DateTime parse(String s) => DateTime(
          int.parse(s.substring(0, 4)), int.parse(s.substring(4, 6)), int.parse(s.substring(6, 8)));
      final from = parse(uri.queryParameters['startDateTime']!);
      final to = parse(uri.queryParameters['endDateTime']!);
      final rows = <Map<String, dynamic>>[];
      for (var d = from; !d.isAfter(to); d = DateTime(d.year, d.month, d.day + 1)) {
        if (d.weekday >= 6) continue;
        final close = 200000.0 + weekdaysSince2026(d) * 500;
        rows.add({
          'localDate': '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}',
          'closePrice': close,
          'openPrice': close - 200,
          'highPrice': close + 700,
          'lowPrice': close - 900,
          'accumulatedTradingVolume': 10000000 + weekdaysSince2026(d),
        });
      }
      return http.Response.bytes(utf8.encode(jsonEncode(rows)), 200);
    }

    return http.Response('not found', 404);
  }
}

int weekdaysSince2026(DateTime d) {
  var n = 0;
  for (var x = DateTime(2026); x.isBefore(d); x = DateTime(x.year, x.month, x.day + 1)) {
    if (x.weekday < 6) n++;
  }
  return n;
}

// 오늘(또는 직전 평일)
DateTime latestWeekday() {
  final now = DateTime.now();
  var d = DateTime(now.year, now.month, now.day);
  while (d.weekday >= 6) {
    d = DateTime(d.year, d.month, d.day - 1);
  }
  return d;
}

// ---------------------------------------------------------------------------
// 화면 조작 도우미
// ---------------------------------------------------------------------------

Future<FakeServer> startApp(WidgetTester tester) async {
  final server = FakeServer();
  await tester.pumpWidget(
    EdencrewAssignmentApp(apiClient: ApiClient(client: MockClient(server.handle))),
  );
  await tester.pumpAndSettle();
  return server;
}

// 종목 이름 글자. 검색창에 입력한 같은 글자(EditableText)는 빼고 화면에 그려진 글자(RichText)만 찾는다.
Finder stockText(String name) => find.byWidgetPredicate(
  (widget) => widget is RichText && widget.text.toPlainText() == name,
);

// 하단 탭 이동 ('관심'은 헤더 제목에도 있어서 탭 바 안에서 찾는다)
Future<void> goToTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(AppBottomNavBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

Future<void> search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump(const Duration(milliseconds: 400));   // 입력 후 잠깐 기다렸다가 검색(debounce)
  await tester.pumpAndSettle();
}

Future<void> tapTooltip(WidgetTester tester, String tooltip, {int index = 0}) async {
  await tester.tap(find.byTooltip(tooltip).at(index));
  await tester.pumpAndSettle();
}

// 관심 목록에서 위에서 아래 순서로 보이는 종목 이름들
List<String> likelistOrder(WidgetTester tester) {
  final shown = <String, double>{};
  for (final name in [samsung, rise, kodex, etn]) {
    final finder = stockText(name);
    if (finder.evaluate().isNotEmpty) shown[name] = tester.getTopLeft(finder.first).dy;
  }
  return (shown.keys.toList()..sort((a, b) => shown[a]!.compareTo(shown[b]!)));
}

Future<void> chooseSort(WidgetTester tester, String from, String to) async {
  await tester.tap(find.text(from));      // 정렬 칩을 눌러 시트를 열고
  await tester.pumpAndSettle();
  await tester.tap(find.text(to));        // 항목을 고른다
  await tester.pumpAndSettle();
}

int candleCount(WidgetTester tester) =>
    tester.widget<CandleChart>(find.byType(CandleChart)).candles.length;

// ---------------------------------------------------------------------------
// 테스트
// ---------------------------------------------------------------------------

void main() {
  testWidgets('전체 흐름: 검색 → 관심 3개 등록 → 정렬 → 상세(기간 탭, 표) → 관심 해제 → 관심/검색 동기화', (tester) async {
    final server = await startApp(tester);

    // 1. 처음에는 관심이 비어 있다.
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
    expect(find.text('검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.'), findsOneWidget);
    expect(server.requests, isEmpty);   // 종목이 없으니 서버에도 묻지 않는다

    // 2. 검색 탭에서 '삼성전자'를 검색하면 결과가 나온다.
    await goToTab(tester, '검색');
    expect(find.text('종목을 검색해 보세요'), findsOneWidget);
    await search(tester, '삼성전자');
    expect(server.searches.length, 1);
    expect(server.searches.single.queryParameters['q'], '삼성전자');
    for (final name in [samsung, rise, kodex, etn]) {
      expect(stockText(name), findsOneWidget, reason: name);
    }
    expect(find.byTooltip('관심 등록'), findsNWidgets(4));   // 아직 아무도 관심이 아니다

    // 3. 위 3개(삼성전자, RISE, KODEX)를 관심으로 등록한다.
    //    결과 순서는 서버가 준 순서 그대로: 삼성전자, RISE, KODEX, ETN
    for (var i = 0; i < 3; i++) {
      await tapTooltip(tester, '관심 등록');   // 등록한 종목은 '관심 해제'로 바뀌어서 늘 첫 번째가 다음 종목이다
      expect(find.text('관심이 등록되었습니다'), findsOneWidget);
    }
    expect(find.byTooltip('관심 해제'), findsNWidgets(3));
    expect(find.byTooltip('관심 등록'), findsNWidgets(1));

    // 4. 관심 탭으로 가면 세 종목이 시세와 함께 보인다.
    await goToTab(tester, '관심');
    expect(find.text('관심 종목이 없습니다'), findsNothing);
    expect(likelistOrder(tester).toSet(), {samsung, rise, kodex});
    expect(stockText(etn), findsNothing);
    expect(find.text('273,500'), findsOneWidget);
    expect(find.text('+13,500 (+5.19%)'), findsOneWidget);
    expect(find.text('13,885'), findsOneWidget);
    expect(find.text('+885 (+6.81%)'), findsOneWidget);
    expect(find.text('14,610'), findsOneWidget);
    expect(find.text('+225 (+1.56%)'), findsOneWidget);
    // 별을 누를 때마다 새로 생긴 종목의 시세만 받는다. (이미 받은 종목은 다시 묻지 않는다)
    expect(server.quotes.length, 3);
    expect(
      server.quotes.map((u) => u.queryParameters['query']),
      ['SERVICE_ITEM:005930', 'SERVICE_ITEM:0162Z0', 'SERVICE_ITEM:0177N0'],
    );

    // 5. 정렬: 가나다순 → 현재가순 → 등락률순 → 다시 가나다순
    expect(find.text('가나다순'), findsOneWidget);
    expect(likelistOrder(tester), [kodex, rise, samsung]);

    await chooseSort(tester, '가나다순', '현재가순');
    expect(find.text('현재가순'), findsOneWidget);
    expect(likelistOrder(tester), [samsung, kodex, rise]);

    await chooseSort(tester, '현재가순', '등락률순');
    expect(find.text('등락률순'), findsOneWidget);
    expect(likelistOrder(tester), [rise, samsung, kodex]);

    await chooseSort(tester, '등락률순', '가나다순');
    expect(likelistOrder(tester), [kodex, rise, samsung]);

    // 정렬은 서버 요청을 늘리지 않는다.
    final quoteRequests = server.quotes.length;
    await chooseSort(tester, '가나다순', '현재가순');
    expect(server.quotes.length, quoteRequests);

    // 6. 새로고침 버튼: 세 종목을 한 번에 다시 받는다.
    await tester.tap(find.byTooltip('새로고침'));
    await tester.pumpAndSettle();
    expect(server.quotes.length, quoteRequests + 1);
    expect(server.quotes.last.queryParameters['query'],
        allOf(contains('005930'), contains('0162Z0'), contains('0177N0')));

    // 7. 현재가가 가장 높은 삼성전자를 눌러 상세 화면으로 간다.
    await tester.tap(stockText(samsung));
    await tester.pumpAndSettle();

    // 7-1. 헤더와 현재가, 등락
    expect(stockText(samsung), findsOneWidget);
    expect(find.text('005930 · 코스피'), findsOneWidget);
    expect(find.byTooltip('뒤로 가기'), findsOneWidget);
    expect(find.byTooltip('관심 해제'), findsOneWidget);       // 이미 관심이다
    expect(find.text('273,500'), findsOneWidget);
    expect(find.text('13,500 (+5.19%)'), findsOneWidget);      // 상세는 금액에 부호를 붙이지 않는다

    // 7-2. 요약 카드: 시가, 고가, 저가, 거래량, 시가총액
    expect(find.text('시가'), findsOneWidget);
    expect(find.text('273,400'), findsOneWidget);
    expect(find.text('고가'), findsOneWidget);
    expect(find.text('274,000'), findsOneWidget);
    expect(find.text('저가'), findsOneWidget);
    expect(find.text('272,800'), findsOneWidget);
    expect(find.text('거래량'), findsWidgets);                  // 카드 라벨과 표 머리글에 모두 있다
    expect(find.text('29,113천'), findsOneWidget);
    expect(find.text('시가총액'), findsOneWidget);
    expect(find.text('1,619조'), findsOneWidget);              // 273,500 x 5,919,637,922 = 1,619조

    // 7-3. 기간 탭과 차트: 처음은 1개월
    expect(find.text('1개월'), findsOneWidget);
    expect(find.text('3개월'), findsOneWidget);
    expect(find.text('6개월'), findsOneWidget);
    expect(find.text('1년'), findsOneWidget);
    expect(find.byType(CandleChart), findsOneWidget);
    final oneMonth = candleCount(tester);
    expect(oneMonth, inInclusiveRange(19, 23));
    expect(server.daily.length, 1);

    // 7-4. 일별 시세 표: 최근 5거래일, 최신이 위
    expect(find.text('일별 시세'), findsOneWidget);
    expect(find.byType(DailyPriceRow), findsNWidgets(5));
    final latest = latestWeekday();
    expect(find.text(formatMonthDay(latest)), findsOneWidget);
    expect(find.text('+500'), findsNWidgets(5));               // 종가가 평일마다 500씩 오르므로 등락은 모두 +500

    // 7-5. 3개월 → 더 오래된 구간만 추가 요청, 표는 그대로
    final tableBefore = find.byType(DailyPriceRow).evaluate().length;
    await tester.tap(find.text('3개월'));
    await tester.pumpAndSettle();
    final threeMonths = candleCount(tester);
    expect(threeMonths, inInclusiveRange(58, 67));
    expect(threeMonths, greaterThan(oneMonth));
    expect(server.daily.length, 2);
    expect(find.byType(DailyPriceRow).evaluate().length, tableBefore);

    // 7-6. 1년 → 6개월/3개월/1개월로 돌아가도 요청이 늘지 않는다.
    await tester.tap(find.text('1년'));
    await tester.pumpAndSettle();
    expect(candleCount(tester), inInclusiveRange(238, 262));
    expect(server.daily.length, 3);
    for (final entry in {'6개월': (118, 132), '3개월': (58, 67), '1개월': (19, 23)}.entries) {
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(candleCount(tester), inInclusiveRange(entry.value.$1, entry.value.$2), reason: entry.key);
    }
    expect(server.daily.length, 3);

    // 8. 상세 화면에서 관심을 해제하면 토스트와 함께 별이 바뀐다.
    await tapTooltip(tester, '관심 해제');
    expect(find.text('관심이 해제되었습니다'), findsOneWidget);
    expect(find.byTooltip('관심 등록'), findsOneWidget);
    expect(find.byTooltip('관심 해제'), findsNothing);

    // 9. 뒤로 가면 관심 목록에서 삼성전자가 빠져 있다.
    await tapTooltip(tester, '뒤로 가기');
    expect(stockText(samsung), findsNothing);
    expect(likelistOrder(tester).toSet(), {kodex, rise});
    expect(find.text('273,500'), findsNothing);

    // 10. 검색 탭의 별도 함께 바뀌어 있다. (관심: RISE, KODEX / 아님: 삼성전자, ETN)
    await goToTab(tester, '검색');
    expect(find.byTooltip('관심 해제'), findsNWidgets(2));
    expect(find.byTooltip('관심 등록'), findsNWidgets(2));

    // 11. 남은 둘도 해제하면 관심 화면이 다시 빈 상태가 된다.
    await tapTooltip(tester, '관심 해제');
    await tapTooltip(tester, '관심 해제');
    await goToTab(tester, '관심');
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
  });

  testWidgets('관심 화면에서 종목을 눌러도, 검색 화면에서 종목을 눌러도 같은 상세 화면이 열린다', (tester) async {
    await startApp(tester);
    await goToTab(tester, '검색');
    await search(tester, '삼성전자');

    // 검색 결과의 종목 이름을 누른다.
    await tester.tap(stockText(kodex));
    await tester.pumpAndSettle();
    expect(find.text('0177N0 · 코스피'), findsOneWidget);
    expect(find.text('14,610'), findsOneWidget);
    expect(find.byTooltip('관심 등록'), findsOneWidget);        // 아직 관심이 아니다

    // 상세에서 관심을 등록하고 돌아오면 검색 결과의 별도 채워져 있다.
    await tapTooltip(tester, '관심 등록');
    expect(find.text('관심이 등록되었습니다'), findsOneWidget);
    await tapTooltip(tester, '뒤로 가기');
    expect(find.byTooltip('관심 해제'), findsOneWidget);
    await goToTab(tester, '관심');
    expect(likelistOrder(tester), [kodex]);

    // 관심 화면의 행을 눌러도 상세로 간다.
    await tester.tap(stockText(kodex));
    await tester.pumpAndSettle();
    expect(find.text('0177N0 · 코스피'), findsOneWidget);
    expect(find.byTooltip('관심 해제'), findsOneWidget);
  });

  testWidgets('새로고침이 실패하면 토스트가 뜨고 기존 시세는 그대로다', (tester) async {
    final server = await startApp(tester);
    await goToTab(tester, '검색');
    await search(tester, '삼성전자');
    await tapTooltip(tester, '관심 등록');
    await goToTab(tester, '관심');
    expect(find.text('273,500'), findsOneWidget);

    server.failQuotes = true;
    await tester.tap(find.byTooltip('새로고침'));
    await tester.pumpAndSettle();

    expect(find.text('시세를 불러오지 못했습니다'), findsOneWidget);   // 토스트
    expect(find.text('273,500'), findsOneWidget);                  // 화면은 비지 않는다

    // 인터넷이 돌아온 뒤 다시 누르면 토스트 없이 갱신된다.
    server.failQuotes = false;
    await tester.pumpAndSettle(const Duration(seconds: 3));         // 토스트가 사라질 때까지
    await tester.tap(find.byTooltip('새로고침'));
    await tester.pumpAndSettle();
    expect(find.text('시세를 불러오지 못했습니다'), findsNothing);
    expect(find.text('273,500'), findsOneWidget);
  });

  testWidgets('상세에서 일별 시세가 실패하면 차트와 표에 안내가 뜨고, 다시 시도하면 복구된다', (tester) async {
    final server = await startApp(tester);
    server.failDaily = true;
    await goToTab(tester, '검색');
    await search(tester, '삼성전자');
    await tester.tap(stockText(samsung));
    await tester.pumpAndSettle();

    // 시세(현재가, 요약 카드)는 정상이고 차트와 표만 실패 안내가 뜬다.
    expect(find.text('273,500'), findsOneWidget);
    expect(find.text('차트를 불러오지 못했습니다'), findsOneWidget);
    expect(find.text('일별 시세를 불러오지 못했습니다'), findsOneWidget);
    expect(find.byType(CandleChart), findsNothing);
    expect(find.byType(DailyPriceRow), findsNothing);
    expect(find.text('다시 시도'), findsNWidgets(2));

    // 인터넷이 돌아온 뒤 차트의 '다시 시도'를 누르면 차트와 표가 함께 채워진다.
    server.failDaily = false;
    await tester.tap(find.text('다시 시도').first);
    await tester.pumpAndSettle();
    expect(find.byType(CandleChart), findsOneWidget);
    expect(find.byType(DailyPriceRow), findsNWidgets(5));
    expect(find.text('차트를 불러오지 못했습니다'), findsNothing);
    expect(find.text('일별 시세를 불러오지 못했습니다'), findsNothing);
  });

  testWidgets('상세에서 시세가 실패하면 오류 화면이 뜨고, 다시 시도하면 화면이 열린다', (tester) async {
    final server = await startApp(tester);
    await goToTab(tester, '검색');
    await search(tester, '삼성전자');
    server.failQuotes = true;
    await tester.tap(stockText(samsung));
    await tester.pumpAndSettle();

    expect(find.text('시세를 불러오지 못했습니다'), findsOneWidget);
    expect(find.text('잠시 후 다시 시도해 주세요.'), findsOneWidget);

    server.failQuotes = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('시세를 불러오지 못했습니다'), findsNothing);
    expect(find.text('273,500'), findsOneWidget);
    expect(find.byType(CandleChart), findsOneWidget);
  });
}
