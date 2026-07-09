// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetsDecoratedSliverLibrary = MockLibraryUnit(
  'lib/src/widgets/decorated_sliver.dart',
  r'''
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

class DecoratedSliver extends SingleChildRenderObjectWidget {
  const DecoratedSliver({
    super.key,
    required Decoration decoration,
    DecorationPosition position = DecorationPosition.background,
    Widget? sliver,
  }) : super(child: sliver);
}
''',
);
