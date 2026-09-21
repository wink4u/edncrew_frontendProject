import 'package:flutter/material.dart';

import '../data/repository/quote_repository.dart';
import '../domain/quote.dart';
import '../domain/stock.dart';
import '../domain/likelist_sort.dart';
import 'favorite_notifier.dart';

// 화면의 한줄의 데이터
typedef LikeListItem = ({Stock stock, Quote? quote});

// 관심 화면의 상태: 시세, 정렬 기준, 새로고침 중, 실패 원인
class LikelistNotifier extends ChangeNotifier {
  LikelistNotifier({
    required FavoriteNotifier favorites,
    required QuoteRepository quotes,
  }) : _favorites = favorites,
       _quoteRepository = quotes {
    _favorites.addListener(_syncWithFavorites);
    _syncWithFavorites();
  }

  final FavoriteNotifier _favorites;
  final QuoteRepository _quoteRepository;

  final Map<String, Quote> _quotes = {};  // 종목코드, 시세

  LikelistSort _sort = LikelistSort.name; // 기본정렬은 가나다순

  bool _isRefreshing = false;
  Object? _error;

  int _requestId = 0; // 오래된 응답을 가려내는 번호

  // 밖에서는 읽기만 가능하게
  LikelistSort get sort => _sort;
  bool get isRefreshing => _isRefreshing;
  Object? get error => _error;
  bool get isEmpty => _favorites.stocks.isEmpty;

  // 화면이 그릴 목록이며, 저장해 두지 않고 읽을 때마다 만듬.
  List<LikeListItem> get items {
    final list = <LikeListItem> [
      for (final stock in _favorites.stocks)
        (stock: stock, quote: _quotes[stock.symbol]),
    ];
    list.sort(_compare);
    return list;
  }

  void setSort(LikelistSort sort) {
    // 같은 기준이 골라지면 아무것도 안하게 됨
    if (sort == _sort) return;

    _sort = sort;
    notifyListeners();
  }

  // 새로고침 버튼을 누를 때, 시세를 다시 요청 받는다.
  Future<void> refresh() =>
      _load(_favorites.stocks.map((s) => s.symbol).toList());

  // 관시에서 빠진 종목의 시세는 버려야함.
  void _syncWithFavorites() {
    final symbols = _favorites.stocks.map((s) => s.symbol).toSet();

    // 시세가 없는 종목을 골라서 요청
    _quotes.removeWhere((symbol, _) => !symbols.contains(symbol));

    // 시세가 없는 종목만 골라서 요청
    final missing = symbols.where((s) => !_quotes.containsKey(s)).toList();

    if (missing.isEmpty) {
      notifyListeners();
    } else {
      _load(missing);
    }
  }

  Future<void> _load(List<String> symbols) async {
    if (symbols.isEmpty) return;

    final requestId = ++_requestId;
    _isRefreshing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _quoteRepository.fetchQuotes(symbols);

      // 새로운 요청이 있다면 버림
      if (requestId != _requestId) return;
      // 덮어쓰지 않고 합침
      _quotes.addAll(result);
    } catch (error, stackTrace) {
      if (requestId != _requestId) return;
      debugPrint('시세 조회 실패: $error\n$stackTrace');
      _error = error; // 기존 시세는 그대로
    }

    _isRefreshing = false;
    notifyListeners();
  }

  // 정렬 기준에 맞게 비교함수를 선책하여 사용
  int _compare(LikeListItem a, LikeListItem b) =>
      switch (_sort) {
        LikelistSort.name => _byName(a, b),
        LikelistSort.price => _byQuote(a, b, (q) => q.price),
        LikelistSort.changeRate => _byQuote(a, b, (q) => q.changeRate),
      };

  // 시세 기준 내림차순으로 정렬, 시세가 없는 종목은 맨 뒤, 시세가 같은 값이면 이름순
  int _byQuote(LikeListItem a, LikeListItem b, num Function(Quote) value) {
    final quoteA = a.quote;
    final quoteB = b.quote;

    if (quoteA == null && quoteB == null) return _byName(a, b);
    if (quoteA == null) return 1;   // a가 뒤로
    if (quoteB == null) return -1;  // b가 뒤로

    // 내림차순 설정
    final result = value(quoteB).compareTo(value(quoteA));

    return result != 0 ? result : _byName(a, b);
  }

  // 이름 오름차순, 이름이 같으면 종목코드로 구분
  int _byName(LikeListItem a, LikeListItem b) {
    final result = a.stock.name.compareTo(b.stock.name);
    return result != 0 ? result : a.stock.symbol.compareTo(b.stock.symbol);
  }

  @override
  void dispose() {
    _favorites.removeListener(_syncWithFavorites);  // 등록한 것은 해제
    _requestId++; // 진행 중 응답 무시
    super.dispose();
  }
}