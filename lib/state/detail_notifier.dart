import 'package:flutter/material.dart';

import '../data/repository/quote_repository.dart';
import '../domain/quote.dart';
import '../domain/stock.dart';

// 종목 상세 화면의 상태: 이 종목의 시세, 불러오는 중, 실패 원인.
// 화면이 열릴 때 만들어지고 화면이 닫히면 함께 사라진다.
class DetailNotifier extends ChangeNotifier {
  DetailNotifier({required this.stock, required QuoteRepository quotes})
    : _quoteRepository = quotes {
    load();
  }

  final Stock stock;
  final QuoteRepository _quoteRepository;

  Quote? _quote;
  bool _isLoading = false;
  Object? _error;

  int _requestId = 0;       // 오래된 응답을 가려내는 번호
  bool _disposed = false;   // 화면이 닫힌 뒤에 notify하지 않기 위해

  Quote? get quote => _quote;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  // 처음 진입, 다시 시도 모두 이 함수를 쓴다.
  Future<void> load() async {
    final requestId = ++_requestId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _quoteRepository.fetchQuotes([stock.symbol]);
      if (_disposed || requestId != _requestId) return;

      // 응답에 이 종목이 없으면 실패로 본다.
      _quote = result[stock.symbol] ?? (throw StateError('시세 없음: ${stock.symbol}'));
    } catch (error, stackTrace) {
      if (_disposed || requestId != _requestId) return;
      debugPrint('상세 시세 조회 실패: $error\n$stackTrace');
      _error = error;
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
