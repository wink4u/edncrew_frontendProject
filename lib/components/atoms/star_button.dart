import 'package:flutter/material.dart';
import '../../theme/theme.dart';

// StatelessWidget은 스스로 값을 바꾸지 않는 위젯
class StarButton extends StatelessWidget{
  // super.key는 위젯을 구분하는 식별자를 부모에게 그대로 전달
  // required 반드시 넘겨야 하는 값
  const StarButton({
    super.key,
    required this.isActive,
    required this.onPressed,
  });

  // 관심 등록된 상태
  final bool isActive;
  // 눌렀을 때 실행할 함수 설정
  final VoidCallback onPressed;

  // 화면에 무엇을 그릴지 정하는 메서드
  // 위젯이 그려질 때마다 호출된다.
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return IconButton(
      onPressed: onPressed,
      tooltip: isActive ? '관심 해제' : '관심 등록',
      iconSize: context.dimens.iconMd,
      color: isActive ? colors.favoriteActive : colors.favoriteInactive,
      icon: Icon(isActive ? Icons.star_rounded : Icons.star_border_rounded),
    );
  }
}