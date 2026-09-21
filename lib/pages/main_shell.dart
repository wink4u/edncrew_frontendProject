import 'package:flutter/material.dart';

import '../components/organisms/app_bottom_nav_bar.dart';
import 'likelist_page.dart';
import 'search_page.dart';

// 하단 탭으로 관심, 검색 화면을 오가는 뼈대
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;   // 0 관심, 1 검색

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack: 탭을 옮겨도 각 화면의 상태(검색어, 스크롤)를 유지
      body: IndexedStack(
        index: _index,
        children: const [LikelistPage(), SearchPage()],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
