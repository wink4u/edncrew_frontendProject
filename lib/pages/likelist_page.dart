import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/molecules/app_toast.dart';
import '../components/molecules/empty_state.dart';
import '../components/organisms/likelist_header.dart';
import '../components/organisms/likelist_item.dart';
import '../components/organisms/sort_bottom_sheet.dart';
import '../state/likelist_notifier.dart';
import '../theme/theme.dart';
import 'detail_page.dart';

// 관심 화면. 상태는 LikelistNotifier가 갖고, 이 화면은 보여주고 이벤트만 전달한다.
class LikelistPage extends StatelessWidget {
  const LikelistPage({super.key});

  // 정렬 시트를 열고, 고른 기준이 있으면 notifier에 넘긴다.
  Future<void> _onSortTap(BuildContext context) async {
    final notifier = context.read<LikelistNotifier>();

    final picked = await SortBottomSheet.show(context, selected: notifier.sort);

    // await 뒤에는 화면이 사라졌을 수 있어서 확인
    if (picked == null || !context.mounted) return;
    notifier.setSort(picked);
  }

  // 새로고침 버튼과 당겨서 새로고침이 같이 쓴다. 실패했을 때만 toast를 띄운다.
  Future<void> _onRefresh(BuildContext context) async {
    final notifier = context.read<LikelistNotifier>();
    await notifier.refresh();

    if (!context.mounted || notifier.error == null) return;
    _showErrorToast(context);
  }

  void _showErrorToast(BuildContext context) {
    final dimens = context.dimens;

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.fromLTRB(dimens.space4, 0, dimens.space4, dimens.space2),
          duration: const Duration(seconds: 2),
          content: const AppToast(
            icon: Icons.error_outline_rounded,
            message: '시세를 불러오지 못했습니다',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 정렬 기준이 바뀔 때만 헤더를 다시 그린다.
            Selector<LikelistNotifier, String>(
              selector: (_, notifier) => notifier.sort.label,
              builder: (context, label, _) => LikelistHeader(
                sortLabel: label,
                onSortTap: () => _onSortTap(context),
                onRefresh: () => _onRefresh(context),
              ),
            ),
            Expanded(child: _LikelistBody(onRefresh: () => _onRefresh(context))),
          ],
        ),
      ),
    );
  }
}

class _LikelistBody extends StatelessWidget {
  const _LikelistBody({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final notifier = context.watch<LikelistNotifier>();

    if (notifier.isEmpty) {
      return const EmptyState(
        icon: Icons.star_border_rounded,
        title: '관심 종목이 없습니다',
        description: '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
      );
    }

    final items = notifier.items;

    return RefreshIndicator(
      color: colors.accentDefault,
      backgroundColor: colors.surfaceOverlay,
      onRefresh: onRefresh,
      child: ListView.builder(
        // 항목이 적어도 당겨서 새로고침이 되도록
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return LikelistItem(
            key: ValueKey(item.stock.id),
            stock: item.stock,
            quote: item.quote,
            onTap: () => Navigator.of(context).push(DetailPage.route(item.stock)),
          );
        },
      ),
    );
  }
}
