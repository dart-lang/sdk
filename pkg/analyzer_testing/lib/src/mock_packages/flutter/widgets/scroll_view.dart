// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetsScrollViewLibrary = MockLibraryUnit(
  'lib/src/widgets/scroll_view.dart',
  r'''
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'sliver.dart';

abstract class ScrollView extends StatelessWidget {
  const ScrollView({
    super.key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    ScrollBehavior? scrollBehavior,
    bool shrinkWrap = false,
    Key? center,
    double anchor = 0.0,
    double? cacheExtent,
    int? semanticChildCount,
    SliverPaintOrder paintOrder = SliverPaintOrder.firstIsTop,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
    HitTestBehavior hitTestBehavior = HitTestBehavior.opaque,
  }) : assert(
         !(controller != null && (primary ?? false)),
         'Primary ScrollViews obtain their ScrollController via inheritance '
         'from a PrimaryScrollController widget. You cannot both set primary to '
         'true and pass an explicit controller.',
       ),
       assert(!shrinkWrap || center == null),
       assert(anchor >= 0.0 && anchor <= 1.0),
       assert(semanticChildCount == null || semanticChildCount >= 0),
       physics =
           physics ??
           ((primary ?? false) ||
                   (primary == null &&
                       controller == null &&
                       identical(scrollDirection, Axis.vertical))
               ? const AlwaysScrollableScrollPhysics()
               : null);
}

class CustomScrollView extends ScrollView {
  const CustomScrollView({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.scrollBehavior,
    super.shrinkWrap,
    super.center,
    super.anchor,
    super.cacheExtent,
    super.paintOrder,
    List<Widget> slivers = const <Widget>[],
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    super.hitTestBehavior,
  });
}
''',
);
