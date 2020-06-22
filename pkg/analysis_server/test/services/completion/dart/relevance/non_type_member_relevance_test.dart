// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_relevance.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonTypeMemberRelevanceTest);
  });
}

@reflectiveTest
class NonTypeMemberRelevanceTest extends CompletionRelevanceTest {
  Future<void> test_contextType_constructorInvocation_before_type() async {
    await addTestFile('''
class StrWrap {
  String string;
  StrWrap(this.string);
}
void foo(StrWrap s) {}
void bar() {
  foo(^);
}
''');

    var constructorInvocationSuggestion =
        suggestionWith(completion: 'StrWrap', element: ElementKind.CONSTRUCTOR);

    var typeSuggestion =
        suggestionWith(completion: 'StrWrap', element: ElementKind.CLASS);

    assertOrder([constructorInvocationSuggestion, typeSuggestion]);
  }

  @failingTest
  Future<void> test_typeParameters() async {
    await addTestFile('''
class Foo{}
void foo<T>(List<T> bar) {
  List<^> baz;
}
''');

    assertOrder(
        [suggestionWith(completion: 'T'), suggestionWith(completion: 'Foo')]);
  }
}
