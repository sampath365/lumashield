import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which tab the home shell shows. Pages use this to jump between tabs.
class HomeTab extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final homeTabProvider = NotifierProvider<HomeTab, int>(HomeTab.new);
