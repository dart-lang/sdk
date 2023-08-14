// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorDeclarationTest1);
    defineReflectiveTests(ConstructorDeclarationTest2);
  });
}

@reflectiveTest
class ConstructorDeclarationTest1 extends AbstractCompletionDriverTest
    with ConstructorDeclarationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ConstructorDeclarationTest2 extends AbstractCompletionDriverTest
    with ConstructorDeclarationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ConstructorDeclarationTestCases on AbstractCompletionDriverTest {
  Future<void> test_initializers_beforeInitializer() async {
    await computeSuggestions('''
class A { int f; A() : ^, f = 1; }
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
''');
  }

  Future<void> test_initializers_first() async {
    await computeSuggestions('''
class A { A() : ^; }
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  super
    kind: keyword
  this
    kind: keyword
''');
  }
}
