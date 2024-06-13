// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinDeclarationTest);
  });
}

@reflectiveTest
class MixinDeclarationTest extends AbstractCompletionDriverTest
    with MixinDeclarationTestCases {}

mixin MixinDeclarationTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterName_beforeBody_partial() async {
    await computeSuggestions('''
mixin M o^ { }
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  on
    kind: keyword
''');
  }

  Future<void> test_afterOnClause_beforeBody_partial() async {
    await computeSuggestions('''
mixin M on A i^ { } class A {}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  implements
    kind: keyword
''');
  }

  Future<void> test_name_withBody() async {
    allowedIdentifiers = {'Test', 'Test {}'};
    await computeSuggestions('''
mixin ^ {}
''');
    assertResponse(r'''
suggestions
  Test
    kind: identifier
''');
  }

  Future<void> test_name_withoutBody() async {
    allowedIdentifiers = {'Test', 'Test {}'};
    await computeSuggestions('''
mixin ^
''');
    assertResponse(r'''
suggestions
  Test {}
    kind: identifier
    selection: 6
''');
  }
}
