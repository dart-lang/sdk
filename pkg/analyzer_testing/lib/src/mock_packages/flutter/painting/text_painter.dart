// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final paintingTextPainterLibrary = MockLibraryUnit(
  'lib/src/painting/text_painter.dart',
  r'''
enum TextWidthBasis { parent, longestLine }
''',
);
