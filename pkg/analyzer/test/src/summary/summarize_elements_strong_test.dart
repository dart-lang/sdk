// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.summarize_elements_strong_test;

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../context/abstract_context.dart';
import 'summarize_elements_test.dart';
import 'summary_common.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(SummarizeElementsStrongTest);
}

/**
 * Override of [SummaryTest] which creates summaries from the element model
 * using strong mode.
 */
@reflectiveTest
class SummarizeElementsStrongTest extends SummarizeElementsTest {
  @override
  AnalysisOptionsImpl get options => super.options..strongMode = true;

  @override
  bool get strongMode => true;

  @override
  DartSdk createDartSdk() => AbstractContextTest.SHARED_STRONG_MOCK_SDK;
}
