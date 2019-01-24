// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/messages.dart';
import 'package:front_end/src/fasta/parser.dart';
import 'package:front_end/src/fasta/scanner.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CollectionElementTest);
    defineReflectiveTests(MapElementTest);
  });
}

@reflectiveTest
class CollectionElementTest {
  test_closingBrace() {
    parseEntry(
      'before }',
      [
        'handleIdentifier  expression',
        'handleNoTypeArguments }',
        'handleNoArguments }',
        'handleSend  }',
      ],
      errors: [error(codeExpectedIdentifier, 7, 1)],
      expectAfter: '}',
    );
  }

  test_comma() {
    parseEntry(
      'before ,',
      [
        'handleIdentifier  expression',
        'handleNoTypeArguments ,',
        'handleNoArguments ,',
        'handleSend  ,',
      ],
      errors: [error(codeExpectedIdentifier, 7, 1)],
      expectAfter: ',',
    );
  }

  test_expression() {
    parseEntry(
      'before x',
      [
        'handleIdentifier x expression',
        'handleNoTypeArguments ',
        'handleNoArguments ',
        'handleSend x ',
      ],
    );
  }

  test_if() {
    parseEntry(
      'before if (true) 2',
      [
        'beginIfControlFlow if',
        'handleLiteralBool true',
        'handleParenthesizedCondition (',
        'handleLiteralInt 2',
        'endIfControlFlow 2',
      ],
    );
  }

  test_ifElse() {
    parseEntry(
      'before if (true) 2 else 5',
      [
        'beginIfControlFlow if',
        'handleLiteralBool true',
        'handleParenthesizedCondition (',
        'handleLiteralInt 2',
        'handleElseControlFlow else',
        'handleLiteralInt 5',
        'endIfElseControlFlow 5',
      ],
    );
  }

  test_ifSpreadQ() {
    parseEntry(
      'before if (true) ...?[2]',
      [
        'beginIfControlFlow if',
        'handleLiteralBool true',
        'handleParenthesizedCondition (',
        'handleNoTypeArguments [',
        'handleLiteralInt 2',
        'handleLiteralList 1, [, null, ]',
        'handleSpreadExpression ...?',
        'endIfControlFlow ]',
      ],
    );
  }

  test_ifElseSpreadQ() {
    parseEntry(
      'before if (true) ...?[2] else ... const {5}',
      [
        'beginIfControlFlow if',
        'handleLiteralBool true',
        'handleParenthesizedCondition (',
        'handleNoTypeArguments [',
        'handleLiteralInt 2',
        'handleLiteralList 1, [, null, ]',
        'handleSpreadExpression ...?',
        'handleElseControlFlow else',
        'beginConstLiteral {',
        'handleNoTypeArguments {',
        'handleLiteralInt 5',
        'handleLiteralSet 1, {, const, }',
        'endConstLiteral ',
        'handleSpreadExpression ...',
        'endIfElseControlFlow }',
      ],
    );
  }

  test_intLiteral() {
    parseEntry('before 1', [
      'handleLiteralInt 1',
    ]);
  }

  test_spread() {
    parseEntry('before ...[1]', [
      'handleNoTypeArguments [',
      'handleLiteralInt 1',
      'handleLiteralList 1, [, null, ]',
      'handleSpreadExpression ...',
    ]);
  }

  test_spreadQ() {
    parseEntry('before ...?[1]', [
      'handleNoTypeArguments [',
      'handleLiteralInt 1',
      'handleLiteralList 1, [, null, ]',
      'handleSpreadExpression ...?',
    ]);
  }

  void parseEntry(String source, List<String> expectedCalls,
      {List<ExpectedError> errors, String expectAfter}) {
    final start = scanString(source).tokens;
    final listener = new TestInfoListener();
    final parser = new Parser(listener);
    final lastConsumed = parser.parseListOrSetLiteralEntry(start);

    expect(listener.errors, errors);
    expect(listener.calls, expectedCalls, reason: source);
    if (expectAfter != null) {
      expect(lastConsumed.next.lexeme, expectAfter);
    } else {
      expect(lastConsumed.next.isEof, isTrue, reason: lastConsumed.lexeme);
    }
  }
}

@reflectiveTest
class MapElementTest {
  test_closingBrace() {
    parseEntry(
      'before }',
      [
        'handleIdentifier  expression',
        'handleNoTypeArguments }',
        'handleNoArguments }',
        'handleSend  }',
        'handleIdentifier  expression',
        'handleNoTypeArguments }',
        'handleNoArguments }',
        'handleSend  }',
        'handleLiteralMapEntry :, }',
      ],
      errors: [
        error(codeExpectedIdentifier, 7, 1),
        error(codeExpectedButGot, 7, 1),
        error(codeExpectedIdentifier, 7, 1),
      ],
      expectAfter: '}',
    );
  }

  test_comma() {
    parseEntry(
      'before ,',
      [
        'handleIdentifier  expression',
        'handleNoTypeArguments ,',
        'handleNoArguments ,',
        'handleSend  ,',
        'handleIdentifier  expression',
        'handleNoTypeArguments ,',
        'handleNoArguments ,',
        'handleSend  ,',
        'handleLiteralMapEntry :, ,',
      ],
      errors: [
        error(codeExpectedIdentifier, 7, 1),
        error(codeExpectedButGot, 7, 1),
        error(codeExpectedIdentifier, 7, 1),
      ],
      expectAfter: ',',
    );
  }

