// 이 파일의 테스트에 'live'(실서버) 꼬리표를 붙인다. 아래 "실행 방법" 참고.
@Tags(['live'])
library;

import 'dart:async';

import 'package:edencrew_assignment_starter/core/network/api_client.dart';
import 'package:edencrew_assignment_starter/core/network/api_exception.dart';
import 'package:edencrew_assignment_starter/data/datasource/search_autocomplete_api.dart';
import 'package:edencrew_assignment_starter/data/repository/search_auto_repository.dart';
import 'package:edencrew_assignment_starter/domain/stock.dart';
import 'package:edencrew_assignment_starter/state/search_notifier.dart';
import 'package:edencrew_assignment_starter/state/search_status.dart';
import 'package:flutter_test/flutter_test.dart';

// ⚠ TestWidgetsFlutterBinding.ensureInitialized() 나 testWidgets 를 쓰지 않는다.
//   쓰는 순간 실서버 요청이 400으로 막힌다. (일반 test()만 사용)

// 진짜 repository를 감싸서 "몇 번, 무엇으로 요청했는지"만 기록하는 도우미.
// 요청은 그대로 진짜 서버로 나간다.
class SpyRepository implements SearchAutoRepository {
  SpyRepository(this._real);

  final SearchAutoRepository _real;
  final calls = <String>[];   // 받은 검색어를 순서대로 기록

  @override
  Future<List<Stock>> search(String query) {
    calls.add(query);
    return _real.search(query);   // 진짜 repository에 그대로 넘김
  }
}

// 조건이 참이 될 때까지 notifier의 "알림"을 기다린다.
// 고정 시간(예: 2초) 대기는 느리거나 불안정해서, 상태가 바뀌는 순간을 직접 기다린다.
Future<void> waitUntil(
    SearchNotifier notifier,
    bool Function() done, {
      Duration timeout = const Duration(seconds: 15),
    }) {
  if (done()) return Future.value();   // 이미 조건이 참이면 바로 끝

  final completer = Completer<void>();   // "다 됐다"를 알리는 신호
  void listener() {
    if (done() && !completer.isCompleted) completer.complete();
  }

  notifier.addListener(listener);   // 알림이 올 때마다 조건 확인
  return completer.future
      .timeout(timeout)                                  // 끝내 안 되면 테스트를 실패시킴
      .whenComplete(() => notifier.removeListener(listener));   // 끝나면 듣기 해제
}

// 진짜 datasource와 repository를 연결한다.
SearchAutoRepository realRepository([ApiClient? client]) =>
    SearchAutoRepository(SearchAutocompleteApi(client ?? ApiClient()));

const shortDebounce = Duration(milliseconds: 20);   // 테스트가 빨리 끝나도록 짧게

void main() {
  test('삼성전자를 검색하면 success가 되고 005930이 포함된다', () async {
    final notifier = SearchNotifier(realRepository(), debounce: shortDebounce);
    addTearDown(notifier.dispose);   // 테스트가 끝나면(실패해도) 정리

    final log = <String>[];
    notifier.addListener(() => log.add(notifier.status.name));

    notifier.onQueryChanged('삼성전자');
    await waitUntil(notifier, () => notifier.status != SearchStatus.loading);

    expect(log, ['loading', 'success']);                       // 상태 전환 순서
    expect(notifier.status, SearchStatus.success);
    expect(notifier.results, isNotEmpty);
    expect(notifier.results.any((s) => s.symbol == '005930'), isTrue);
    expect(notifier.results.every((s) => s.symbol.length == 6), isTrue);   // 6자리만 통과
  });

  test('없는 검색어는 empty가 된다', () async {
    final notifier = SearchNotifier(realRepository(), debounce: shortDebounce);
    addTearDown(notifier.dispose);

    notifier.onQueryChanged('zzzzqqqq');
    await waitUntil(notifier, () => notifier.status != SearchStatus.loading);

    expect(notifier.status, SearchStatus.empty);
    expect(notifier.results, isEmpty);
    expect(notifier.query, 'zzzzqqqq');   // 빈 상태 문구에 쓸 검색어가 남아 있다
  });

  test('결과가 나온 뒤 검색어를 지우면 initial로 돌아간다', () async {
    final notifier = SearchNotifier(realRepository(), debounce: shortDebounce);
    addTearDown(notifier.dispose);

    notifier.onQueryChanged('삼성');
    await waitUntil(notifier, () => notifier.status == SearchStatus.success);

    notifier.onQueryChanged('');

    expect(notifier.status, SearchStatus.initial);
    expect(notifier.results, isEmpty);
    expect(notifier.query, '');
  });

  test('빠르게 연속 입력하면 요청은 한 번, 마지막 검색어의 결과가 남는다', () async {
    final spy = SpyRepository(realRepository());
    final notifier = SearchNotifier(spy, debounce: const Duration(milliseconds: 100));
    addTearDown(notifier.dispose);

    notifier.onQueryChanged('삼');
    notifier.onQueryChanged('삼성');
    notifier.onQueryChanged('삼성전자');
    await waitUntil(notifier, () => notifier.status != SearchStatus.loading);

    expect(spy.calls, ['삼성전자']);   // 서버에는 마지막 검색어로 한 번만 나감
    expect(notifier.query, '삼성전자');
    expect(notifier.results.any((s) => s.symbol == '005930'), isTrue);
  });

  test('실제 타임아웃이 나면 error 상태와 timeout 예외가 된다', () async {
    // 1ms 안에 응답이 올 수 없으므로 진짜 TimeoutException이 발생한다.
    final notifier = SearchNotifier(
      realRepository(ApiClient(timeout: const Duration(milliseconds: 1))),
      debounce: shortDebounce,
    );
    addTearDown(notifier.dispose);

    notifier.onQueryChanged('삼성전자');
    await waitUntil(notifier, () => notifier.status != SearchStatus.loading);


    expect(notifier.status, SearchStatus.error);
    expect(notifier.error, isA<ApiException>());
    expect((notifier.error as ApiException).type, ApiErrorType.timeout);
  });
}