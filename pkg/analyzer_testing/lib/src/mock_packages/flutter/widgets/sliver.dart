// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetsSliverLibrary = MockLibraryUnit('lib/src/widgets/sliver.dart', r'''
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

abstract class SliverWithKeepAliveWidget extends RenderObjectWidget {}

abstract class SliverMultiBoxAdaptorWidget extends SliverWithKeepAliveWidget {}

class SliverList extends SliverMultiBoxAdaptorWidget {
  SliverList.list({
    super.key,
    required List<Widget> children,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  });
}

class SliverMainAxisGroup extends Widget {
  final List<Widget> slivers;
  const SliverMainAxisGroup({required this.slivers});
}

class SliverCrossAxisGroup extends Widget {
  final List<Widget> slivers;
  const SliverCrossAxisGroup({required this.slivers});
}
''');
