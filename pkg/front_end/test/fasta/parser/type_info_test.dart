// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/messages.dart';
import 'package:front_end/src/fasta/parser.dart';
import 'package:front_end/src/fasta/parser/type_info.dart';
import 'package:front_end/src/fasta/scanner.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TokenInfoTest);
  });
}

@reflectiveTest
class TokenInfoTest {
  void test_noType() {
    TypeInfo typeInfo = noTypeInfo;
    Token start = scanString('before ;').tokens;
    Token expectedEnd = start;
    expect(typeInfo.skipType(start), expectedEnd);

    TypeInfoListener listener = new TypeInfoListener();
    expect(typeInfo.parseType(start, new Parser(listener)), expectedEnd);
    expect(listener.calls, ['handleNoType before']);
  }

  void test_voidType() {
    TypeInfo typeInfo = voidTypeInfo;
    Token start = scanString('before void ;').tokens;
    Token expectedEnd = start.next;
    expect(typeInfo.skipType(start), expectedEnd);

    TypeInfoListener listener = new TypeInfoListener();
    expect(typeInfo.parseType(start, new Parser(listener)), expectedEnd);
    expect(listener.calls, ['handleVoidKeyword void']);
  }

  void test_prefixedTypeInfo() {
    TypeInfo typeInfo = prefixedTypeInfo;
    Token start = scanString('before C.a ;').tokens;
    Token expectedEnd = start.next.next.next;
    expect(typeInfo.skipType(start), expectedEnd);

    TypeInfoListener listener = new TypeInfoListener();
    expect(typeInfo.parseType(start, new Parser(listener)), expectedEnd);
    expect(listener.calls, [
      'handleIdentifier C prefixedTypeReference',
      'handleIdentifier a typeReferenceContinuation',
      'handleQualified .',
      'handleNoTypeArguments ;',
      'handleType C ;',
    ]);
  }

  void test_simpleTypeInfo() {
    TypeInfo typeInfo = simpleTypeInfo;
    Token start = scanString('before C ;').tokens;
    Token expectedEnd = start.next;
    expect(typeInfo.skipType(start), expectedEnd);

    TypeInfoListener listener = new TypeInfoListener();
    expect(typeInfo.parseType(start, new Parser(listener)), expectedEnd);
    expect(listener.calls, [
      'handleIdentifier C typeReference',
      'handleNoTypeArguments ;',
      'handleType C ;',
    ]);
  }

  void test_simpleTypeArgumentsInfo() {
    TypeInfo typeInfo = simpleTypeArgumentsInfo;
    Token start = scanString('before C<T> ;').tokens;
    Token expectedEnd = start.next.next.next.next;
    expect(typeInfo.skipType(start), expectedEnd);

    TypeInfoListener listener = new TypeInfoListener();
    expect(typeInfo.parseType(start, new Parser(listener)), expectedEnd);
    expect(listener.calls, [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier T typeReference',
      'handleNoTypeArguments >',
      'handleType T >',
      'endTypeArguments 1 < >',
      'handleType C ;',
    ]);
  }

