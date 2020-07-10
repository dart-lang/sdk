// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_relevance.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedMemberRelevanceTest);
  });
}

@reflectiveTest
class DeprecatedMemberRelevanceTest extends CompletionRelevanceTest {
  Future<void> test_deprecated() async {
    await addTestFile('''
class A {
  void a1() { }
  @deprecated
  void a2() { }
}

void main() {
  var a = A();
  a.^
}
''');

    assertOrder([
      suggestionWith(
          completion: 'a1',
          element: ElementKind.METHOD,
          kind: CompletionSuggestionKind.INVOCATION),
      suggestionWith(
          completion: 'a2',
          element: ElementKind.METHOD,
          kind: CompletionSuggestionKind.INVOCATION),
    ]);
  }
}
