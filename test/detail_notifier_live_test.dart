// 이 파일의 테스트에 'live'(실서버) 꼬리표를 붙인다.
@Tags(['live'])
library;

import 'dart:async';

import 'package:edencrew_assignment_starter/core/network/api_client.dart';
import 'package:edencrew_assignment_starter/core/network/api_exception.dart';
import 'package:edencrew_assignment_starter/data/datasource/daily_price_api.dart';
import 'package:edencrew_assignment_starter/data/datasource/realtime_price_api.dart';
import 'package:edencrew_assignment_starter/data/repository/daily_price_repository.dart';
import 'package:edencrew_assignment_starter/data/repository/quote_repository.dart';
import 'package:edencrew_assignment_starter/domain/candle.dart';
import 'package:edencrew_assignment_starter/domain/chart_period.dart';
import 'package:edencrew_assignment_starter/domain/stock.dart';
import 'package:edencrew_assignment_starter/state/detail_notifier.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

// ⚠ TestWidgetsFlutterBinding.ensureInitialized() 나 testWidgets 를 쓰지 않는다.
//   쓰는 순간 실서버 요청이 400으로 막힌다. (일반 test()만 사용)
//
// 시나리오: 종목 상세 화면(DetailNotifier)을 진짜 서버(시세 + 일별 시세)로 열어서
//          시세, 기간별 캔들, 일별 시세 표, 기간 탭 전환, 실패와 재시도를 확인한다.

const stock = Stock(symbol: '005930', name: '삼성전자', market: '코스피');

// ---------------------------------------------------------------------------
// 도우미
// ---------------------------------------------------------------------------

// 진짜 http 클라이언트를 감싸서 "어떤 주소로 몇 번 요청했는지"를 기록한다.
// 요청은 그대로 진짜 서버로 나간다. 필요할 때만 일부 요청을 인터넷 끊김처럼 실패시킨다.
class SpyClient extends http.BaseClient {
  final _inner = http.Client();
  final requests = <Uri>[];
  bool Function(Uri uri)? failWhen;   // true를 돌려주는 주소는 연결 실패로 만든다

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests.add(request.url);
    if (failWhen?.call(request.url) ?? false) {
      throw http.ClientException('offline (테스트에서 일부러 끊음)', request.url);
    }
    return _inner.send(request);
  }

  // 일별 시세 요청 (api.stock.naver.com/chart/...)
  List<Uri> get daily => requests.where((u) => u.path.contains('/chart/')).toList();
  // 실시간 시세 요청 (polling.finance.naver.com)
  List<Uri> get quotes => requests.where((u) => u.host.contains('polling')).toList();

  static bool isDaily(Uri uri) => uri.path.contains('/chart/');
  static bool isQuote(Uri uri) => uri.host.contains('polling');
}

// 조건이 참이 될 때까지 notifier의 "알림"을 기다린다. (고정 시간 대기는 느리고 불안정하다)
Future<void> waitUntil(
  ChangeNotifier notifier,
  bool Function() done, {
  Duration timeout = const Duration(seconds: 20),
}) {
  if (done()) return Future.value();

  final completer = Completer<void>();
  void listener() {
    if (done() && !completer.isCompleted) completer.complete();
  }

  notifier.addListener(listener);
  return completer.future
      .timeout(timeout)
      .whenComplete(() => notifier.removeListener(listener));
}

// 테스트마다 새로 만드는 한 벌: 진짜 통신 + 요청 기록 + 상세 화면 상태
class Setup {
  // failWhen: 화면을 만들 때부터 일부 요청을 실패시키고 싶을 때. (시세 요청은 화면을 만드는 순간 바로 나가므로 만든 뒤에는 늦다)
  Setup({bool Function(Uri uri)? failWhen}) {
    spy.failWhen = failWhen;
    final client = ApiClient(client: spy);
    notifier = DetailNotifier(
      stock: stock,
      quotes: QuoteRepository(RealtimePriceApi(client)),
      dailyPrices: DailyPriceRepository(DailyPriceApi(client)),
    );
    addTearDown(notifier.dispose);
  }

  final spy = SpyClient();
  late final DetailNotifier notifier;

  // 화면을 열었을 때 처음 필요한 것이 다 왔다: 시세, 1개월 캔들(=표)
  Future<void> waitOpened() => waitUntil(
    notifier,
    () => !notifier.isLoading && notifier.hasCandles && notifier.hasRecentCandles,
  );

  // 이 기간의 캔들이 도착했다
  Future<void> waitCandles(ChartPeriod period) {
    notifier.setPeriod(period);
    return waitUntil(notifier, () => notifier.period == period && notifier.hasCandles);
  }
}

