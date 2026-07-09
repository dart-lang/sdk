// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final paintingColorsLibrary = MockLibraryUnit(
  'lib/src/painting/colors.dart',
  r'''
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

@immutable
class ColorSwatch<T> extends Color {
  const ColorSwatch(super.primary, this._swatch);

  @protected
  final Map<T, InvalidType> _swatch;

  Color operator [](T key) => throw 0;
}
''',
);
