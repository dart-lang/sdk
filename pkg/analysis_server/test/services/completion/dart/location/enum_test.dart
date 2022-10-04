// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

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
    var response = await getTestCodeSuggestions('''
enum E w^ {
  v
}
''');

    assertResponseText(response, r'''
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

    printerConfiguration = printer.Configuration(
      filter: (suggestion) {
        final completion = suggestion.completion;
        if (suggestion.kind == CompletionSuggestionKind.IDENTIFIER) {
          return const {'Object'}.contains(completion);
        }
        return true;
      },
    );
  }

  Future<void> test_afterConstants_noSemicolon() async {
    var response = await getTestCodeSuggestions('''
enum E {
  v ^
}
''');

    assertResponseText(response, r'''
suggestions
''');
  }

  Future<void> test_afterImplements() async {
    var response = await getTestCodeSuggestions('''
enum E implements ^ {
  v
}
''');

    assertResponseText(response, r'''
suggestions
  Object
    kind: class
''');
  }

  Future<void> test_afterImplementsClause() async {
    var response = await getTestCodeSuggestions('''
enum E implements A ^ {
  v
}
''');

    assertResponseText(response, r'''
suggestions
  with
    kind: keyword
''');
  }

  Future<void> test_afterName() async {
    var response = await getTestCodeSuggestions('''
enum E ^ {
  v
}
''');

    assertResponseText(response, r'''
suggestions
  implements
    kind: keyword
  with
    kind: keyword
''');
  }

  Future<void> test_afterName_atEnd() async {
    var response = await getTestCodeSuggestions('''
enum E^ {
  v
}
''');

    assertResponseText(response, r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_afterName_atLeftCurlyBracket() async {
    var response = await getTestCodeSuggestions('''
enum E ^{
  v
}
''');

    assertResponseText(response, r'''
suggestions
  implements
    kind: keyword
  with
    kind: keyword
''');
  }

  Future<void> test_afterName_beforeImplements() async {
    var response = await getTestCodeSuggestions('''
enum E ^ implements A {
  v
}
''');

    assertResponseText(response, r'''
suggestions
  with
    kind: keyword
''');
  }

  Future<void> test_afterName_hasWith_hasImplements() async {
    var response = await getTestCodeSuggestions('''
enum E ^ with M implements A {
  v
}
''');

    assertResponseText(response, r'''
suggestions
''');
  }

  Future<void> test_afterName_language216() async {
    var response = await getTestCodeSuggestions('''
// @dart = 2.16
enum E ^ {
  v
}
''');

    assertResponseText(response, r'''
suggestions
''');
  }

  Future<void> test_afterWith() async {
    var response = await getTestCodeSuggestions('''
enum E with ^ {
  v
}
''');

    assertResponseText(response, r'''
suggestions
  Object
    kind: class
''');
  }

  Future<void> test_afterWithClause() async {
    var response = await getTestCodeSuggestions('''
enum E with M ^ {
  v
}
''');

    assertResponseText(response, r'''
suggestions
  implements
    kind: keyword
''');
  }

  Future<void> test_beforeConstants_hasSemicolon() async {
    var response = await getTestCodeSuggestions('''
enum E {
 ^ v;
}
''');

    assertResponseText(response, r'''
suggestions
''');
  }

  Future<void> test_beforeConstants_noSemicolon() async {
    var response = await getTestCodeSuggestions('''
enum E {
 ^ v
}
''');

    assertResponseText(response, r'''
suggestions
''');
  }

  Future<void> test_constantName_dot_name_x_argumentList_named() async {
    var response = await getTestCodeSuggestions('''
enum E {
  v.foo0^();
  const E.foo01();
  const E.foo02();
  const E.bar01();
}
''');

    if (isProtocolVersion2) {
      assertResponseText(response, r'''
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
    var response = await getTestCodeSuggestions('''
enum E {
  v.foo0^;
  const E.foo01();
  const E.foo02();
  const E.bar01();
}
''');

    if (isProtocolVersion2) {
      assertResponseText(response, r'''
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
    var response = await getTestCodeSuggestions('''
enum E {
  v.^();
  const E.foo01();
  const E.foo02();
}
''');

    assertResponseText(response, r'''
suggestions
  foo01
    kind: constructorInvocation
  foo02
    kind: constructorInvocation
''');
  }

  Future<void> test_constantName_dot_x_semicolon_named() async {
    var response = await getTestCodeSuggestions('''
enum E {
  v.^;
  const E.foo01();
  const E.foo02();
}
''');

    assertResponseText(response, r'''
suggestions
  foo01
    kind: constructorInvocation
  foo02
    kind: constructorInvocation
''');
  }

  Future<void> test_constantName_dot_x_semicolon_unnamed_declared() async {
    var response = await getTestCodeSuggestions('''
enum E {
  v.^;
  const E();
}
''');

    assertResponseText(response, r'''
suggestions
  new
    kind: constructorInvocation
''');
  }

  Future<void> test_constantName_dot_x_unnamed_implicit() async {
    var response = await getTestCodeSuggestions('''
enum E {
  v.^
}
''');

    assertResponseText(response, r'''
suggestions
  new
    kind: constructorInvocation
''');
  }

  Future<void> test_constantName_dot_x_unnamed_language216() async {
    var response = await getTestCodeSuggestions('''
// @dart = 2.16
enum E {
  v.^
}
''');

    assertResponseText(response, r'''
suggestions
''');
  }

  Future<void> test_constantName_typeArguments_dot_x_semicolon_named() async {
    var response = await getTestCodeSuggestions('''
enum E<T> {
  v<int>.^;
  const E.foo01();
  const E.foo02();
}
''');

    assertResponseText(response, r'''
suggestions
  foo01
    kind: constructorInvocation
  foo02
    kind: constructorInvocation
''');
  }
}
