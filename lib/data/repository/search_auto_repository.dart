import '../../domain/stock.dart';
import '../datasource/search_autocomplete_api.dart';

class SearchAutoRepository {
  const SearchAutoRepository(this._api);

  final SearchAutocompleteApi _api;

  // symbol이 6자리인지 확인
  static final _symbolPattern = RegExp(r'[0-9A-z]{6}');

  Future<List<Stock>> search(String query) async {
    // 검색 앞 뒤 공백 제거
    final trimmed = query.trim();
    // 검색값이 비어 있으면 빈 리스트 return
    if (trimmed.isEmpty) return const [];

    // 검색 결과인 DTO 배열
    final items = await _api.search(trimmed);

    // 조건에 맞는 것을 Stock으로 정리
    return [
      for (final item in items)
        if (item.nationCode == 'KOR' &&
          item.category == 'stock' &&
          _symbolPattern.hasMatch(item.code))
          Stock(symbol: item.code, name: item.name, market: item.typeName),
    ];
  }
}