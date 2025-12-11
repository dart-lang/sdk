// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final materialScaffoldLibrary = MockLibraryUnit(
  'lib/src/material/scaffold.dart',
  r'''
import 'package:flutter/widgets.dart';

class Scaffold extends StatefulWidget {
  const Scaffold({
    super.key,
    PrefferedSizeWidget? appBar,
    Widget? body,
    Widget? floatingActionButton,
    FloatingActionButtonLocation? floatingActionButtonLocation,
    FloatingActionButtonAnimator? floatingActionButtonAnimator,
    List<Widget>? persistentFooterButtons,
    AlignmentDirectional persistentFooterAlignment = AlignmentDirectional.centerEnd,
    BoxDecoration? persistentFooterDecoration,
    Widget? drawer,
    void Function(bool)? onDrawerChanged,
    Widget? endDrawer,
    void Function(bool)? onEndDrawerChanged,
    Widget? bottomNavigationBar,
    Widget? bottomSheet,
    Color? backgroundColor,
    bool? resizeToAvoidBottomInset,
    bool primary = true,
    DragStartBehavior drawerDragStartBehavior = DragStartBehavior.start,
    bool extendBody = false,
    bool drawerBarrierDismissible = true,
    bool extendBodyBehindAppBar = false,
    Color? drawerScrimColor,
    Widget? Function(BuildContext, Animation<double>) bottomSheetScrimBuilder =
        _defaultBottomSheetScrimBuilder,
    double? drawerEdgeDragWidth,
    bool drawerEnableOpenDragGesture = true,
    bool endDrawerEnableOpenDragGesture = true,
    String? restorationId,
  });
}
''',
);
