// 이 파일의 테스트에 'live'(실서버) 꼬리표를 붙인다.
@Tags(['live'])
library;

import 'dart:async';

import 'package:edencrew_assignment_starter/core/network/api_client.dart';
import 'package:edencrew_assignment_starter/core/network/api_exception.dart';
import 'package:edencrew_assignment_starter/data/datasource/realtime_price_api.dart';
import 'package:edencrew_assignment_starter/data/datasource/search_autocomplete_api.dart';
import 'package:edencrew_assignment_starter/data/repository/quote_repository.dart';
import 'package:edencrew_assignment_starter/data/repository/search_auto_repository.dart';
import 'package:edencrew_assignment_starter/domain/likelist_sort.dart';
import 'package:edencrew_assignment_starter/domain/quote.dart';
import 'package:edencrew_assignment_starter/domain/stock.dart';
import 'package:edencrew_assignment_starter/state/favorite_notifier.dart';
import 'package:edencrew_assignment_starter/state/likelist_notifier.dart';
import 'package:edencrew_assignment_starter/state/search_notifier.dart';
import 'package:edencrew_assignment_starter/state/search_status.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter_test/flutter_test.dart';

// ⚠ TestWidgetsFlutterBinding.ensureInitialized() 나 testWidgets 를 쓰지 않는다.
//   쓰는 순간 실서버 요청이 400으로 막힌다. (일반 test()만 사용)
//
// 시나리오: 검색 화면에서 '삼성전자'를 검색해 위 3개를 관심으로 등록하고,
//          관심 화면(LikelistNotifier)의 기능을 진짜 서버로 하나씩 확인한다.

// ---------------------------------------------------------------------------
// 도우미
// ---------------------------------------------------------------------------

// 진짜 QuoteRepository를 감싸서 "무엇을 몇 번 요청했는지" 기록한다. 요청은 그대로 진짜 서버로 나간다.
// 필요할 때만 (1) 일부 종목의 시세를 숨기거나 (2) 진짜 타임아웃을 일으킨다.
class SpyQuotes implements QuoteRepository {
  SpyQuotes()
    : _real = QuoteRepository(RealtimePriceApi(ApiClient())),
      // 1ms 안에 응답이 올 수 없으므로 진짜 TimeoutException이 난다.
      _slow = QuoteRepository(
        RealtimePriceApi(ApiClient(timeout: const Duration(milliseconds: 1))),
      );

  final QuoteRepository _real;
  final QuoteRepository _slow;

  final calls = <List<String>>[];         // 요청한 종목코드 묶음을 순서대로 기록
  final hidden = <String>{};              // 응답에서 빼 버릴 종목코드 (시세가 없는 종목을 흉내)
  bool forceTimeout = false;

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    calls.add(List.of(symbols));
    final result = await (forceTimeout ? _slow : _real).fetchQuotes(symbols);
    return {
      for (final entry in result.entries)
        if (!hidden.contains(entry.key)) entry.key: entry.value,
    };
  }
}

