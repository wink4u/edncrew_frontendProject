import 'package:flutter/material.dart';
import '../../theme/theme.dart';

// 글자 스타일을 모은 클래스
abstract final class TextStyles {

  // 종목명 (검색 결과, 관심) 및 검색 입력창 글자
  static const TextStyle stockName = TextStyle(
    fontSize: 15,
    fontWeight: AppTypography.medium,
    height: 20 / 15,
  );

  // 검색결과 005930 . 코스피 및 중간 미들 subtitle
  static const TextStyle stockSubtitle = TextStyle(
    fontSize: 11,
    fontWeight: AppTypography.regular,
    height: 14 / 11,
  );

  static const TextStyle emptyTitle = TextStyle(
    fontSize: 19,
    fontWeight: AppTypography.bold,
    height: 22 / 19,
  );

  static const TextStyle emptySubtitle = TextStyle(
    fontSize: 11,
    fontWeight: AppTypography.regular,
    height: 14 / 11,
  );

  static const TextStyle toast = TextStyle(
    fontSize: 14,
    fontWeight: AppTypography.bold,
    height: 18 / 14,
  );

  // 현재가 (관심 행, 상세 헤더)
  static const TextStyle price = TextStyle(
    fontSize: 15,
    fontWeight: AppTypography.medium,
    height: 20 / 15,
  );

// 등락 텍스트 (색은 방향에 따라 PriceChangeText가 지정)
  static const TextStyle priceChange = TextStyle(
    fontSize: 11,
    fontWeight: AppTypography.regular,
    height: 14 / 11,
  );

  // 상세 화면 현재가
  static const TextStyle detailPrice = TextStyle(
    fontSize: 30,
    fontWeight: AppTypography.bold,
    height: 36 / 30,
  );

  // 상세 화면 등락 (색은 방향에 따라 지정)
  static const TextStyle detailChange = TextStyle(
    fontSize: 15,
    fontWeight: AppTypography.medium,
    height: 20 / 15,
  );

  static const TextStyle sortChip = TextStyle(
    fontSize: 13,
    fontWeight: AppTypography.bold,
    height: 18 / 13,
  );

  // 화면 헤더 제목 (관심)
  static const TextStyle headerTitle = TextStyle(
    fontSize: 19,
    fontWeight: AppTypography.bold,
    height: 22 / 19,
  );

  // 정렬 시트 제목
  static const TextStyle sheetTitle = TextStyle(
    fontSize: 19,
    fontWeight: AppTypography.bold,
    height: 22 / 19,
  );

  // 정렬 시트의 항목 글자 (선택 여부에 따라 색과 굵기를 덧입힘)
  static const TextStyle sortOption = TextStyle(
    fontSize: 15,
    fontWeight: AppTypography.medium,
    height: 20 / 15,
  );

  static const TextStyle periodTab = TextStyle(
    fontSize: 14,
    fontWeight: AppTypography.medium,
    height: 20 / 14,
  );

  // 요약 카드 라벨 (시가, 고가 ...)
  static const TextStyle summaryLabel = TextStyle(
    fontSize: 11,
    fontWeight: AppTypography.regular,
    height: 14 / 11,
  );

  // 요약 카드 값
  static const TextStyle summaryValue = TextStyle(
    fontSize: 15,
    fontWeight: AppTypography.medium,
    height: 20 / 15,
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