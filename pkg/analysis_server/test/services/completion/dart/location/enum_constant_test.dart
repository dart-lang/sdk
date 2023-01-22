// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumConstantDeclarationTest1);
    defineReflectiveTests(EnumConstantDeclarationTest2);
  });
}

@reflectiveTest
class EnumConstantDeclarationTest1 extends AbstractCompletionDriverTest
    with EnumConstantDeclarationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class EnumConstantDeclarationTest2 extends AbstractCompletionDriverTest
    with EnumConstantDeclarationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin EnumConstantDeclarationTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterName_atEnd() async {
    await computeSuggestions('''
enum E {
  v^
}
''');

    assertResponse('''
replacement
  left: 1
suggestions
''');
  }
}
