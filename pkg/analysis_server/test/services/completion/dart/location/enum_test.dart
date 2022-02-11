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
      (suggestion) => suggestion.isKeyword(Keyword.WITH),
    ]);
  }
}

mixin EnumDeclarationTestCases on AbstractCompletionDriverTest {
  static List<CompletionSuggestionChecker> get _bodyKeywords {
    const keywords = [
      Keyword.CONST,
      Keyword.DYNAMIC,
      Keyword.FINAL,
      Keyword.GET,
      Keyword.LATE,
      Keyword.OPERATOR,
      Keyword.SET,
      Keyword.STATIC,
      Keyword.VAR,
      Keyword.VOID
    ];
    return keywords.asKeywordChecks;
  }

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
      ..includesAll([
        (suggestion) => suggestion
          ..completion.isEqualTo('Object')
          ..isClass,
      ])
      ..excludesAll([
        (suggestion) => suggestion.isKeywordAny,
      ]);
  }

  Future<void> test_afterImplementsClause() async {
    var response = await getTestCodeSuggestions('''
enum E implements A ^ {
  v
}
''');

    check(response).suggestions.matchesInAnyOrder([
      (suggestion) => suggestion.isKeyword(Keyword.WITH),
    ]);
  }

  Future<void> test_afterName() async {
    var response = await getTestCodeSuggestions('''
enum E ^ {
  v
}
''');

    check(response).suggestions.matchesInAnyOrder([
      (suggestion) => suggestion.isKeyword(Keyword.IMPLEMENTS),
      (suggestion) => suggestion.isKeyword(Keyword.WITH),
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
      (suggestion) => suggestion.isKeyword(Keyword.IMPLEMENTS),
      (suggestion) => suggestion.isKeyword(Keyword.WITH),
    ]);
  }

  Future<void> test_afterName_beforeImplements() async {
    var response = await getTestCodeSuggestions('''
enum E ^ implements A {
  v
}
''');

    check(response).suggestions.matchesInAnyOrder([
      (suggestion) => suggestion.isKeyword(Keyword.WITH),
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

  Future<void> test_afterSemicolon() async {
    var response = await getTestCodeSuggestions('''
enum E {
  v;^
}
''');

    check(response).suggestions.includesAll([
      (suggestion) => suggestion
        ..completion.isEqualTo('Object')
        ..isClass,
      ..._bodyKeywords,
    ]);
  }

  Future<void> test_afterSemicolon_beforeVoid() async {
    var response = await getTestCodeSuggestions('''
enum E {
  v;
  ^void foo() {}
}
''');

    check(response).suggestions.includesAll([
      (suggestion) => suggestion
        ..completion.isEqualTo('Object')
        ..isClass,
      ..._bodyKeywords,
    ]);
  }

  Future<void> test_afterWith() async {
    var response = await getTestCodeSuggestions('''
enum E with ^ {
  v
}
''');

    check(response).suggestions
      ..includesAll([
        (suggestion) => suggestion
          ..completion.isEqualTo('Object')
          ..isClass,
      ])
      ..excludesAll([
        (suggestion) => suggestion.isKeywordAny,
      ]);
  }

  Future<void> test_afterWithClause() async {
    var response = await getTestCodeSuggestions('''
enum E with M ^ {
  v
}
''');

    check(response).suggestions.matchesInAnyOrder([
      (suggestion) => suggestion.isKeyword(Keyword.IMPLEMENTS),
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
}
