// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final materialColorsLibrary = MockLibraryUnit(
  'lib/src/material/color_scheme.dart',
  r'''
class ColorScheme {
  const ColorScheme.light({
    Color primary = const Color(0xff6200ee)
  });

  const ColorScheme.dark({
    Color primary = const Color(0xff6200ee)
  });
}
''',
);
