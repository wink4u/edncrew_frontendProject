import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'data/datasource/realtime_price_api.dart';
import 'data/datasource/search_autocomplete_api.dart';
import 'data/repository/quote_repository.dart';
import 'data/repository/search_auto_repository.dart';
import 'pages/main_shell.dart';
import 'state/favorite_notifier.dart';
import 'state/likelist_notifier.dart';
import 'state/search_notifier.dart';
import 'theme/theme.dart';

void main() {
  runApp(const EdencrewAssignmentApp());
}

class EdencrewAssignmentApp extends StatelessWidget {
  // apiClient: 테스트에서 가짜 통신을 끼워 넣기 위한 자리. 앱이 실제로 실행될 때는 비워 두면 진짜 통신을 쓴다.
  const EdencrewAssignmentApp({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  Widget build(BuildContext context) {
    // MultiProvider: 여러 provider를 한 번에 등록한다.
    // MaterialApp "위"에 두어서 앱 안의 모든 화면(상세 화면 포함)이 꺼내 쓸 수 있게 한다.
    return MultiProvider(
      providers: [
        // 1. 통신 통로. 앱 전체에서 하나를 공유한다.
        Provider<ApiClient>(create: (_) => apiClient ?? ApiClient()),

        // 2. 검색 repository. 앞에서 등록한 ApiClient를 꺼내 datasource에 넣는다.
        Provider<SearchAutoRepository>(
          create: (context) => SearchAutoRepository(
            SearchAutocompleteApi(context.read<ApiClient>()),
          ),
        ),

        // 3. 시세 repository. 관심 화면과 상세 화면이 함께 쓴다.
        Provider<QuoteRepository>(
          create: (context) => QuoteRepository(
            RealtimePriceApi(context.read<ApiClient>()),
          ),
        ),

        // 4. 관심 목록 상태. ChangeNotifier라서 ChangeNotifierProvider를 쓴다.
        ChangeNotifierProvider<FavoriteNotifier>(
          create: (_) => FavoriteNotifier(),
        ),

        // 5. 검색 상태. repository를 꺼내 넣는다.
        ChangeNotifierProvider<SearchNotifier>(
          create: (context) => SearchNotifier(context.read<SearchAutoRepository>()),
        ),

        // 6. 관심 화면 상태. 위에서 등록한 관심 목록과 시세 repository를 꺼내 넣는다.
        //    (그래서 이 둘보다 아래에 있어야 한다)
        ChangeNotifierProvider<LikelistNotifier>(
          create: (context) => LikelistNotifier(
            favorites: context.read<FavoriteNotifier>(),
            quotes: context.read<QuoteRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: '이든크루 평가 과제',
        theme: AppTheme.dark,
        home: const MainShell(),
      ),
    );
  }
}