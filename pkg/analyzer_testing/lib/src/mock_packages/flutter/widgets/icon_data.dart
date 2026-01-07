// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetsIconDataLibrary = MockLibraryUnit(
  'lib/src/widgets/icon_data.dart',
  r'''
@immutable
class IconData {
  final int codePoint;

  final String? fontFamily;

  const IconData(
    this.codePoint, {
    this.fontFamily,
    String? fontPackage,
    bool matchTextDirection = false,
    List<String>? fontFamilyFallback,
  });
}
''',
);
