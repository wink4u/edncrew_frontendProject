import 'dart:async';

import 'package:flutter/foundation.dart';
import '../data/repository/search_auto_repository.dart';
import '../domain/stock.dart';
import 'search_status.dart';

class SearchNotifier extends ChangeNotifier {
  SearchNotifier(
    this._repository,
    {this.debounce = const Duration(milliseconds: 300)}
  );

  final SearchAutoRepository _repository;
  final Duration debounce;

  String _query = ''; // 공백일 때 검색어
  SearchStatus _status = SearchStatus.initial;
  List<Stock> _results = const [];
  Object? _error;     // 실패했을 때의 원인

  // 검색할 때 debounce 처리
  Timer? _debounceTimer;  // 디바운스 타이머
  int _requestId = 0;     // 요청 번호 오래된 응답 가리는 용

  String get query => _query;
  SearchStatus get status => _status;
  List<Stock> get results => _results;
  Object? get error => _error;

  void onQueryChanged(String input) {
    final keyword = input.trim();
    // 공백만 바뀐 경우 무시
    if (keyword == _query) return;

    _query = keyword;
    _debounceTimer?.cancel();   // 기다리던 이전 요청 예약 취소
    final requestId = ++_requestId; // 새 번호 발급

    if (keyword.isEmpty) {
      // 검색어를 지웠다면
      _results = const [];
      _error = null;
      _status = SearchStatus.initial;
    } else {
      // 검색어가 있다면 300ms 뒤 요청 보낸다.
      _status = SearchStatus.loading;
      _debounceTimer = Timer(debounce, () => _search(keyword, requestId));
    }

    notifyListeners();
  }

  void retry() {
    if (_query.isEmpty) return;

    _debounceTimer?.cancel();
    _error = null;
    _status = SearchStatus.loading;
    notifyListeners();
    _search(_query, ++_requestId);
  }

  Future<void> _search(String keyword, int requestId) async {
    try {
      final stocks = await _repository.search(keyword);
      if (requestId != _requestId) return;

      _results = stocks;
      _error = null;
      _status = stocks.isEmpty ? SearchStatus.empty : SearchStatus.success;
    } catch (error, stackTrace) {
      if (requestId != _requestId) return;

      debugPrint('검색 실패: $error\n$stackTrace');
      _results = const [];
      _error = error;
      _status = SearchStatus.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _requestId++;
    super.dispose();
  }
}