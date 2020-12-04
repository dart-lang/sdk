// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/parser.dart';
import 'package:_fe_analyzer_shared/src/parser/type_info.dart';
import 'package:_fe_analyzer_shared/src/parser/type_info_impl.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' hide scanString;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' as scanner;
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:front_end/src/fasta/messages.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoTypeInfoTest);
    defineReflectiveTests(PrefixedTypeInfoTest);
    defineReflectiveTests(SimpleNullableTypeTest);
    defineReflectiveTests(SimpleNullableTypeWith1ArgumentTest);
    defineReflectiveTests(SimpleTypeTest);
    defineReflectiveTests(SimpleTypeWith1ArgumentTest);
    defineReflectiveTests(TypeInfoTest);
    defineReflectiveTests(VoidTypeInfoTest);

    defineReflectiveTests(NoTypeParamOrArgTest);
    defineReflectiveTests(SimpleTypeParamOrArgTest);
    defineReflectiveTests(TypeParamOrArgInfoTest);
    defineReflectiveTests(CouldBeExpressionTest);
  });
}

ScannerResult scanString(String source, {bool includeComments: false}) =>
    scanner.scanString(source,
        configuration: const ScannerConfiguration(enableTripleShift: true),
        includeComments: includeComments);

@reflectiveTest
class NoTypeInfoTest {
  void test_basic() {
    final Token start = scanString('before ;').tokens;

    expect(noType.couldBeExpression, isFalse);
    expect(noType.skipType(start), start);
  }

  void test_compute() {
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

    expectInfo(noType, 'C', required: false);
    expectInfo(noType, 'C;', required: false);
    expectInfo(noType, 'C(', required: false);
    expectInfo(noType, 'C<', required: false);
    expectInfo(noType, 'C.', required: false);
    expectInfo(noType, 'C=', required: false);
    expectInfo(noType, 'C*', required: false);
    expectInfo(noType, 'C do', required: false);

    expectInfo(noType, 'C.a', required: false);
    expectInfo(noType, 'C.a;', required: false);
    expectInfo(noType, 'C.a(', required: false);
    expectInfo(noType, 'C.a<', required: false);
    expectInfo(noType, 'C.a=', required: false);
    expectInfo(noType, 'C.a*', required: false);
    expectInfo(noType, 'C.a do', required: false);

    expectInfo(noType, 'C<T>', required: false);
    expectInfo(noType, 'C<T>;', required: false);
    expectInfo(noType, 'C<T>(', required: false);
    expectInfo(noType, 'C<T> do', required: false);
    expectInfo(noType, 'C<void>', required: false);

    expectInfo(noType, 'C<T>= foo', required: false);
    expectInfo(noType, 'C<T>= get', required: false);
    expectInfo(noType, 'C<T>= set', required: false);
    expectInfo(noType, 'C<T>= operator', required: false);
    expectInfo(noType, 'C<T>= Function', required: false);

    expectInfo(noType, 'C<T>> foo', required: false);
    expectInfo(noType, 'C<T>> get', required: false);
    expectInfo(noType, 'C<T>> set', required: false);
    expectInfo(noType, 'C<T>> operator', required: false);
    expectInfo(noType, 'C<T>> Function', required: false);

    expectInfo(noType, 'C<T>>= foo', required: false);
    expectInfo(noType, 'C<T>>= get', required: false);
    expectInfo(noType, 'C<T>>= set', required: false);
    expectInfo(noType, 'C<T>>= operator', required: false);
    expectInfo(noType, 'C<T>>= Function', required: false);

    expectInfo(noType, 'C<S,T>', required: false);
    expectInfo(noType, 'C<S<T>>', required: false);
    expectInfo(noType, 'C.a<T>', required: false);
    expectInfo(noType, 'C<S,T>=', required: false);
    expectInfo(noType, 'C<S<T>>=', required: false);
    expectInfo(noType, 'C.a<T>=', required: false);

    expectInfo(noType, 'Function(int x)', required: false);
    expectInfo(noType, 'Function<T>(int x)', required: false);
  }

  void test_ensureTypeNotVoid() {
    final Token start = scanString('before ;').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(noType.ensureTypeNotVoid(start, new Parser(listener)),
        const TypeMatcher<SyntheticStringToken>());
    expect(listener.calls, [
      'handleIdentifier  typeReference',
      'handleNoTypeArguments ;',
      'handleType  null',
    ]);
    expect(listener.errors, [new ExpectedError(codeExpectedType, 7, 1)]);
  }

  void test_ensureTypeOrVoid() {
    final Token start = scanString('before ;').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(noType.ensureTypeOrVoid(start, new Parser(listener)),
        const TypeMatcher<SyntheticStringToken>());
    expect(listener.calls, [
      'handleIdentifier  typeReference',
      'handleNoTypeArguments ;',
      'handleType  null',
    ]);
    expect(listener.errors, [new ExpectedError(codeExpectedType, 7, 1)]);
  }

  void test_parseType() {
    final Token start = scanString('before ;').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(noType.parseType(start, new Parser(listener)), start);
    expect(listener.calls, ['handleNoType before']);
    expect(listener.errors, isNull);
  }

  void test_parseTypeNotVoid() {
    final Token start = scanString('before ;').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(noType.parseTypeNotVoid(start, new Parser(listener)), start);
    expect(listener.calls, ['handleNoType before']);
    expect(listener.errors, isNull);
  }
}

@reflectiveTest
class VoidTypeInfoTest {
  void test_basic() {
    final Token start = scanString('before void ;').tokens;

    expect(voidType.skipType(start), start.next);
    expect(voidType.couldBeExpression, isFalse);
  }

  void test_compute() {
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

    expectInfo(voidType, 'void Function()', required: false);
    expectInfo(voidType, 'void Function<T>()', required: false);
    expectInfo(voidType, 'void Function(int)', required: false);
    expectInfo(voidType, 'void Function<T>(int)', required: false);
    expectInfo(voidType, 'void Function(int x)', required: false);
    expectInfo(voidType, 'void Function<T>(int x)', required: false);
  }

  void test_ensureTypeNotVoid() {
    final Token start = scanString('before void ;').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(voidType.ensureTypeNotVoid(start, new Parser(listener)), start.next);
    expect(listener.calls, [
      'handleIdentifier void typeReference',
      'handleNoTypeArguments ;',
      'handleType void null',
    ]);
    expect(listener.errors, [new ExpectedError(codeInvalidVoid, 7, 4)]);
  }

  void test_ensureTypeOrVoid() {
    final Token start = scanString('before void ;').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(voidType.parseType(start, new Parser(listener)), start.next);
    expect(listener.calls, ['handleVoidKeyword void']);
    expect(listener.errors, isNull);
  }

  void test_parseType() {
    final Token start = scanString('before void ;').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(voidType.parseType(start, new Parser(listener)), start.next);
    expect(listener.calls, ['handleVoidKeyword void']);
    expect(listener.errors, isNull);
  }

  void test_parseTypeNotVoid() {
    final Token start = scanString('before void ;').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(voidType.parseTypeNotVoid(start, new Parser(listener)), start.next);
    expect(listener.calls, [
      'handleIdentifier void typeReference',
      'handleNoTypeArguments ;',
      'handleType void null',
    ]);
    expect(listener.errors, [new ExpectedError(codeInvalidVoid, 7, 4)]);
  }
}

@reflectiveTest
class PrefixedTypeInfoTest {
  void test_compute() {
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
        'handleType C null',
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
}

@reflectiveTest
class SimpleNullableTypeTest {
  void test_compute() {
    expectInfo(simpleNullableType, 'C?', required: true);
    expectInfo(simpleNullableType, 'C?;', required: true);
    expectInfo(simpleNullableType, 'C?(', required: true);
    expectInfo(simpleNullableType, 'C?<', required: true);
    expectInfo(simpleNullableType, 'C?=', required: true);
    expectInfo(simpleNullableType, 'C?*', required: true);
    expectInfo(simpleNullableType, 'C? do', required: true);

    expectInfo(simpleNullableType, 'C? foo');
    expectInfo(simpleNullableType, 'C? get');
    expectInfo(simpleNullableType, 'C? set');
    expectInfo(simpleNullableType, 'C? operator');
    expectInfo(simpleNullableType, 'C? this');
    expectInfo(simpleNullableType, 'C? Function');

    expectInfo(simpleNullableType, 'C? Function()', required: false);
    expectInfo(simpleNullableType, 'C? Function<T>()', required: false);
    expectInfo(simpleNullableType, 'C? Function(int)', required: false);
    expectInfo(simpleNullableType, 'C? Function<T>(int)', required: false);
    expectInfo(simpleNullableType, 'C? Function(int x)', required: false);
    expectInfo(simpleNullableType, 'C? Function<T>(int x)', required: false);
  }

