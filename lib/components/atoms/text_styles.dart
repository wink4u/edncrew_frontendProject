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

}