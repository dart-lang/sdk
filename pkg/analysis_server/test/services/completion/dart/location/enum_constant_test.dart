// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumConstantDeclarationTest);
  });
}

@reflectiveTest
class EnumConstantDeclarationTest extends AbstractCompletionDriverTest
    with EnumConstantDeclarationTestCases {}

mixin EnumConstantDeclarationTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterName_atEnd() async {
    await computeSuggestions('''
enum E {
  v^
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }
}