int daysAgo(DateTime date) {
  final today = DateTime.now();
  return DateTime(today.year, today.month, today.day).difference(date).inDays;
}

// 캔들 한 개를 비교하기 쉽게 문자열로
String describe(Candle c) => '${c.date}|${c.close}|${c.previousClose}';

// ---------------------------------------------------------------------------
// 테스트
// ---------------------------------------------------------------------------

void main() {
  group('화면을 열었을 때', () {
    test('시세와 1개월 캔들이 오고, 처음 선택된 기간은 1개월이다', () async {
      final s = Setup();
      expect(s.notifier.period, ChartPeriod.oneMonth);
      expect(s.notifier.quote, isNull);           // 아직 안 왔다
      expect(s.notifier.hasCandles, isFalse);
      expect(s.notifier.isLoading, isTrue);       // 시세를 받는 중

      await s.waitOpened();

      expect(s.notifier.error, isNull);
      expect(s.notifier.candlesError, isNull);
      expect(s.notifier.isLoading, isFalse);
      expect(s.notifier.quote, isNotNull);
      expect(s.notifier.quote!.symbol, stock.symbol);
    });

    test('요약 카드 값(시가, 고가, 저가, 거래량, 시가총액)이 실제 값으로 온다', () async {
      final s = Setup();
      await s.waitOpened();
      final q = s.notifier.quote!;

      expect(q.price, greaterThan(0));
      expect(q.open, greaterThan(0));
      expect(q.high, greaterThanOrEqualTo(q.low));
      expect(q.high, greaterThanOrEqualTo(q.price));
      expect(q.low, lessThanOrEqualTo(q.price));
      expect(q.volume, greaterThan(0));
      expect(q.marketCap, greaterThan(1000000000000));   // 삼성전자 시가총액은 1조 이상
    });

    test('시세는 한 번, 일별 시세는 한 번만 요청한다', () async {
      final s = Setup();
      await s.waitOpened();

      expect(s.spy.quotes.length, 1);
      expect(s.spy.daily.length, 1);   // 1개월 + 등락 계산용 앞당김을 한 번에
    });

    test('일별 시세 요청 구간은 (1개월 전 - 5일)부터 오늘까지다', () async {
      final s = Setup();
      await s.waitOpened();

      final query = s.spy.daily.single.queryParameters;
      final start = query['startDateTime']!;
      final end = query['endDateTime']!;
      final now = DateTime.now();

      expect(start.length, 12);
      expect(start.endsWith('0000'), isTrue);
      expect(end.endsWith('2359'), isTrue);
      expect(end.substring(0, 8),
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}');
      final startDate = DateTime.parse(start.substring(0, 8));
      expect(daysAgo(startDate), inInclusiveRange(32, 40));   // 약 한 달 + 5일
    });
  });

  group('1개월 캔들', () {
    test('오래된 날짜가 앞이고, 하루에 하나씩이며, 최근 한 달이다', () async {
      final s = Setup();
      await s.waitOpened();
      final candles = s.notifier.candles;

      expect(candles.length, inInclusiveRange(19, 23));
      final dates = candles.map((c) => c.date).toList();
      expect(dates, List.of(dates)..sort());                 // 오래된 날짜가 앞
      expect(dates.toSet().length, dates.length);            // 같은 날이 두 번 없다
      expect(daysAgo(candles.first.date), inInclusiveRange(28, 36));   // 한 달 전 근처에서 시작
      expect(daysAgo(candles.last.date), lessThanOrEqualTo(4));        // 마지막은 오늘 또는 직전 거래일
      expect(candles.every((c) => c.date.weekday <= 5), isTrue);       // 주말은 없다
    });

    test('각 캔들의 값이 말이 된다 (고가 >= 시가, 종가 >= 저가 등)', () async {
      final s = Setup();
      await s.waitOpened();

      for (final c in s.notifier.candles) {
        final reason = describe(c);
        expect(c.high, greaterThanOrEqualTo(c.open), reason: reason);
        expect(c.high, greaterThanOrEqualTo(c.close), reason: reason);
        expect(c.low, lessThanOrEqualTo(c.open), reason: reason);
        expect(c.low, lessThanOrEqualTo(c.close), reason: reason);
        expect(c.low, greaterThan(0), reason: reason);
        expect(c.volume, greaterThan(0), reason: reason);
      }
    });

    test('전일비는 바로 앞 거래일 종가와의 차이이고, 첫 캔들도 계산된다', () async {
      final s = Setup();
      await s.waitOpened();
      final candles = s.notifier.candles;

      // 앞당겨 받은 덕분에 화면의 첫 캔들도 직전 거래일 종가를 안다.
      expect(candles.first.previousClose, isNotNull);
      expect(candles.first.change, candles.first.close - candles.first.previousClose!);

      for (var i = 1; i < candles.length; i++) {
        expect(candles[i].previousClose, candles[i - 1].close, reason: describe(candles[i]));
        expect(candles[i].change, candles[i].close - candles[i - 1].close);
      }
    });

    test('마지막 캔들의 종가는 현재가와 비슷하다', () async {
      final s = Setup();
      await s.waitOpened();
      final last = s.notifier.candles.last;
      final price = s.notifier.quote!.price;

      // 장중에는 마지막 행이 확정 전이라 미세하게 다를 수 있다. 크게 벗어나지 않는지만 본다.
      expect((last.close - price).abs() / price, lessThan(0.05));
    });
  });

  group('일별 시세 표 (최근 5거래일)', () {
    test('5행이고 최신 날짜가 위, 1개월 캔들의 마지막 5개를 뒤집은 것이다', () async {
      final s = Setup();
      await s.waitOpened();
      final recent = s.notifier.recentCandles;
      final candles = s.notifier.candles;

      expect(recent.length, DetailNotifier.tableDays);
      expect(DetailNotifier.tableDays, 5);
      final dates = recent.map((c) => c.date).toList();
      expect(dates, List.of(dates)..sort((a, b) => b.compareTo(a)));   // 최신이 앞
      expect(recent.map(describe), candles.reversed.take(5).map(describe));
    });

    test('각 행의 전일비가 바로 아래 행(더 예전 날)의 종가와 이어진다', () async {
      final s = Setup();
      await s.waitOpened();
      final recent = s.notifier.recentCandles;

      for (var i = 0; i < recent.length - 1; i++) {
        expect(recent[i].previousClose, recent[i + 1].close);
      }
      expect(recent.last.previousClose, isNotNull);   // 5번째 행도 앞 거래일을 안다
    });

    test('기간 탭을 바꿔도 표는 그대로이고 표를 위한 요청도 늘지 않는다', () async {
      final s = Setup();
      await s.waitOpened();
      final before = s.notifier.recentCandles.map(describe).toList();

      await s.waitCandles(ChartPeriod.oneYear);

      expect(s.notifier.recentCandles.map(describe), before);
      expect(s.notifier.hasRecentCandles, isTrue);
    });
  });

  group('기간 탭', () {
    test('같은 기간을 다시 누르면 알림도 요청도 없다', () async {
      final s = Setup();
      await s.waitOpened();
      final requests = s.spy.requests.length;

      var notified = 0;
      s.notifier.addListener(() => notified++);
      s.notifier.setPeriod(ChartPeriod.oneMonth);

      expect(notified, 0);
      expect(s.spy.requests.length, requests);
    });

    test('3개월을 누르면 더 오래된 구간만 추가로 받아서 60일 남짓이 된다', () async {
      final s = Setup();
      await s.waitOpened();
      final oneMonth = s.notifier.candles.length;

      s.notifier.setPeriod(ChartPeriod.threeMonths);
      expect(s.notifier.period, ChartPeriod.threeMonths);
      expect(s.notifier.hasCandles, isFalse);   // 도착 전: 이 기간의 캔들은 아직 없다
      await waitUntil(s.notifier, () => s.notifier.hasCandles);

      expect(s.notifier.candles.length, inInclusiveRange(58, 67));
      expect(s.notifier.candles.length, greaterThan(oneMonth));
      expect(s.spy.daily.length, 2);            // 1개월 + 그보다 오래된 부분
      // 두 번째 요청의 끝은 첫 요청의 시작 바로 앞 (겹치지 않는다)
      final first = s.spy.daily[0].queryParameters['startDateTime']!.substring(0, 8);
      final second = s.spy.daily[1].queryParameters['endDateTime']!.substring(0, 8);
      expect(DateTime.parse(first).difference(DateTime.parse(second)).inDays, 1);
    });

    test('이어 붙인 3개월 캔들이, 처음부터 3개월을 받은 것과 완전히 같다', () async {
      final s = Setup();
      await s.waitOpened();
      await s.waitCandles(ChartPeriod.threeMonths);

      final fresh = DailyPriceRepository(DailyPriceApi(ApiClient()));
      final direct = await fresh.fetchCandles(stock.symbol, ChartPeriod.threeMonths);

      // 오늘 행은 장중이면 조회할 때마다 값이 바뀌므로(실시간) 비교에서 뺀다.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      Iterable<String> settled(List<Candle> list) =>
          list.where((c) => c.date != today).map(describe);

      expect(settled(s.notifier.candles), settled(direct));
      expect(s.notifier.candles.length, direct.length);
    });

    test('받은 기간으로 돌아가면 요청이 늘지 않는다 (1개월 → 3개월 → 1개월 → 3개월)', () async {
      final s = Setup();
      await s.waitOpened();
      await s.waitCandles(ChartPeriod.threeMonths);
      final requests = s.spy.requests.length;
      final three = s.notifier.candles.map(describe).toList();

      s.notifier.setPeriod(ChartPeriod.oneMonth);
      expect(s.notifier.hasCandles, isTrue);     // 기다리지 않고 바로 있다
      expect(s.notifier.candles.length, inInclusiveRange(19, 23));
      s.notifier.setPeriod(ChartPeriod.threeMonths);
      expect(s.notifier.candles.map(describe), three);

      expect(s.spy.requests.length, requests);
    });

    test('1년은 243거래일 안팎이고, 1년을 받은 뒤 6개월과 3개월은 요청이 없다', () async {
      final s = Setup();
      await s.waitOpened();
      await s.waitCandles(ChartPeriod.oneYear);

      expect(s.notifier.candles.length, inInclusiveRange(238, 252));
      final requests = s.spy.daily.length;

      // 이미 받은 구간이라 요청 없이 곧바로 채워진다. (값이 들어오는 데 마이크로태스크 한 번은 걸린다)
      await s.waitCandles(ChartPeriod.sixMonths);
      expect(s.notifier.candles.length, inInclusiveRange(118, 130));
      await s.waitCandles(ChartPeriod.threeMonths);
      expect(s.notifier.candles.length, inInclusiveRange(58, 67));

      expect(s.spy.daily.length, requests);
    });

    test('기간이 길수록 캔들이 많고, 짧은 기간은 긴 기간의 뒷부분이다', () async {
      final s = Setup();
      await s.waitOpened();
      final lists = <ChartPeriod, List<String>>{};
      for (final period in ChartPeriod.values) {
        await s.waitCandles(period);
        lists[period] = s.notifier.candles.map(describe).toList();
      }

      final ordered = ChartPeriod.values.map((p) => lists[p]!).toList();
      for (var i = 1; i < ordered.length; i++) {
        expect(ordered[i].length, greaterThan(ordered[i - 1].length));
        // 짧은 기간의 캔들이 긴 기간의 끝에 그대로 들어 있다
        final shorter = ordered[i - 1];
        final longer = ordered[i];
        expect(longer.sublist(longer.length - shorter.length), shorter);
      }
    });

    test('1개월 → 1년 → 3개월로 연달아 눌러도 일별 시세 요청은 2번이다', () async {
      final s = Setup();
      await s.waitOpened();

      s.notifier.setPeriod(ChartPeriod.oneYear);         // 기다리지 않고
      s.notifier.setPeriod(ChartPeriod.threeMonths);     // 바로 다음 탭
      await waitUntil(s.notifier, () => s.notifier.hasCandles);
      // 3개월은 1년 응답이 오면 이미 들어 있으니 요청 없이 채워진다.
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(s.notifier.period, ChartPeriod.threeMonths);
      expect(s.notifier.candles.length, inInclusiveRange(58, 67));
      expect(s.spy.daily.length, 2);   // 1개월 + 1년의 더 오래된 부분
    });
  });

  group('실패와 다시 시도', () {
    test('일별 시세가 실패하면 캔들 오류가 생기고 시세는 그대로다', () async {
      final s = Setup(failWhen: SpyClient.isDaily);   // 일별 시세 요청만 인터넷 끊김처럼

      await waitUntil(s.notifier, () => !s.notifier.isLoading && s.notifier.candlesError != null);

      expect(s.notifier.candlesError, isA<ApiException>());
      expect((s.notifier.candlesError as ApiException).type, ApiErrorType.network);
      expect(s.notifier.hasCandles, isFalse);
      expect(s.notifier.hasRecentCandles, isFalse);
      expect(s.notifier.recentCandlesError, isNotNull);   // 표도 같은 이유로 실패
      expect(s.notifier.quote, isNotNull);                // 시세는 정상
      expect(s.notifier.error, isNull);
    });

    test('실패한 뒤 다시 시도하면 차트와 표가 복구된다', () async {
      final s = Setup(failWhen: SpyClient.isDaily);
      await waitUntil(s.notifier, () => s.notifier.candlesError != null);

      s.spy.failWhen = null;   // 인터넷이 돌아왔다
      await s.notifier.loadCandles();

      expect(s.notifier.candlesError, isNull);
      expect(s.notifier.hasCandles, isTrue);
      expect(s.notifier.hasRecentCandles, isTrue);
      expect(s.notifier.recentCandles.length, 5);
    });

    test('표만 다시 시도할 수 있다 (다른 탭을 보고 있어도 1개월을 지정해서)', () async {
      final s = Setup(failWhen: SpyClient.isDaily);
      await waitUntil(s.notifier, () => s.notifier.candlesError != null);
      s.notifier.setPeriod(ChartPeriod.sixMonths);   // 다른 탭으로 옮겨 놓고
      await waitUntil(s.notifier, () => s.notifier.candlesError != null);

      s.spy.failWhen = null;
      await s.notifier.loadCandles(ChartPeriod.oneMonth);

      expect(s.notifier.hasRecentCandles, isTrue);
      expect(s.notifier.recentCandles.length, 5);
      expect(s.notifier.recentCandlesError, isNull);
    });

    test('더 긴 기간이 실패해도 이미 받은 1개월과 표는 그대로다', () async {
      final s = Setup();
      await s.waitOpened();
      final oneMonth = s.notifier.candles.map(describe).toList();
      s.spy.failWhen = SpyClient.isDaily;

      s.notifier.setPeriod(ChartPeriod.oneYear);
      await waitUntil(s.notifier, () => s.notifier.candlesError != null);

      expect(s.notifier.hasCandles, isFalse);          // 1년은 없다
      expect(s.notifier.recentCandles.length, 5);      // 표는 그대로
      s.notifier.setPeriod(ChartPeriod.oneMonth);
      expect(s.notifier.candles.map(describe), oneMonth);   // 1개월도 그대로
      expect(s.notifier.candlesError, isNull);              // 그 탭에는 오류가 없다
    });

    test('실패한 탭으로 돌아오면 자동으로 다시 요청하고, 성공하면 채워진다', () async {
      final s = Setup();
      await s.waitOpened();
      s.spy.failWhen = SpyClient.isDaily;
      s.notifier.setPeriod(ChartPeriod.oneYear);
      await waitUntil(s.notifier, () => s.notifier.candlesError != null);

      s.spy.failWhen = null;
      s.notifier.setPeriod(ChartPeriod.oneMonth);
      s.notifier.setPeriod(ChartPeriod.oneYear);    // 실패했던 탭으로 다시
      await waitUntil(s.notifier, () => s.notifier.hasCandles);

      expect(s.notifier.candlesError, isNull);
      expect(s.notifier.candles.length, inInclusiveRange(238, 252));
    });

    test('시세가 실패하면 error가 생기고, 다시 시도하면 시세가 채워진다', () async {
      final s = Setup(failWhen: SpyClient.isQuote);

      await waitUntil(s.notifier, () => !s.notifier.isLoading && s.notifier.error != null);
      expect(s.notifier.error, isA<ApiException>());
      expect(s.notifier.quote, isNull);
      // 차트와 표는 시세와 상관없이 온다.
      await waitUntil(s.notifier, () => s.notifier.hasCandles);
      expect(s.notifier.hasRecentCandles, isTrue);

      s.spy.failWhen = null;
      await s.notifier.load();

      expect(s.notifier.error, isNull);
      expect(s.notifier.quote, isNotNull);
      expect(s.notifier.quote!.price, greaterThan(0));
    });

    test('시세를 한 번 받은 뒤 다시 실패해도 기존 시세는 남는다', () async {
      final s = Setup();
      await s.waitOpened();
      final price = s.notifier.quote!.price;

      s.spy.failWhen = SpyClient.isQuote;
      await s.notifier.load();

      expect(s.notifier.error, isNotNull);
      expect(s.notifier.quote, isNotNull);        // 화면이 비지 않는다
      expect(s.notifier.quote!.price, price);
    });
  });

  group('화면을 닫을 때', () {
    test('요청 중에 닫아도(dispose) 오류 없이 끝난다', () async {
      final spy = SpyClient();
      final client = ApiClient(client: spy);
      final notifier = DetailNotifier(
        stock: stock,
        quotes: QuoteRepository(RealtimePriceApi(client)),
        dailyPrices: DailyPriceRepository(DailyPriceApi(client)),
      );

      notifier.setPeriod(ChartPeriod.oneYear);   // 요청이 나간 상태에서
      notifier.dispose();                        // 응답이 오기 전에 닫는다

      // 응답이 도착해도 이미 정리된 notifier를 건드리지 않아야 한다. (건드리면 예외)
      await Future<void>.delayed(const Duration(seconds: 3));
      expect(spy.requests, isNotEmpty);
    });
  });
}
