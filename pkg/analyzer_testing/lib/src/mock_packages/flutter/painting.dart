// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/flutter/painting/alignment.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/painting/basic_types.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/painting/border_radius.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/painting/borders.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/painting/box_border.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/painting/box_decoration.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/painting/colors.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/painting/decoration.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/painting/edge_insets.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/painting/text_painter.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/painting/text_scaler.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/painting/text_style.dart';
import 'package:analyzer_testing/src/mock_packages/mock_library.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/painting/text_span.dart';

/// The set of compilation units that make up the mock 'painting' component of
/// the 'flutter' package.
final List<MockLibraryUnit> units = [
  paintingLibrary,
  paintingAlignmentLibrary,
  paintingBasicTypesLibrary,
  paintingBorderRadiusLibrary,
  paintingBordersLibrary,
  paintingBoxBorderLibrary,
  paintingBoxDecorationLibrary,
  paintingColorsLibrary,
  paintingDecorationLibrary,
  paintingEdgeInsetsLibrary,
  paintingTextPainterLibrary,
  paintingTextScalerLibrary,
  paintingTextStyleLibrary,
  paintingTextSpanLibrary,
];

final paintingLibrary = MockLibraryUnit('lib/painting.dart', r'''
export 'dart:ui';

export 'src/painting/alignment.dart';
export 'src/painting/basic_types.dart';
export 'src/painting/border_radius.dart';
export 'src/painting/borders.dart';
export 'src/painting/box_border.dart';
export 'src/painting/box_decoration.dart';
export 'src/painting/colors.dart';
export 'src/painting/decoration.dart';
export 'src/painting/edge_insets.dart';
export 'src/painting/text_painter.dart';
export 'src/painting/text_scaler.dart';
export 'src/painting/text_style.dart';
export 'src/painting/text_span.dart';
''');
