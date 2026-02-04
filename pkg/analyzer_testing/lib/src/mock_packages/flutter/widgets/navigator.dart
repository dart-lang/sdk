// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetsNavigatorLibrary = MockLibraryUnit(
  'lib/src/widgets/navigator.dart',
  r'''
class Navigator extends StatefulWidget {
  static NavigatorState of(
    BuildContext context, {
    bool rootNavigator = false,
  }) => throw 0;
}

class NavigatorState extends State<Navigator>
    with TickerProviderStateMixin, RestorationMixin {
  @optionalTypeArgs
  void pop<T extends Object?>([T? result]) {}
}
''',
);
