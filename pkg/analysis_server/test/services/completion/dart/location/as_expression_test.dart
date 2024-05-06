// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AsExpressionTest);
  });
}

@reflectiveTest
class AsExpressionTest extends AbstractCompletionDriverTest {
  Future<void> test_expression() async {
    await computeSuggestions('''
void f(Object v01) {
  ^ as int;
}
''');
    includeKeywords = false;
    assertResponse(r'''
suggestions
  v01
    kind: parameter
''');
  }

  Future<void> test_expression_partial() async {
    await computeSuggestions('''
void f(Object v01) {
  v0^ as int;
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  v01
    kind: parameter
''');
  }

  Future<void> test_type_partial() async {
    await computeSuggestions('''
class A01 {}
void f(Object x) {
  x as A0^;
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  A01
    kind: class
''');
  }
}
