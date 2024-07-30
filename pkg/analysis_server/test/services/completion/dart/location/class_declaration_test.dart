// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDeclarationTest);
  });
}

@reflectiveTest
class ClassDeclarationTest extends AbstractCompletionDriverTest
    with ClassDeclarationTestCases {}

mixin ClassDeclarationTestCases on AbstractCompletionDriverTest {
  Future<void> test_extends() async {
    await computeSuggestions('''
class A extends foo ^
''');
    assertResponse(r'''
suggestions
  implements
    kind: keyword
  with
    kind: keyword
''');
  }

  Future<void> test_extends_name() async {
    await computeSuggestions('''
class A extends ^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_extends_withBody_partial() async {
    await computeSuggestions('''
class A extends foo i^ { }
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  implements
    kind: keyword
''');
  }

  Future<void> test_extends_withoutBody_partial() async {
    await computeSuggestions('''
class A extends foo i^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  implements
    kind: keyword
''');
  }

  Future<void> test_implements() async {
    await computeSuggestions('''
class A ^ implements foo
''');
    assertResponse(r'''
suggestions
  extends
    kind: keyword
  with
    kind: keyword
''');
  }

  Future<void> test_implements_name() async {
    await computeSuggestions('''
class A implements ^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_implements_withBody_partial() async {
    await computeSuggestions('''
class A e^ implements foo { }
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  extends
    kind: keyword
''');
  }

  Future<void> test_implements_withoutBody_partial() async {
    await computeSuggestions('''
class A e^ implements foo
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  extends
    kind: keyword
''');
  }

  Future<void> test_name_withBody() async {
    allowedIdentifiers = {'Test', 'Test {}'};
    await computeSuggestions('''
class ^ {}
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
class ^
''');
    assertResponse(r'''
suggestions
  Test {}
    kind: identifier
    selection: 6
''');
  }

  Future<void> test_noBody() async {
    await computeSuggestions('''
class A ^
''');
    assertResponse(r'''
suggestions
  extends
    kind: keyword
  implements
    kind: keyword
  with
    kind: keyword
''');
  }

  Future<void> test_noBody_atEnd_partial() async {
    await computeSuggestions('''
class A e^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  extends
    kind: keyword
''');
  }

  Future<void> test_noBody_beforeVariable_partial() async {
    await computeSuggestions('''
class A e^ String foo;
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  extends
    kind: keyword
''');
  }

  Future<void> test_partial() async {
    await computeSuggestions('''
class A e^ { }
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  extends
    kind: keyword
''');
  }

  Future<void> test_with() async {
    await computeSuggestions('''
class A extends foo with bar ^
''');
    assertResponse(r'''
suggestions
  implements
    kind: keyword
''');
  }

  Future<void> test_with_name() async {
    await computeSuggestions('''
class A extends foo with ^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_with_partial() async {
    await computeSuggestions('''
class A extends foo with bar i^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  implements
    kind: keyword
''');
  }

  Future<void> test_with_partial2() async {
    await computeSuggestions('''
class A extends foo with bar i^ { }
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  implements
    kind: keyword
''');
  }
}
