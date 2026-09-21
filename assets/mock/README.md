# 목 데이터

실제 API에서 받은 응답을 그대로 저장한 파일입니다. 파싱 로직을 네트워크 없이 검증할 때 씁니다.

| 파일 | endpoint | 조회 조건 |
| --- | --- | --- |
| `chart_day_005930_1m.json` | 일별 시세 `api.stock.naver.com/chart/domestic/item/005930/day` | 2026-08-16 ~ 2026-09-21 (`1개월` 탭 + 등락 계산용 앞당김 5일) |

## 참고

- 일별 시세는 과제 초기 문서의 `finance.naver.com/item/sise_day.naver`(HTML)가 아니라
  현재 문서(`docs/NAVER_API.md`)의 JSON endpoint를 사용합니다.
- 응답은 거래일만 담긴 배열이고 오래된 날짜가 앞입니다. 등락은 응답에 없어서 직전 거래일 종가와의 차이로 계산합니다.