  test_expression() {
    parseEntry(
      'before x:y',
      [
        'handleIdentifier x expression',
        'handleNoTypeArguments :',
        'handleNoArguments :',
        'handleSend x :',
        'handleIdentifier y expression',
        'handleNoTypeArguments ',
        'handleNoArguments ',
        'handleSend y ',
        'handleLiteralMapEntry :, ',
      ],
    );
  }

  test_if() {
    parseEntry(
      'before if (true) 2:3',
      [
        'beginIfControlFlow if',
        'handleLiteralBool true',
        'handleParenthesizedCondition (',
        'handleLiteralInt 2',
        'handleLiteralInt 3',
        'handleLiteralMapEntry :, ',
        'endIfControlFlow 3',
      ],
    );
  }

  test_ifSpread() {
    parseEntry(
      'before if (true) ...{2:3}',
      [
        'beginIfControlFlow if',
        'handleLiteralBool true',
        'handleParenthesizedCondition (',
        'handleNoTypeArguments {',
        'handleLiteralInt 2',
        'handleLiteralInt 3',
        'handleLiteralMapEntry :, }',
        'handleLiteralMap 1, {, null, }',
        'handleSpreadExpression ...',
        'endIfControlFlow }',
      ],
    );
  }

  test_intLiteral() {
    parseEntry('before 1:2', [
      'handleLiteralInt 1',
      'handleLiteralInt 2',
      'handleLiteralMapEntry :, ',
    ]);
  }

  test_spread() {
    parseEntry('before ...const {1:2}', [
      'beginConstLiteral {',
      'handleNoTypeArguments {',
      'handleLiteralInt 1',
      'handleLiteralInt 2',
      'handleLiteralMapEntry :, }',
      'handleLiteralMap 1, {, const, }',
      'endConstLiteral ',
      'handleSpreadExpression ...',
    ]);
  }

  test_spreadQ() {
    parseEntry('before ...?const {1:3}', [
      'beginConstLiteral {',
      'handleNoTypeArguments {',
      'handleLiteralInt 1',
      'handleLiteralInt 3',
      'handleLiteralMapEntry :, }',
      'handleLiteralMap 1, {, const, }',
      'endConstLiteral ',
      'handleSpreadExpression ...?',
    ]);
  }

  void parseEntry(String source, List<String> expectedCalls,
      {List<ExpectedError> errors, String expectAfter}) {
    final start = scanString(source).tokens;
    final listener = new TestInfoListener();
    final parser = new Parser(listener);
    final lastConsumed = parser.parseMapLiteralEntry(start);

    expect(listener.errors, errors);
    expect(listener.calls, expectedCalls, reason: source);
    if (expectAfter != null) {
      expect(lastConsumed.next.lexeme, expectAfter);
    } else {
      expect(lastConsumed.next.isEof, isTrue, reason: lastConsumed.lexeme);
    }
  }
}

class TestInfoListener implements Listener {
  List<String> calls = <String>[];
  List<ExpectedError> errors;

  @override
  void beginConstLiteral(Token token) {
    calls.add('beginConstLiteral $token');
  }

  @override
  void beginIfControlFlow(Token ifToken) {
    calls.add('beginIfControlFlow $ifToken');
  }

  @override
  void endConstLiteral(Token token) {
    calls.add('endConstLiteral $token');
  }

  @override
  void endIfControlFlow(Token token) {
    calls.add('endIfControlFlow $token');
  }

  @override
  void endIfElseControlFlow(Token token) {
    calls.add('endIfElseControlFlow $token');
  }

  @override
  void handleElseControlFlow(Token elseToken) {
    calls.add('handleElseControlFlow $elseToken');
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    calls.add('handleIdentifier $token $context');
  }

  @override
  void handleLiteralBool(Token token) {
    calls.add('handleLiteralBool $token');
  }

  @override
  void handleLiteralInt(Token token) {
    calls.add('handleLiteralInt $token');
  }

  @override
  void handleLiteralList(
      int count, Token leftBracket, Token constKeyword, Token rightBracket) {
    calls.add(
        'handleLiteralList $count, $leftBracket, $constKeyword, $rightBracket');
  }

  @override
  void handleLiteralMap(
      int count, Token leftBrace, Token constKeyword, Token rightBrace) {
    calls
        .add('handleLiteralMap $count, $leftBrace, $constKeyword, $rightBrace');
  }

  @override
  void handleLiteralMapEntry(Token colon, Token endToken) {
    calls.add('handleLiteralMapEntry $colon, $endToken');
  }

  @override
  void handleLiteralSet(
      int count, Token beginToken, Token constKeyword, Token token) {
    calls.add('handleLiteralSet $count, $beginToken, $constKeyword, $token');
  }

  @override
  void handleNoArguments(Token token) {
    calls.add('handleNoArguments $token');
  }

  @override
  void handleParenthesizedCondition(Token token) {
    calls.add('handleParenthesizedCondition $token');
  }

  @override
  void handleNoTypeArguments(Token token) {
    calls.add('handleNoTypeArguments $token');
  }

  @override
  void handleRecoverableError(
      Message message, Token startToken, Token endToken) {
    errors ??= <ExpectedError>[];
    int offset = startToken.charOffset;
    errors.add(error(message.code, offset, endToken.charEnd - offset));
  }

  @override
  void handleSend(Token beginToken, Token endToken) {
    calls.add('handleSend $beginToken $endToken');
  }

  @override
  void handleSpreadExpression(Token spreadToken) {
    calls.add('handleSpreadExpression $spreadToken');
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
  String toString() => 'error(code${code.name}, $start, $length)';
}
