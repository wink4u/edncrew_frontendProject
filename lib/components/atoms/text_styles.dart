import 'package:flutter/material.dart';
import '../../theme/theme.dart';

// 글자 스타일을 모은 클래스
abstract final class TextStyles {

  // 종목명 (검색 결과, 관심) 및 검색 입력창 글자
  static const TextStyle stockName = TextStyle(
    fontSize: 15,
    fontWeight: AppTypography.medium,
    height: 1.4,
  );

  // 검색결과 005930 . 코스피 및 중간 미들 subtitle
  static const TextStyle stockSubtitle = TextStyle(
    fontSize: 11,
    fontWeight: AppTypography.regular,
    height: 1.4,
  );

  static const TextStyle emptyTitle = TextStyle(
    fontSize: 19,
    fontWeight: AppTypography.bold,
    height: 1.4,
  );

  static const TextStyle emptySubtitle = TextStyle(
    fontSize: 11,
    fontWeight: AppTypography.regular,
    height: 1.4,
  );


  // 상세 화면 '일별 시세' 제목
  static const TextStyle dailyTitle = TextStyle(
    fontSize: 13,
    fontWeight: AppTypography.bold,
    height: 18 / 13,
  );

  // 일별 시세 표 머리글 (날짜, 종가, 등락, 거래량)
  static const TextStyle tableHeader = TextStyle(
    fontSize: 11,
    fontWeight: AppTypography.regular,   // TODO(figma): 굵기 확인
    height: 14 / 11,
  );

  // 일별 시세 표 데이터
  static const TextStyle tableCell = TextStyle(
    fontSize: 11,
    fontWeight: AppTypography.regular,
    height: 14 / 11,
  );
}
