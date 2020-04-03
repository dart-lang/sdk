// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_ranking_internal.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  group('getCursorToken', () {
    MockCompletionRequest request;
    MockCompletionTarget target;

    setUp(() {
      request = MockCompletionRequest();
      target = MockCompletionTarget();
      when(request.target).thenReturn(target);
    });

    test('areCompletionsEquivalent exact match', () {
      expect(areCompletionsEquivalent('foo', 'foo'), equals(true));
    });

    test('areCompletionsEquivalent function call', () {
      expect(areCompletionsEquivalent('foo()', 'foo'), equals(true));
    });

    test('areCompletionsEquivalent field name', () {
      expect(areCompletionsEquivalent('foo: ,', 'foo'), equals(true));
    });

    test('areCompletionsEquivalent different name', () {
      expect(areCompletionsEquivalent('foo', 'fooBar'), equals(false));
    });

    test('areCompletionsEquivalent method invocation', () {
      expect(areCompletionsEquivalent('foo.bar()', 'foo'), equals(false));
    });

    test('getCursorToken AstNode', () {
      final node = MockAstNode();
      final token = MockToken();
      when(target.entity).thenReturn(node);
      when(node.endToken).thenReturn(token);
      expect(getCursorToken(request), equals(token));
    });

    test('getCursorToken Token', () {
      final token = MockToken();
      when(target.entity).thenReturn(token);
      expect(getCursorToken(request), equals(token));
    });

    test('getCursorToken null', () {
      when(target.entity).thenReturn(null);
      expect(getCursorToken(request), equals(null));
    });
  });

  test('isStopToken null', () {
    expect(isStopToken(null, 5), equals(true));
  });

  test('isStopToken synthetic', () {
    final token = MockToken();
    when(token.isSynthetic).thenReturn(true);
    when(token.isEof).thenReturn(false);
    expect(isStopToken(token, 5), equals(false));
  });

  test('isStopToken punctuation', () {
    final token = MockToken();
    when(token.isSynthetic).thenReturn(false);
    when(token.offset).thenReturn(4);
    when(token.length).thenReturn(1);
    when(token.lexeme).thenReturn(')');
    expect(isStopToken(token, 5), equals(true));
  });

  test('isStopToken alphabetic', () {
    final token = MockToken();
    when(token.isSynthetic).thenReturn(false);
    when(token.offset).thenReturn(2);
    when(token.length).thenReturn(3);
    when(token.lexeme).thenReturn('foo');
    expect(isStopToken(token, 5), equals(false));
  });

  test('isStringLiteral null', () {
    expect(isStringLiteral(null), equals(false));
  });

  test('isStringLiteral empty string', () {
    expect(isStringLiteral(''), equals(false));
  });

  test('isStringLiteral basic', () {
    expect(isStringLiteral("'foo'"), equals(true));
  });

  test('isStringLiteral raw', () {
    expect(isStringLiteral("r'foo'"), equals(true));
  });

  test('isLiteral string', () {
    expect(isLiteral("'foo'"), equals(true));
  });

  test('isLiteral numeric', () {
    expect(isLiteral('12345'), equals(true));
  });

  test('isLiteral not literal', () {
    expect(isLiteral('foo'), equals(false));
  });

  test('isTokenDot dot', () {
    final token = MockToken();
    when(token.isSynthetic).thenReturn(false);
    when(token.lexeme).thenReturn('.');
    expect(isTokenDot(token), equals(true));
  });

  test('isTokenDot not dot', () {
    final token = MockToken();
    when(token.isSynthetic).thenReturn(false);
    when(token.lexeme).thenReturn('foo');
    expect(isTokenDot(token), equals(false));
  });

  test('isTokenDot synthetic', () {
    final token = MockToken();
    when(token.isSynthetic).thenReturn(true);
    expect(isTokenDot(token), false);
  });

  test('getCurrentToken', () {
    final one = MockToken();
    final two = MockToken();
    final three = MockToken();
    when(three.previous).thenReturn(two);
    when(two.previous).thenReturn(one);
    final request = MockCompletionRequest();
    final target = MockCompletionTarget();
    when(request.offset).thenReturn(2);
    when(request.target).thenReturn(target);
    when(target.entity).thenReturn(three);
    when(two.isSynthetic).thenReturn(true);
    when(two.isEof).thenReturn(false);
    when(one.isSynthetic).thenReturn(false);
    when(one.offset).thenReturn(1);
    when(one.length).thenReturn(3);
    when(one.lexeme).thenReturn('foo');
    expect(getCurrentToken(request), equals(one));
  });

  test('constructQuery', () {
    final start = MockToken();
    when(start.isSynthetic).thenReturn(true);
    when(start.isEof).thenReturn(true);
    final one = MockToken();
    when(one.lexeme).thenReturn('class');
    when(one.offset).thenReturn(0);
    when(one.length).thenReturn(5);
    when(one.isSynthetic).thenReturn(false);
    when(one.isEof).thenReturn(false);
    when(one.type).thenReturn(Keyword.CLASS);
    final two = MockToken();
    when(two.lexeme).thenReturn('Animal');
    when(two.offset).thenReturn(6);
    when(two.length).thenReturn(6);
    when(two.isSynthetic).thenReturn(false);
    when(one.previous).thenReturn(start);
    when(two.previous).thenReturn(one);
    when(two.type).thenReturn(TokenType.IDENTIFIER);
    when(two.isEof).thenReturn(false);
    final request = MockCompletionRequest();
    final target = MockCompletionTarget();
    when(request.offset).thenReturn(13);
    when(request.target).thenReturn(target);
    when(target.entity).thenReturn(two);
    expect(constructQuery(request, 100), equals(['class', 'Animal']));
  });

  test('constructQuery cursor over paren', () {
    final start = MockToken();
    when(start.isSynthetic).thenReturn(true);
    when(start.isEof).thenReturn(true);
    final one = MockToken();
    when(one.lexeme).thenReturn('main');
    when(one.offset).thenReturn(0);
    when(one.length).thenReturn(4);
    when(one.isSynthetic).thenReturn(false);
    when(one.isEof).thenReturn(false);
    when(one.type).thenReturn(TokenType.IDENTIFIER);
    final two = MockToken();
    when(two.lexeme).thenReturn('(');
    when(two.offset).thenReturn(5);
    when(two.length).thenReturn(1);
    when(two.isSynthetic).thenReturn(false);
    when(one.previous).thenReturn(start);
    when(two.previous).thenReturn(one);
    when(two.type).thenReturn(TokenType.OPEN_PAREN);
    when(two.isEof).thenReturn(false);
    final request = MockCompletionRequest();
    final target = MockCompletionTarget();
    when(request.offset).thenReturn(6);
    when(request.target).thenReturn(target);
    when(target.entity).thenReturn(two);
    expect(constructQuery(request, 50), equals(['main', '(']));
  });

  test('elementNameFromRelevanceTag', () {
    final tag =
        'package::flutter/src/widgets/preferred_size.dart::::PreferredSizeWidget';
    expect(elementNameFromRelevanceTag(tag), equals('PreferredSizeWidget'));
  });

  test('selectStringLiterals', () {
    final result = selectStringLiterals([
      MapEntry('foo', 0.2),
      MapEntry("'bar'", 0.3),
      MapEntry('\'baz\'', 0.1),
      MapEntry("'qu\'ux'", 0.4),
    ]);
    expect(result[0].key, equals('bar'));
    expect(result[1].key, equals('baz'));
    expect(result[2].key, equals('qu\'ux'));
    expect(result, hasLength(3));
  });

  test('testNamedArgument', () {
    expect(testNamedArgument([]), equals(false));
    expect(testNamedArgument(null), equals(false));
    expect(
        testNamedArgument([
          CompletionSuggestion(CompletionSuggestionKind.NAMED_ARGUMENT, 1,
              'title: ,', 8, 0, false, false)
        ]),
        equals(true));
    expect(
        testNamedArgument([
          CompletionSuggestion(
              CompletionSuggestionKind.IDENTIFIER, 1, 'foo', 3, 0, false, false)
        ]),
        equals(false));
    expect(
        testNamedArgument([
          CompletionSuggestion(CompletionSuggestionKind.NAMED_ARGUMENT, 1,
              'title: ,', 8, 0, false, false),
          CompletionSuggestion(CompletionSuggestionKind.IDENTIFIER, 1, 'foo', 3,
              0, false, false),
        ]),
        equals(true));
  });
}

class MockAstNode extends Mock implements AstNode {}

class MockCompletionRequest extends Mock implements DartCompletionRequest {}

class MockCompletionTarget extends Mock implements CompletionTarget {}

class MockToken extends Mock implements Token {}
