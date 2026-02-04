// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final paintingBoxDecorationLibrary = MockLibraryUnit(
  'lib/src/painting/box_decoration.dart',
  r'''
import 'basic_types.dart';
import 'border_radius.dart';
import 'box_border.dart';
import 'decoration.dart';

class BoxDecoration extends Decoration {
  final Color color;

  final BoxBorder? border;

  final BorderRadiusGeometry? borderRadius;

  final InvalidType backgroundBlendMode;

  final BoxShape shape;

  const BoxDecoration({
    this.color,
    DecorationImage? image,
    this.border,
    this.borderRadius,
    List<BoxShadow>? boxShadow,
    Gradient? gradient,
    this.backgroundBlendMode,
    this.shape = BoxShape.rectangle,
  }) : assert(
         backgroundBlendMode == null || color != null || gradient != null,
         "backgroundBlendMode applies to BoxDecoration's background color or "
         'gradient, but no color or gradient was provided.',
       );
}
''',
);
