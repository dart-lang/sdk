// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionMethodsParserTest);
  });
}

@reflectiveTest
class ExtensionMethodsParserTest extends FastaParserTestCase {
  void test_complex_extends() {
    var unit = parseCompilationUnit(
      'extension E extends A with B, C implements D { }',
      errors: [
        expectedError(ParserErrorCode.expectedInstead, 12, 7),
        expectedError(ParserErrorCode.unexpectedToken, 22, 4),
        expectedError(ParserErrorCode.unexpectedToken, 28, 1),
        expectedError(ParserErrorCode.unexpectedToken, 32, 10),
      ],
    );
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name!.lexeme, 'E');
    expect(extension.onClause!.onKeyword.lexeme, 'extends');
    expect((extension.onClause!.extendedType as NamedType).name.lexeme, 'A');
    expect(extension.members, hasLength(0));
  }

  void test_complex_implements() {
    var unit = parseCompilationUnit(
      'extension E implements C, D { }',
      errors: [
        expectedError(ParserErrorCode.expectedInstead, 12, 10),
        expectedError(ParserErrorCode.unexpectedToken, 24, 1),
      ],
    );
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name!.lexeme, 'E');
    expect(extension.onClause!.onKeyword.lexeme, 'implements');
    expect((extension.onClause!.extendedType as NamedType).name.lexeme, 'C');
    expect(extension.members, hasLength(0));
  }

  void test_complex_type() {
    var unit = parseCompilationUnit('extension E on C<T> { }');
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name!.lexeme, 'E');
    expect(extension.onClause!.onKeyword.lexeme, 'on');
    var namedType = extension.onClause!.extendedType as NamedType;
    expect(namedType.name.lexeme, 'C');
    expect(namedType.typeArguments!.arguments, hasLength(1));
    expect(extension.members, hasLength(0));
  }

  void test_complex_type2() {
    var unit = parseCompilationUnit('extension E<T> on C<T> { }');
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name!.lexeme, 'E');
    expect(extension.onClause!.onKeyword.lexeme, 'on');
    var namedType = extension.onClause!.extendedType as NamedType;
    expect(namedType.name.lexeme, 'C');
    expect(namedType.typeArguments!.arguments, hasLength(1));
    expect(extension.members, hasLength(0));
  }

  void test_complex_type2_no_name() {
    var unit = parseCompilationUnit('extension<T> on C<T> { }');
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name, isNull);
    expect(extension.onClause!.onKeyword.lexeme, 'on');
    var namedType = extension.onClause!.extendedType as NamedType;
    expect(namedType.name.lexeme, 'C');
    expect(namedType.typeArguments!.arguments, hasLength(1));
    expect(extension.members, hasLength(0));
  }

  void test_constructor_named() {
    var unit = parseCompilationUnit(
      '''
extension E on C {
  E.named();
}
class C {}
''',
      errors: [
        expectedError(ParserErrorCode.extensionDeclaresConstructor, 21, 1),
      ],
    );
    expect(unit.declarations, hasLength(2));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.members, hasLength(0));
  }

  void test_constructor_unnamed() {
    var unit = parseCompilationUnit(
      '''
extension E on C {
  E();
}
class C {}
''',
      errors: [
        expectedError(ParserErrorCode.extensionDeclaresConstructor, 21, 1),
      ],
    );
    expect(unit.declarations, hasLength(2));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.members, hasLength(0));
  }

  void test_missing_on() {
    var unit = parseCompilationUnit(
      'extension E',
      errors: [
        expectedError(ParserErrorCode.expectedToken, 10, 1),
        expectedError(ParserErrorCode.expectedTypeName, 11, 0),
        expectedError(ParserErrorCode.expectedExtensionBody, 11, 0),
      ],
    );
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name!.lexeme, 'E');
    expect(extension.onClause!.onKeyword.lexeme, 'on');
    expect((extension.onClause!.extendedType as NamedType).name.lexeme, '');
    expect(extension.members, hasLength(0));
  }

  void test_missing_on_withBlock() {
    var unit = parseCompilationUnit(
      'extension E {}',
      errors: [
        expectedError(ParserErrorCode.expectedToken, 10, 1),
        expectedError(ParserErrorCode.expectedTypeName, 12, 1),
      ],
    );
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name!.lexeme, 'E');
    expect(extension.onClause!.onKeyword.lexeme, 'on');
    expect((extension.onClause!.extendedType as NamedType).name.lexeme, '');
    expect(extension.members, hasLength(0));
  }

  void test_missing_on_withClassAndBlock() {
    var unit = parseCompilationUnit(
      'extension E C {}',
      errors: [expectedError(ParserErrorCode.expectedToken, 10, 1)],
    );
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name!.lexeme, 'E');
    expect(extension.onClause!.onKeyword.lexeme, 'on');
    expect((extension.onClause!.extendedType as NamedType).name.lexeme, 'C');
    expect(extension.members, hasLength(0));
  }

  void test_parse_toplevel_member_called_late_calling_self() {
    var unit = parseCompilationUnit('void late() { late(); }');
    var method = unit.declarations[0] as FunctionDeclaration;

    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name.lexeme, 'late');
    expect(method.functionExpression, isNotNull);

    var body = method.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var invocation = statement.expression as MethodInvocation;
    expect(invocation.operator, isNull);
    expect(invocation.toSource(), 'late()');
  }

  void test_simple() {
    var unit = parseCompilationUnit('extension E on C { }');
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name!.lexeme, 'E');
    expect(extension.onClause!.onKeyword.lexeme, 'on');
    expect((extension.onClause!.extendedType as NamedType).name.lexeme, 'C');
    var namedType = extension.onClause!.extendedType as NamedType;
    expect(namedType.name.lexeme, 'C');
    expect(namedType.typeArguments, isNull);
    expect(extension.members, hasLength(0));
  }

  void test_simple_extends() {
    var unit = parseCompilationUnit(
      'extension E extends C { }',
      errors: [expectedError(ParserErrorCode.expectedInstead, 12, 7)],
    );
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name!.lexeme, 'E');
    expect(extension.onClause!.onKeyword.lexeme, 'extends');
    expect((extension.onClause!.extendedType as NamedType).name.lexeme, 'C');
    expect(extension.members, hasLength(0));
  }

  void test_simple_implements() {
    var unit = parseCompilationUnit(
      'extension E implements C { }',
      errors: [expectedError(ParserErrorCode.expectedInstead, 12, 10)],
    );
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name!.lexeme, 'E');
    expect(extension.onClause!.onKeyword.lexeme, 'implements');
    expect((extension.onClause!.extendedType as NamedType).name.lexeme, 'C');
    expect(extension.members, hasLength(0));
  }

  void test_simple_no_name() {
    var unit = parseCompilationUnit('extension on C { }');
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name, isNull);
    expect(extension.onClause!.onKeyword.lexeme, 'on');
    expect((extension.onClause!.extendedType as NamedType).name.lexeme, 'C');
    var namedType = extension.onClause!.extendedType as NamedType;
    expect(namedType.name.lexeme, 'C');
    expect(namedType.typeArguments, isNull);
    expect(extension.members, hasLength(0));
  }

  void test_simple_with() {
    var unit = parseCompilationUnit(
      'extension E with C { }',
      errors: [expectedError(ParserErrorCode.expectedInstead, 12, 4)],
    );
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name!.lexeme, 'E');
    expect(extension.onClause!.onKeyword.lexeme, 'with');
    expect((extension.onClause!.extendedType as NamedType).name.lexeme, 'C');
    expect(extension.members, hasLength(0));
  }

  void test_void_type() {
    var unit = parseCompilationUnit('extension E on void { }');
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name!.lexeme, 'E');
    expect(extension.onClause!.onKeyword.lexeme, 'on');
    expect((extension.onClause!.extendedType as NamedType).name.lexeme, 'void');
    expect(extension.members, hasLength(0));
  }
}
