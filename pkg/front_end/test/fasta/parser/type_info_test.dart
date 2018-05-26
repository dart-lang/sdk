// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/messages.dart';
import 'package:front_end/src/fasta/parser.dart';
import 'package:front_end/src/fasta/parser/type_info.dart';
import 'package:front_end/src/fasta/parser/type_info_impl.dart';
import 'package:front_end/src/fasta/scanner.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeInfoTest);
    defineReflectiveTests(TypeParamOrArgInfoTest);
  });
}

@reflectiveTest
class TypeInfoTest {
  void test_noType() {
    final Token start = scanString('before ;').tokens;

    expect(noType.couldBeExpression, isFalse);
    expect(noType.skipType(start), start);
  }

  void test_noType_ensureTypeNotVoid() {
    final Token start = scanString('before ;').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(noType.ensureTypeNotVoid(start, new Parser(listener)),
        new isInstanceOf<SyntheticStringToken>());
    expect(listener.calls, [
      'handleIdentifier  typeReference',
      'handleNoTypeArguments ;',
      'handleType  ;',
    ]);
    expect(listener.errors, [new ExpectedError(codeExpectedType, 7, 1)]);
  }

  void test_noType_ensureTypeOrVoid() {
    final Token start = scanString('before ;').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(noType.ensureTypeOrVoid(start, new Parser(listener)),
        new isInstanceOf<SyntheticStringToken>());
    expect(listener.calls, [
      'handleIdentifier  typeReference',
      'handleNoTypeArguments ;',
      'handleType  ;',
    ]);
    expect(listener.errors, [new ExpectedError(codeExpectedType, 7, 1)]);
  }

  void test_noType_parseType() {
    final Token start = scanString('before ;').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(noType.parseType(start, new Parser(listener)), start);
    expect(listener.calls, ['handleNoType before']);
    expect(listener.errors, isNull);
  }

  void test_noType_parseTypeNotVoid() {
    final Token start = scanString('before ;').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(noType.parseTypeNotVoid(start, new Parser(listener)), start);
    expect(listener.calls, ['handleNoType before']);
    expect(listener.errors, isNull);
  }

  void test_voidType() {
    final Token start = scanString('before void ;').tokens;

    expect(voidType.skipType(start), start.next);
    expect(voidType.couldBeExpression, isFalse);
  }

  void test_voidType_ensureTypeNotVoid() {
    final Token start = scanString('before void ;').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(voidType.ensureTypeNotVoid(start, new Parser(listener)), start.next);
    expect(listener.calls, [
      'handleIdentifier void typeReference',
      'handleNoTypeArguments ;',
      'handleType void ;',
    ]);
    expect(listener.errors, [new ExpectedError(codeInvalidVoid, 7, 4)]);
  }

  void test_voidType_ensureTypeOrVoid() {
    final Token start = scanString('before void ;').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(voidType.parseType(start, new Parser(listener)), start.next);
    expect(listener.calls, ['handleVoidKeyword void']);
    expect(listener.errors, isNull);
  }

  void test_voidType_parseType() {
    final Token start = scanString('before void ;').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(voidType.parseType(start, new Parser(listener)), start.next);
    expect(listener.calls, ['handleVoidKeyword void']);
    expect(listener.errors, isNull);
  }

  void test_voidType_parseTypeNotVoid() {
    final Token start = scanString('before void ;').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(voidType.parseTypeNotVoid(start, new Parser(listener)), start.next);
    expect(listener.calls, [
      'handleIdentifier void typeReference',
      'handleNoTypeArguments ;',
      'handleType void ;',
    ]);
    expect(listener.errors, [new ExpectedError(codeInvalidVoid, 7, 4)]);
  }

