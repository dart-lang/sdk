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

  void addTestUnit(String content) {
    super.addTestUnit(content);
    computer = new TopLevelComputer(searchEngine, testUnit);
  }

  test_class_1() {
    addUnit('/testA.dart', 'var T1; class A {bool x;}');
    addUnit('/testB.dart', 'class B {bool y;}');
    addTestUnit('import "/testA.dart"; class C {bool v;^}');
    return compute().then((_) {
      assertHasResult(CompletionSuggestionKind.CLASS, 'A');
      assertHasResult(CompletionSuggestionKind.CLASS, 'B', CompletionRelevance.LOW);
      assertHasResult(CompletionSuggestionKind.CLASS, 'C');
      assertHasResult(CompletionSuggestionKind.CLASS, 'Object');
      assertHasResult(CompletionSuggestionKind.TOP_LEVEL_VARIABLE, 'T1');
      assertNoResult('x');
      assertNoResult('y');
      assertNoResult('v');
    });
  }
}