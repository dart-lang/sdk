// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeDeclarationTest1);
    defineReflectiveTests(ExtensionTypeDeclarationTest2);
  });
}

@reflectiveTest
class ExtensionTypeDeclarationTest1 extends AbstractCompletionDriverTest
    with ExtensionTypeDeclarationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ExtensionTypeDeclarationTest2 extends AbstractCompletionDriverTest
    with ExtensionTypeDeclarationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ExtensionTypeDeclarationTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterRepresentationField_beforeEof() async {
    await computeSuggestions('''
extension type E(int i) ^
''');
    assertResponse(r'''
suggestions
  implements
    kind: keyword
''');
  }

  Future<void> test_afterRepresentationField_beforeEof_partial() async {
    await computeSuggestions('''
extension type E(int i) i^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  implements
    kind: keyword
''');
  }

  @FailingTest(reason: 'The AstBuilder drops the incomplete extension type')
  Future<void> test_afterType_beforeEof() async {
    await computeSuggestions('''
extension type ^
''');
    assertResponse(r'''
suggestions
''');
  }
}
