// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer_utilities/check/check.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../util/ast_check.dart';
import '../../util/token_check.dart';
import '../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AstBuilderTest);
  });
}

@reflectiveTest
class AstBuilderTest extends ParserDiagnosticsTest {
  void test_constructor_factory_misnamed() {
    var parseResult = parseStringWithErrors(r'''
class A {
  factory B() => throw 0;
}
''');
    parseResult.assertNoErrors();
    var unit = parseResult.unit;
    expect(unit.declarations, hasLength(1));
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration, isNotNull);
    expect(declaration.members, hasLength(1));
    var member = declaration.members[0] as ConstructorDeclaration;
    expect(member, isNotNull);
    expect(member.factoryKeyword, isNotNull);
    expect(member.name, isNull);
    expect(member.returnType.name, 'B');
  }

  void test_constructor_wrongName() {
    var parseResult = parseStringWithErrors(r'''
class A {
  B() : super();
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.INVALID_CONSTRUCTOR_NAME, 12, 1),
    ]);
    var unit = parseResult.unit;
    expect(unit.declarations, hasLength(1));
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration, isNotNull);
    expect(declaration.members, hasLength(1));
    var member = declaration.members[0] as ConstructorDeclaration;
    expect(member, isNotNull);
    expect(member.initializers, hasLength(1));
  }

  void test_enum_constant_name_dot() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v.
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.MISSING_IDENTIFIER, 14, 1),
    ]);

    var v = parseResult.findNode.enumConstantDeclaration('v.');
    check(v).name.name.isEqualTo('v');
    check(v).arguments.isNotNull
      ..typeArguments.isNull
      ..constructorSelector.isNotNull.name.isSynthetic
      ..argumentList.isSynthetic;
  }

  void test_enum_constant_name_dot_identifier_semicolon() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v.named;
}
''');
    parseResult.assertNoErrors();

    var v = parseResult.findNode.enumConstantDeclaration('v.');
    check(v).name.name.isEqualTo('v');
    check(v).arguments.isNotNull
      ..typeArguments.isNull
      ..constructorSelector.isNotNull.name.name.isEqualTo('named')
      ..argumentList.isSynthetic;
  }

  void test_enum_constant_name_dot_semicolon() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v.;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.MISSING_IDENTIFIER, 13, 1),
    ]);

    var v = parseResult.findNode.enumConstantDeclaration('v.');
    check(v).name.name.isEqualTo('v');
    check(v).arguments.isNotNull
      ..typeArguments.isNull
      ..constructorSelector.isNotNull.name.isSynthetic
      ..argumentList.isSynthetic;
  }

  void test_enum_constant_name_typeArguments_dot() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v<int>.
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.ENUM_CONSTANT_WITH_TYPE_ARGUMENTS_WITHOUT_ARGUMENTS,
          12, 5),
      error(ParserErrorCode.MISSING_IDENTIFIER, 19, 1),
    ]);

    var v = parseResult.findNode.enumConstantDeclaration('v<int>.');
    check(v).name.name.isEqualTo('v');
    check(v).arguments.isNotNull
      ..typeArguments.isNotNull
      ..constructorSelector.isNotNull.name.isSynthetic
      ..argumentList.isSynthetic;
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48380')
  void test_enum_constant_name_typeArguments_dot_semicolon() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v<int>.;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.ENUM_CONSTANT_WITH_TYPE_ARGUMENTS_WITHOUT_ARGUMENTS,
          12, 5),
      error(ParserErrorCode.MISSING_IDENTIFIER, 18, 1),
    ]);

    var E = parseResult.findNode.enumDeclaration('enum E');
    var v = parseResult.findNode.enumConstantDeclaration('v<int>');
    check(v).name.name.isEqualTo('v');

    var arguments = check(v).arguments.isNotNull;
    arguments.typeArguments.isNotNull;

    var constructorSelector = arguments.constructorSelector.isNotNull;
    var syntheticName = constructorSelector.value.name;
    constructorSelector.name.isSynthetic;

    arguments.argumentList
      ..isSynthetic
      ..leftParenthesis.isLinkedToPrevious(syntheticName.token)
      ..rightParenthesis.isLinkedToNext(E.semicolon!);
  }

  void test_enum_constant_withTypeArgumentsWithoutArguments() {
    var parseResult = parseStringWithErrors(r'''
enum E<T> {
  v<int>;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.ENUM_CONSTANT_WITH_TYPE_ARGUMENTS_WITHOUT_ARGUMENTS,
          15, 5),
    ]);

    var v = parseResult.findNode.enumConstantDeclaration('v<int>');
    check(v).name.name.isEqualTo('v');
    check(v).arguments.isNotNull
      ..typeArguments.isNotNull
      ..argumentList.isSynthetic;
  }

  void test_enum_semicolon_null() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v
}
''');
    parseResult.assertNoErrors();

    var v = parseResult.findNode.enumDeclaration('enum E');
    check(v).semicolon.isNull;
  }

  void test_enum_semicolon_optional() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v;
}
''');
    parseResult.assertNoErrors();

    var v = parseResult.findNode.enumDeclaration('enum E');
    check(v).semicolon.isNotNull.isSemicolon;
  }

  void test_getter_sameNameAsClass() {
    var parseResult = parseStringWithErrors(r'''
class A {
  get A => 0;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 16, 1),
    ]);
    var unit = parseResult.unit;
    expect(unit.declarations, hasLength(1));
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration, isNotNull);
    expect(declaration.members, hasLength(1));
    var member = declaration.members[0] as MethodDeclaration;
    expect(member, isNotNull);
    expect(member.isGetter, isTrue);
    expect(member.name.name, 'A');
  }

  void test_superFormalParameter() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(super.a);
}
''');
    parseResult.assertNoErrors();
    check(parseResult.findNode.superFormalParameter('super.a'))
      ..type.isNull
      ..superKeyword.isKeywordSuper
      ..identifier.which((it) => it
        ..name.isEqualTo('a')
        ..inDeclarationContext.isTrue)
      ..typeParameters.isNull
      ..parameters.isNull;
  }
}
