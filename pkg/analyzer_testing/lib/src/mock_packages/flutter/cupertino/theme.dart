// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final cupertinoThemeLibrary = MockLibraryUnit(
  'lib/src/cupertino/theme.dart',
  r'''
class NoDefaultCupertinoThemeData {
  const NoDefaultCupertinoThemeData({Color? primaryColor});
}

class CupertinoThemeData extends NoDefaultCupertinoThemeData {
  const CupertinoThemeData({super.primaryColor});
}
''',
);
