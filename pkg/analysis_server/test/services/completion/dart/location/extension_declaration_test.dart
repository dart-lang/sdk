// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclarationTest);
  });
}

@reflectiveTest
class ExtensionDeclarationTest extends AbstractCompletionDriverTest
    with ExtensionDeclarationTestCases {}

mixin ExtensionDeclarationTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterExtension_beforeEof() async {
    await computeSuggestions('''
extension ^
''');
    assertResponse(r'''
suggestions
  on
    kind: keyword
  type
    kind: keyword
''');
  }

  Future<void> test_afterName_beforeEof() async {
    await computeSuggestions('''
extension E ^
''');
    assertResponse(r'''
suggestions
  on
    kind: keyword
''');
  }

  Future<void> test_afterName_beforeEof_partial() async {
    await computeSuggestions('''
extension o^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  on
    kind: keyword
''');
  }
}
