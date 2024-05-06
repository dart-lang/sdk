// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StringInterpolationTest);
    defineReflectiveTests(StringLiteralTest);
  });
}

@reflectiveTest
class StringInterpolationTest extends AbstractCompletionDriverTest
    with StringInterpolationTestCases {}

mixin StringInterpolationTestCases on AbstractCompletionDriverTest {
  Future<void> test_inBraces_nonVoid() async {
    await computeSuggestions(r'''
var s = 'a ${^} b';
void f0() {}
int f1() {}
''');
    assertResponse(r'''
suggestions
  f1
    kind: functionInvocation
''');
  }
}

@reflectiveTest
class StringLiteralTest extends AbstractCompletionDriverTest
    with StringLiteralTestCases {}

mixin StringLiteralTestCases on AbstractCompletionDriverTest {
  Future<void> test_inArgumentList_named() async {
    await computeSuggestions('''
void f() {foo(bar: "^");}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_inArgumentList_positional() async {
    await computeSuggestions('''
void f() {foo("^");}
''');
    assertResponse(r'''
suggestions
''');
  }
}
