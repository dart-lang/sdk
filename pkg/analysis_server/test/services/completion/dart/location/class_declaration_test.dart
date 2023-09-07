// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDeclarationTest1);
    defineReflectiveTests(ClassDeclarationTest2);
  });
}

@reflectiveTest
class ClassDeclarationTest1 extends AbstractCompletionDriverTest
    with ClassDeclarationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ClassDeclarationTest2 extends AbstractCompletionDriverTest
    with ClassDeclarationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

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
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  implements
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  implements
    kind: keyword
  with
    kind: keyword
''');
    }
  }

  Future<void> test_extends_withoutBody_partial() async {
    await computeSuggestions('''
class A extends foo i^
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  implements
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  implements
    kind: keyword
  with
    kind: keyword
''');
    }
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
    // TODO(brianwilkerson) The keyword `with` should not be suggested when
    //  using protocol 2 (so this these should require a conditional check).
    //  The reason it is being suggested is as follows: The `e` is ignored by
    //  the parser so it doesn't show up in the AST. As a result, the "entity"
    //  is the implements clause, and the code doesn't find the unattached token
    //  for `e`. As a result, there is no prefix, so the fuzzy matcher returns 1
    //  (a perfect match). We need to improve the detection of a prefix in order
    //  to fix this bug.
    assertResponse(r'''
replacement
  left: 1
suggestions
  extends
    kind: keyword
  with
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
  with
    kind: keyword
''');
  }

  Future<void> test_name() async {
    await computeSuggestions('''
class ^
''');
    assertResponse(r'''
suggestions
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
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  extends
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  extends
    kind: keyword
  implements
    kind: keyword
  with
    kind: keyword
''');
    }
  }

  Future<void> test_noBody_beforeVariable_partial() async {
    await computeSuggestions('''
class A e^ String foo;
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  extends
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  extends
    kind: keyword
  implements
    kind: keyword
  with
    kind: keyword
''');
    }
  }

  Future<void> test_partial() async {
    await computeSuggestions('''
class A e^ { }
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  extends
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  extends
    kind: keyword
  implements
    kind: keyword
  with
    kind: keyword
''');
    }
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
