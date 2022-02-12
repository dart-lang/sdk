// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_utilities/check/check.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_check.dart';

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

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48371')
  Future<void> test_afterName_w() async {
    var response = await getTestCodeSuggestions('''
enum E w^ {
  v
}
''');

    check(response).suggestions.matchesInAnyOrder([
      ...{
        Keyword.WITH,
      }.asKeywordChecks,
    ]);
  }
}

mixin EnumDeclarationTestCases on AbstractCompletionDriverTest {
  @override
  bool get supportsAvailableSuggestions => true;

  Future<void> test_afterConstants_noSemicolon() async {
    var response = await getTestCodeSuggestions('''
enum E {
  v ^
}
''');

    check(response).suggestions.isEmpty;
  }

  Future<void> test_afterImplements() async {
    var response = await getTestCodeSuggestions('''
enum E implements ^ {
  v
}
''');

    check(response).suggestions
      ..withKindKeyword.isEmpty
      ..includesAll([
        (suggestion) => suggestion
          ..completion.isEqualTo('Object')
          ..isClass,
      ]);
  }

  Future<void> test_afterImplementsClause() async {
    var response = await getTestCodeSuggestions('''
enum E implements A ^ {
  v
}
''');

    check(response).suggestions.matchesInAnyOrder([
      ...{
        Keyword.WITH,
      }.asKeywordChecks,
    ]);
  }

  Future<void> test_afterName() async {
    var response = await getTestCodeSuggestions('''
enum E ^ {
  v
}
''');

    check(response).suggestions.matchesInAnyOrder([
      ...{
        Keyword.IMPLEMENTS,
        Keyword.WITH,
      }.asKeywordChecks,
    ]);
  }

  Future<void> test_afterName_atEnd() async {
    var response = await getTestCodeSuggestions('''
enum E^ {
  v
}
''');

    check(response).suggestions.isEmpty;
  }

  Future<void> test_afterName_atLeftCurlyBracket() async {
    var response = await getTestCodeSuggestions('''
enum E ^{
  v
}
''');

    check(response).suggestions.matchesInAnyOrder([
      ...{
        Keyword.IMPLEMENTS,
        Keyword.WITH,
      }.asKeywordChecks,
    ]);
  }

  Future<void> test_afterName_beforeImplements() async {
    var response = await getTestCodeSuggestions('''
enum E ^ implements A {
  v
}
''');

    check(response).suggestions.matchesInAnyOrder([
      ...{
        Keyword.WITH,
      }.asKeywordChecks,
    ]);
  }

  Future<void> test_afterName_hasWith_hasImplements() async {
    var response = await getTestCodeSuggestions('''
enum E ^ with M implements A {
  v
}
''');

    check(response).suggestions.isEmpty;
  }

  Future<void> test_afterName_language216() async {
    var response = await getTestCodeSuggestions('''
// @dart = 2.16
enum E ^ {
  v
}
''');

    check(response).suggestions.isEmpty;
  }

  Future<void> test_afterWith() async {
    var response = await getTestCodeSuggestions('''
enum E with ^ {
  v
}
''');

    check(response).suggestions
      ..withKindKeyword.isEmpty
      ..includesAll([
        (suggestion) => suggestion
          ..completion.isEqualTo('Object')
          ..isClass,
      ]);
  }

  Future<void> test_afterWithClause() async {
    var response = await getTestCodeSuggestions('''
enum E with M ^ {
  v
}
''');

    check(response).suggestions.matchesInAnyOrder([
      ...{
        Keyword.IMPLEMENTS,
      }.asKeywordChecks,
    ]);
  }

  Future<void> test_beforeConstants_hasSemicolon() async {
    var response = await getTestCodeSuggestions('''
enum E {
 ^ v;
}
''');

    check(response).suggestions.isEmpty;
  }

  Future<void> test_beforeConstants_noSemicolon() async {
    var response = await getTestCodeSuggestions('''
enum E {
 ^ v
}
''');

    check(response).suggestions.isEmpty;
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
      check(response)
        ..hasReplacement(left: 4)
        ..suggestions.matchesInAnyOrder([
          (suggestion) => suggestion
            ..completion.isEqualTo('foo01')
            ..isConstructorInvocation,
          (suggestion) => suggestion
            ..completion.isEqualTo('foo02')
            ..isConstructorInvocation,
        ]);
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
      check(response)
        ..hasReplacement(left: 4)
        ..suggestions.matchesInAnyOrder([
          (suggestion) => suggestion
            ..completion.isEqualTo('foo01')
            ..isConstructorInvocation,
          (suggestion) => suggestion
            ..completion.isEqualTo('foo02')
            ..isConstructorInvocation,
        ]);
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

    check(response).suggestions.matchesInAnyOrder([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isConstructorInvocation,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isConstructorInvocation,
    ]);
  }

  Future<void> test_constantName_dot_x_semicolon_named() async {
    var response = await getTestCodeSuggestions('''
enum E {
  v.^;
  const E.foo01();
  const E.foo02();
}
''');

    check(response).suggestions.matchesInAnyOrder([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isConstructorInvocation,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isConstructorInvocation,
    ]);
  }

  Future<void> test_constantName_dot_x_semicolon_unnamed_declared() async {
    var response = await getTestCodeSuggestions('''
enum E {
  v.^;
  const E();
}
''');

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('new')
        ..isConstructorInvocation,
    ]);
  }

  Future<void> test_constantName_dot_x_unnamed_implicit() async {
    var response = await getTestCodeSuggestions('''
enum E {
  v.^
}
''');

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('new')
        ..isConstructorInvocation,
    ]);
  }

  Future<void> test_constantName_dot_x_unnamed_language216() async {
    var response = await getTestCodeSuggestions('''
// @dart = 2.16
enum E {
  v.^
}
''');

    check(response).suggestions.isEmpty;
  }
}