  void test_prefixedTypeInfo() {
    final Token start = scanString('before C.a ;').tokens;
    final Token expectedEnd = start.next.next.next;

    expect(prefixedType.skipType(start), expectedEnd);
    expect(prefixedType.couldBeExpression, isTrue);

    TypeInfoListener listener;
    assertResult(Token actualEnd) {
      expect(actualEnd, expectedEnd);
      expect(listener.calls, [
        'handleIdentifier C prefixedTypeReference',
        'handleIdentifier a typeReferenceContinuation',
        'handleQualified .',
        'handleNoTypeArguments ;',
        'handleType C ;',
      ]);
      expect(listener.errors, isNull);
    }

    listener = new TypeInfoListener();
    assertResult(prefixedType.ensureTypeNotVoid(start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(prefixedType.ensureTypeOrVoid(start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(prefixedType.parseTypeNotVoid(start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(prefixedType.parseType(start, new Parser(listener)));
  }

  void test_simpleTypeInfo() {
    final Token start = scanString('before C ;').tokens;
    final Token expectedEnd = start.next;

    expect(simpleType.skipType(start), expectedEnd);
    expect(simpleType.couldBeExpression, isTrue);

    TypeInfoListener listener;
    assertResult(Token actualEnd) {
      expect(actualEnd, expectedEnd);
      expect(listener.calls, [
        'handleIdentifier C typeReference',
        'handleNoTypeArguments ;',
        'handleType C ;',
      ]);
      expect(listener.errors, isNull);
    }

    listener = new TypeInfoListener();
    assertResult(simpleType.ensureTypeNotVoid(start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(simpleType.ensureTypeOrVoid(start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(simpleType.parseTypeNotVoid(start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(simpleType.parseType(start, new Parser(listener)));
  }

  void test_simpleTypeArgumentsInfo() {
    final Token start = scanString('before C<T> ;').tokens;
    final Token expectedEnd = start.next.next.next.next;
    expect(expectedEnd.lexeme, '>');

    expect(simpleTypeWith1Argument.skipType(start), expectedEnd);
    expect(simpleTypeWith1Argument.couldBeExpression, isFalse);

    TypeInfoListener listener;
    assertResult(Token actualEnd) {
      expect(actualEnd, expectedEnd);
      expect(listener.calls, [
        'handleIdentifier C typeReference',
        'beginTypeArguments <',
        'handleIdentifier T typeReference',
        'handleNoTypeArguments >',
        'handleType T >',
        'endTypeArguments 1 < >',
        'handleType C ;',
      ]);
      expect(listener.errors, isNull);
    }

    listener = new TypeInfoListener();
    assertResult(
        simpleTypeWith1Argument.ensureTypeNotVoid(start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(
        simpleTypeWith1Argument.ensureTypeOrVoid(start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(
        simpleTypeWith1Argument.parseTypeNotVoid(start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(
        simpleTypeWith1Argument.parseType(start, new Parser(listener)));
  }

  void test_computeType_basic() {
    expectInfo(noType, '');
    expectInfo(noType, ';');
    expectInfo(noType, '( foo');
    expectInfo(noType, '< foo');
    expectInfo(noType, '= foo');
    expectInfo(noType, '* foo');
    expectInfo(noType, 'do foo');
    expectInfo(noType, 'get foo');
    expectInfo(noType, 'set foo');
    expectInfo(noType, 'operator *');

    expectInfo(noType, '.', required: false);
    expectComplexInfo('.', required: true, expectedErrors: [
      error(codeExpectedType, 0, 1),
      error(codeExpectedType, 1, 0)
    ]);

    expectInfo(noType, '.Foo', required: false);
    expectComplexInfo('.Foo',
        required: true, expectedErrors: [error(codeExpectedType, 0, 1)]);
  }

  void test_computeType_builtin() {
    // Expect complex rather than simpleTypeInfo so that parseType reports
    // an error for the builtin used as a type.
    expectComplexInfo('abstract',
        required: true,
        expectedErrors: [error(codeBuiltInIdentifierAsType, 0, 8)]);
    expectComplexInfo('export',
        required: true,
        expectedErrors: [error(codeBuiltInIdentifierAsType, 0, 6)]);
    expectComplexInfo('abstract Function()',
        required: false,
        expectedAfter: 'Function',
        expectedErrors: [error(codeBuiltInIdentifierAsType, 0, 8)]);
    expectComplexInfo('export Function()',
        required: false,
        expectedAfter: 'Function',
        expectedErrors: [error(codeBuiltInIdentifierAsType, 0, 6)]);
  }

  void test_computeType_gft() {
    expectComplexInfo('Function() m', expectedAfter: 'm', expectedCalls: [
      'handleNoTypeVariables (',
      'beginFunctionType Function',
      'handleNoType ',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function m',
    ]);
    expectComplexInfo('Function<T>() m', expectedAfter: 'm', expectedCalls: [
      'beginTypeVariables <',
      'beginTypeVariable T',
      'beginMetadataStar T',
      'endMetadataStar 0',
      'handleIdentifier T typeVariableDeclaration',
      'handleNoType T',
      'endTypeVariable > null',
      'endTypeVariables 1 < >',
      'beginFunctionType Function',
      'handleNoType ',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function m',
    ]);
    expectComplexInfo('Function(int) m', expectedAfter: 'm', expectedCalls: [
      'handleNoTypeVariables (',
      'beginFunctionType Function',
      'handleNoType ',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'beginMetadataStar int',
      'endMetadataStar 0',
      'beginFormalParameter int MemberKind.GeneralizedFunctionType',
      'handleIdentifier int typeReference',
      'handleNoTypeArguments )',
      'handleType int )',
      'handleNoName )',
      'handleFormalParameterWithoutValue )',
      'beginTypeVariables null null ) FormalParameterKind.mandatory '
          'MemberKind.GeneralizedFunctionType',
      'endFormalParameters 1 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function m',
    ]);
    expectComplexInfo('Function<T>(int) m', expectedAfter: 'm', expectedCalls: [
      'beginTypeVariables <',
      'beginTypeVariable T',
      'beginMetadataStar T',
      'endMetadataStar 0',
      'handleIdentifier T typeVariableDeclaration',
      'handleNoType T',
      'endTypeVariable > null',
      'endTypeVariables 1 < >',
      'beginFunctionType Function',
      'handleNoType ',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'beginMetadataStar int',
      'endMetadataStar 0',
      'beginFormalParameter int MemberKind.GeneralizedFunctionType',
      'handleIdentifier int typeReference',
      'handleNoTypeArguments )',
      'handleType int )',
      'handleNoName )',
      'handleFormalParameterWithoutValue )',
      'beginTypeVariables null null ) FormalParameterKind.mandatory MemberKind.GeneralizedFunctionType',
      'endFormalParameters 1 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function m',
    ]);

    expectInfo(noType, 'Function(int x)', required: false);
    expectInfo(noType, 'Function<T>(int x)', required: false);

    expectComplexInfo('Function(int x)', required: true);
    expectComplexInfo('Function<T>(int x)', required: true);

    expectComplexInfo('Function(int x) m', expectedAfter: 'm');
    expectComplexInfo('Function<T>(int x) m', expectedAfter: 'm');
    expectComplexInfo('Function<T>(int x) Function<T>(int x)',
        required: false, expectedAfter: 'Function');
    expectComplexInfo('Function<T>(int x) Function<T>(int x)', required: true);
    expectComplexInfo('Function<T>(int x) Function<T>(int x) m',
        expectedAfter: 'm');
  }

  void test_computeType_identifier() {
    expectInfo(noType, 'C', required: false);
    expectInfo(noType, 'C;', required: false);
    expectInfo(noType, 'C(', required: false);
    expectInfo(noType, 'C<', required: false);
    expectInfo(noType, 'C.', required: false);
    expectInfo(noType, 'C=', required: false);
    expectInfo(noType, 'C*', required: false);
    expectInfo(noType, 'C do', required: false);

    expectInfo(simpleType, 'C', required: true);
    expectInfo(simpleType, 'C;', required: true);
    expectInfo(simpleType, 'C(', required: true);
    expectInfo(simpleType, 'C<', required: true);
    expectComplexInfo('C.',
        required: true, expectedErrors: [error(codeExpectedType, 2, 0)]);
    expectInfo(simpleType, 'C=', required: true);
    expectInfo(simpleType, 'C*', required: true);
    expectInfo(simpleType, 'C do', required: true);

    expectInfo(simpleType, 'C foo');
    expectInfo(simpleType, 'C get');
    expectInfo(simpleType, 'C set');
    expectInfo(simpleType, 'C operator');
    expectInfo(simpleType, 'C this');
    expectInfo(simpleType, 'C Function');
  }

  void test_computeType_identifierComplex() {
    expectInfo(simpleType, 'C Function()', required: false);
    expectInfo(simpleType, 'C Function<T>()', required: false);
    expectInfo(simpleType, 'C Function(int)', required: false);
    expectInfo(simpleType, 'C Function<T>(int)', required: false);
    expectInfo(simpleType, 'C Function(int x)', required: false);
    expectInfo(simpleType, 'C Function<T>(int x)', required: false);

    expectComplexInfo('C Function()', required: true);
    expectComplexInfo('C Function<T>()', required: true);
    expectComplexInfo('C Function(int)', required: true);
    expectComplexInfo('C Function<T>(int)', required: true);
    expectComplexInfo('C Function(int x)', required: true);
    expectComplexInfo('C Function<T>(int x)', required: true);
    expectComplexInfo('C Function<T>(int x) Function<T>(int x)',
        required: false, expectedAfter: 'Function');
    expectComplexInfo('C Function<T>(int x) Function<T>(int x)',
        required: true);
    expectComplexInfo('C Function(', // Scanner inserts synthetic ')'.
        required: true,
        expectedCalls: [
          'handleNoTypeVariables (',
          'beginFunctionType C',
          'handleIdentifier C typeReference',
          'handleNoTypeArguments Function',
          'handleType C Function',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function ',
        ]);
  }

  void test_computeType_identifierTypeArg() {
    expectInfo(noType, 'C<T>', required: false);
    expectInfo(noType, 'C<T>;', required: false);
    expectInfo(noType, 'C<T>(', required: false);
    expectInfo(noType, 'C<T> do', required: false);
    expectInfo(noType, 'C<void>', required: false);

    expectInfo(simpleTypeWith1Argument, 'C<T>', required: true);
    expectInfo(simpleTypeWith1Argument, 'C<T>;', required: true);
    expectInfo(simpleTypeWith1Argument, 'C<T>(', required: true);
    expectInfo(simpleTypeWith1Argument, 'C<T> do', required: true);
    expectComplexInfo('C<void>', required: true, expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleVoidKeyword void',
      'endTypeArguments 1 < >',
      'handleType C ',
    ]);

    expectInfo(simpleTypeWith1Argument, 'C<T> foo');
    expectInfo(simpleTypeWith1Argument, 'C<T> get');
    expectInfo(simpleTypeWith1Argument, 'C<T> set');
    expectInfo(simpleTypeWith1Argument, 'C<T> operator');
    expectInfo(simpleTypeWith1Argument, 'C<T> Function');
  }

  void test_computeType_identifierTypeArgComplex() {
    expectInfo(noType, 'C<S,T>', required: false);
    expectInfo(noType, 'C<S<T>>', required: false);
    expectInfo(noType, 'C.a<T>', required: false);

    expectComplexInfo('C<S,T>', required: true, expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments ,',
      'handleType S ,',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T >',
      'endTypeArguments 2 < >',
      'handleType C ',
    ]);
    expectComplexInfo('C<S<T>>', required: true, expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T >',
      'endTypeArguments 1 < >',
      'handleType S >',
      'endTypeArguments 1 < >',
      'handleType C ',
    ]);
    expectComplexInfo('C<S,T> f', expectedAfter: 'f', expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments ,',
      'handleType S ,',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T >',
      'endTypeArguments 2 < >',
      'handleType C f',
    ]);
    expectComplexInfo('C<S<T>> f', expectedAfter: 'f', expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T >',
      'endTypeArguments 1 < >',
      'handleType S >',
      'endTypeArguments 1 < >',
      'handleType C f',
    ]);
  }

  void test_computeType_identifierTypeArgGFT() {
    expectComplexInfo('C<T> Function(', // Scanner inserts synthetic ')'.
        required: true,
        expectedCalls: [
          'handleNoTypeVariables (',
          'beginFunctionType C',
          'handleIdentifier C typeReference',
          'beginTypeArguments <',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments >',
          'handleType T >',
          'endTypeArguments 1 < >',
          'handleType C Function',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function ',
        ]);
    expectComplexInfo('C<T> Function<T>(int x) Function<T>(int x)',
        required: false, expectedAfter: 'Function');
    expectComplexInfo('C<T> Function<T>(int x) Function<T>(int x)',
        required: true);
  }

  void test_computeType_identifierTypeArgRecovery() {
    // TOOD(danrubel): dynamic, do, other keywords, malformed, recovery
    // <T>

    // TODO(danrubel): Improve missing comma recovery
    expectTypeParamOrArg(noTypeParamOrArg, 'G<int double> g');
    // expectComplexInfo('G<int double> g',
    //     required: true,
    //     tokenAfter: 'g',
    //     expectedCalls: [
    //       'handleIdentifier G typeReference',
    //       'beginTypeArguments <',
    //       'handleIdentifier int typeReference',
    //       'handleNoTypeArguments double',
    //       'handleType int double',
    //       'endTypeArguments 1 < >',
    //       'handleType G g',
    //     ],
    //     expectedErrors: [
    //       error(codeExpectedToken, 6, 6)
    //     ]);

    expectInfo(noType, 'C<>', required: false);
    expectComplexInfo('C<>', required: true, expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier  typeReference',
      'handleNoTypeArguments >',
      'handleType  >',
      'endTypeArguments 1 < >',
      'handleType C ',
    ], expectedErrors: [
      error(codeExpectedType, 2, 1)
    ]);
    expectComplexInfo('C<> f',
        required: true,
        expectedAfter: 'f',
        expectedCalls: [
          'handleIdentifier C typeReference',
          'beginTypeArguments <',
          'handleIdentifier  typeReference',
          'handleNoTypeArguments >',
          'handleType  >',
          'endTypeArguments 1 < >',
          'handleType C f',
        ],
        expectedErrors: [
          error(codeExpectedType, 2, 1)
        ]);

    // Statements that should not have a type
    expectInfo(noType, 'C<T ; T>U;', required: false);
    expectInfo(noType, 'C<T && T>U;', required: false);
  }

  void test_computeType_nested() {
    expectNestedInfo(simpleType, '<T>');
    expectNestedInfo(simpleTypeWith1Argument, '<T<S>>');
    expectNestedComplexInfo('<T<S,R>>');
    expectNestedComplexInfo('<T<S Function()>>');
    expectNestedComplexInfo('<T<S Function()>>');
  }

  void test_computeType_nested_recovery() {
    expectNestedInfo(noType, '<>');
    expectNestedInfo(noType, '<3>');
    expectNestedInfo(noType, '<,T>');
    expectNestedInfo(simpleType, '<T,>');
    expectNestedInfo(noType, '<,T<S>>');
    expectNestedInfo(simpleTypeWith1Argument, '<T<S>,>');
  }

  void test_computeType_prefixed() {
    expectInfo(noType, 'C.a', required: false);
    expectInfo(noType, 'C.a;', required: false);
    expectInfo(noType, 'C.a(', required: false);
    expectInfo(noType, 'C.a<', required: false);
    expectInfo(noType, 'C.a=', required: false);
    expectInfo(noType, 'C.a*', required: false);
    expectInfo(noType, 'C.a do', required: false);

    expectInfo(prefixedType, 'C.a', required: true);
    expectInfo(prefixedType, 'C.a;', required: true);
    expectInfo(prefixedType, 'C.a(', required: true);
    expectInfo(prefixedType, 'C.a<', required: true);
    expectInfo(prefixedType, 'C.a=', required: true);
    expectInfo(prefixedType, 'C.a*', required: true);
    expectInfo(prefixedType, 'C.a do', required: true);

    expectInfo(prefixedType, 'C.a foo');
    expectInfo(prefixedType, 'C.a get');
    expectInfo(prefixedType, 'C.a set');
    expectInfo(prefixedType, 'C.a operator');
    expectInfo(prefixedType, 'C.a Function');
  }

  void test_computeType_prefixedComplex() {
    expectComplexInfo('a < b, c > d', expectedAfter: 'd');
    expectComplexInfo('a < b, c > d', expectedAfter: 'd');

    expectComplexInfo('a < p.b, c > d', expectedAfter: 'd');
    expectComplexInfo('a < b, p.c > d', expectedAfter: 'd');

    expectInfo(noType, 'a < p.q.b, c > d', required: false);
    expectInfo(noType, 'a < b, p.q.c > d', required: false);

    expectInfo(simpleType, 'a < p.q.b, c > d', required: true);
    expectInfo(simpleType, 'a < b, p.q.c > d', required: true);
  }

  void test_computeType_prefixedGFT() {
    expectComplexInfo('C.a Function(', // Scanner inserts synthetic ')'.
        required: true,
        expectedCalls: [
          'handleNoTypeVariables (',
          'beginFunctionType C',
          'handleIdentifier C prefixedTypeReference',
          'handleIdentifier a typeReferenceContinuation',
          'handleQualified .',
          'handleNoTypeArguments Function',
          'handleType C Function',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function ',
        ]);
    expectComplexInfo('C.a Function<T>(int x) Function<T>(int x)',
        required: false, expectedAfter: 'Function');
    expectComplexInfo('C.a Function<T>(int x) Function<T>(int x)',
        required: true);
  }

  void test_computeType_prefixedTypeArg() {
    expectComplexInfo('C.a<T>', required: true, expectedCalls: [
      'handleIdentifier C prefixedTypeReference',
      'handleIdentifier a typeReferenceContinuation',
      'handleQualified .',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T >',
      'endTypeArguments 1 < >',
      'handleType C ',
    ]);

    expectComplexInfo('C.a<T> f', expectedAfter: 'f', expectedCalls: [
      'handleIdentifier C prefixedTypeReference',
      'handleIdentifier a typeReferenceContinuation',
      'handleQualified .',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T >',
      'endTypeArguments 1 < >',
      'handleType C f',
    ]);
  }

  void test_computeType_prefixedTypeArgGFT() {
    expectComplexInfo('C.a<T> Function<T>(int x) Function<T>(int x)',
        required: true,
        expectedCalls: [
          'beginTypeVariables <',
          'beginTypeVariable T',
          'beginMetadataStar T',
          'endMetadataStar 0',
          'handleIdentifier T typeVariableDeclaration',
          'handleNoType T',
          'endTypeVariable > null',
          'endTypeVariables 1 < >',
          'beginFunctionType C',
          'beginTypeVariables <',
          'beginTypeVariable T',
          'beginMetadataStar T',
          'endMetadataStar 0',
          'handleIdentifier T typeVariableDeclaration',
          'handleNoType T',
          'endTypeVariable > null',
          'endTypeVariables 1 < >',
          'beginFunctionType C',
          'handleIdentifier C prefixedTypeReference',
          'handleIdentifier a typeReferenceContinuation',
          'handleQualified .',
          'beginTypeArguments <',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments >',
          'handleType T >',
          'endTypeArguments 1 < >',
          'handleType C Function',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'beginMetadataStar int',
          'endMetadataStar 0',
          'beginFormalParameter int MemberKind.GeneralizedFunctionType',
          'handleIdentifier int typeReference',
          'handleNoTypeArguments x',
          'handleType int x',
          'handleIdentifier x formalParameterDeclaration',
          'handleFormalParameterWithoutValue )',
          'beginTypeVariables null null x FormalParameterKind.mandatory '
              'MemberKind.GeneralizedFunctionType',
          'endFormalParameters 1 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function Function',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'beginMetadataStar int',
          'endMetadataStar 0',
          'beginFormalParameter int MemberKind.GeneralizedFunctionType',
          'handleIdentifier int typeReference',
          'handleNoTypeArguments x',
          'handleType int x',
          'handleIdentifier x formalParameterDeclaration',
          'handleFormalParameterWithoutValue )',
          'beginTypeVariables null null x FormalParameterKind.mandatory '
              'MemberKind.GeneralizedFunctionType',
          'endFormalParameters 1 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function ',
        ]);
  }

  void test_computeType_void() {
    expectInfo(voidType, 'void');
    expectInfo(voidType, 'void;');
    expectInfo(voidType, 'void(');
    expectInfo(voidType, 'void<');
    expectInfo(voidType, 'void=');
    expectInfo(voidType, 'void*');
    expectInfo(voidType, 'void<T>');
    expectInfo(voidType, 'void do');
    expectInfo(voidType, 'void foo');
    expectInfo(voidType, 'void get');
    expectInfo(voidType, 'void set');
    expectInfo(voidType, 'void operator');
    expectInfo(voidType, 'void Function');
    expectComplexInfo('void Function(', // Scanner inserts synthetic ')'.
        required: true,
        expectedCalls: [
          'handleNoTypeVariables (',
          'beginFunctionType void',
          'handleVoidKeyword void',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function ',
        ]);
  }

  void test_computeType_voidComplex() {
    expectInfo(voidType, 'void Function()', required: false);
    expectComplexInfo('void Function()', required: true, expectedCalls: [
      'handleNoTypeVariables (',
      'beginFunctionType void',
      'handleVoidKeyword void',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function ',
    ]);

    expectInfo(voidType, 'void Function<T>()', required: false);
    expectInfo(voidType, 'void Function(int)', required: false);
    expectInfo(voidType, 'void Function<T>(int)', required: false);
    expectInfo(voidType, 'void Function(int x)', required: false);
    expectInfo(voidType, 'void Function<T>(int x)', required: false);

    expectComplexInfo('void Function<T>()', required: true);
    expectComplexInfo('void Function(int)', required: true);
    expectComplexInfo('void Function<T>(int)', required: true);
    expectComplexInfo('void Function(int x)', required: true);
    expectComplexInfo('void Function<T>(int x)', required: true);

    expectComplexInfo('void Function<T>(int x) Function<T>(int x)',
        required: false, expectedAfter: 'Function');
    expectComplexInfo('void Function<T>(int x) Function<T>(int x)',
        required: true);
  }
}

@reflectiveTest
class TypeParamOrArgInfoTest {
  void test_noTypeParamOrArg() {
    final Token start = scanString('before after').tokens;

    expect(noTypeParamOrArg.skip(start), start);
  }

  void test_noTypeParamOrArg_parseArguments() {
    final Token start = scanString('before after').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(noTypeParamOrArg.parseArguments(start, new Parser(listener)), start);
    expect(listener.calls, ['handleNoTypeArguments after']);
    expect(listener.errors, isNull);
  }

  void test_noTypeParamOrArg_parseVariables() {
    final Token start = scanString('before after').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(noTypeParamOrArg.parseVariables(start, new Parser(listener)), start);
    expect(listener.calls, ['handleNoTypeVariables after']);
    expect(listener.errors, isNull);
  }

  void test_simple_skip() {
    final Token start = scanString('before <T> after').tokens;
    final Token gt = start.next.next.next;
    expect(gt.lexeme, '>');

    expect(simpleTypeArgument1.skip(start), gt);
  }

  void test_simple_skip2() {
    final Token start = scanString('before <S<T>> after').tokens.next.next;
    Token t = start.next.next;
    expect(t.next.lexeme, '>>');

    expect(simpleTypeArgument1.skip(start), t);
  }

  void test_simple_parseArguments() {
    final Token start = scanString('before <T> after').tokens;
    final Token gt = start.next.next.next;
    expect(gt.lexeme, '>');
    final TypeInfoListener listener = new TypeInfoListener();

    expect(simpleTypeArgument1.parseArguments(start, new Parser(listener)), gt);
    expect(listener.calls, [
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T >',
      'endTypeArguments 1 < >'
    ]);
    expect(listener.errors, isNull);
  }

  void test_simple_parseVariables() {
    final Token start = scanString('before <T> after').tokens;
    final Token gt = start.next.next.next;
    expect(gt.lexeme, '>');
    final TypeInfoListener listener = new TypeInfoListener();

    expect(simpleTypeArgument1.parseVariables(start, new Parser(listener)), gt);
    expect(listener.calls, [
      'beginTypeVariables <',
      'beginTypeVariable T',
      'beginMetadataStar T',
      'endMetadataStar 0',
      'handleIdentifier T typeVariableDeclaration',
      'handleNoType T',
      'endTypeVariable > null',
      'endTypeVariables 1 < >',
    ]);
    expect(listener.errors, isNull);
  }

  void test_computeTypeParamOrArg_basic() {
    expectTypeParamOrArg(noTypeParamOrArg, '');
    expectTypeParamOrArg(noTypeParamOrArg, 'a');
    expectTypeParamOrArg(noTypeParamOrArg, 'a b');
    expectTypeParamOrArg(noTypeParamOrArg, '<');
    expectTypeParamOrArg(noTypeParamOrArg, '< b');
    expectTypeParamOrArg(noTypeParamOrArg, '< 3 >');
  }

  void test_computeTypeParamOrArg_simple() {
    expectTypeParamOrArg(simpleTypeArgument1, '<T>');
  }

  void test_computeTypeParamOrArg_simple_nested() {
    String source = '<C<T>>';
    Token start = scan(source).next.next;
    expect(start.lexeme, 'C');
    Token gtgt = start.next.next.next;
    expect(gtgt.lexeme, '>>');

    TypeParamOrArgInfo typeVarInfo = computeTypeParamOrArg(start, gtgt);
    expect(typeVarInfo, simpleTypeArgument1, reason: source);
  }

  void test_computeTypeArg_complex() {
    expectComplexTypeArg('<S,T>', expectedCalls: [
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments ,',
      'handleType S ,',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T >',
      'endTypeArguments 2 < >'
    ]);
    expectComplexTypeArg('<S Function()>', expectedCalls: [
      'beginTypeArguments <',
      'handleNoTypeVariables (',
      'beginFunctionType S',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments Function',
      'handleType S Function',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function >',
      'endTypeArguments 1 < >'
    ]);
    expectComplexTypeArg('<void Function()>', expectedCalls: [
      'beginTypeArguments <',
      'handleNoTypeVariables (',
      'beginFunctionType void',
      'handleVoidKeyword void',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function >',
      'endTypeArguments 1 < >'
    ]);
    expectComplexTypeArg('<S<T>>', expectedCalls: [
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T >',
      'endTypeArguments 1 < >',
      'handleType S >',
      'endTypeArguments 1 < >'
    ]);
    expectComplexTypeArg('<S<Function()>>', expectedCalls: [
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'beginTypeArguments <',
      'handleNoTypeVariables (',
      'beginFunctionType Function',
      'handleNoType <',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function >',
      'endTypeArguments 1 < >',
      'handleType S >',
      'endTypeArguments 1 < >'
    ]);
    expectComplexTypeArg('<S<void Function()>>', expectedCalls: [
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'beginTypeArguments <',
      'handleNoTypeVariables (',
      'beginFunctionType void', // was 'beginFunctionType Function'
      'handleVoidKeyword void', // was 'handleNoType <'
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function >',
      'endTypeArguments 1 < >',
      'handleType S >',
      'endTypeArguments 1 < >'
    ]);
  }

  void test_computeTypeArg_complex_recovery() {
    expectComplexTypeArg('<S extends T>', expectedErrors: [
      error(codeUnexpectedToken, 3, 7)
    ], expectedCalls: [
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments extends',
      'handleType S extends',
      'endTypeArguments 1 < >',
    ]);
    expectComplexTypeArg('<S extends List<T>>', expectedErrors: [
      error(codeUnexpectedToken, 3, 7)
    ], expectedCalls: [
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments extends',
      'handleType S extends',
      'endTypeArguments 1 < >',
    ]);
    expectComplexTypeArg('<@A S,T>', expectedErrors: [
      error(codeUnexpectedToken, 1, 1)
    ], expectedCalls: [
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments ,',
      'handleType S ,',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T >',
      'endTypeArguments 2 < >'
    ]);
    expectComplexTypeArg('<@A() S,T>', expectedErrors: [
      error(codeUnexpectedToken, 1, 1)
    ], expectedCalls: [
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments ,',
      'handleType S ,',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T >',
      'endTypeArguments 2 < >'
    ]);
    expectComplexTypeArg('<@A() @B S,T>', expectedErrors: [
      error(codeUnexpectedToken, 1, 1),
      error(codeUnexpectedToken, 6, 1),
    ], expectedCalls: [
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments ,',
      'handleType S ,',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T >',
      'endTypeArguments 2 < >'
    ]);
  }

  void test_computeTypeParam_complex() {
    expectComplexTypeParam('<S,T>', expectedCalls: [
      'beginTypeVariables <',
      'beginTypeVariable S',
      'beginMetadataStar S',
      'endMetadataStar 0',
      'handleIdentifier S typeVariableDeclaration',
      'handleNoType S',
      'endTypeVariable , null',
      'beginTypeVariable T',
      'beginMetadataStar T',
      'endMetadataStar 0',
      'handleIdentifier T typeVariableDeclaration',
      'handleNoType T',
      'endTypeVariable > null',
      'endTypeVariables 2 < >',
    ]);
    expectComplexTypeParam('<S extends T>', expectedCalls: [
      'beginTypeVariables <',
      'beginTypeVariable S',
      'beginMetadataStar S',
      'endMetadataStar 0',
      'handleIdentifier S typeVariableDeclaration',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T >',
      'endTypeVariable > extends',
      'endTypeVariables 1 < >',
    ]);
    expectComplexTypeParam('<S super T>', expectedCalls: [
      'beginTypeVariables <',
      'beginTypeVariable S',
      'beginMetadataStar S',
      'endMetadataStar 0',
      'handleIdentifier S typeVariableDeclaration',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T >',
      'endTypeVariable > super',
      'endTypeVariables 1 < >',
    ]);
    expectComplexTypeParam('<S extends List<T>>', expectedCalls: [
      'beginTypeVariables <',
      'beginTypeVariable S',
      'beginMetadataStar S',
      'endMetadataStar 0',
      'handleIdentifier S typeVariableDeclaration',
      'handleIdentifier List typeReference',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T >',
      'endTypeArguments 1 < >',
      'handleType List >',
      'endTypeVariable > extends',
      'endTypeVariables 1 < >',
    ]);
    expectComplexTypeParam('<R, S extends void Function()>', expectedCalls: [
      'beginTypeVariables <',
      'beginTypeVariable R',
      'beginMetadataStar R',
      'endMetadataStar 0',
      'handleIdentifier R typeVariableDeclaration',
      'handleNoType R',
      'endTypeVariable , null',
      'beginTypeVariable S',
      'beginMetadataStar S',
      'endMetadataStar 0',
      'handleIdentifier S typeVariableDeclaration',
      'handleNoTypeVariables (',
      'beginFunctionType void',
      'handleVoidKeyword void',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function >',
      'endTypeVariable > extends',
      'endTypeVariables 2 < >',
    ]);
    expectComplexTypeParam('<@A S,T>', expectedCalls: [
      'beginTypeVariables <',
      'beginTypeVariable @',
      'beginMetadataStar @',
      'beginMetadata @',
      'handleIdentifier A metadataReference',
      'handleNoTypeArguments S',
      'handleNoArguments S',
      'endMetadata @ null S',
      'endMetadataStar 1',
      'handleIdentifier S typeVariableDeclaration',
      'handleNoType S',
      'endTypeVariable , null',
      'beginTypeVariable T',
      'beginMetadataStar T',
      'endMetadataStar 0',
      'handleIdentifier T typeVariableDeclaration',
      'handleNoType T',
      'endTypeVariable > null',
      'endTypeVariables 2 < >',
    ]);
    expectComplexTypeParam('<@A() S,T>', expectedCalls: [
      'beginTypeVariables <',
      'beginTypeVariable @',
      'beginMetadataStar @',
      'beginMetadata @',
      'handleIdentifier A metadataReference',
      'handleNoTypeArguments (',
      'beginArguments (',
      'endArguments 0 ( )',
      'endMetadata @ null S',
      'endMetadataStar 1',
      'handleIdentifier S typeVariableDeclaration',
      'handleNoType S',
      'endTypeVariable , null',
      'beginTypeVariable T',
      'beginMetadataStar T',
      'endMetadataStar 0',
      'handleIdentifier T typeVariableDeclaration',
      'handleNoType T',
      'endTypeVariable > null',
      'endTypeVariables 2 < >',
    ]);
    expectComplexTypeParam('<@A() @B S,T>', expectedCalls: [
      'beginTypeVariables <',
      'beginTypeVariable @',
      'beginMetadataStar @',
      'beginMetadata @',
      'handleIdentifier A metadataReference',
      'handleNoTypeArguments (',
      'beginArguments (',
      'endArguments 0 ( )',
      'endMetadata @ null @',
      'beginMetadata @',
      'handleIdentifier B metadataReference',
      'handleNoTypeArguments S',
      'handleNoArguments S',
      'endMetadata @ null S',
      'endMetadataStar 2',
      'handleIdentifier S typeVariableDeclaration',
      'handleNoType S',
      'endTypeVariable , null',
      'beginTypeVariable T',
      'beginMetadataStar T',
      'endMetadataStar 0',
      'handleIdentifier T typeVariableDeclaration',
      'handleNoType T',
      'endTypeVariable > null',
      'endTypeVariables 2 < >',
    ]);
  }

  void test_computeTypeParam_complex_recovery() {
    expectComplexTypeParam('<S Function()>', expectedErrors: [
      error(codeUnexpectedToken, 3, 8),
    ], expectedCalls: [
      'beginTypeVariables <',
      'beginTypeVariable S',
      'beginMetadataStar S',
      'endMetadataStar 0',
      'handleIdentifier S typeVariableDeclaration',
      'handleNoType S',
      'endTypeVariable Function null',
      'endTypeVariables 1 < >',
    ]);
    expectComplexTypeParam('<void Function()>', expectedErrors: [
      error(codeExpectedIdentifier, 1, 4),
      error(codeUnexpectedToken, 1, 4),
    ], expectedCalls: [
      'beginTypeVariables <',
      'beginTypeVariable void',
      'beginMetadataStar void',
      'endMetadataStar 0',
      'handleIdentifier  typeVariableDeclaration',
      'handleNoType ',
      'endTypeVariable void null',
      'endTypeVariables 1 < >',
    ]);
    expectComplexTypeParam('<S<T>>', expectedErrors: [
      error(codeUnexpectedToken, 2, 1),
    ], expectedCalls: [
      'beginTypeVariables <',
      'beginTypeVariable S',
      'beginMetadataStar S',
      'endMetadataStar 0',
      'handleIdentifier S typeVariableDeclaration',
      'handleNoType S',
      'endTypeVariable < null',
      'endTypeVariables 1 < >',
    ]);
  }
}

void expectInfo(expectedInfo, String source, {bool required}) {
  if (required == null) {
    compute(expectedInfo, source, scan(source), true);
    compute(expectedInfo, source, scan(source), false);
  } else {
    compute(expectedInfo, source, scan(source), required);
  }
}

void expectComplexInfo(String source,
    {bool required,
    String expectedAfter,
    List<String> expectedCalls,
    List<ExpectedError> expectedErrors}) {
  if (required == null) {
    computeComplex(source, scan(source), true, expectedAfter, expectedCalls,
        expectedErrors);
    computeComplex(source, scan(source), false, expectedAfter, expectedCalls,
        expectedErrors);
  } else {
    computeComplex(source, scan(source), required, expectedAfter, expectedCalls,
        expectedErrors);
  }
}

void expectNestedInfo(expectedInfo, String source) {
  expect(source.startsWith('<'), isTrue);
  Token start = scan(source).next;
  Token innerEndGroup = start;
  while (!innerEndGroup.next.isEof) {
    innerEndGroup = innerEndGroup.next;
  }
  if (!optional('>>', innerEndGroup)) {
    innerEndGroup = null;
  }
  compute(expectedInfo, source, start, true, innerEndGroup: innerEndGroup);
}

void expectNestedComplexInfo(String source) {
  expectNestedInfo(const isInstanceOf<ComplexTypeInfo>(), source);
}

TypeInfo compute(expectedInfo, String source, Token start, bool required,
    {Token innerEndGroup}) {
  int expectedGtGtAndNullEndCount = countGtGtAndNullEnd(start);
  TypeInfo typeInfo = computeType(start, required, innerEndGroup);
  expect(typeInfo, expectedInfo, reason: source);
  expect(countGtGtAndNullEnd(start), expectedGtGtAndNullEndCount,
      reason: 'computeType should not modify the token stream');
  return typeInfo;
}

ComplexTypeInfo computeComplex(
    String source,
    Token start,
    bool required,
    String expectedAfter,
    List<String> expectedCalls,
    List<ExpectedError> expectedErrors) {
  int expectedGtGtAndNullEndCount = countGtGtAndNullEnd(start);
  ComplexTypeInfo typeInfo =
      compute(const isInstanceOf<ComplexTypeInfo>(), source, start, required);
  expect(typeInfo.start, start.next, reason: source);
  expect(typeInfo.couldBeExpression, isFalse);
  expectEnd(expectedAfter, typeInfo.skipType(start));
  expect(countGtGtAndNullEnd(start), expectedGtGtAndNullEndCount,
      reason: 'TypeInfo.skipType should not modify the token stream');

  TypeInfoListener listener = new TypeInfoListener();
  Token actualEnd = typeInfo.parseType(start, new Parser(listener));

  expectEnd(expectedAfter, actualEnd);
  if (expectedCalls != null) {
    // TypeInfoListener listener2 = new TypeInfoListener();
    // new Parser(listener2).parseType(start, TypeContinuation.Required);
    // print('[');
    // for (String call in listener2.calls) {
    //   print("'$call',");
    // }
    // print(']');

    expect(listener.calls, expectedCalls, reason: source);
  }
  expect(listener.errors, expectedErrors, reason: source);
  return typeInfo;
}

void expectComplexTypeArg(String source,
    {String expectedAfter,
    List<String> expectedCalls,
    List<ExpectedError> expectedErrors}) {
  Token start = scan(source);
  int expectedGtGtAndNullEndCount = countGtGtAndNullEnd(start);
  ComplexTypeParamOrArgInfo typeVarInfo = computeVar(
      const isInstanceOf<ComplexTypeParamOrArgInfo>(), source, start);

  expect(typeVarInfo.start, start.next, reason: source);
  expectEnd(expectedAfter, typeVarInfo.skip(start));
  expect(countGtGtAndNullEnd(start), expectedGtGtAndNullEndCount,
      reason: 'TypeParamOrArgInfo.skipType'
          ' should not modify the token stream');

  TypeInfoListener listener = new TypeInfoListener();
  Parser parser = new Parser(listener);
  Token actualEnd = typeVarInfo.parseArguments(start, parser);
  expectEnd(expectedAfter, actualEnd);

  if (expectedCalls != null) {
    try {
      expect(listener.calls, expectedCalls, reason: source);
    } catch (e) {
      TypeInfoListener listener2 = new TypeInfoListener();
      new Parser(listener2).parseTypeArgumentsOpt(start);
      print('Events from parseTypeArgumentsOpt: [');
      for (String call in listener2.calls) {
        print("  '$call',");
      }
      print(']');
      rethrow;
    }
  }
  expect(listener.errors, expectedErrors, reason: source);
}

void expectComplexTypeParam(String source,
    {String expectedAfter,
    List<String> expectedCalls,
    List<ExpectedError> expectedErrors}) {
  Token start = scan(source);
  int expectedGtGtAndNullEndCount = countGtGtAndNullEnd(start);
  ComplexTypeParamOrArgInfo typeVarInfo = computeVar(
      const isInstanceOf<ComplexTypeParamOrArgInfo>(), source, start);

  expect(typeVarInfo.start, start.next, reason: source);
  expectEnd(expectedAfter, typeVarInfo.skip(start));
  expect(countGtGtAndNullEnd(start), expectedGtGtAndNullEndCount,
      reason: 'TypeParamOrArgInfo.skipType'
          ' should not modify the token stream');

  TypeInfoListener listener = new TypeInfoListener(metadataAllowed: true);
  Parser parser = new Parser(listener);
  Token actualEnd = typeVarInfo.parseVariables(start, parser);
  expectEnd(expectedAfter, actualEnd);

  if (expectedCalls != null) {
    try {
      expect(listener.calls, expectedCalls, reason: source);
    } catch (e) {
      TypeInfoListener listener2 = new TypeInfoListener(metadataAllowed: true);
      new Parser(listener2).parseTypeVariablesOpt(start);
      print('Events from parseTypeVariablesOpt: [');
      for (String call in listener2.calls) {
        print("  '$call',");
      }
      print(']');
      rethrow;
    }
  }
  expect(listener.errors, expectedErrors, reason: source);
}

void expectTypeParamOrArg(expectedInfo, String source,
    {bool splitGtGt: true,
    String expectedAfter,
    List<String> expectedCalls,
    List<ExpectedError> expectedErrors}) {
  Token start = scan(source);
  computeVar(expectedInfo, source, start);
}

TypeParamOrArgInfo computeVar(expectedInfo, String source, Token start) {
  int expectedGtGtAndNullEndCount = countGtGtAndNullEnd(start);
  TypeParamOrArgInfo typeVarInfo = computeTypeParamOrArg(start);
  expect(typeVarInfo, expectedInfo, reason: source);
  expect(countGtGtAndNullEnd(start), expectedGtGtAndNullEndCount,
      reason: 'computeTypeParamOrArg should not modify the token stream');
  return typeVarInfo;
}

void expectEnd(String tokenAfter, Token end) {
  if (tokenAfter == null) {
    expect(end.isEof, isFalse);
    expect(end.next.isEof, isTrue);
  } else {
    expect(end.next.lexeme, tokenAfter);
  }
}

Token scan(String source) {
  Token start = scanString(source).tokens;
  while (start is ErrorToken) {
    start = start.next;
  }
  return new SyntheticToken(TokenType.EOF, 0)..setNext(start);
}

int countGtGtAndNullEnd(Token token) {
  int count = 0;
  while (!token.isEof) {
    if ((optional('<', token) && token.endGroup == null) ||
        optional('>>', token)) {
      ++count;
    }
    token = token.next;
  }
  return count;
}

class TypeInfoListener implements Listener {
  final bool metadataAllowed;
  List<String> calls = <String>[];
  List<ExpectedError> errors;

  TypeInfoListener({this.metadataAllowed: false});

  @override
  void beginArguments(Token token) {
    if (metadataAllowed) {
      calls.add('beginArguments $token');
    } else {
      throw 'beginArguments should not be called.';
    }
  }

  @override
  void beginFormalParameter(Token token, MemberKind kind, Token covariantToken,
      Token varFinalOrConst) {
    calls.add('beginFormalParameter $token $kind');
  }

  @override
  void beginFormalParameters(Token token, MemberKind kind) {
    calls.add('beginFormalParameters $token $kind');
  }

  @override
  void beginFunctionType(Token token) {
    calls.add('beginFunctionType $token');
  }

  @override
  void beginMetadata(Token token) {
    if (metadataAllowed) {
      calls.add('beginMetadata $token');
    } else {
      throw 'beginMetadata should not be called.';
    }
  }

  @override
  void beginMetadataStar(Token token) {
    calls.add('beginMetadataStar $token');
  }

  @override
  void beginTypeArguments(Token token) {
    calls.add('beginTypeArguments $token');
  }

  @override
  void beginTypeVariable(Token token) {
    calls.add('beginTypeVariable $token');
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    calls.add('endFormalParameters $count $beginToken $endToken $kind');
  }

  @override
  void beginTypeVariables(Token token) {
    calls.add('beginTypeVariables $token');
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    if (metadataAllowed) {
      calls.add('endArguments $count $beginToken $endToken');
    } else {
      throw 'endArguments should not be called.';
    }
  }

  @override
  void endFormalParameter(Token thisKeyword, Token periodAfterThis,
      Token nameToken, FormalParameterKind kind, MemberKind memberKind) {
    calls.add('beginTypeVariables $thisKeyword $periodAfterThis '
        '$nameToken $kind $memberKind');
  }

  @override
  void endFunctionType(Token functionToken, Token endToken) {
    calls.add('endFunctionType $functionToken $endToken');
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    if (metadataAllowed) {
      calls.add('endMetadata $beginToken $periodBeforeName $endToken');
    } else {
      throw 'endMetadata should not be called.';
    }
  }

  @override
  void endMetadataStar(int count) {
    calls.add('endMetadataStar $count');
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    calls.add('endTypeArguments $count $beginToken $endToken');
  }

  @override
  void endTypeVariable(Token token, Token extendsOrSuper) {
    calls.add('endTypeVariable $token $extendsOrSuper');
  }

  @override
  void endTypeVariables(int count, Token beginToken, Token endToken) {
    calls.add('endTypeVariables $count $beginToken $endToken');
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {
    calls.add('handleFormalParameterWithoutValue $token');
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    calls.add('handleIdentifier $token $context');
  }

  @override
  void handleNoArguments(Token token) {
    if (metadataAllowed) {
      calls.add('handleNoArguments $token');
    } else {
      throw 'handleNoArguments should not be called.';
    }
  }

  @override
  void handleNoName(Token token) {
    calls.add('handleNoName $token');
  }

  @override
  void handleNoType(Token token) {
    calls.add('handleNoType $token');
  }

  @override
  void handleNoTypeArguments(Token token) {
    calls.add('handleNoTypeArguments $token');
  }

  @override
  void handleNoTypeVariables(Token token) {
    calls.add('handleNoTypeVariables $token');
  }

  @override
  void handleRecoverableError(
      Message message, Token startToken, Token endToken) {
    errors ??= <ExpectedError>[];
    int offset = startToken.charOffset;
    errors.add(error(message.code, offset, endToken.charEnd - offset));
  }

  @override
  void handleQualified(Token token) {
    calls.add('handleQualified $token');
  }

  @override
  void handleType(Token beginToken, Token endToken) {
    calls.add('handleType $beginToken $endToken');
  }

  @override
  void handleVoidKeyword(Token token) {
    calls.add('handleVoidKeyword $token');
  }

  noSuchMethod(Invocation invocation) {
    throw '${invocation.memberName} should not be called.';
  }
}

ExpectedError error(Code code, int start, int length) =>
    new ExpectedError(code, start, length);

class ExpectedError {
  final Code code;
  final int start;
  final int length;

  ExpectedError(this.code, this.start, this.length);

  @override
  bool operator ==(other) =>
      other is ExpectedError &&
      code == other.code &&
      start == other.start &&
      length == other.length;

  @override
  String toString() => 'error(${code.name}, $start, $length)';
}
