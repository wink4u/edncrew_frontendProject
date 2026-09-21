import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/molecules/app_toast.dart';
import '../components/molecules/empty_state.dart';
import '../components/molecules/search_field.dart';
import '../components/organisms/search_result_title.dart';
import '../core/network/api_exception.dart';
import '../domain/stock.dart';
import '../state/favorite_notifier.dart';
import '../state/search_notifier.dart';
import '../state/search_status.dart';
import '../theme/theme.dart';
import 'detail_page.dart';

// StatefulWidget -> TextEditingController 를 만들고 없애야함
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onFavoritePressed(Stock stock) {
    final added = context.read<FavoriteNotifier>().toggle(stock);
    _showToast(added);
  }

  void _showToast(bool added) {
    final colors = context.colors;
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
          content: AppToast(
            icon: added ? Icons.star_rounded : Icons.star_border_rounded,
            iconColor: added ? colors.favoriteActive : null,
            message: added ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
          )
        )
      );
  }

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(dimens.space4),
              child: SearchField(
              controller: _controller,
              onChanged: (value) => context.read<SearchNotifier>().onQueryChanged(value)
              ),
            ),

            Expanded(child: _SearchBody(onFavoritePressed: _onFavoritePressed)),
          ],
        ),
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({required this.onFavoritePressed});

  final void Function(Stock stock) onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchNotifier>();

    return switch (search.status) {
      SearchStatus.initial => const EmptyState(
        icon: Icons.search,
        title: '종목을 검색해 보세요',
        description: '종목명 또는 종목코드 6자리로\n검색하실 수 있습니다.',
      ),

      SearchStatus.loading when search.results.isEmpty =>
        Center(
          child: CircularProgressIndicator(color: context.colors.accentDefault),
        ),

      SearchStatus.loading || SearchStatus.success =>
        _ResultList(
          results: search.results,
          query: search.query,
          onFavoritePressed: onFavoritePressed,
        ),

      SearchStatus.empty => EmptyState(
        icon: Icons.search,
        title: '검색 결과가 없습니다',
        description: "'${search.query}'와 일치하는 검색 결과를 찾지 못했습니다.",
      ),

      SearchStatus.error => EmptyState(
        icon: Icons.error_outline_rounded,
        title: '검색에 실패했습니다',
        description:  _errorMessage(search.error),
        action: TextButton(
          onPressed: search.retry,
          child: const Text('다시 시도'),
        ),
      ),
    };
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.results,
    required this.query,
    required this.onFavoritePressed,
  });

  final List<Stock> results;
  final String query;
  final void Function(Stock stock) onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final stock = results[index];

        return Selector<FavoriteNotifier, bool> (
          key: ValueKey(stock.id),
          selector: (_, favorites) =>
              favorites.isFavorite(stock.id),
          builder: (context, isFavorite, _) =>
              SearchResultTitle(
                  stock: stock,
                  query: query,
                  isFavorite: isFavorite,
                  onTap: () => Navigator.of(context).push(DetailPage.route(stock)),
                  onFavoritePressed: () => onFavoritePressed(stock),
              ),
          );
        },
      );
  }
}

String _errorMessage(Object? error) {
  if (error is ApiException) {
    return switch (error.type) {
      ApiErrorType.timeout => '응답이 늦어지고 있습니다.\n잠시 후 다시 시도해 주세요.',
      ApiErrorType.network => '인터넷 연결을 확인해 주세요.',
      ApiErrorType.http => '서버에 문제가 있습니다.\n잠시 후 다시 시도해 주세요.',
      ApiErrorType.parse => '데이터를 읽지 못했습니다.',
    };
  }
  return '알 수 없는 오류가 발생했습니다.';
}
