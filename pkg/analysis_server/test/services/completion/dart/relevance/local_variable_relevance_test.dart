// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_relevance.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalVariableRelevanceTest);
  });
}

@reflectiveTest
class LocalVariableRelevanceTest extends CompletionRelevanceTest {
  Future<void> test_localVariables() async {
    await addTestFile('''
int f() {
  var a = 0;
  var b = 1;
  var c = 2;
  var d = ^;
}
''');

    assertOrder([
      suggestionWith(
          completion: 'c',
          element: ElementKind.LOCAL_VARIABLE,
          kind: CompletionSuggestionKind.INVOCATION),
      suggestionWith(
          completion: 'b',
          element: ElementKind.LOCAL_VARIABLE,
          kind: CompletionSuggestionKind.INVOCATION),
      suggestionWith(
          completion: 'a',
          element: ElementKind.LOCAL_VARIABLE,
          kind: CompletionSuggestionKind.INVOCATION),
    ]);
  }
}
