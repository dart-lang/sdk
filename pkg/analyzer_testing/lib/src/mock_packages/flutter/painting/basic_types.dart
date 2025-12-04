// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final paintingBasicTypesLibrary = MockLibraryUnit(
  'lib/src/painting/basic_types.dart',
  r'''
import 'package:ui/ui.dart' show TextDirection;

export 'package:ui/ui.dart'
    show
        BlendMode,
        Color,
        FontStyle,
        FontWeight,
        Radius,
        TextAlign,
        TextBaseline,
        TextDirection;

enum Axis { horizontal, vertical }

enum AxisDirection { up, right, down, left }

enum VerticalDirection { up, down }
''',
);
