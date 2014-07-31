// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.toplevel;

import 'package:analysis_services/completion/completion_suggestion.dart';
import 'package:analysis_services/src/completion/top_level_computer.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(TopLevelComputerTest);
}

@ReflectiveTestCase()
class TopLevelComputerTest extends AbstractCompletionTest {

  test_class() {
    addTestUnit('class B {boolean v;}');
    return compute().then((_) {
      assertHasResult(CompletionSuggestionKind.CLASS, 'B');
      assertNoResult('v');
    });
  }

  @override
  void setUp() {
    super.setUp();
    computer = new TopLevelComputer(searchEngine);
  }
}