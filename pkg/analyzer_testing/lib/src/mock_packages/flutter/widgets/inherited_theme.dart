// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetsInheritedThemeLibrary = MockLibraryUnit(
  'lib/src/widgets/inherited_theme.dart',
  r'''
import 'framework.dart';

abstract class InheritedTheme extends InheritedWidget {}
''',
);
