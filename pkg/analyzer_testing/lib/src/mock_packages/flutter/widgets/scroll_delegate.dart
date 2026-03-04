import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetsScrollDelegateLibrary = MockLibraryUnit(
  'src/widgets/scroll_delegate.dart',
  r'''
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'framework.dart';

abstract class SliverChildDelegate {}

class SliverChildListDelegate extends SliverChildDelegate {
  final List<Widget> children;
  const SliverChildListDelegate(this.children);
}
''',
);