// 조건이 참이 될 때까지 notifier의 "알림"을 기다린다. (고정 시간 대기는 느리고 불안정하다)
Future<void> waitUntil(
  ChangeNotifier notifier,
  bool Function() done, {
  Duration timeout = const Duration(seconds: 15),
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

// 관심 화면이 "다 준비된" 상태: 요청이 끝났고, 목록의 모든 종목이 시세를 갖고 있다.
bool settled(LikelistNotifier n) =>
    !n.isRefreshing && n.items.every((item) => item.quote != null);

// 검색 화면 흉내: 진짜 서버로 '삼성전자'를 검색해서 위 3개를 돌려준다.
Future<List<Stock>> searchTopThree() async {
  final search = SearchNotifier(
    SearchAutoRepository(SearchAutocompleteApi(ApiClient())),
    debounce: const Duration(milliseconds: 20),
  );
  addTearDown(search.dispose);

  search.onQueryChanged('삼성전자');
  await waitUntil(search, () => search.status != SearchStatus.loading);

  expect(search.status, SearchStatus.success);
  expect(search.results.length, greaterThanOrEqualTo(3));
  return search.results.take(3).toList();
}

// 이름 오름차순, 같으면 종목코드 (LikelistNotifier의 가나다순 규칙과 같다)
int byName(Stock a, Stock b) {
  final result = a.name.compareTo(b.name);
  return result != 0 ? result : a.symbol.compareTo(b.symbol);
}

// 테스트마다 새로 만드는 한 벌: 관심 목록 + 시세 요청 기록 + 관심 화면 상태
class Setup {
  Setup() {
    likelist = LikelistNotifier(favorites: favorites, quotes: quotes);
    addTearDown(likelist.dispose);
    addTearDown(favorites.dispose);
  }

  final favorites = FavoriteNotifier();
  final quotes = SpyQuotes();
  late final LikelistNotifier likelist;
}

// ---------------------------------------------------------------------------
// 테스트
// ---------------------------------------------------------------------------

void main() {
  late List<Stock> top3;   // 검색으로 고른 3개 (모든 테스트가 같이 씀)

  setUpAll(() async {
    top3 = await searchTopThree();
    // 검색 결과가 바뀌어 종목이 이상하면 이후 테스트 의미가 없다.
    expect(top3.map((s) => s.symbol).toSet().length, 3);
  });

  test('관심이 없으면 비어 있다', () async {
    final s = Setup();

    expect(s.likelist.isEmpty, isTrue);
    expect(s.likelist.items, isEmpty);
    expect(s.likelist.isRefreshing, isFalse);
    expect(s.quotes.calls, isEmpty);   // 종목이 없으면 요청도 없다
  });

  test('검색한 위 3개를 관심으로 두면 시세가 모두 채워진다', () async {
    final s = Setup();

    for (final stock in top3) {
      s.favorites.toggle(stock);
    }
    expect(s.likelist.isEmpty, isFalse);
    expect(s.likelist.items.length, 3);
    // 시세가 오기 전에는 시세 없는 행(스켈레톤)으로 먼저 보인다.
    expect(s.likelist.items.every((item) => item.quote == null), isTrue);
    expect(s.likelist.isRefreshing, isTrue);

    await waitUntil(s.likelist, () => settled(s.likelist));

    expect(s.likelist.error, isNull);
    for (final item in s.likelist.items) {
      expect(item.quote, isNotNull, reason: '${item.stock.name} 시세');
      expect(item.quote!.symbol, item.stock.symbol);
      expect(item.quote!.price, greaterThan(0));
      expect(item.quote!.previousClose, greaterThan(0));
    }
  });

  test('시세 요청은 종목마다 따로가 아니라 묶음으로 나간다', () async {
    final s = Setup();

    // 세 종목을 한 번에 등록하면 마지막 요청에 세 종목이 모두 들어 있다.
    for (final stock in top3) {
      s.favorites.toggle(stock);
    }
    await waitUntil(s.likelist, () => settled(s.likelist));

    expect(s.quotes.calls.length, lessThanOrEqualTo(3));   // 종목 수(3)보다 많이 나가지 않는다
    expect(
      s.quotes.calls.last.toSet(),
      top3.map((stock) => stock.symbol).toSet(),
    );
    // 한 요청 안에 종목이 여러 개 담겼다 (종목당 한 번씩 부르지 않는다)
    expect(s.quotes.calls.any((symbols) => symbols.length > 1), isTrue);
  });

  test('처음 정렬은 가나다순이다', () async {
    final s = Setup();
    for (final stock in top3) {
      s.favorites.toggle(stock);
    }
    await waitUntil(s.likelist, () => settled(s.likelist));

    expect(s.likelist.sort, LikelistSort.name);
    expect(
      s.likelist.items.map((item) => item.stock.symbol),
      (List.of(top3)..sort(byName)).map((stock) => stock.symbol),
    );
  });

  test('현재가순은 현재가가 높은 순서로 정렬된다', () async {
    final s = Setup();
    for (final stock in top3) {
      s.favorites.toggle(stock);
    }
    await waitUntil(s.likelist, () => settled(s.likelist));

    s.likelist.setSort(LikelistSort.price);

    final prices = s.likelist.items.map((item) => item.quote!.price).toList();
    expect(prices, List.of(prices)..sort((a, b) => b.compareTo(a)));
  });

  test('등락률순은 등락률이 높은 순서로 정렬된다', () async {
    final s = Setup();
    for (final stock in top3) {
      s.favorites.toggle(stock);
    }
    await waitUntil(s.likelist, () => settled(s.likelist));

    s.likelist.setSort(LikelistSort.changeRate);

    final rates = s.likelist.items.map((item) => item.quote!.changeRate).toList();
    expect(rates, List.of(rates)..sort((a, b) => b.compareTo(a)));
  });

  test('정렬을 바꿔도 서버 요청은 늘지 않고, 같은 기준을 다시 고르면 알림도 없다', () async {
    final s = Setup();
    for (final stock in top3) {
      s.favorites.toggle(stock);
    }
    await waitUntil(s.likelist, () => settled(s.likelist));
    final before = s.quotes.calls.length;

    var notified = 0;
    s.likelist.addListener(() => notified++);

    s.likelist.setSort(LikelistSort.price);
    s.likelist.setSort(LikelistSort.changeRate);
    s.likelist.setSort(LikelistSort.name);
    expect(notified, 3);                           // 바뀔 때마다 한 번씩 알린다
    expect(s.quotes.calls.length, before);         // 정렬은 이미 받은 시세로 한다

    s.likelist.setSort(LikelistSort.name);         // 같은 기준
    expect(notified, 3);                           // 알리지 않는다
  });

  test('상위 하나를 관심 해제하면 그 종목만 빠지고 다시 요청하지 않는다', () async {
    final s = Setup();
    for (final stock in top3) {
      s.favorites.toggle(stock);
    }
    await waitUntil(s.likelist, () => settled(s.likelist));
    s.likelist.setSort(LikelistSort.price);
    final removed = s.likelist.items.first.stock;   // 현재가가 가장 높은 종목
    final before = s.quotes.calls.length;

    s.favorites.toggle(removed);

    final items = s.likelist.items;
    expect(items.length, 2);
    expect(items.any((item) => item.stock.symbol == removed.symbol), isFalse);
    expect(items.every((item) => item.quote != null), isTrue);   // 남은 시세는 그대로
    expect(s.likelist.sort, LikelistSort.price);                 // 정렬 기준도 유지
    expect(s.quotes.calls.length, before);                       // 이미 있으니 요청 없음
    expect(s.likelist.isRefreshing, isFalse);
  });

  test('관심 해제했던 종목을 다시 등록하면 그 종목만 다시 조회한다', () async {
    final s = Setup();
    for (final stock in top3) {
      s.favorites.toggle(stock);
    }
    await waitUntil(s.likelist, () => settled(s.likelist));
    final target = top3.first;
    s.favorites.toggle(target);   // 해제
    final before = s.quotes.calls.length;

    s.favorites.toggle(target);   // 다시 등록
    await waitUntil(s.likelist, () => settled(s.likelist));

    expect(s.likelist.items.length, 3);
    expect(s.quotes.calls.length, before + 1);
    expect(s.quotes.calls.last, [target.symbol]);   // 새로 생긴 종목만 요청
  });

  test('모두 해제하면 빈 상태가 된다', () async {
    final s = Setup();
    for (final stock in top3) {
      s.favorites.toggle(stock);
    }
    await waitUntil(s.likelist, () => settled(s.likelist));

    for (final stock in top3) {
      s.favorites.toggle(stock);
    }

    expect(s.likelist.isEmpty, isTrue);
    expect(s.likelist.items, isEmpty);
  });

  test('새로고침은 전체 종목을 한 번에 다시 받고, 끝나면 isRefreshing이 꺼진다', () async {
    final s = Setup();
    for (final stock in top3) {
      s.favorites.toggle(stock);
    }
    await waitUntil(s.likelist, () => settled(s.likelist));
    final before = s.quotes.calls.length;

    final states = <bool>[];
    s.likelist.addListener(() => states.add(s.likelist.isRefreshing));

    await s.likelist.refresh();

    expect(states, [true, false]);                   // 시작과 끝, 각각 한 번씩 알림
    expect(s.likelist.isRefreshing, isFalse);
    expect(s.likelist.error, isNull);
    expect(s.quotes.calls.length, before + 1);       // 요청은 한 번
    expect(s.quotes.calls.last.toSet(), top3.map((e) => e.symbol).toSet());
    expect(s.likelist.items.every((item) => item.quote != null), isTrue);
  });

  test('새로고침이 실패하면 error가 생기고 기존 시세는 그대로 남는다', () async {
    final s = Setup();
    for (final stock in top3) {
      s.favorites.toggle(stock);
    }
    await waitUntil(s.likelist, () => settled(s.likelist));
    final beforePrices = {
      for (final item in s.likelist.items) item.stock.symbol: item.quote!.price,
    };

    s.quotes.forceTimeout = true;   // 진짜 타임아웃
    await s.likelist.refresh();

    expect(s.likelist.error, isA<ApiException>());
    expect((s.likelist.error as ApiException).type, ApiErrorType.timeout);
    expect(s.likelist.isRefreshing, isFalse);
    expect(s.likelist.items.length, 3);
    for (final item in s.likelist.items) {
      expect(item.quote, isNotNull);   // 화면이 비지 않는다
      expect(item.quote!.price, beforePrices[item.stock.symbol]);
    }

    // 이어서 다시 새로고침하면 복구되고 error가 지워진다.
    s.quotes.forceTimeout = false;
    await s.likelist.refresh();
    expect(s.likelist.error, isNull);
    expect(s.likelist.items.every((item) => item.quote != null), isTrue);
  });

  test('시세를 못 받은 종목은 현재가순, 등락률순에서 맨 뒤로 간다', () async {
    final s = Setup();
    s.quotes.hidden.add(top3.first.symbol);   // 서버 응답에서 첫 종목의 시세를 뺀다
    for (final stock in top3) {
      s.favorites.toggle(stock);
    }
    await waitUntil(s.likelist, () => !s.likelist.isRefreshing);

    for (final sort in [LikelistSort.price, LikelistSort.changeRate]) {
      s.likelist.setSort(sort);
      final items = s.likelist.items;
      expect(items.length, 3, reason: sort.name);
      expect(items.last.stock.symbol, top3.first.symbol, reason: sort.name);
      expect(items.last.quote, isNull, reason: sort.name);
      expect(items.take(2).every((item) => item.quote != null), isTrue, reason: sort.name);
    }
  });

  test('관심을 빠르게 연달아 눌러도 마지막에는 세 종목 시세가 모두 채워진다', () async {
    final s = Setup();

    // 응답을 기다리지 않고 바로 다음 종목을 등록한다.
    s.favorites.toggle(top3[0]);
    s.favorites.toggle(top3[1]);
    s.favorites.toggle(top3[2]);
    await waitUntil(s.likelist, () => settled(s.likelist));

    expect(s.likelist.items.length, 3);
    expect(s.likelist.items.every((item) => item.quote != null), isTrue);
    expect(s.likelist.error, isNull);
  });

  test('요청 중에 화면이 사라져도(dispose) 오류 없이 끝난다', () async {
    final favorites = FavoriteNotifier();
    final quotes = SpyQuotes();
    final likelist = LikelistNotifier(favorites: favorites, quotes: quotes);

    favorites.toggle(top3.first);   // 요청이 나간다
    likelist.dispose();             // 응답이 오기 전에 화면이 닫힌다

    // 응답이 도착해도 이미 정리된 notifier를 건드리지 않아야 한다. (건드리면 예외)
    await Future<void>.delayed(const Duration(seconds: 3));
    favorites.dispose();
    expect(quotes.calls, isNotEmpty);
  });
}
