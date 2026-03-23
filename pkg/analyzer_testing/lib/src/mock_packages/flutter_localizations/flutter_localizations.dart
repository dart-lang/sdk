// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

/// The set of compilation units that make up the mock 'flutter_localizations' package.
final List<MockLibraryUnit> units = [_flutterLocalizationsUnit];

final _flutterLocalizationsUnit = MockLibraryUnit(
  'lib/flutter_localizations.dart',
  r'''
library flutter_localizations;

class LocalizationsDelegate<T> {
  const LocalizationsDelegate();
}

abstract class WidgetsLocalizations {}

abstract class GlobalWidgetsLocalizations implements WidgetsLocalizations {
  static const LocalizationsDelegate<WidgetsLocalizations> delegate =
      LocalizationsDelegate<WidgetsLocalizations>();
}

abstract class GlobalMaterialLocalizations implements WidgetsLocalizations {
  static const LocalizationsDelegate<WidgetsLocalizations> delegate =
      LocalizationsDelegate<WidgetsLocalizations>();
}

abstract class GlobalCupertinoLocalizations implements WidgetsLocalizations {
  static const LocalizationsDelegate<WidgetsLocalizations> delegate =
      LocalizationsDelegate<WidgetsLocalizations>();
}
''',
);