  void test_computeType() {
    Token scan(String source) {
      Token start = scanString(source).tokens;
      while (start is ErrorToken) {
        start = start.next;
      }
      return new SyntheticToken(TokenType.EOF, 0)..setNext(start);
    }

    void expectEnd(String tokenAfter, Token end) {
      if (tokenAfter == null) {
        expect(end.isEof, isFalse);
        expect(end.next.isEof, isTrue);
      } else {
        expect(end.next.lexeme, tokenAfter);
      }
    }

    void compute(expectedInfo, String source, Token start, bool required,
        String expectedAfter, List<String> expectedCalls) {
      TypeInfo typeInfo = computeType(start, required);
      expect(typeInfo, expectedInfo, reason: source);
      if (typeInfo is ComplexTypeInfo) {
        TypeInfoListener listener = new TypeInfoListener();
        Parser parser = new Parser(listener);
        expect(typeInfo.start, start.next, reason: source);
        expectEnd(expectedAfter, typeInfo.skipType(start));
        expectEnd(expectedAfter, typeInfo.parseType(start, parser));
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
      }
    }

    void t(expectedInfo, String source,
        {bool required, String expectedAfter, List<String> expectedCalls}) {
      Token start = scan(source);
      if (required == null) {
        compute(
            expectedInfo, source, start, true, expectedAfter, expectedCalls);
        compute(
            expectedInfo, source, start, false, expectedAfter, expectedCalls);
      } else {
        compute(expectedInfo, source, start, required, expectedAfter,
            expectedCalls);
      }
    }

    void tComplex(String source,
        {bool required, String tokenAfter, List<String> expectedCalls}) {
      t(const isInstanceOf<ComplexTypeInfo>(), source,
          required: required,
          expectedAfter: tokenAfter,
          expectedCalls: expectedCalls);
    }

    t(noTypeInfo, '');
    t(noTypeInfo, ';');
    t(noTypeInfo, '( foo');
    t(noTypeInfo, '< foo');
    t(noTypeInfo, '= foo');
    t(noTypeInfo, '* foo');
    t(noTypeInfo, 'do foo');
    t(noTypeInfo, 'get foo');
    t(noTypeInfo, 'set foo');
    t(noTypeInfo, 'operator *');

    // TOOD(danrubel): dynamic, do, other keywords, malformed, recovery
    // <T>

    t(voidTypeInfo, 'void');
    t(voidTypeInfo, 'void;');
    t(voidTypeInfo, 'void(');
    t(voidTypeInfo, 'void<');
    t(voidTypeInfo, 'void=');
    t(voidTypeInfo, 'void*');
    t(voidTypeInfo, 'void<T>');
    t(voidTypeInfo, 'void do');
    t(voidTypeInfo, 'void foo');
    t(voidTypeInfo, 'void get');
    t(voidTypeInfo, 'void set');
    t(voidTypeInfo, 'void operator');
    t(voidTypeInfo, 'void Function');
    tComplex('void Function(', // Scanner inserts synthetic ')'.
        expectedCalls: [
          'handleNoTypeVariables (',
          'beginFunctionType void',
          'handleVoidKeyword void',
          'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
          'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
          'endFunctionType Function ',
        ]);

    t(noTypeInfo, 'C', required: false);
    t(noTypeInfo, 'C;', required: false);
    t(noTypeInfo, 'C(', required: false);
    t(noTypeInfo, 'C<', required: false);
    t(noTypeInfo, 'C.', required: false);
    t(noTypeInfo, 'C=', required: false);
    t(noTypeInfo, 'C*', required: false);
    t(noTypeInfo, 'C do', required: false);

    t(simpleTypeInfo, 'C', required: true);
    t(simpleTypeInfo, 'C;', required: true);
    t(simpleTypeInfo, 'C(', required: true);
    t(simpleTypeInfo, 'C<', required: true);
    t(simpleTypeInfo, 'C.', required: true);
    t(simpleTypeInfo, 'C=', required: true);
    t(simpleTypeInfo, 'C*', required: true);
    t(simpleTypeInfo, 'C do', required: true);

    t(noTypeInfo, 'C<>', required: false);
    tComplex('C<>', required: true, expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier  typeReference',
      'handleNoTypeArguments >',
      'handleType > >',
      'endTypeArguments 1 < >',
      'handleType C ',
    ]);
    tComplex('C<> f', required: true, tokenAfter: 'f', expectedCalls: [
      'handleIdentifier C typeReference',
      'beginTypeArguments <',
      'handleIdentifier  typeReference',
      'handleNoTypeArguments >',
      'handleType > >',
      'endTypeArguments 1 < >',
      'handleType C f',
    ]);

