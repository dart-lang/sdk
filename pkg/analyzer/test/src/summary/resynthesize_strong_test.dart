// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.resynthesize_strong_test;

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../context/abstract_context.dart';
import 'resynthesize_test.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(ResynthesizeStrongTest);
}

@reflectiveTest
class ResynthesizeStrongTest extends ResynthesizeElementTest {
  @override
  DartSdk createDartSdk() => AbstractContextTest.SHARED_STRONG_MOCK_SDK;

  @override
  AnalysisOptionsImpl createOptions() =>
      super.createOptions()..strongMode = true;
}
