import 'package:flutter/material.dart';

import '../domain/stock.dart';

// 관심 목록을 들고 있는 상태관리
// ChangeNotifier는 값이 바뀌면 알려주는 기능을 가짐
class FavoriteNotifier extends ChangeNotifier {

  // 키 값은 domestic:000000, 값은 Stock
  // Map은 넣은 순서를 기억하는 것을 활용
  final Map<String, Stock> _stocks = {};

  List<Stock> get stocks => List.unmodifiable(_stocks.values);

  // 종목이 관심 등록 되어있는 bool 값
  bool isFavorite(String id) => _stocks.containsKey(id);

  // true 등록, false 해제
  bool toggle(Stock stock) {
    final willBeFavorite = !_stocks.containsKey(stock.id);

    if (willBeFavorite) {
      _stocks[stock.id] = stock;
    } else {
      _stocks.remove(stock.id);
    }

    // 다시 그리라는 함수
    notifyListeners();
    return willBeFavorite;
  }
}