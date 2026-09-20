import '../../core/network/api_client.dart';
import '../dto/search_autocomplete_dto.dart';

// 검색 자동완성 api
class SearchAutocompleteApi {
  // 받은 Apiclient의 _client에 저장
  const SearchAutocompleteApi(this._client);

  final ApiClient _client;

  Future<List<SearchAutocompleteDto>> search(String query) async {
    // url 경로 설정
    final uri = Uri.https('ac.stock.naver.com', '/ac', {
      'q': query,
      'target' : 'stock,ipo,index,marketindicator',
    });

    // JSON객체를 get요청에 의한 Map으로 받기 위함.
    final json = await _client.getJson(uri);
    final items = json['items'] as List<dynamic>? ?? const [];

    // 배열의 값의 각 원하는 값들을 DTO로 바꾸고 List로 정리
    return items
      .map((e) => SearchAutocompleteDto.fromJson(e as Map<String, dynamic>))
      .toList();
  }
}