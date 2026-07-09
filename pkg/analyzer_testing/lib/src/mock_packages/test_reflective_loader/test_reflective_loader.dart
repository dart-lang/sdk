// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

/// The set of compilation units that make up the mock 'test_reflective_loader'
/// package.
final List<MockLibraryUnit> units = [_testReflectiveLoaderUnit];

final _testReflectiveLoaderUnit = MockLibraryUnit(
  'lib/test_reflective_loader.dart',
  r'''
library test_reflective_loader;

const Object reflectiveTest = _ReflectiveTest();

const Object skippedTest = SkippedTest();

const Object soloTest = _SoloTest();

class SkippedTest {
  const SkippedTest({String? issue, String? reason});
}

class _ReflectiveTest {
  const _ReflectiveTest();
}

class _SoloTest {
  const _SoloTest();
}
''',
);