  void test_simpleNullableType() {
    final Token start = scanString('before C? ;').tokens;
    final Token expectedEnd = start.next.next;

    expect(simpleNullableType.skipType(start), expectedEnd);
    expect(simpleNullableType.couldBeExpression, isTrue);

    TypeInfoListener listener;
    assertResult(Token actualEnd) {
      expect(actualEnd, expectedEnd);
      expect(listener.calls, [
        'handleIdentifier C typeReference',
        'handleNoTypeArguments ?',
        'handleType C ?',
      ]);
      expect(listener.errors, isNull);
    }

    listener = new TypeInfoListener();
    assertResult(
        simpleNullableType.ensureTypeNotVoid(start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(
        simpleNullableType.ensureTypeOrVoid(start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(
        simpleNullableType.parseTypeNotVoid(start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(simpleNullableType.parseType(start, new Parser(listener)));
  }
}

@reflectiveTest
class SimpleNullableTypeWith1ArgumentTest {
  void test_compute() {
    expectInfo(simpleNullableTypeWith1Argument, 'C<T>?', required: true);
    expectInfo(simpleNullableTypeWith1Argument, 'C<T>?;', required: true);
    expectInfo(simpleNullableTypeWith1Argument, 'C<T>?(', required: true);
    expectInfo(simpleNullableTypeWith1Argument, 'C<T>? do', required: true);

    expectInfo(simpleNullableTypeWith1Argument, 'C<T>? foo');
    expectInfo(simpleNullableTypeWith1Argument, 'C<T>? get');
    expectInfo(simpleNullableTypeWith1Argument, 'C<T>? set');
    expectInfo(simpleNullableTypeWith1Argument, 'C<T>? operator');
    expectInfo(simpleNullableTypeWith1Argument, 'C<T>? Function');
  }

  void test_gt_questionMark() {
    final Token start = scanString('before C<T>? ;').tokens;
    final Token expectedEnd = start.next.next.next.next.next;
    expect(expectedEnd.lexeme, '?');

    expect(simpleNullableTypeWith1Argument.skipType(start), expectedEnd);
    expect(simpleNullableTypeWith1Argument.couldBeExpression, isFalse);

    TypeInfoListener listener;
    assertResult(Token actualEnd) {
      expect(actualEnd, expectedEnd);
      expect(listener.calls, [
        'handleIdentifier C typeReference',
        'beginTypeArguments <',
        'handleIdentifier T typeReference',
        'handleNoTypeArguments >',
        'handleType T null',
        'endTypeArguments 1 < >',
        'handleType C ?',
      ]);
      expect(listener.errors, isNull);
    }

    listener = new TypeInfoListener();
    assertResult(simpleNullableTypeWith1Argument.ensureTypeNotVoid(
        start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(simpleNullableTypeWith1Argument.ensureTypeOrVoid(
        start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(simpleNullableTypeWith1Argument.parseTypeNotVoid(
        start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(
        simpleNullableTypeWith1Argument.parseType(start, new Parser(listener)));
  }
}

@reflectiveTest
class SimpleTypeTest {
  void test_compute() {
    expectInfo(simpleType, 'C', required: true);
    expectInfo(simpleType, 'C;', required: true);
    expectInfo(simpleType, 'C(', required: true);
    expectInfo(simpleType, 'C<', required: true);
    expectComplexInfo('C.',
        required: true,
        couldBeExpression: true,
        expectedErrors: [error(codeExpectedType, 2, 0)]);
    expectInfo(simpleType, 'C=', required: true);
    expectInfo(simpleType, 'C*', required: true);
    expectInfo(simpleType, 'C do', required: true);

    expectInfo(simpleType, 'C foo');
    expectInfo(simpleType, 'C get');
    expectInfo(simpleType, 'C set');
    expectInfo(simpleType, 'C operator');
    expectInfo(simpleType, 'C this');
    expectInfo(simpleType, 'C Function');

    expectInfo(simpleType, 'C Function()', required: false);
    expectInfo(simpleType, 'C Function<T>()', required: false);
    expectInfo(simpleType, 'C Function(int)', required: false);
    expectInfo(simpleType, 'C Function<T>(int)', required: false);
    expectInfo(simpleType, 'C Function(int x)', required: false);
    expectInfo(simpleType, 'C Function<T>(int x)', required: false);
  }

  void test_simpleType() {
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
        'handleType C null',
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
}

@reflectiveTest
class SimpleTypeWith1ArgumentTest {
  void test_compute_gt() {
    expectInfo(simpleTypeWith1Argument, 'C<T>', required: true);
    expectInfo(simpleTypeWith1Argument, 'C<T>;', required: true);
    expectInfo(simpleTypeWith1Argument, 'C<T>(', required: true);
    expectInfo(simpleTypeWith1Argument, 'C<T> do', required: true);

    expectInfo(simpleTypeWith1Argument, 'C<T> foo');
    expectInfo(simpleTypeWith1Argument, 'C<T> get');
    expectInfo(simpleTypeWith1Argument, 'C<T> set');
    expectInfo(simpleTypeWith1Argument, 'C<T> operator');
    expectInfo(simpleTypeWith1Argument, 'C<T> Function');
  }

  void test_compute_gt_eq() {
    expectInfo(simpleTypeWith1ArgumentGtEq, 'C<T>=', required: true);
    expectInfo(simpleTypeWith1ArgumentGtEq, 'C<T>=;', required: true);
    expectInfo(simpleTypeWith1ArgumentGtEq, 'C<T>=(', required: true);
    expectInfo(simpleTypeWith1ArgumentGtEq, 'C<T>= do', required: true);

    expectInfo(simpleTypeWith1ArgumentGtEq, 'C<T>= foo', required: true);
    expectInfo(simpleTypeWith1ArgumentGtEq, 'C<T>= get', required: true);
    expectInfo(simpleTypeWith1ArgumentGtEq, 'C<T>= set', required: true);
    expectInfo(simpleTypeWith1ArgumentGtEq, 'C<T>= operator', required: true);
    expectInfo(simpleTypeWith1ArgumentGtEq, 'C<T>= Function', required: true);
  }

  void test_compute_gt_gt() {
    expectInfo(simpleTypeWith1ArgumentGtGt, 'C<T>>', required: true);
    expectInfo(simpleTypeWith1ArgumentGtGt, 'C<T>>;', required: true);
    expectInfo(simpleTypeWith1ArgumentGtGt, 'C<T>>(', required: true);
    expectInfo(simpleTypeWith1ArgumentGtGt, 'C<T>> do', required: true);

    expectInfo(simpleTypeWith1ArgumentGtGt, 'C<T>> foo', required: true);
    expectInfo(simpleTypeWith1ArgumentGtGt, 'C<T>> get', required: true);
    expectInfo(simpleTypeWith1ArgumentGtGt, 'C<T>> set', required: true);
    expectInfo(simpleTypeWith1ArgumentGtGt, 'C<T>> operator', required: true);
    expectInfo(simpleTypeWith1ArgumentGtGt, 'C<T>> Function', required: true);
  }

  void test_gt() {
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
        'handleType T null',
        'endTypeArguments 1 < >',
        'handleType C null',
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

  void test_gt_eq() {
    final Token start = scanString('before C<T>= ;').tokens;
    final Token t = start.next.next.next;
    final Token semicolon = t.next.next;
    expect(semicolon.lexeme, ';');

    Token skip = simpleTypeWith1ArgumentGtEq.skipType(start);
    expect(skip.lexeme, '>');
    expect(skip.next.lexeme, '=');
    expect(skip.next.next, semicolon);
    expect(simpleTypeWith1ArgumentGtEq.couldBeExpression, isFalse);

    TypeInfoListener listener;
    assertResult(Token actualEnd) {
      expect(actualEnd.lexeme, '>');
      expect(actualEnd.next.lexeme, '=');
      expect(actualEnd.next.next, semicolon);
      expect(listener.calls, [
        'handleIdentifier C typeReference',
        'beginTypeArguments <',
        'handleIdentifier T typeReference',
        'handleNoTypeArguments >',
        'handleType T null',
        'endTypeArguments 1 < >',
        'handleType C null',
      ]);
      expect(listener.errors, isNull);
    }

    listener = new TypeInfoListener();
    assertResult(simpleTypeWith1ArgumentGtEq.ensureTypeNotVoid(
        start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(simpleTypeWith1ArgumentGtEq.ensureTypeOrVoid(
        start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(simpleTypeWith1ArgumentGtEq.parseTypeNotVoid(
        start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(
        simpleTypeWith1ArgumentGtEq.parseType(start, new Parser(listener)));
  }

  void test_gt_gt() {
    final Token start = scanString('before C<T>> ;').tokens;
    final Token semicolon = start.next.next.next.next.next;
    expect(semicolon.lexeme, ';');

    Token skip = simpleTypeWith1ArgumentGtGt.skipType(start);
    expect(skip.lexeme, '>');
    expect(skip.next.lexeme, '>');
    expect(skip.next.next, semicolon);
    expect(simpleTypeWith1ArgumentGtGt.couldBeExpression, isFalse);

    TypeInfoListener listener;
    assertResult(Token actualEnd) {
      expect(actualEnd.lexeme, '>');
      expect(actualEnd.next.lexeme, '>');
      expect(actualEnd.next.next, semicolon);
      expect(listener.calls, [
        'handleIdentifier C typeReference',
        'beginTypeArguments <',
        'handleIdentifier T typeReference',
        'handleNoTypeArguments >',
        'handleType T null',
        'endTypeArguments 1 < >',
        'handleType C null',
      ]);
      expect(listener.errors, isNull);
    }

    listener = new TypeInfoListener();
    assertResult(simpleTypeWith1ArgumentGtGt.ensureTypeNotVoid(
        start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(simpleTypeWith1ArgumentGtGt.ensureTypeOrVoid(
        start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(simpleTypeWith1ArgumentGtGt.parseTypeNotVoid(
        start, new Parser(listener)));

    listener = new TypeInfoListener();
    assertResult(
        simpleTypeWith1ArgumentGtGt.parseType(start, new Parser(listener)));
  }
}

@reflectiveTest
class TypeInfoTest {
  void test_computeType_basic() {
    expectInfo(noType, '.', required: false);
    expectComplexInfo('.',
        required: true,
        couldBeExpression: true,
        expectedErrors: [
          error(codeExpectedType, 0, 1),
          error(codeExpectedType, 1, 0)
        ]);

    expectInfo(noType, '.Foo', required: false);
    expectComplexInfo('.Foo',
        required: true,
        couldBeExpression: true,
        expectedErrors: [error(codeExpectedType, 0, 1)]);
  }

  void test_computeType_builtin() {
    // Expect complex rather than simpleTypeInfo so that parseType reports
    // an error for the builtin used as a type.
    expectComplexInfo('abstract',
        required: true,
        couldBeExpression: true,
        expectedErrors: [error(codeBuiltInIdentifierAsType, 0, 8)]);
    expectComplexInfo('export',
        required: true,
        couldBeExpression: true,
        expectedErrors: [error(codeBuiltInIdentifierAsType, 0, 6)]);
    expectComplexInfo('abstract Function()',
        required: false,
        couldBeExpression: true,
        expectedAfter: 'Function',
        expectedErrors: [error(codeBuiltInIdentifierAsType, 0, 8)]);
    expectComplexInfo('export Function()',
        required: false,
        couldBeExpression: true,
        expectedAfter: 'Function',
        expectedErrors: [error(codeBuiltInIdentifierAsType, 0, 6)]);
  }

  void test_computeType_gft() {
    expectComplexInfo('Function() m', expectedAfter: 'm', expectedCalls: [
      'beginFunctionType Function',
      'handleNoTypeVariables (',
      'handleNoType ',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function null',
    ]);
    expectComplexInfo('Function<T>() m', expectedAfter: 'm', expectedCalls: [
      'beginFunctionType Function',
      'beginTypeVariables <',
      'beginMetadataStar T',
      'endMetadataStar 0',
      'handleIdentifier T typeVariableDeclaration',
      'beginTypeVariable T',
      'handleTypeVariablesDefined T 1',
      'handleNoType T',
      'endTypeVariable > 0 null null',
      'endTypeVariables < >',
      'handleNoType ',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function null',
    ]);
    expectComplexInfo('Function(int) m', expectedAfter: 'm', expectedCalls: [
      'beginFunctionType Function',
      'handleNoTypeVariables (',
      'handleNoType ',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'beginMetadataStar int',
      'endMetadataStar 0',
      'beginFormalParameter int MemberKind.GeneralizedFunctionType',
      'handleIdentifier int typeReference',
      'handleNoTypeArguments )',
      'handleType int null',
      'handleNoName )',
      'handleFormalParameterWithoutValue )',
      'endFormalParameter null null ) FormalParameterKind.mandatory '
          'MemberKind.GeneralizedFunctionType',
      'endFormalParameters 1 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function null',
    ]);
    expectComplexInfo('Function<T>(int) m', expectedAfter: 'm', expectedCalls: [
      'beginFunctionType Function',
      'beginTypeVariables <',
      'beginMetadataStar T',
      'endMetadataStar 0',
      'handleIdentifier T typeVariableDeclaration',
      'beginTypeVariable T',
      'handleTypeVariablesDefined T 1',
      'handleNoType T',
      'endTypeVariable > 0 null null',
      'endTypeVariables < >',
      'handleNoType ',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'beginMetadataStar int',
      'endMetadataStar 0',
      'beginFormalParameter int MemberKind.GeneralizedFunctionType',
      'handleIdentifier int typeReference',
      'handleNoTypeArguments )',
      'handleType int null',
      'handleNoName )',
      'handleFormalParameterWithoutValue )',
      'endFormalParameter null null ) FormalParameterKind.mandatory'
          ' MemberKind.GeneralizedFunctionType',
      'endFormalParameters 1 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function null',
    ]);

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

  void test_computeType_identifierComplex() {
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
          'beginFunctionType C',
          'handleNoTypeVariables (',
          'handleIdentifier C typeReference',
          'handleNoTypeArguments Function',
          'handleType C null',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
        ]);
  }

  void test_computeType_identifierComplex_questionMark() {
    expectComplexInfo('C? Function()', required: true, expectedCalls: [
      'beginFunctionType C',
      'handleNoTypeVariables (',
      'handleIdentifier C typeReference',
      'handleNoTypeArguments ?',
      'handleType C ?',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function null',
    ]);
  }

  void test_computeType_identifierComplex_questionMark2() {
    expectComplexInfo('C Function()?', required: true, expectedCalls: [
      'beginFunctionType C',
      'handleNoTypeVariables (',
      'handleIdentifier C typeReference',
      'handleNoTypeArguments Function',
      'handleType C null',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function ?',
    ]);
  }

  void test_computeType_identifierComplex_questionMark3() {
    expectComplexInfo('C<T>? Function()', required: true, expectedCalls: [
      'beginFunctionType C',
      'handleNoTypeVariables (',
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 1 < >',
      'handleType C ?',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function null',
    ]);
  }

  void test_computeType_identifierComplex_questionMark4() {
    expectComplexInfo('C<S,T>? Function()', required: true, expectedCalls: [
      'beginFunctionType C',
      'handleNoTypeVariables (',
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments ,',
      'handleType S null',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 2 < >',
      'handleType C ?',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function null',
    ]);
  }

  void test_computeType_identifierComplex_questionMark5() {
    expectComplexInfo('C Function()? Function()',
        required: true,
        expectedCalls: [
          'beginFunctionType C',
          'handleNoTypeVariables (',
          'beginFunctionType C',
          'handleNoTypeVariables (',
          'handleIdentifier C typeReference',
          'handleNoTypeArguments Function',
          'handleType C null',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function ?',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
        ]);
  }

  void test_computeType_identifierComplex_questionMark6() {
    expectComplexInfo('C Function() Function()?',
        required: true,
        expectedCalls: [
          'beginFunctionType C',
          'handleNoTypeVariables (',
          'beginFunctionType C',
          'handleNoTypeVariables (',
          'handleIdentifier C typeReference',
          'handleNoTypeArguments Function',
          'handleType C null',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function ?',
        ]);
  }

  void test_computeType_identifierComplex_questionMark7() {
    expectComplexInfo('C? Function() Function()?',
        required: true,
        expectedCalls: [
          'beginFunctionType C',
          'handleNoTypeVariables (',
          'beginFunctionType C',
          'handleNoTypeVariables (',
          'handleIdentifier C typeReference',
          'handleNoTypeArguments ?',
          'handleType C ?',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function ?',
        ]);
  }

  void test_computeType_identifierComplex_questionMark8() {
    expectComplexInfo('C Function()? Function()?',
        required: true,
        expectedCalls: [
          'beginFunctionType C',
          'handleNoTypeVariables (',
          'beginFunctionType C',
          'handleNoTypeVariables (',
          'handleIdentifier C typeReference',
          'handleNoTypeArguments Function',
          'handleType C null',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function ?',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function ?',
        ]);
  }

  void test_computeType_identifierComplex_questionMark9() {
    expectComplexInfo('C? Function()? Function()?',
        required: true,
        expectedCalls: [
          'beginFunctionType C',
          'handleNoTypeVariables (',
          'beginFunctionType C',
          'handleNoTypeVariables (',
          'handleIdentifier C typeReference',
          'handleNoTypeArguments ?',
          'handleType C ?',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function ?',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function ?',
        ]);
  }

  void test_computeType_identifierTypeArg() {
    expectComplexInfo('C<void>', required: true, expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleVoidKeyword void',
      'endTypeArguments 1 < >',
      'handleType C null',
    ]);
  }

  void test_computeType_identifierTypeArg_questionMark() {
    expectComplexInfo('C<void>?', required: true, expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleVoidKeyword void',
      'endTypeArguments 1 < >',
      'handleType C ?',
    ]);
  }

  void test_computeType_identifierTypeArgComplex() {
    expectComplexInfo('C<S,T>', required: true, expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments ,',
      'handleType S null',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 2 < >',
      'handleType C null',
    ]);
    expectComplexInfo('C<S<T>>', required: true, expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 1 < >',
      'handleType S null',
      'endTypeArguments 1 < >',
      'handleType C null',
    ]);
    expectComplexInfo('C<S,T> f', expectedAfter: 'f', expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments ,',
      'handleType S null',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 2 < >',
      'handleType C null',
    ]);
    expectComplexInfo('C<S<T>> f', expectedAfter: 'f', expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 1 < >',
      'handleType S null',
      'endTypeArguments 1 < >',
      'handleType C null',
    ]);
  }

  void test_computeType_identifierTypeArgComplex_questionMark() {
    expectComplexInfo('C<S,T>?', required: true, expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments ,',
      'handleType S null',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 2 < >',
      'handleType C ?',
    ]);
    expectComplexInfo('C<S,T?>', required: true, expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments ,',
      'handleType S null',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments ?',
      'handleType T ?',
      'endTypeArguments 2 < >',
      'handleType C null',
    ]);
    expectComplexInfo('C<S,T?>>',
        expectedAfter: '>',
        required: true,
        expectedCalls: [
          'handleIdentifier C typeReference',
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'handleNoTypeArguments ,',
          'handleType S null',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments ?',
          'handleType T ?',
          'endTypeArguments 2 < >',
          'handleType C null',
        ]);
    expectComplexInfo('C<S,T?>=',
        expectedAfter: '=',
        required: true,
        expectedCalls: [
          'handleIdentifier C typeReference',
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'handleNoTypeArguments ,',
          'handleType S null',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments ?',
          'handleType T ?',
          'endTypeArguments 2 < >',
          'handleType C null',
        ]);
    expectComplexInfo('C<S,T?>>>',
        expectedAfter: '>>',
        required: true,
        expectedCalls: [
          'handleIdentifier C typeReference',
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'handleNoTypeArguments ,',
          'handleType S null',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments ?',
          'handleType T ?',
          'endTypeArguments 2 < >',
          'handleType C null',
        ]);
    expectComplexInfo('C<S?,T>', required: true, expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments ?',
      'handleType S ?',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 2 < >',
      'handleType C null',
    ]);
    expectComplexInfo('C<S<T>>?', required: true, expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 1 < >',
      'handleType S null',
      'endTypeArguments 1 < >',
      'handleType C ?',
    ]);
    expectComplexInfo('C<S<T?>>', required: true, expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments ?',
      'handleType T ?',
      'endTypeArguments 1 < >',
      'handleType S null',
      'endTypeArguments 1 < >',
      'handleType C null',
    ]);
    expectComplexInfo('C<S<T?>>>',
        expectedAfter: '>',
        required: true,
        expectedCalls: [
          'handleIdentifier C typeReference',
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'beginTypeArguments <',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments ?',
          'handleType T ?',
          'endTypeArguments 1 < >',
          'handleType S null',
          'endTypeArguments 1 < >',
          'handleType C null',
        ]);
    expectComplexInfo('C<S,T>? f', expectedAfter: 'f', expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments ,',
      'handleType S null',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 2 < >',
      'handleType C ?',
    ]);
    expectComplexInfo('C<S<T>>? f', expectedAfter: 'f', expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 1 < >',
      'handleType S null',
      'endTypeArguments 1 < >',
      'handleType C ?',
    ]);
  }

  void test_computeType_identifierTypeArgGFT() {
    expectComplexInfo('C<T> Function(', // Scanner inserts synthetic ')'.
        required: true,
        expectedCalls: [
          'beginFunctionType C',
          'handleNoTypeVariables (',
          'handleIdentifier C typeReference',
          'beginTypeArguments <',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments >',
          'handleType T null',
          'endTypeArguments 1 < >',
          'handleType C null',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
        ]);
    expectComplexInfo('C<T> Function<T>(int x) Function<T>(int x)',
        required: false, expectedAfter: 'Function');
    expectComplexInfo('C<T> Function<T>(int x) Function<T>(int x)',
        required: true);
  }

  void test_computeType_identifierTypeArgRecovery() {
    // TODO(danrubel): dynamic, do, other keywords, malformed, recovery
    // <T>

    expectTypeParamOrArg(noTypeParamOrArg, 'G<int double> g');
    expectComplexInfo('G<int double> g',
        inDeclaration: true,
        expectedAfter: 'g',
        expectedCalls: [
          'handleIdentifier G typeReference',
          'beginTypeArguments <',
          'handleIdentifier int typeReference',
          'handleNoTypeArguments double' /* was , */,
          'handleType int null' /* was , */,
          'handleIdentifier double typeReference',
          'handleNoTypeArguments >',
          'handleType double null',
          'endTypeArguments 2 < >',
          'handleType G null',
        ],
        expectedErrors: [
          error(codeExpectedButGot, 6, 6)
        ]);

    expectInfo(noType, 'C<>', required: false);
    expectComplexInfo('C<>', required: true, expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier  typeReference',
      'handleNoTypeArguments >',
      'handleType  null',
      'endTypeArguments 1 < >',
      'handleType C null',
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
          'handleType  null',
          'endTypeArguments 1 < >',
          'handleType C null',
        ],
        expectedErrors: [
          error(codeExpectedType, 2, 1)
        ]);
  }

  void test_computeType_statements() {
    // Statements that should not have a type
    expectInfo(noType, 'C<T ; T>U;', required: false);
    expectInfo(noType, 'C<T && T>U;', required: false);
  }

  void test_computeType_nested() {
    expectNestedInfo(simpleType, '<T>');
    expectNestedInfo(simpleTypeWith1ArgumentGtGt, '<T<S>>');
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
          'beginFunctionType C',
          'handleNoTypeVariables (',
          'handleIdentifier C prefixedTypeReference',
          'handleIdentifier a typeReferenceContinuation',
          'handleQualified .',
          'handleNoTypeArguments Function',
          'handleType C null',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
        ]);
    expectComplexInfo('C.a Function<T>(int x) Function<T>(int x)',
        required: false, expectedAfter: 'Function');
    expectComplexInfo('C.a Function<T>(int x) Function<T>(int x)',
        required: true);
  }

  void test_computeType_prefixedGFT_questionMark() {
    expectComplexInfo('C.a? Function(', // Scanner inserts synthetic ')'.
        required: true,
        expectedCalls: [
          'beginFunctionType C',
          'handleNoTypeVariables (',
          'handleIdentifier C prefixedTypeReference',
          'handleIdentifier a typeReferenceContinuation',
          'handleQualified .',
          'handleNoTypeArguments ?',
          'handleType C ?',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
        ]);
    expectComplexInfo('C.a? Function<T>(int x) Function<T>(int x)',
        required: false, expectedAfter: 'Function');
    expectComplexInfo('C.a? Function<T>(int x) Function<T>(int x)',
        required: true);
  }

  void test_computeType_prefixedQuestionMark() {
    expectComplexInfo('C.a? Function',
        couldBeExpression: true,
        expectedAfter: 'Function',
        expectedCalls: [
          'handleIdentifier C prefixedTypeReference',
          'handleIdentifier a typeReferenceContinuation',
          'handleQualified .',
          'handleNoTypeArguments ?',
          'handleType C ?',
        ]);
  }

  void test_computeType_prefixedTypeArg() {
    expectComplexInfo('C.a<T>', required: true, expectedCalls: [
      'handleIdentifier C prefixedTypeReference',
      'handleIdentifier a typeReferenceContinuation',
      'handleQualified .',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 1 < >',
      'handleType C null',
    ]);

    expectComplexInfo('C.a<T> f', expectedAfter: 'f', expectedCalls: [
      'handleIdentifier C prefixedTypeReference',
      'handleIdentifier a typeReferenceContinuation',
      'handleQualified .',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 1 < >',
      'handleType C null',
    ]);
  }

  void test_computeType_prefixedTypeArgGFT() {
    expectComplexInfo('C.a<T> Function<T>(int x) Function<T>(int x)',
        required: true,
        expectedCalls: [
          'beginFunctionType C',
          'beginTypeVariables <',
          'beginMetadataStar T',
          'endMetadataStar 0',
          'handleIdentifier T typeVariableDeclaration',
          'beginTypeVariable T',
          'handleTypeVariablesDefined T 1',
          'handleNoType T',
          'endTypeVariable > 0 null null',
          'endTypeVariables < >',
          'beginFunctionType C',
          'beginTypeVariables <',
          'beginMetadataStar T',
          'endMetadataStar 0',
          'handleIdentifier T typeVariableDeclaration',
          'beginTypeVariable T',
          'handleTypeVariablesDefined T 1',
          'handleNoType T',
          'endTypeVariable > 0 null null',
          'endTypeVariables < >',
          'handleIdentifier C prefixedTypeReference',
          'handleIdentifier a typeReferenceContinuation',
          'handleQualified .',
          'beginTypeArguments <',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments >',
          'handleType T null',
          'endTypeArguments 1 < >',
          'handleType C null',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'beginMetadataStar int',
          'endMetadataStar 0',
          'beginFormalParameter int MemberKind.GeneralizedFunctionType',
          'handleIdentifier int typeReference',
          'handleNoTypeArguments x',
          'handleType int null',
          'handleIdentifier x formalParameterDeclaration',
          'handleFormalParameterWithoutValue )',
          'endFormalParameter null null x FormalParameterKind.mandatory '
              'MemberKind.GeneralizedFunctionType',
          'endFormalParameters 1 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'beginMetadataStar int',
          'endMetadataStar 0',
          'beginFormalParameter int MemberKind.GeneralizedFunctionType',
          'handleIdentifier int typeReference',
          'handleNoTypeArguments x',
          'handleType int null',
          'handleIdentifier x formalParameterDeclaration',
          'handleFormalParameterWithoutValue )',
          'endFormalParameter null null x FormalParameterKind.mandatory '
              'MemberKind.GeneralizedFunctionType',
          'endFormalParameters 1 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
        ]);
  }

  void test_computeType_void() {
    expectComplexInfo('void Function(', // Scanner inserts synthetic ')'.
        required: true,
        expectedCalls: [
          'beginFunctionType void',
          'handleNoTypeVariables (',
          'handleVoidKeyword void',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
        ]);
  }

  void test_computeType_voidComplex() {
    expectComplexInfo('void Function()', required: true, expectedCalls: [
      'beginFunctionType void',
      'handleNoTypeVariables (',
      'handleVoidKeyword void',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function null',
    ]);

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
class NoTypeParamOrArgTest {
  void test_basic() {
    expect(noTypeParamOrArg.isSimpleTypeArgument, isFalse);
    expect(noTypeParamOrArg.typeArgumentCount, 0);

    final Token start = scanString('before after').tokens;
    expect(noTypeParamOrArg.skip(start), start);
    validateTokens(start);
  }

  void test_compute() {
    expectTypeParamOrArg(noTypeParamOrArg, '');
    expectTypeParamOrArg(noTypeParamOrArg, 'a');
    expectTypeParamOrArg(noTypeParamOrArg, 'a b');
    expectTypeParamOrArg(noTypeParamOrArg, '<');
    expectTypeParamOrArg(noTypeParamOrArg, '< b');
    expectTypeParamOrArg(noTypeParamOrArg, '< 3 >');
    expectTypeParamOrArg(noTypeParamOrArg, '< (');
    expectTypeParamOrArg(noTypeParamOrArg, '< (', inDeclaration: true);
  }

  void test_parseArguments() {
    final Token start = scanString('before after').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(noTypeParamOrArg.parseArguments(start, new Parser(listener)), start);
    validateTokens(start);
    expect(listener.calls, ['handleNoTypeArguments after']);
    expect(listener.errors, isNull);
  }

  void test_parseVariables() {
    final Token start = scanString('before after').tokens;
    final TypeInfoListener listener = new TypeInfoListener();

    expect(noTypeParamOrArg.parseVariables(start, new Parser(listener)), start);
    validateTokens(start);
    expect(listener.calls, ['handleNoTypeVariables after']);
    expect(listener.errors, isNull);
  }
}

@reflectiveTest
class SimpleTypeParamOrArgTest {
  void test_basic_gt() {
    expect(simpleTypeArgument1.isSimpleTypeArgument, isTrue);
    expect(simpleTypeArgument1.typeArgumentCount, 1);
    expect(simpleTypeArgument1.typeInfo, simpleTypeWith1Argument);

    final Token start = scanString('before <T> after').tokens;
    final Token gt = start.next.next.next;
    expect(gt.lexeme, '>');

    Token skip = simpleTypeArgument1.skip(start);
    validateTokens(start);
    expect(skip, gt);
  }

  void test_basic_gt_eq() {
    expect(simpleTypeArgument1GtEq.isSimpleTypeArgument, isTrue);
    expect(simpleTypeArgument1GtEq.typeArgumentCount, 1);
    expect(simpleTypeArgument1GtEq.typeInfo, simpleTypeWith1ArgumentGtEq);

    final Token start = scanString('before <T>= after').tokens;
    Token t = start.next.next;
    expect(t.next.lexeme, '>=');

    Token skip = simpleTypeArgument1GtEq.skip(start);
    validateTokens(start);
    expect(skip.lexeme, '>');
    expect(skip.next.lexeme, '=');
    expect(skip.next.next, t.next.next);
  }

  void test_basic_gt_gt() {
    expect(simpleTypeArgument1GtGt.isSimpleTypeArgument, isTrue);
    expect(simpleTypeArgument1GtGt.typeArgumentCount, 1);
    expect(simpleTypeArgument1GtGt.typeInfo, simpleTypeWith1ArgumentGtGt);

    final Token start = scanString('before <S<T>> after').tokens.next.next;
    var gtgt = start.next.next.next;
    expect(gtgt.lexeme, '>>');
    Token after = gtgt.next;
    expect(after.lexeme, 'after');

    Token skip = simpleTypeArgument1GtGt.skip(start);
    validateTokens(start);
    expect(skip.lexeme, '>');
    expect(skip.next.lexeme, '>');
    expect(skip.next.next, after);
  }

  void test_compute_gt() {
    expectTypeParamOrArg(simpleTypeArgument1, '<T>');
  }

  void test_compute_gt_eq() {
    expectTypeParamOrArg(simpleTypeArgument1GtEq, '<T>=');
  }

  void test_compute_gt_gt() {
    String source = '<C<T>>';
    Token start = scan(source).next.next;
    expect(start.lexeme, 'C');
    Token gtgt = start.next.next.next;
    expect(gtgt.lexeme, '>>');

    expect(computeTypeParamOrArg(start, false), simpleTypeArgument1GtGt);
    validateTokens(start);
  }

  void testParseArguments(TypeParamOrArgInfo typeArg, String source,
      [String next]) {
    final Token start = scanString('before $source after').tokens;
    final Token after = start.next.next.next.next;
    expect(after.lexeme, 'after');
    final TypeInfoListener listener = new TypeInfoListener();

    var token = typeArg.parseArguments(start, new Parser(listener));
    validateTokens(start);
    expect(token.lexeme, '>');
    token = token.next;
    if (next != null) {
      expect(token.lexeme, next);
      token = token.next;
    }
    expect(token, after);
    expect(listener.calls, [
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 1 < >'
    ]);
    expect(listener.errors, isNull);
  }

  void test_parseArguments_gt() {
    testParseArguments(simpleTypeArgument1, '<T>');
  }

  void test_parseArguments_gt_eq() {
    testParseArguments(simpleTypeArgument1GtEq, '<T>=', '=');
  }

  void test_parseArguments_gt_gt() {
    testParseArguments(simpleTypeArgument1GtGt, '<T>>', '>');
  }

  void testParseVariables(TypeParamOrArgInfo typeParam, String source,
      [String next]) {
    final Token start = scanString('before $source after').tokens;
    final Token after = start.next.next.next.next;
    expect(after.lexeme, 'after');
    final TypeInfoListener listener = new TypeInfoListener();

    Token token = typeParam.parseVariables(start, new Parser(listener));
    validateTokens(start);
    expect(token.lexeme, '>');
    token = token.next;
    if (next != null) {
      expect(token.lexeme, next);
      token = token.next;
    }
    expect(token, after);
    expect(listener.calls, [
      'beginTypeVariables <',
      'beginMetadataStar T',
      'endMetadataStar 0',
      'handleIdentifier T typeVariableDeclaration',
      'beginTypeVariable T',
      'handleTypeVariablesDefined T 1',
      'handleNoType T',
      'endTypeVariable > 0 null null',
      'endTypeVariables < >',
    ]);
    expect(listener.errors, isNull);
  }

  void test_parseVariables_gt() {
    testParseVariables(simpleTypeArgument1, '<T>');
  }

  void test_parseVariables_gt_eq() {
    testParseVariables(simpleTypeArgument1GtEq, '<T>=', '=');
  }

  void test_parseVariables_gt_gt() {
    testParseVariables(simpleTypeArgument1GtGt, '<T>>', '>');
  }
}

@reflectiveTest
class TypeParamOrArgInfoTest {
  void test_computeTypeArg_complex() {
    expectComplexTypeArg('<S,T>', typeArgumentCount: 2, expectedCalls: [
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments ,',
      'handleType S null',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 2 < >'
    ]);
    expectComplexTypeArg('<S,T>=',
        typeArgumentCount: 2,
        expectedAfter: '=',
        expectedCalls: [
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'handleNoTypeArguments ,',
          'handleType S null',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments >=',
          'handleType T null',
          'endTypeArguments 2 < >'
        ]);
    expectComplexTypeArg('<S,T>>=',
        typeArgumentCount: 2,
        expectedAfter: '>=',
        expectedCalls: [
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'handleNoTypeArguments ,',
          'handleType S null',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments >>=',
          'handleType T null',
          'endTypeArguments 2 < >'
        ]);
    expectComplexTypeArg('<S Function()>',
        typeArgumentCount: 1,
        expectedCalls: [
          'beginTypeArguments <',
          'beginFunctionType S',
          'handleNoTypeVariables (',
          'handleIdentifier S typeReference',
          'handleNoTypeArguments Function',
          'handleType S null',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
          'endTypeArguments 1 < >'
        ]);
    expectComplexTypeArg('<void Function()>',
        typeArgumentCount: 1,
        expectedCalls: [
          'beginTypeArguments <',
          'beginFunctionType void',
          'handleNoTypeVariables (',
          'handleVoidKeyword void',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
          'endTypeArguments 1 < >'
        ]);
    expectComplexTypeArg('<S<T>>', typeArgumentCount: 1, expectedCalls: [
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 1 < >',
      'handleType S null',
      'endTypeArguments 1 < >'
    ]);
    expectComplexTypeArg('<S<T>>=',
        typeArgumentCount: 1,
        expectedAfter: '=',
        expectedCalls: [
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'beginTypeArguments <',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments >>=',
          'handleType T null',
          'endTypeArguments 1 < >',
          'handleType S null',
          'endTypeArguments 1 < >'
        ]);
    expectComplexTypeArg('<S<T<U>>>', typeArgumentCount: 1, expectedCalls: [
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'beginTypeArguments <',
      'handleIdentifier U typeReference',
      'handleNoTypeArguments >>>',
      'handleType U null',
      'endTypeArguments 1 < >',
      'handleType T null',
      'endTypeArguments 1 < >',
      'handleType S null',
      'endTypeArguments 1 < >'
    ]);
    expectComplexTypeArg('<S<T<U,V>>>', typeArgumentCount: 1, expectedCalls: [
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'beginTypeArguments <',
      'handleIdentifier U typeReference',
      'handleNoTypeArguments ,',
      'handleType U null',
      'handleIdentifier V typeReference',
      'handleNoTypeArguments >>>',
      'handleType V null',
      'endTypeArguments 2 < >',
      'handleType T null',
      'endTypeArguments 1 < >',
      'handleType S null',
      'endTypeArguments 1 < >'
    ]);
    expectComplexTypeArg('<S<T<U>>>=',
        typeArgumentCount: 1,
        expectedAfter: '=',
        expectedCalls: [
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'beginTypeArguments <',
          'handleIdentifier T typeReference',
          'beginTypeArguments <',
          'handleIdentifier U typeReference',
          'handleNoTypeArguments >>>=',
          'handleType U null',
          'endTypeArguments 1 < >',
          'handleType T null',
          'endTypeArguments 1 < >',
          'handleType S null',
          'endTypeArguments 1 < >'
        ]);
    expectComplexTypeArg('<S<T<U,V>>>=',
        typeArgumentCount: 1,
        expectedAfter: '=',
        expectedCalls: [
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'beginTypeArguments <',
          'handleIdentifier T typeReference',
          'beginTypeArguments <',
          'handleIdentifier U typeReference',
          'handleNoTypeArguments ,',
          'handleType U null',
          'handleIdentifier V typeReference',
          'handleNoTypeArguments >>>=',
          'handleType V null',
          'endTypeArguments 2 < >',
          'handleType T null',
          'endTypeArguments 1 < >',
          'handleType S null',
          'endTypeArguments 1 < >'
        ]);
    expectComplexTypeArg('<S<Function()>>',
        typeArgumentCount: 1,
        expectedCalls: [
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'beginTypeArguments <',
          'beginFunctionType Function',
          'handleNoTypeVariables (',
          'handleNoType <',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
          'endTypeArguments 1 < >',
          'handleType S null',
          'endTypeArguments 1 < >'
        ]);
    expectComplexTypeArg('<S<Function()>>=',
        typeArgumentCount: 1,
        expectedAfter: '=',
        expectedCalls: [
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'beginTypeArguments <',
          'beginFunctionType Function',
          'handleNoTypeVariables (',
          'handleNoType <',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
          'endTypeArguments 1 < >',
          'handleType S null',
          'endTypeArguments 1 < >'
        ]);
    expectComplexTypeArg('<S<void Function()>>',
        typeArgumentCount: 1,
        expectedCalls: [
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'beginTypeArguments <',
          'beginFunctionType void', // was 'beginFunctionType Function'
          'handleNoTypeVariables (',
          'handleVoidKeyword void', // was 'handleNoType <'
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
          'endTypeArguments 1 < >',
          'handleType S null',
          'endTypeArguments 1 < >'
        ]);
    expectComplexTypeArg('<S<T<void Function()>>>',
        typeArgumentCount: 1,
        expectedCalls: [
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'beginTypeArguments <',
          'handleIdentifier T typeReference',
          'beginTypeArguments <',
          'beginFunctionType void', // was 'beginFunctionType Function'
          'handleNoTypeVariables (',
          'handleVoidKeyword void', // was 'handleNoType <'
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
          'endTypeArguments 1 < >',
          'handleType T null',
          'endTypeArguments 1 < >',
          'handleType S null',
          'endTypeArguments 1 < >'
        ]);
    expectComplexTypeArg('<S<T<void Function()>>>=',
        typeArgumentCount: 1,
        expectedAfter: '=',
        expectedCalls: [
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'beginTypeArguments <',
          'handleIdentifier T typeReference',
          'beginTypeArguments <',
          'beginFunctionType void', // was 'beginFunctionType Function'
          'handleNoTypeVariables (',
          'handleVoidKeyword void', // was 'handleNoType <'
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
          'endTypeArguments 1 < >',
          'handleType T null',
          'endTypeArguments 1 < >',
          'handleType S null',
          'endTypeArguments 1 < >'
        ]);
  }

  void test_computeTypeArg_complex_recovery() {
    expectComplexTypeArg('<S extends T>',
        typeArgumentCount: 1,
        expectedErrors: [
          error(codeExpectedAfterButGot, 1, 1)
        ],
        expectedCalls: [
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'handleNoTypeArguments extends',
          'handleType S null',
          'endTypeArguments 1 < >',
        ]);
    expectComplexTypeArg('<S extends List<T>>',
        typeArgumentCount: 1,
        expectedErrors: [
          error(codeExpectedAfterButGot, 1, 1)
        ],
        expectedCalls: [
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'handleNoTypeArguments extends',
          'handleType S null',
          'endTypeArguments 1 < >',
        ]);
    expectComplexTypeArg('<@A S,T>', typeArgumentCount: 2, expectedErrors: [
      error(codeAnnotationOnTypeArgument, 1, 2)
    ], expectedCalls: [
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments ,',
      'handleType S null',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 2 < >'
    ]);
    expectComplexTypeArg('<@A() S,T>', typeArgumentCount: 2, expectedErrors: [
      error(codeAnnotationOnTypeArgument, 1, 4)
    ], expectedCalls: [
      'beginTypeArguments <',
      'handleIdentifier S typeReference',
      'handleNoTypeArguments ,',
      'handleType S null',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T null',
      'endTypeArguments 2 < >'
    ]);
    expectComplexTypeArg('<@A() @B S,T>',
        typeArgumentCount: 2,
        expectedErrors: [
          error(codeAnnotationOnTypeArgument, 1, 4),
          error(codeAnnotationOnTypeArgument, 6, 2),
        ],
        expectedCalls: [
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'handleNoTypeArguments ,',
          'handleType S null',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments >',
          'handleType T null',
          'endTypeArguments 2 < >'
        ]);
    expectComplexTypeArg('<S T>',
        inDeclaration: true,
        typeArgumentCount: 2,
        expectedErrors: [error(codeExpectedButGot, 3, 1)]);
    expectComplexTypeArg('<S',
        inDeclaration: true,
        typeArgumentCount: 1,
        expectedErrors: [error(codeExpectedAfterButGot, 1, 1)]);
    expectComplexTypeArg('<@Foo S',
        inDeclaration: true,
        typeArgumentCount: 1,
        expectedErrors: [
          error(codeAnnotationOnTypeArgument, 1, 4),
          error(codeExpectedAfterButGot, 6, 1)
        ]);
    expectComplexTypeArg('<S<T',
        inDeclaration: true,
        typeArgumentCount: 1,
        expectedErrors: [
          error(codeExpectedAfterButGot, 3, 1)
        ],
        expectedCalls: [
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'beginTypeArguments <',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments ',
          'handleType T null',
          'endTypeArguments 1 < >',
          'handleType S null',
          'endTypeArguments 1 < >'
        ]);
  }

  void test_computeTypeParam_complex() {
    expectComplexTypeParam('<S,T>', typeArgumentCount: 2, expectedCalls: [
      'beginTypeVariables <',
      'beginMetadataStar S',
      'endMetadataStar 0',
      'handleIdentifier S typeVariableDeclaration',
      'beginTypeVariable S',
      'beginMetadataStar T',
      'endMetadataStar 0',
      'handleIdentifier T typeVariableDeclaration',
      'beginTypeVariable T',
      'handleTypeVariablesDefined T 2',
      'handleNoType T',
      'endTypeVariable > 1 null null',
      'handleNoType S',
      'endTypeVariable , 0 null null',
      'endTypeVariables < >',
    ]);
    expectComplexTypeParam('<S extends T>',
        typeArgumentCount: 1,
        expectedCalls: [
          'beginTypeVariables <',
          'beginMetadataStar S',
          'endMetadataStar 0',
          'handleIdentifier S typeVariableDeclaration',
          'beginTypeVariable S',
          'handleTypeVariablesDefined T 1',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments >',
          'handleType T null',
          'endTypeVariable > 0 extends null',
          'endTypeVariables < >',
        ]);
    expectComplexTypeParam('<S extends List<T>>',
        typeArgumentCount: 1,
        expectedCalls: [
          'beginTypeVariables <',
          'beginMetadataStar S',
          'endMetadataStar 0',
          'handleIdentifier S typeVariableDeclaration',
          'beginTypeVariable S',
          'handleTypeVariablesDefined > 1',
          'handleIdentifier List typeReference',
          'beginTypeArguments <',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments >',
          'handleType T null',
          'endTypeArguments 1 < >',
          'handleType List null',
          'endTypeVariable > 0 extends null',
          'endTypeVariables < >',
        ]);
    expectComplexTypeParam('<R, S extends void Function()>',
        typeArgumentCount: 2,
        expectedCalls: [
          'beginTypeVariables <',
          'beginMetadataStar R',
          'endMetadataStar 0',
          'handleIdentifier R typeVariableDeclaration',
          'beginTypeVariable R',
          'beginMetadataStar S',
          'endMetadataStar 0',
          'handleIdentifier S typeVariableDeclaration',
          'beginTypeVariable S',
          'handleTypeVariablesDefined ) 2',
          'beginFunctionType void',
          'handleNoTypeVariables (',
          'handleVoidKeyword void',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
          'endTypeVariable > 1 extends null',
          'handleNoType R',
          'endTypeVariable , 0 null null',
          'endTypeVariables < >',
        ]);
    expectComplexTypeParam('<@A S,T>', typeArgumentCount: 2, expectedCalls: [
      'beginTypeVariables <',
      'beginMetadataStar @',
      'beginMetadata @',
      'handleIdentifier A metadataReference',
      'handleNoTypeArguments S',
      'handleNoArguments S',
      'endMetadata @ null S',
      'endMetadataStar 1',
      'handleIdentifier S typeVariableDeclaration',
      'beginTypeVariable S',
      'beginMetadataStar T',
      'endMetadataStar 0',
      'handleIdentifier T typeVariableDeclaration',
      'beginTypeVariable T',
      'handleTypeVariablesDefined T 2',
      'handleNoType T',
      'endTypeVariable > 1 null null',
      'handleNoType S',
      'endTypeVariable , 0 null null',
      'endTypeVariables < >',
    ]);
    expectComplexTypeParam('<@A() S,T>', typeArgumentCount: 2, expectedCalls: [
      'beginTypeVariables <',
      'beginMetadataStar @',
      'beginMetadata @',
      'handleIdentifier A metadataReference',
      'handleNoTypeArguments (',
      'beginArguments (',
      'endArguments 0 ( )',
      'endMetadata @ null S',
      'endMetadataStar 1',
      'handleIdentifier S typeVariableDeclaration',
      'beginTypeVariable S',
      'beginMetadataStar T',
      'endMetadataStar 0',
      'handleIdentifier T typeVariableDeclaration',
      'beginTypeVariable T',
      'handleTypeVariablesDefined T 2',
      'handleNoType T',
      'endTypeVariable > 1 null null',
      'handleNoType S',
      'endTypeVariable , 0 null null',
      'endTypeVariables < >',
    ]);
    expectComplexTypeParam('<@A() @B S,T>',
        typeArgumentCount: 2,
        expectedCalls: [
          'beginTypeVariables <',
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
          'beginTypeVariable S',
          'beginMetadataStar T',
          'endMetadataStar 0',
          'handleIdentifier T typeVariableDeclaration',
          'beginTypeVariable T',
          'handleTypeVariablesDefined T 2',
          'handleNoType T',
          'endTypeVariable > 1 null null',
          'handleNoType S',
          'endTypeVariable , 0 null null',
          'endTypeVariables < >',
        ]);
  }

  void test_computeTypeParam_complex_extends_void() {
    expectComplexTypeParam('<T extends void>',
        typeArgumentCount: 1,
        expectedErrors: [
          error(codeInvalidVoid, 11, 4),
        ],
        expectedCalls: [
          'beginTypeVariables <',
          'beginMetadataStar T',
          'endMetadataStar 0',
          'handleIdentifier T typeVariableDeclaration',
          'beginTypeVariable T',
          'handleTypeVariablesDefined void 1',
          'handleIdentifier void typeReference',
          'handleNoTypeArguments >',
          'handleType void null',
          'endTypeVariable > 0 extends null',
          'endTypeVariables < >'
        ]);
  }

  void test_computeTypeParam_complex_recovery() {
    expectComplexTypeParam('<S Function()>',
        typeArgumentCount: 1,
        expectedErrors: [
          error(codeExpectedAfterButGot, 1, 1),
        ],
        expectedCalls: [
          'beginTypeVariables <',
          'beginMetadataStar S',
          'endMetadataStar 0',
          'handleIdentifier S typeVariableDeclaration',
          'beginTypeVariable S',
          'handleTypeVariablesDefined S 1',
          'handleNoType S',
          'endTypeVariable Function 0 null null',
          'endTypeVariables < >',
        ]);
    expectComplexTypeParam('<void Function()>',
        typeArgumentCount: 1,
        expectedErrors: [
          error(codeExpectedIdentifier, 1, 4),
        ],
        expectedCalls: [
          'beginTypeVariables <',
          'beginMetadataStar void',
          'endMetadataStar 0',
          'handleIdentifier  typeVariableDeclaration',
          'beginTypeVariable ',
          'handleTypeVariablesDefined  1',
          'handleNoType ',
          'endTypeVariable void 0 null null',
          'endTypeVariables < >',
        ]);
    expectComplexTypeParam('<S<T>>', typeArgumentCount: 1, expectedErrors: [
      error(codeExpectedAfterButGot, 1, 1),
    ], expectedCalls: [
      'beginTypeVariables <',
      'beginMetadataStar S',
      'endMetadataStar 0',
      'handleIdentifier S typeVariableDeclaration',
      'beginTypeVariable S',
      'handleTypeVariablesDefined S 1',
      'handleNoType S',
      'endTypeVariable < 0 null null',
      'endTypeVariables < >',
    ]);
    expectComplexTypeParam('<S T>',
        inDeclaration: true,
        typeArgumentCount: 2,
        expectedErrors: [
          error(codeExpectedButGot, 3, 1),
        ]);
    expectComplexTypeParam('<S',
        inDeclaration: true,
        typeArgumentCount: 1,
        expectedErrors: [
          error(codeExpectedAfterButGot, 1, 1),
        ]);
    expectComplexTypeParam('<@Foo S',
        inDeclaration: true,
        typeArgumentCount: 1,
        expectedErrors: [error(codeExpectedAfterButGot, 6, 1)]);
    expectComplexTypeParam('<@Foo }',
        inDeclaration: true,
        typeArgumentCount: 0,
        expectedAfter: '}',
        expectedErrors: [error(codeExpectedIdentifier, 6, 1)]);
    expectComplexTypeParam('<S extends List<T fieldName;',
        inDeclaration: true,
        typeArgumentCount: 1,
        expectedErrors: [error(codeExpectedAfterButGot, 16, 1)],
        expectedAfter: 'fieldName',
        expectedCalls: [
          'beginTypeVariables <',
          'beginMetadataStar S',
          'endMetadataStar 0',
          'handleIdentifier S typeVariableDeclaration',
          'beginTypeVariable S',
          'handleTypeVariablesDefined > 1',
          'handleIdentifier List typeReference',
          'beginTypeArguments <',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments fieldName',
          'handleType T null',
          'endTypeArguments 1 < >',
          'handleType List null',
          'endTypeVariable fieldName 0 extends null',
          'endTypeVariables < >',
        ]);
  }

  void test_computeTypeParam_31846() {
    expectComplexTypeParam('<T extends Comparable<T>>',
        typeArgumentCount: 1,
        expectedCalls: [
          'beginTypeVariables <',
          'beginMetadataStar T',
          'endMetadataStar 0',
          'handleIdentifier T typeVariableDeclaration',
          'beginTypeVariable T',
          'handleTypeVariablesDefined > 1',
          'handleIdentifier Comparable typeReference',
          'beginTypeArguments <',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments >',
          'handleType T null',
          'endTypeArguments 1 < >',
          'handleType Comparable null',
          'endTypeVariable > 0 extends null',
          'endTypeVariables < >',
        ]);
    expectComplexTypeParam('<T extends Comparable<S>, S>',
        typeArgumentCount: 2,
        expectedCalls: [
          'beginTypeVariables <',
          'beginMetadataStar T',
          'endMetadataStar 0',
          'handleIdentifier T typeVariableDeclaration',
          'beginTypeVariable T',
          'beginMetadataStar S',
          'endMetadataStar 0',
          'handleIdentifier S typeVariableDeclaration',
          'beginTypeVariable S',
          'handleTypeVariablesDefined S 2',
          'handleNoType S',
          'endTypeVariable > 1 null null',
          'handleIdentifier Comparable typeReference',
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'handleNoTypeArguments >',
          'handleType S null',
          'endTypeArguments 1 < >',
          'handleType Comparable null',
          'endTypeVariable , 0 extends null',
          'endTypeVariables < >'
        ]);
    expectComplexTypeParam('<T extends Function(T)>',
        typeArgumentCount: 1,
        expectedCalls: [
          'beginTypeVariables <',
          'beginMetadataStar T',
          'endMetadataStar 0',
          'handleIdentifier T typeVariableDeclaration',
          'beginTypeVariable T',
          'handleTypeVariablesDefined ) 1',
          'beginFunctionType Function',
          'handleNoTypeVariables (',
          'handleNoType extends',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'beginMetadataStar T',
          'endMetadataStar 0',
          'beginFormalParameter T MemberKind.GeneralizedFunctionType',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments )',
          'handleType T null',
          'handleNoName )',
          'handleFormalParameterWithoutValue )',
          'endFormalParameter null null ) FormalParameterKind.mandatory '
              'MemberKind.GeneralizedFunctionType',
          'endFormalParameters 1 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function null',
          'endTypeVariable > 0 extends null',
          'endTypeVariables < >'
        ]);
    expectComplexTypeParam('<T extends List<List<T>>>',
        typeArgumentCount: 1,
        expectedCalls: [
          'beginTypeVariables <',
          'beginMetadataStar T',
          'endMetadataStar 0',
          'handleIdentifier T typeVariableDeclaration',
          'beginTypeVariable T',
          'handleTypeVariablesDefined > 1',
          'handleIdentifier List typeReference',
          'beginTypeArguments <',
          'handleIdentifier List typeReference',
          'beginTypeArguments <',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments >>>',
          'handleType T null',
          'endTypeArguments 1 < >',
          'handleType List null',
          'endTypeArguments 1 < >',
          'handleType List null',
          'endTypeVariable > 0 extends null',
          'endTypeVariables < >'
        ]);
    expectComplexTypeParam('<T extends List<Map<S, T>>>',
        typeArgumentCount: 1,
        expectedCalls: [
          'beginTypeVariables <',
          'beginMetadataStar T',
          'endMetadataStar 0',
          'handleIdentifier T typeVariableDeclaration',
          'beginTypeVariable T',
          'handleTypeVariablesDefined > 1',
          'handleIdentifier List typeReference',
          'beginTypeArguments <',
          'handleIdentifier Map typeReference',
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'handleNoTypeArguments ,',
          'handleType S null',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments >>>',
          'handleType T null',
          'endTypeArguments 2 < >',
          'handleType Map null',
          'endTypeArguments 1 < >',
          'handleType List null',
          'endTypeVariable > 0 extends null',
          'endTypeVariables < >'
        ]);
    expectComplexTypeParam('<T extends List<Map<S, T>>>=',
        typeArgumentCount: 1,
        expectedAfter: '=',
        expectedCalls: [
          'beginTypeVariables <',
          'beginMetadataStar T',
          'endMetadataStar 0',
          'handleIdentifier T typeVariableDeclaration',
          'beginTypeVariable T',
          'handleTypeVariablesDefined > 1',
          'handleIdentifier List typeReference',
          'beginTypeArguments <',
          'handleIdentifier Map typeReference',
          'beginTypeArguments <',
          'handleIdentifier S typeReference',
          'handleNoTypeArguments ,',
          'handleType S null',
          'handleIdentifier T typeReference',
          'handleNoTypeArguments >>>=',
          'handleType T null',
          'endTypeArguments 2 < >',
          'handleType Map null',
          'endTypeArguments 1 < >',
          'handleType List null',
          'endTypeVariable >= 0 extends null',
          'endTypeVariables < >'
        ]);
  }

  void test_computeTypeParam_34850() {
    expectComplexTypeParam('<S<T>> A',
        typeArgumentCount: 1,
        expectedAfter: 'A',
        expectedErrors: [
          error(codeExpectedAfterButGot, 1, 1),
        ],
        expectedCalls: [
          'beginTypeVariables <',
          'beginMetadataStar S',
          'endMetadataStar 0',
          'handleIdentifier S typeVariableDeclaration',
          'beginTypeVariable S',
          'handleTypeVariablesDefined S 1',
          'handleNoType S',
          'endTypeVariable < 0 null null',
          'endTypeVariables < >',
        ]);
    expectComplexTypeParam('<S();> A',
        inDeclaration: true,
        typeArgumentCount: 1,
        expectedAfter: 'A',
        expectedErrors: [
          error(codeExpectedAfterButGot, 1, 1),
        ],
        expectedCalls: [
          'beginTypeVariables <',
          'beginMetadataStar S',
          'endMetadataStar 0',
          'handleIdentifier S typeVariableDeclaration',
          'beginTypeVariable S',
          'handleTypeVariablesDefined S 1',
          'handleNoType S',
          'endTypeVariable ( 0 null null',
          'endTypeVariables < >',
        ]);
  }
}

@reflectiveTest
class CouldBeExpressionTest {
  void couldBeExpression(String code, bool expected) {
    final typeInfo = computeType(scan(code), true);
    expect(typeInfo.couldBeExpression, expected);
  }

  void test_simple() {
    couldBeExpression('S', true);
  }

  void test_simple_nullable() {
    couldBeExpression('S?', true);
  }

  void test_partial() {
    couldBeExpression('.S', true);
  }

  void test_partial_nullable() {
    couldBeExpression('.S?', true);
  }

  void test_prefixed() {
    couldBeExpression('p.S', true);
  }

  void test_prefixed_nullable() {
    couldBeExpression('p.S?', true);
  }

  void test_typeArg() {
    couldBeExpression('S<T>', false);
  }

  void test_typeArg_nullable() {
    couldBeExpression('S<T>?', false);
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
    bool inDeclaration = false,
    bool couldBeExpression = false,
    String expectedAfter,
    List<String> expectedCalls,
    List<ExpectedError> expectedErrors}) {
  if (required == null) {
    computeComplex(source, scan(source), true, inDeclaration, couldBeExpression,
        expectedAfter, expectedCalls, expectedErrors);
    computeComplex(source, scan(source), false, inDeclaration,
        couldBeExpression, expectedAfter, expectedCalls, expectedErrors);
  } else {
    computeComplex(source, scan(source), required, inDeclaration,
        couldBeExpression, expectedAfter, expectedCalls, expectedErrors);
  }
}

void expectNestedInfo(expectedInfo, String source) {
  expect(source.startsWith('<'), isTrue);
  Token start = scan(source).next;
  compute(expectedInfo, source, start, true);
}

void expectNestedComplexInfo(String source) {
  expectNestedInfo(const TypeMatcher<ComplexTypeInfo>(), source);
}

TypeInfo compute(expectedInfo, String source, Token start, bool required,
    {bool inDeclaration = false}) {
  int expectedGtGtAndNullEndCount = countGtGtAndNullEnd(start);
  TypeInfo typeInfo = computeType(start, required, inDeclaration);
  expect(typeInfo, expectedInfo, reason: source);
  expect(countGtGtAndNullEnd(start), expectedGtGtAndNullEndCount,
      reason: 'computeType should not modify the token stream');
  return typeInfo;
}

ComplexTypeInfo computeComplex(
    String source,
    Token start,
    bool required,
    bool inDeclaration,
    bool couldBeExpression,
    String expectedAfter,
    List<String> expectedCalls,
    List<ExpectedError> expectedErrors) {
  int expectedGtGtAndNullEndCount = countGtGtAndNullEnd(start);
  ComplexTypeInfo typeInfo = compute(
      const TypeMatcher<ComplexTypeInfo>(), source, start, required,
      inDeclaration: inDeclaration);
  expect(typeInfo.start, start.next, reason: source);
  expect(typeInfo.couldBeExpression, couldBeExpression);
  expectEnd(expectedAfter, typeInfo.skipType(start));
  expect(countGtGtAndNullEnd(start), expectedGtGtAndNullEndCount,
      reason: 'TypeInfo.skipType should not modify the token stream');

  TypeInfoListener listener = new TypeInfoListener();
  Token actualEnd = typeInfo.parseType(start, new Parser(listener));

  expectEnd(expectedAfter, actualEnd);
  if (expectedCalls != null) {
    expect(listener.calls, expectedCalls, reason: source);
  }
  expect(listener.errors, expectedErrors, reason: source);
  return typeInfo;
}

void expectComplexTypeArg(String source,
    {bool inDeclaration = false,
    int typeArgumentCount = -1,
    String expectedAfter,
    List<String> expectedCalls,
    List<ExpectedError> expectedErrors}) {
  Token start = scan(source);
  int expectedGtGtAndNullEndCount = countGtGtAndNullEnd(start);
  ComplexTypeParamOrArgInfo typeVarInfo = computeVar(
      const TypeMatcher<ComplexTypeParamOrArgInfo>(),
      source,
      start,
      inDeclaration);

  expect(typeVarInfo.start, start.next, reason: source);
  expectEnd(expectedAfter, typeVarInfo.skip(start));
  validateTokens(start);
  expect(countGtGtAndNullEnd(start), expectedGtGtAndNullEndCount,
      reason: 'TypeParamOrArgInfo.skipType'
          ' should not modify the token stream');
  expect(typeVarInfo.typeArgumentCount, typeArgumentCount);

  TypeInfoListener listener = new TypeInfoListener();
  Parser parser = new Parser(listener);
  Token actualEnd = typeVarInfo.parseArguments(start, parser);
  validateTokens(start);
  expectEnd(expectedAfter, actualEnd);

  if (expectedCalls != null) {
    expect(listener.calls, expectedCalls, reason: source);
  }
  expect(listener.errors, expectedErrors, reason: source);
}

void expectComplexTypeParam(String source,
    {bool inDeclaration = false,
    int typeArgumentCount = -1,
    String expectedAfter,
    List<String> expectedCalls,
    List<ExpectedError> expectedErrors}) {
  Token start = scan(source);
  int expectedGtGtAndNullEndCount = countGtGtAndNullEnd(start);
  ComplexTypeParamOrArgInfo typeVarInfo = computeVar(
      const TypeMatcher<ComplexTypeParamOrArgInfo>(),
      source,
      start,
      inDeclaration);

  expect(typeVarInfo.start, start.next, reason: source);
  expectEnd(expectedAfter, typeVarInfo.skip(start));
  validateTokens(start);
  expect(countGtGtAndNullEnd(start), expectedGtGtAndNullEndCount,
      reason: 'TypeParamOrArgInfo.skipType'
          ' should not modify the token stream');
  expect(typeVarInfo.typeArgumentCount, typeArgumentCount);

  TypeInfoListener listener =
      new TypeInfoListener(firstToken: start, metadataAllowed: true);
  Parser parser = new Parser(listener);
  Token actualEnd = typeVarInfo.parseVariables(start, parser);
  validateTokens(start);
  expectEnd(expectedAfter, actualEnd);

  if (expectedCalls != null) {
    expect(listener.calls, expectedCalls, reason: source);
  }
  expect(listener.errors, expectedErrors, reason: source);
}

void expectTypeParamOrArg(expectedInfo, String source,
    {bool inDeclaration = false,
    String expectedAfter,
    List<String> expectedCalls,
    List<ExpectedError> expectedErrors}) {
  Token start = scan(source);
  computeVar(expectedInfo, source, start, inDeclaration);
}

TypeParamOrArgInfo computeVar(
    expectedInfo, String source, Token start, bool inDeclaration) {
  int expectedGtGtAndNullEndCount = countGtGtAndNullEnd(start);
  TypeParamOrArgInfo typeVarInfo = computeTypeParamOrArg(start, inDeclaration);
  validateTokens(start);
  expect(typeVarInfo, expectedInfo, reason: source);
  expect(countGtGtAndNullEnd(start), expectedGtGtAndNullEndCount,
      reason: 'computeTypeParamOrArg should not modify the token stream');
  return typeVarInfo;
}

void expectEnd(String tokenAfter, Token end) {
  if (tokenAfter == null) {
    expect(end.isEof, isFalse);
    if (!end.next.isEof) {
      fail('Expected EOF after $end but found ${end.next}');
    }
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

void validateTokens(Token token) {
  int count = 0;
  if (token.isEof && !token.next.isEof) {
    token = token.next;
  }
  while (!token.isEof) {
    Token next = token.next;
    expect(token.charOffset, lessThanOrEqualTo(next.charOffset));
    expect(next.previous, token, reason: next.type.toString());
    if (next is SyntheticToken) {
      expect(next.beforeSynthetic, token);
    }
    expect(count, lessThanOrEqualTo(10000));
    token = next;
    ++count;
  }
}

class TypeInfoListener implements Listener {
  final bool metadataAllowed;
  List<String> calls = <String>[];
  List<ExpectedError> errors;
  Token firstToken;

  TypeInfoListener({this.firstToken, this.metadataAllowed: false}) {
    if (firstToken != null && firstToken.isEof) {
      firstToken = firstToken.next;
    }
  }

  @override
  void beginArguments(Token token) {
    if (metadataAllowed) {
      calls.add('beginArguments $token');
    } else {
      throw 'beginArguments should not be called.';
    }
  }

  @override
  void beginFormalParameter(Token token, MemberKind kind, Token requiredToken,
      Token covariantToken, Token varFinalOrConst) {
    // TODO(danrubel): Update tests to include required and covariant
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
  void endFormalParameter(
      Token thisKeyword,
      Token periodAfterThis,
      Token nameToken,
      Token initializerStart,
      Token initializerEnd,
      FormalParameterKind kind,
      MemberKind memberKind) {
    calls.add('endFormalParameter $thisKeyword $periodAfterThis '
        '$nameToken $kind $memberKind');
  }

  @override
  void endFunctionType(Token functionToken, Token questionMark) {
    calls.add('endFunctionType $functionToken $questionMark');
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
    assertTokenInStream(beginToken);
    assertTokenInStream(endToken);
  }

  @override
  void endTypeVariable(
      Token token, int index, Token extendsOrSuper, Token variance) {
    calls.add('endTypeVariable $token $index $extendsOrSuper $variance');
    assertTokenInStream(token);
    assertTokenInStream(extendsOrSuper);
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    calls.add('endTypeVariables $beginToken $endToken');
    assertTokenInStream(beginToken);
    assertTokenInStream(endToken);
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
  void handleType(Token beginToken, Token questionMark) {
    calls.add('handleType $beginToken $questionMark');
  }

  @override
  void handleTypeVariablesDefined(Token token, int count) {
    calls.add('handleTypeVariablesDefined $token $count');
  }

  @override
  void handleVoidKeyword(Token token) {
    calls.add('handleVoidKeyword $token');
  }

  @override
  void handleVoidKeywordWithTypeArguments(Token token) {
    calls.add('handleVoidKeywordWithTypeArguments $token');
  }

  noSuchMethod(Invocation invocation) {
    throw '${invocation.memberName} should not be called.';
  }

  assertTokenInStream(Token match) {
    if (firstToken != null && match != null && !match.isEof) {
      Token token = firstToken;
      while (!token.isEof) {
        if (identical(token, match)) {
          return;
        }
        token = token.next;
      }
      final msg = new StringBuffer();
      msg.writeln('Expected $match in token stream, but found');
      while (!token.isEof) {
        msg.write(' $token');
        token = token.next;
      }
      fail(msg.toString());
    }
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
