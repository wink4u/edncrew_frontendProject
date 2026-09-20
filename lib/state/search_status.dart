// 검색 화면이 가질 수 있는 상태
enum SearchStatus {
  initial, // 검색어가 없음
  loading, // 결과를 기다림
  success, // 결과가 나옴
  empty,   // 결과가 0개
  error,   // 요청 실패
}