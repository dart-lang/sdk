// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeDeclarationTest);
  });
}

@reflectiveTest
class ExtensionTypeDeclarationTest extends AbstractCompletionDriverTest
    with ExtensionTypeDeclarationTestCases {}

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

  Future<void> test_afterType_beforeEof() async {
    await computeSuggestions('''
extension type ^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_emptyRepresentationField() async {
    await computeSuggestions('''
extension type E(^)

class C0 {}
''');
    assertResponse(r'''
suggestions
  C0
    kind: class
''');
  }

  Future<void> test_identifier_imported() async {
    includeKeywords = false;

    newFile('$testPackageLibPath/a.dart', r'''
extension type E0(int it) {}
''');

    await computeSuggestions('''
import 'a.dart';

void f() {
  ^
}
''');
    assertResponse(r'''
suggestions
  E0
    kind: extensionType
''');
  }

  Future<void> test_identifier_local() async {
    includeKeywords = false;

    await computeSuggestions('''
extension type E0(int it) {}

void f() {
  ^
}
''');
    assertResponse(r'''
suggestions
  E0
    kind: extensionType
''');
  }

  Future<void> test_identifier_notImported() async {
    includeKeywords = false;

    newFile('$testPackageLibPath/a.dart', r'''
extension type E0(int it) {}
''');

    await computeSuggestions('''
void f() {
  ^
}
''');
    assertResponse(r'''
suggestions
  E0
    kind: extensionType
  E0
    kind: constructorInvocation
''');
  }

  Future<void> test_name_withBody() async {
    allowedIdentifiers = {'Test', 'Test {}'};
    printerConfiguration.withSelection = true;
    await computeSuggestions('''
extension type ^ {}
''');
    assertResponse(r'''
suggestions
  Test
    kind: identifier
''');
  }

  Future<void> test_name_withoutBody() async {
    allowedIdentifiers = {'Test', 'Test {}'};
    printerConfiguration.withSelection = true;
    await computeSuggestions('''
extension type ^
''');
    assertResponse(r'''
suggestions
  Test {}
    kind: identifier
    selection: 6
''');
  }

  Future<void> test_representationField_annotation() async {
    await computeSuggestions('''
extension type E(@^)

const a0 = 0;
''');
    assertResponse(r'''
suggestions
  a0
    kind: topLevelVariable
''');
  }

  Future<void> test_representationField_identifier_empty() async {
    await computeSuggestions('''
extension type E(C0 ^)

class C0 {}
''');
    assertResponse(r'''
suggestions
  _c0
    kind: identifier
  c0
    kind: identifier
''');
  }

  Future<void>
      test_representationField_identifier_empty_withSuggestions() async {
    allowedIdentifiers = {'buffer', 'stringBuffer'};
    await computeSuggestions('''
extension type E(StringBuffer ^) {}
''');
    assertResponse(r'''
suggestions
  buffer
    kind: identifier
  stringBuffer
    kind: identifier
''');
  }

  Future<void> test_representationField_identifier_partial() async {
    allowedIdentifiers = {'buffer', 'stringBuffer'};
    await computeSuggestions('''
extension type E(StringBuffer s^) {}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  stringBuffer
    kind: identifier
''');
  }

  Future<void> test_representationField_type_partial() async {
    await computeSuggestions('''
extension type E(C^)

class C0 {}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  C0
    kind: class
''');
  }
}
