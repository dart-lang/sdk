// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IndexExpressionTest);
  });
}

@reflectiveTest
class IndexExpressionTest extends AbstractCompletionDriverTest {
  Future<void> test_index() async {
    await computeSuggestions('''
void f(List<int> v, int a01) {
  v[a0^];
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  a01
    kind: parameter
''');
  }

  Future<void> test_target() async {
    await computeSuggestions('''
void f(List<int> a01) {
  a0^[0];
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  a01
    kind: parameter
''');
  }
}
