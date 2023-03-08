// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumDeclarationTest1);
    defineReflectiveTests(EnumDeclarationTest2);
  });
}

@reflectiveTest
class EnumDeclarationTest1 extends AbstractCompletionDriverTest
    with EnumDeclarationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class EnumDeclarationTest2 extends AbstractCompletionDriverTest
    with EnumDeclarationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;

  Future<void> test_afterName_w() async {
    await computeSuggestions('''
enum E w^ {
  v
}
''');

    assertResponse('''
replacement
  left: 1
suggestions
  with
    kind: keyword
''');
  }
}

mixin EnumDeclarationTestCases on AbstractCompletionDriverTest {
  @override
  Future<void> setUp() async {
    await super.setUp();
    allowedIdentifiers = const {'Object', 'foo01', 'foo02', 'new', 'A01'};
  }

  Future<void> test_afterConstants_noSemicolon() async {
    await computeSuggestions('''
enum E {
  v ^
}
''');

    assertResponse('''
suggestions
''');
  }

  Future<void> test_afterImplements() async {
    await computeSuggestions('''
enum E implements ^ {
  v
}
''');

    assertResponse('''
suggestions
  Object
    kind: class
''');
  }

  Future<void> test_afterImplementsClause() async {
    await computeSuggestions('''
enum E implements A ^ {
  v
}
''');

    assertResponse('''
suggestions
  with
    kind: keyword
''');
  }

  Future<void> test_afterName() async {
    await computeSuggestions('''
enum E ^ {
  v
}
''');

    assertResponse('''
suggestions
  implements
    kind: keyword
  with
    kind: keyword
''');
  }

  Future<void> test_afterName_atEnd() async {
    await computeSuggestions('''
enum E^ {
  v
}
''');

    assertResponse('''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_afterName_atLeftCurlyBracket() async {
    await computeSuggestions('''
enum E ^{
  v
}
''');

    assertResponse('''
suggestions
  implements
    kind: keyword
  with
    kind: keyword
''');
  }

  Future<void> test_afterName_beforeImplements() async {
    await computeSuggestions('''
enum E ^ implements A {
  v
}
''');

    assertResponse('''
suggestions
  with
    kind: keyword
''');
  }

  Future<void> test_afterName_hasWith_hasImplements() async {
    await computeSuggestions('''
enum E ^ with M implements A {
  v
}
''');

    assertResponse('''
suggestions
''');
  }

  Future<void> test_afterName_language216() async {
    await computeSuggestions('''
// @dart = 2.16
enum E ^ {
  v
}
''');

    assertResponse('''
suggestions
''');
  }

  Future<void> test_afterWith() async {
    await computeSuggestions('''
mixin class A01 {}

enum E with ^ {
  v
}
''');

    if (isProtocolVersion2) {
      assertResponse('''
suggestions
  A01
    kind: class
''');
    } else {
      assertResponse('''
suggestions
  A01
    kind: class
  Object
    kind: class
''');
    }
  }

  Future<void> test_afterWithClause() async {
    await computeSuggestions('''
enum E with M ^ {
  v
}
''');

    assertResponse('''
suggestions
  implements
    kind: keyword
''');
  }

  Future<void> test_beforeConstants_hasSemicolon() async {
    await computeSuggestions('''
enum E {
 ^ v;
}
''');

    assertResponse('''
suggestions
''');
  }

  Future<void> test_beforeConstants_noSemicolon() async {
    await computeSuggestions('''
enum E {
 ^ v
}
''');

    assertResponse('''
suggestions
''');
  }

  Future<void> test_constantName_dot_name_x_argumentList_named() async {
    await computeSuggestions('''
enum E {
  v.foo0^();
  const E.foo01();
  const E.foo02();
  const E.bar01();
}
''');

    if (isProtocolVersion2) {
      assertResponse('''
replacement
  left: 4
suggestions
  foo01
    kind: constructorInvocation
  foo02
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_constantName_dot_name_x_semicolon_named() async {
    await computeSuggestions('''
enum E {
  v.foo0^;
  const E.foo01();
  const E.foo02();
  const E.bar01();
}
''');

    if (isProtocolVersion2) {
      assertResponse('''
replacement
  left: 4
suggestions
  foo01
    kind: constructorInvocation
  foo02
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_constantName_dot_x_argumentList_named() async {
    await computeSuggestions('''
enum E {
  v.^();
  const E.foo01();
  const E.foo02();
}
''');

    assertResponse('''
suggestions
  foo01
    kind: constructorInvocation
  foo02
    kind: constructorInvocation
''');
  }

  Future<void> test_constantName_dot_x_semicolon_named() async {
    await computeSuggestions('''
enum E {
  v.^;
  const E.foo01();
  const E.foo02();
}
''');

    assertResponse('''
suggestions
  foo01
    kind: constructorInvocation
  foo02
    kind: constructorInvocation
''');
  }

  Future<void> test_constantName_dot_x_semicolon_unnamed_declared() async {
    await computeSuggestions('''
enum E {
  v.^;
  const E();
}
''');

    assertResponse('''
suggestions
  new
    kind: constructorInvocation
''');
  }

  Future<void> test_constantName_dot_x_unnamed_implicit() async {
    await computeSuggestions('''
enum E {
  v.^
}
''');

    assertResponse('''
suggestions
  new
    kind: constructorInvocation
''');
  }

  Future<void> test_constantName_dot_x_unnamed_language216() async {
    await computeSuggestions('''
// @dart = 2.16
enum E {
  v.^
}
''');

    assertResponse('''
suggestions
''');
  }

  Future<void> test_constantName_typeArguments_dot_x_semicolon_named() async {
    await computeSuggestions('''
enum E<T> {
  v<int>.^;
  const E.foo01();
  const E.foo02();
}
''');

    assertResponse('''
suggestions
  foo01
    kind: constructorInvocation
  foo02
    kind: constructorInvocation
''');
  }
}