    t(simpleTypeInfo, 'C foo');
    t(simpleTypeInfo, 'C get');
    t(simpleTypeInfo, 'C set');
    t(simpleTypeInfo, 'C operator');
    t(simpleTypeInfo, 'C this');
    t(simpleTypeInfo, 'C Function');
    tComplex('C Function(', // Scanner inserts synthetic ')'.
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

    t(noTypeInfo, 'C<T>', required: false);
    t(noTypeInfo, 'C<T>;', required: false);
    t(noTypeInfo, 'C<T>(', required: false);
    t(noTypeInfo, 'C<T> do', required: false);

    t(simpleTypeArgumentsInfo, 'C<T>', required: true);
    t(simpleTypeArgumentsInfo, 'C<T>;', required: true);
    t(simpleTypeArgumentsInfo, 'C<T>(', required: true);
    t(simpleTypeArgumentsInfo, 'C<T> do', required: true);

    t(simpleTypeArgumentsInfo, 'C<T> foo');
    t(simpleTypeArgumentsInfo, 'C<T> get');
    t(simpleTypeArgumentsInfo, 'C<T> set');
    t(simpleTypeArgumentsInfo, 'C<T> operator');
    t(simpleTypeArgumentsInfo, 'C<T> Function');
    tComplex('C<T> Function(', // Scanner inserts synthetic ')'.
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

    // Statements that should not have a type
    t(noTypeInfo, 'C<T ; T>U;', required: false);
    t(noTypeInfo, 'C<T && T>U;', required: false);

    t(noTypeInfo, 'C.a', required: false);
    t(noTypeInfo, 'C.a;', required: false);
    t(noTypeInfo, 'C.a(', required: false);
    t(noTypeInfo, 'C.a<', required: false);
    t(noTypeInfo, 'C.a=', required: false);
    t(noTypeInfo, 'C.a*', required: false);
    t(noTypeInfo, 'C.a do', required: false);

    t(prefixedTypeInfo, 'C.a', required: true);
    t(prefixedTypeInfo, 'C.a;', required: true);
    t(prefixedTypeInfo, 'C.a(', required: true);
    t(prefixedTypeInfo, 'C.a<', required: true);
    t(prefixedTypeInfo, 'C.a=', required: true);
    t(prefixedTypeInfo, 'C.a*', required: true);
    t(prefixedTypeInfo, 'C.a do', required: true);

    t(prefixedTypeInfo, 'C.a foo');
    t(prefixedTypeInfo, 'C.a get');
    t(prefixedTypeInfo, 'C.a set');
    t(prefixedTypeInfo, 'C.a operator');
    t(prefixedTypeInfo, 'C.a Function');
    tComplex('C.a Function(', // Scanner inserts synthetic ')'.
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

    t(noTypeInfo, 'C<S,T>', required: false);
    t(noTypeInfo, 'C<S<T>>', required: false);
    t(noTypeInfo, 'C.a<T>', required: false);

    tComplex('C<S,T>', required: true, expectedCalls: [
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
    tComplex('C<S<T>>', required: true, expectedCalls: [
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
    tComplex('C.a<T>', required: true, expectedCalls: [
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

    tComplex('C<S,T> f', tokenAfter: 'f', expectedCalls: [
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
    tComplex('C<S<T>> f', tokenAfter: 'f', expectedCalls: [
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
    tComplex('C.a<T> f', tokenAfter: 'f', expectedCalls: [
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

    tComplex('Function()', expectedCalls: [
      'handleNoTypeVariables (',
      'beginFunctionType Function',
      'handleNoType ',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function ',
    ]);
    tComplex('Function<T>()', expectedCalls: [
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
      'endFunctionType Function ',
    ]);
    tComplex('Function(int)', expectedCalls: [
      'handleNoTypeVariables (',
      'beginFunctionType Function',
      'handleNoType ',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'beginMetadataStar int',
      'endMetadataStar 0',
      'beginFormalParameter int MemberKind.GeneralizedFunctionType',
      'handleModifiers 0',
      'handleIdentifier int typeReference',
      'handleNoTypeArguments )',
      'handleType int )',
      'handleNoName )',
      'handleFormalParameterWithoutValue )',
      'beginTypeVariables null null ) FormalParameterKind.mandatory '
          'MemberKind.GeneralizedFunctionType',
      'endFormalParameters 1 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function ',
    ]);
    tComplex('Function<T>(int)', expectedCalls: [
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
      'handleModifiers 0',
      'handleIdentifier int typeReference',
      'handleNoTypeArguments )',
      'handleType int )',
      'handleNoName )',
      'handleFormalParameterWithoutValue )',
      'beginTypeVariables null null ) FormalParameterKind.mandatory MemberKind.GeneralizedFunctionType',
      'endFormalParameters 1 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function ',
    ]);
    tComplex('Function(int x)');
    tComplex('Function<T>(int x)');
    tComplex('Function<T>(int x) Function<T>(int x)');

    tComplex('C Function()');
    tComplex('C Function<T>()');
    tComplex('C Function(int)');
    tComplex('C Function<T>(int)');
    tComplex('C Function(int x)');
    tComplex('C Function<T>(int x)');
    tComplex('C Function<T>(int x) Function<T>(int x)');
    tComplex('C.a Function<T>(int x) Function<T>(int x)');
    tComplex('C<T> Function<T>(int x) Function<T>(int x)');
    tComplex('C.a<T> Function<T>(int x) Function<T>(int x)', expectedCalls: [
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
      'handleModifiers 0',
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
      'handleModifiers 0',
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

    tComplex('void Function()', expectedCalls: [
      'handleNoTypeVariables (',
      'beginFunctionType void',
      'handleVoidKeyword void',
      'beginFormalParameters ( MemberKind.GeneralizedFunctionType',
      'endFormalParameters 0 ( ) MemberKind.GeneralizedFunctionType',
      'endFunctionType Function ',
    ]);
    tComplex('void Function<T>()');
    tComplex('void Function(int)');
    tComplex('void Function<T>(int)');
    tComplex('void Function(int x)');
    tComplex('void Function<T>(int x)');
    tComplex('void Function<T>(int x) Function<T>(int x)');
  }
}

class TypeInfoListener implements Listener {
  List<String> calls = <String>[];

  @override
  void beginFormalParameter(Token token, MemberKind kind) {
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
  void handleModifiers(int count) {
    calls.add('handleModifiers $count');
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
    // ignored
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
