class SearchAutocompleteDto {

  // required는 반드시 남겨야 한다는 정의
  const SearchAutocompleteDto({
    required this.code,
    required this.name,
    required this.typeCode,
    required this.typeName,
    required this.url,
    required this.nationCode,
    required this.category
  });

  final String code;        // 종목코드
  final String name;        // 종목명
  final String typeCode;    // 시장 코드
  final String typeName;    // 시장 이름
  final String url;         // 경로
  final String nationCode;  // 국가 코드
  final String category;    // 분류

  factory SearchAutocompleteDto.fromJson(Map<String, dynamic> json) =>
      SearchAutocompleteDto(
          // as String은 문자열이거나 null
          // null이면 빈 문자열로 대체
          code: json['code'] as String? ?? '',
          name: json['name'] as String? ?? '',
          typeCode: json['typeCode'] as String? ?? '',
          typeName: json['typeName'] as String? ?? '',
          url: json['url'] as String? ?? '',
          nationCode: json['nationCode'] as String? ?? '',
          category: json['category'] as String? ?? ''
      );
}