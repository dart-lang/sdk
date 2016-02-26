// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.resynthesize_strong_test;

import 'package:analyzer/src/generated/engine.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'resynthesize_test.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(ResynthStrongTest);
}

@reflectiveTest
class ResynthStrongTest extends ResynthTest {
  @override
  AnalysisOptionsImpl createOptions() =>
      super.createOptions()..strongMode = true;
}
