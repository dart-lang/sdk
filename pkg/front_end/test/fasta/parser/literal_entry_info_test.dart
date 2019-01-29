// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/messages.dart';
import 'package:front_end/src/fasta/parser.dart';
import 'package:front_end/src/fasta/parser/async_modifier.dart';
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

  test_for() {
    parseEntry(
      'before for (var i = 0; i < 10; ++i) 2',
      [
        'beginForControlFlow null for',
        'beginMetadataStar var',
        'endMetadataStar 0',
        'handleNoTypeArguments var',
        'beginVariablesDeclaration i var',
        'handleIdentifier i localVariableDeclaration',
        'beginInitializedIdentifier i',
        'beginVariableInitializer =',
        'handleLiteralInt 0',
        'endVariableInitializer =',
        'endInitializedIdentifier i',
        'endVariablesDeclaration 1 null',
        'handleForInitializerLocalVariableDeclaration 0',
        'handleIdentifier i expression',
        'handleNoTypeArguments <',
        'handleNoArguments <',
        'handleSend i <',
        'beginBinaryExpression <',
        'handleLiteralInt 10',
        'endBinaryExpression <',
        'handleExpressionStatement ;',
        'handleIdentifier i expression',
        'handleNoTypeArguments )',
        'handleNoArguments )',
        'handleSend i )',
        'handleUnaryPrefixAssignmentExpression ++',
        'handleForInitializerExpressionStatement for ( ; 1',
        'handleLiteralInt 2',
        'endForControlFlow 2',
      ],
    );
  }

  test_forIn() {
    parseEntry(
      'before await for (var x in y) 2',
      [
        'beginForControlFlow await for',
        'beginMetadataStar var',
        'endMetadataStar 0',
        'handleNoTypeArguments var',
        'beginVariablesDeclaration x var',
        'handleIdentifier x localVariableDeclaration',
        'beginInitializedIdentifier x',
        'handleNoVariableInitializer in',
        'endInitializedIdentifier x',
        'endVariablesDeclaration 1 null',
        'handleForInitializerLocalVariableDeclaration x',
        'beginForInExpression y',
        'handleIdentifier y expression',
        'handleNoTypeArguments )',
        'handleNoArguments )',
        'handleSend y )',
        'endForInExpression )',
        'handleForInLoopParts await for ( in',
        'handleLiteralInt 2',
        'endForInControlFlow 2',
      ],
      inAsync: true,
    );
  }

  test_forInSpread() {
    parseEntry(
      'before for (var x in y) ...[2]',
      [
        'beginForControlFlow null for',
        'beginMetadataStar var',
        'endMetadataStar 0',
        'handleNoTypeArguments var',
        'beginVariablesDeclaration x var',
        'handleIdentifier x localVariableDeclaration',
        'beginInitializedIdentifier x',
        'handleNoVariableInitializer in',
        'endInitializedIdentifier x',
        'endVariablesDeclaration 1 null',
        'handleForInitializerLocalVariableDeclaration x',
        'beginForInExpression y',
        'handleIdentifier y expression',
        'handleNoTypeArguments )',
        'handleNoArguments )',
        'handleSend y )',
        'endForInExpression )',
        'handleForInLoopParts null for ( in',
        'handleNoTypeArguments [',
        'handleLiteralInt 2',
        'handleLiteralList 1, [, null, ]',
        'handleSpreadExpression ...',
        'endForInControlFlow ]',
      ],
    );
  }

  test_forSpreadQ() {
    parseEntry(
      'before for (i = 0; i < 10; ++i) ...[2]',
      [
        'beginForControlFlow null for',
        'handleIdentifier i expression',
        'handleNoTypeArguments =',
        'handleNoArguments =',
        'handleSend i =',
        'handleLiteralInt 0',
        'handleAssignmentExpression =',
        'handleForInitializerExpressionStatement 0',
        'handleIdentifier i expression',
        'handleNoTypeArguments <',
        'handleNoArguments <',
        'handleSend i <',
        'beginBinaryExpression <',
        'handleLiteralInt 10',
        'endBinaryExpression <',
        'handleExpressionStatement ;',
        'handleIdentifier i expression',
        'handleNoTypeArguments )',
        'handleNoArguments )',
        'handleSend i )',
        'handleUnaryPrefixAssignmentExpression ++',
        'handleForInitializerExpressionStatement for ( ; 1',
        'handleNoTypeArguments [',
        'handleLiteralInt 2',
        'handleLiteralList 1, [, null, ]',
        'handleSpreadExpression ...',
        'endForControlFlow ]',
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
      {bool inAsync, List<ExpectedError> errors, String expectAfter}) {
    final start = scanString(source).tokens;
    final listener = new TestInfoListener();
    final parser = new Parser(listener);
    if (inAsync != null) parser.asyncState = AsyncModifier.Async;
    final lastConsumed = parser.parseListOrSetLiteralEntry(start);

    expect(listener.errors, errors);
    try {
      expect(listener.calls, expectedCalls, reason: source);
    } catch (e) {
      listener.calls.forEach((line) => print("  '$line',"));
      throw e;
    }
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

  test_for() {
    parseEntry(
      'before for (var i = 0; i < 10; ++i) 2:3',
      [
        'beginForControlFlow null for',
        'beginMetadataStar var',
        'endMetadataStar 0',
        'handleNoTypeArguments var',
        'beginVariablesDeclaration i var',
        'handleIdentifier i localVariableDeclaration',
        'beginInitializedIdentifier i',
        'beginVariableInitializer =',
        'handleLiteralInt 0',
        'endVariableInitializer =',
        'endInitializedIdentifier i',
        'endVariablesDeclaration 1 null',
        'handleForInitializerLocalVariableDeclaration 0',
        'handleIdentifier i expression',
        'handleNoTypeArguments <',
        'handleNoArguments <',
        'handleSend i <',
        'beginBinaryExpression <',
        'handleLiteralInt 10',
        'endBinaryExpression <',
        'handleExpressionStatement ;',
        'handleIdentifier i expression',
        'handleNoTypeArguments )',
        'handleNoArguments )',
        'handleSend i )',
        'handleUnaryPrefixAssignmentExpression ++',
        'handleForInitializerExpressionStatement for ( ; 1',
        'handleLiteralInt 2',
        'handleLiteralInt 3',
        'handleLiteralMapEntry :, ',
        'endForControlFlow 3',
      ],
    );
  }

  test_forIn() {
    parseEntry(
      'before await for (var x in y) 2:3',
      [
        'beginForControlFlow await for',
        'beginMetadataStar var',
        'endMetadataStar 0',
        'handleNoTypeArguments var',
        'beginVariablesDeclaration x var',
        'handleIdentifier x localVariableDeclaration',
        'beginInitializedIdentifier x',
        'handleNoVariableInitializer in',
        'endInitializedIdentifier x',
        'endVariablesDeclaration 1 null',
        'handleForInitializerLocalVariableDeclaration x',
        'beginForInExpression y',
        'handleIdentifier y expression',
        'handleNoTypeArguments )',
        'handleNoArguments )',
        'handleSend y )',
        'endForInExpression )',
        'handleForInLoopParts await for ( in',
        'handleLiteralInt 2',
        'handleLiteralInt 3',
        'handleLiteralMapEntry :, ',
        'endForInControlFlow 3',
      ],
      inAsync: true,
    );
  }

  test_forInSpread() {
    parseEntry(
      'before for (var x in y) ...{2:3}',
      [
        'beginForControlFlow null for',
        'beginMetadataStar var',
        'endMetadataStar 0',
        'handleNoTypeArguments var',
        'beginVariablesDeclaration x var',
        'handleIdentifier x localVariableDeclaration',
        'beginInitializedIdentifier x',
        'handleNoVariableInitializer in',
        'endInitializedIdentifier x',
        'endVariablesDeclaration 1 null',
        'handleForInitializerLocalVariableDeclaration x',
        'beginForInExpression y',
        'handleIdentifier y expression',
        'handleNoTypeArguments )',
        'handleNoArguments )',
        'handleSend y )',
        'endForInExpression )',
        'handleForInLoopParts null for ( in',
        'handleNoTypeArguments {',
        'handleLiteralInt 2',
        'handleLiteralInt 3',
        'handleLiteralMapEntry :, }',
        'handleLiteralMap 1, {, null, }',
        'handleSpreadExpression ...',
        'endForInControlFlow }',
      ],
    );
  }

  test_forSpreadQ() {
    parseEntry(
      'before for (i = 0; i < 10; ++i) ...?{2:7}',
      [
        'beginForControlFlow null for',
        'handleIdentifier i expression',
        'handleNoTypeArguments =',
        'handleNoArguments =',
        'handleSend i =',
        'handleLiteralInt 0',
        'handleAssignmentExpression =',
        'handleForInitializerExpressionStatement 0',
        'handleIdentifier i expression',
        'handleNoTypeArguments <',
        'handleNoArguments <',
        'handleSend i <',
        'beginBinaryExpression <',
        'handleLiteralInt 10',
        'endBinaryExpression <',
        'handleExpressionStatement ;',
        'handleIdentifier i expression',
        'handleNoTypeArguments )',
        'handleNoArguments )',
        'handleSend i )',
        'handleUnaryPrefixAssignmentExpression ++',
        'handleForInitializerExpressionStatement for ( ; 1',
        'handleNoTypeArguments {',
        'handleLiteralInt 2',
        'handleLiteralInt 7',
        'handleLiteralMapEntry :, }',
        'handleLiteralMap 1, {, null, }',
        'handleSpreadExpression ...?',
        'endForControlFlow }',
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
      {bool inAsync, List<ExpectedError> errors, String expectAfter}) {
    final start = scanString(source).tokens;
    final listener = new TestInfoListener();
    final parser = new Parser(listener);
    if (inAsync != null) parser.asyncState = AsyncModifier.Async;
    final lastConsumed = parser.parseMapLiteralEntry(start);

    expect(listener.errors, errors);
    try {
      expect(listener.calls, expectedCalls, reason: source);
    } catch (e) {
      listener.calls.forEach((line) => print("  '$line',"));
      throw e;
    }
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
  void beginBinaryExpression(Token token) {
    calls.add('beginBinaryExpression $token');
  }

  @override
  void beginConstLiteral(Token token) {
    calls.add('beginConstLiteral $token');
  }

  @override
  void beginForControlFlow(Token awaitToken, Token forToken) {
    calls.add('beginForControlFlow $awaitToken $forToken');
  }

  @override
  void beginForInExpression(Token token) {
    calls.add('beginForInExpression $token');
  }

  @override
  void beginIfControlFlow(Token ifToken) {
    calls.add('beginIfControlFlow $ifToken');
  }

  @override
  void beginInitializedIdentifier(Token token) {
    calls.add('beginInitializedIdentifier $token');
  }

  @override
  void beginMetadataStar(Token token) {
    calls.add('beginMetadataStar $token');
  }

  @override
  void beginVariablesDeclaration(Token token, Token varFinalOrConst) {
    calls.add('beginVariablesDeclaration $token $varFinalOrConst');
  }

  @override
  void beginVariableInitializer(Token token) {
    calls.add('beginVariableInitializer $token');
  }

  @override
  void endBinaryExpression(Token token) {
    calls.add('endBinaryExpression $token');
  }

  @override
  void endConstLiteral(Token token) {
    calls.add('endConstLiteral $token');
  }

  @override
  void endForControlFlow(Token token) {
    calls.add('endForControlFlow $token');
  }

  @override
  void endForInControlFlow(Token token) {
    calls.add('endForInControlFlow $token');
  }

  @override
  void endForInExpression(Token token) {
    calls.add('endForInExpression $token');
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
  void endInitializedIdentifier(Token nameToken) {
    calls.add('endInitializedIdentifier $nameToken');
  }

  @override
  void endMetadataStar(int count) {
    calls.add('endMetadataStar $count');
  }

  @override
  void endVariablesDeclaration(int count, Token endToken) {
    calls.add('endVariablesDeclaration $count $endToken');
  }

  @override
  void endVariableInitializer(Token assignmentOperator) {
    calls.add('endVariableInitializer $assignmentOperator');
  }

  @override
  void handleAssignmentExpression(Token token) {
    calls.add('handleAssignmentExpression $token');
  }

  @override
  void handleElseControlFlow(Token elseToken) {
    calls.add('handleElseControlFlow $elseToken');
  }

  @override
  void handleExpressionStatement(Token token) {
    calls.add('handleExpressionStatement $token');
  }

  @override
  void handleForInitializerExpressionStatement(Token token) {
    calls.add('handleForInitializerExpressionStatement $token');
  }

  @override
  void handleForInitializerLocalVariableDeclaration(Token token) {
    calls.add('handleForInitializerLocalVariableDeclaration $token');
  }

  @override
  void handleForInLoopParts(Token awaitToken, Token forToken,
      Token leftParenthesis, Token inKeyword) {
    calls.add('handleForInLoopParts '
        '$awaitToken $forToken $leftParenthesis $inKeyword');
  }

  @override
  void handleForLoopParts(Token forKeyword, Token leftParen,
      Token leftSeparator, int updateExpressionCount) {
    calls.add('handleForInitializerExpressionStatement '
        '$forKeyword $leftParen $leftSeparator $updateExpressionCount');
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
  void handleNoType(Token lastConsumed) {
    calls.add('handleNoTypeArguments $lastConsumed');
  }

  @override
  void handleNoTypeArguments(Token token) {
    calls.add('handleNoTypeArguments $token');
  }

  @override
  void handleNoVariableInitializer(Token token) {
    calls.add('handleNoVariableInitializer $token');
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

  @override
  void handleUnaryPrefixAssignmentExpression(Token token) {
    calls.add('handleUnaryPrefixAssignmentExpression $token');
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
