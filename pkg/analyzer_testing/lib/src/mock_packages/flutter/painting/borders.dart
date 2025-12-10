// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final paintingBordersLibrary = MockLibraryUnit(
  'lib/src/painting/borders.dart',
  r'''
import 'package:flutter/foundation.dart';
import 'basic_types.dart';

@immutable
class BorderSide with Diagnosticable {
  static const BorderSide none = BorderSide(
    width: 0.0,
    style: BorderStyle.none,
  );

  final Color color;

  final double width;

  final BorderStyle style;

  const BorderSide({
    this.color = const Color(0xFF000000),
    this.width = 1.0,
    this.style = BorderStyle.solid,
    double strokeAlign = strokeAlignInside,
  }) : assert(width >= 0.0);

  BorderSide copyWith({
    Color? color,
    double? width,
    BorderStyle? style,
    double? strokeAlign,
  }) => throw 0;
}

enum BorderStyle { none, solid }

@immutable
abstract class ShapeBorder {
  const ShapeBorder();
}
''',
);
