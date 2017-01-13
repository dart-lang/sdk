// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.parser.listener;

import '../common.dart';
import '../diagnostics/messages.dart' show MessageTemplate;
import '../tokens/precedence_constants.dart' as Precedence
    show EOF_INFO, IDENTIFIER_INFO;
import '../tokens/token.dart'
    show
        BadInputToken,
        BeginGroupToken,
        ErrorToken,
        StringToken,
        Token,
        UnmatchedToken,
        UnterminatedToken;
import '../tree/tree.dart';

const bool VERBOSE = false;

/**
 * A parser event listener that does nothing except throw exceptions
 * on parser errors.
 */
class Listener {
  set suppressParseErrors(bool value) {}

  void beginArguments(Token token) {}

  void endArguments(int count, Token beginToken, Token endToken) {}

  /// Handle async modifiers `async`, `async*`, `sync`.
  void handleAsyncModifier(Token asyncToken, Token startToken) {}

  void beginAwaitExpression(Token token) {}

  void endAwaitExpression(Token beginToken, Token endToken) {}

  void beginBlock(Token token) {}

  void endBlock(int count, Token beginToken, Token endToken) {}

  void beginCascade(Token token) {}

  void endCascade() {}

  void beginClassBody(Token token) {}

  void endClassBody(int memberCount, Token beginToken, Token endToken) {}

  void beginClassDeclaration(Token token) {}

  void endClassDeclaration(int interfacesCount, Token beginToken,
      Token extendsKeyword, Token implementsKeyword, Token endToken) {}

  void beginCombinators(Token token) {}

  void endCombinators(int count) {}

  void beginCompilationUnit(Token token) {}

  void endCompilationUnit(int count, Token token) {}

  void beginConstructorReference(Token start) {}

  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {}

  void beginDoWhileStatement(Token token) {}

  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token endToken) {}

  void beginEnum(Token enumKeyword) {}

  void endEnum(Token enumKeyword, Token endBrace, int count) {}

  void beginExport(Token token) {}

  void endExport(Token exportKeyword, Token semicolon) {}

  void beginExpressionStatement(Token token) {}

  void endExpressionStatement(Token token) {}

  void beginFactoryMethod(Token token) {}

  void endFactoryMethod(Token beginToken, Token endToken) {}

  void beginFormalParameter(Token token) {}

  void endFormalParameter(Token thisKeyword) {}

  void handleNoFormalParameters(Token token) {}

  void beginFormalParameters(Token token) {}

  void endFormalParameters(int count, Token beginToken, Token endToken) {}

  void endFields(int count, Token beginToken, Token endToken) {}

  void beginForStatement(Token token) {}

  void endForStatement(
      int updateExpressionCount, Token beginToken, Token endToken) {}

  void endForIn(
      Token awaitToken, Token forToken, Token inKeyword, Token endToken) {}

  void beginFunction(Token token) {}

  void endFunction(Token getOrSet, Token endToken) {}

  void beginFunctionDeclaration(Token token) {}

  void endFunctionDeclaration(Token token) {}

  void beginFunctionBody(Token token) {}

  void endFunctionBody(int count, Token beginToken, Token endToken) {}

  void handleNoFunctionBody(Token token) {}

  void skippedFunctionBody(Token token) {}

  void beginFunctionName(Token token) {}

  void endFunctionName(Token token) {}

  void beginFunctionTypeAlias(Token token) {}

  void endFunctionTypeAlias(Token typedefKeyword, Token endToken) {}

  void beginMixinApplication(Token token) {}

  void endMixinApplication() {}

  void beginNamedMixinApplication(Token token) {}

  void endNamedMixinApplication(
      Token classKeyword, Token implementsKeyword, Token endToken) {}

  void beginHide(Token hideKeyword) {}

  void endHide(Token hideKeyword) {}

  void beginIdentifierList(Token token) {}

  void endIdentifierList(int count) {}

  void beginTypeList(Token token) {}

  void endTypeList(int count) {}

  void beginIfStatement(Token token) {}

  void endIfStatement(Token ifToken, Token elseToken) {}

  void beginImport(Token importKeyword) {}

  void endImport(Token importKeyword, Token DeferredKeyword, Token asKeyword,
      Token semicolon) {}

  void beginConditionalUris(Token token) {}

  void endConditionalUris(int count) {}

  void beginConditionalUri(Token ifKeyword) {}

  void endConditionalUri(Token ifKeyword, Token equalitySign) {}

  void beginDottedName(Token token) {}

  void endDottedName(int count, Token firstIdentifier) {}

  void beginInitializedIdentifier(Token token) {}

  void endInitializedIdentifier() {}

  void beginInitializer(Token token) {}

  void endInitializer(Token assignmentOperator) {}

  void beginInitializers(Token token) {}

  void endInitializers(int count, Token beginToken, Token endToken) {}

  void handleNoInitializers() {}

  void handleLabel(Token token) {}

  void beginLabeledStatement(Token token, int labelCount) {}

  void endLabeledStatement(int labelCount) {}

  void beginLibraryName(Token token) {}

  void endLibraryName(Token libraryKeyword, Token semicolon) {}

  void beginLiteralMapEntry(Token token) {}

  void endLiteralMapEntry(Token colon, Token endToken) {}

  void beginLiteralString(Token token) {}

  void endLiteralString(int interpolationCount) {}

  void handleStringJuxtaposition(int literalCount) {}

  void beginMember(Token token) {}

  void endMember() {}

  void endMethod(Token getOrSet, Token beginToken, Token endToken) {}

  void beginMetadataStar(Token token) {}

  void endMetadataStar(int count, bool forParameter) {}

  void beginMetadata(Token token) {}

  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {}

  void beginOptionalFormalParameters(Token token) {}

  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {}

  void beginPart(Token token) {}

  void endPart(Token partKeyword, Token semicolon) {}

  void beginPartOf(Token token) {}

  void endPartOf(Token partKeyword, Token semicolon) {}

  void beginRedirectingFactoryBody(Token token) {}

  void endRedirectingFactoryBody(Token beginToken, Token endToken) {}

  void beginReturnStatement(Token token) {}

  void endReturnStatement(
      bool hasExpression, Token beginToken, Token endToken) {}

  void beginSend(Token token) {}

  void endSend(Token token) {}

  void beginShow(Token showKeyword) {}

  void endShow(Token showKeyword) {}

  void beginSwitchStatement(Token token) {}

  void endSwitchStatement(Token switchKeyword, Token endToken) {}

  void beginSwitchBlock(Token token) {}

  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {}

  void beginLiteralSymbol(Token token) {}

  void endLiteralSymbol(Token hashToken, int identifierCount) {}

  void beginThrowExpression(Token token) {}

  void endThrowExpression(Token throwToken, Token endToken) {}

  void beginRethrowStatement(Token token) {}

  void endRethrowStatement(Token throwToken, Token endToken) {}

  void endTopLevelDeclaration(Token token) {}

  void beginTopLevelMember(Token token) {}

  void endTopLevelFields(int count, Token beginToken, Token endToken) {}

  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {}

  void beginTryStatement(Token token) {}

  void handleCaseMatch(Token caseKeyword, Token colon) {}

  void handleCatchBlock(Token onKeyword, Token catchKeyword) {}

  void handleFinallyBlock(Token finallyKeyword) {}

  void endTryStatement(
      int catchCount, Token tryKeyword, Token finallyKeyword) {}

  void endType(Token beginToken, Token endToken) {}

  void beginTypeArguments(Token token) {}

  void endTypeArguments(int count, Token beginToken, Token endToken) {}

  void handleNoTypeArguments(Token token) {}

  void beginTypeVariable(Token token) {}

  void endTypeVariable(Token token, Token extendsOrSuper) {}

  void beginTypeVariables(Token token) {}

  void endTypeVariables(int count, Token beginToken, Token endToken) {}

  void beginUnnamedFunction(Token token) {}

  void endUnnamedFunction(Token token) {}

  void beginVariablesDeclaration(Token token) {}

  void endVariablesDeclaration(int count, Token endToken) {}

  void beginWhileStatement(Token token) {}

  void endWhileStatement(Token whileKeyword, Token endToken) {}

  void handleAsOperator(Token operator, Token endToken) {}

  void handleAssignmentExpression(Token token) {}

  void handleBinaryExpression(Token token) {}

  void handleConditionalExpression(Token question, Token colon) {}

  void handleConstExpression(Token token) {}

  void handleFunctionTypedFormalParameter(Token token) {}

  void handleIdentifier(Token token) {}

  void handleIndexedExpression(
      Token openCurlyBracket, Token closeCurlyBracket) {}

  void handleIsOperator(Token operator, Token not, Token endToken) {}

  void handleLiteralBool(Token token) {}

  void handleBreakStatement(
      bool hasTarget, Token breakKeyword, Token endToken) {}

  void handleContinueStatement(
      bool hasTarget, Token continueKeyword, Token endToken) {}

  void handleEmptyStatement(Token token) {}

  void handleAssertStatement(
      Token assertKeyword, Token commaToken, Token semicolonToken) {}

  /** Called with either the token containing a double literal, or
    * an immediately preceding "unary plus" token.
    */
  void handleLiteralDouble(Token token) {}

  /** Called with either the token containing an integer literal,
    * or an immediately preceding "unary plus" token.
    */
  void handleLiteralInt(Token token) {}

  void handleLiteralList(
      int count, Token beginToken, Token constKeyword, Token endToken) {}

  void handleLiteralMap(
      int count, Token beginToken, Token constKeyword, Token endToken) {}

  void handleLiteralNull(Token token) {}

  void handleModifier(Token token) {}

  void handleModifiers(int count) {}

  void handleNamedArgument(Token colon) {}

  void handleNewExpression(Token token) {}

  void handleNoArguments(Token token) {}

  void handleNoExpression(Token token) {}

  void handleNoType(Token token) {}

  void handleNoTypeVariables(Token token) {}

  void handleOperator(Token token) {}

  void handleOperatorName(Token operatorKeyword, Token token) {}

  void handleParenthesizedExpression(BeginGroupToken token) {}

  void handleQualified(Token period) {}

  void handleStringPart(Token token) {}

  void handleSuperExpression(Token token) {}

  void handleSwitchCase(
      int labelCount,
      int expressionCount,
      Token defaultKeyword,
      int statementCount,
      Token firstToken,
      Token endToken) {}

  void handleThisExpression(Token token) {}

  void handleUnaryPostfixAssignmentExpression(Token token) {}

  void handleUnaryPrefixExpression(Token token) {}

  void handleUnaryPrefixAssignmentExpression(Token token) {}

  void handleValuedFormalParameter(Token equals, Token token) {}

  void handleVoidKeyword(Token token) {}

  void beginYieldStatement(Token token) {}

  void endYieldStatement(Token yieldToken, Token starToken, Token endToken) {}

  Token expected(String string, Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected '$string', but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token synthesizeIdentifier(Token token) {
    Token synthesizedToken = new StringToken.fromString(
        Precedence.IDENTIFIER_INFO, '?', token.charOffset);
    synthesizedToken.next = token.next;
    return synthesizedToken;
  }

  Token expectedIdentifier(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected identifier, but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token expectedType(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected a type, but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token expectedExpression(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected an expression, but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token unexpected(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("unexpected token '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token expectedBlockToSkip(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected a block, but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token expectedFunctionBody(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected a function body, but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token expectedClassBody(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected a class body, but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token expectedClassBodyToSkip(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected a class body, but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token expectedDeclaration(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected a declaration, but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token unmatched(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("unmatched '${token.value}'", token);
    }
    return skipToEof(token);
  }

  skipToEof(Token token) {
    while (!identical(token.info, Precedence.EOF_INFO)) {
      token = token.next;
    }
    return token;
  }

  void recoverableError(Token token, String message) {
    error(message, token);
  }

  void error(String message, Token token) {
    throw new ParserError("$message @ ${token.charOffset}");
  }

  void reportError(Spannable spannable, MessageKind messageKind,
      [Map arguments = const {}]) {
    if (spannable is ErrorToken) {
      reportErrorToken(spannable);
    } else {
      reportErrorHelper(spannable, messageKind, arguments);
    }
  }

  void reportErrorHelper(Spannable spannable, MessageKind messageKind,
      [Map arguments = const {}]) {
    MessageTemplate template = MessageTemplate.TEMPLATES[messageKind];
    String message = template.message(arguments, true).toString();
    Token token;
    if (spannable is Token) {
      token = spannable;
    } else if (spannable is Node) {
      token = spannable.getBeginToken();
    } else {
      throw new ParserError(message);
    }
    recoverableError(token, message);
  }

  void reportErrorToken(ErrorToken token) {
    if (token is BadInputToken) {
      String hex = token.character.toRadixString(16);
      if (hex.length < 4) {
        String padding = "0000".substring(hex.length);
        hex = "$padding$hex";
      }
      reportErrorHelper(
          token, MessageKind.BAD_INPUT_CHARACTER, {'characterHex': hex});
    } else if (token is UnterminatedToken) {
      MessageKind kind;
      var arguments = const {};
      switch (token.start) {
        case '1e':
          kind = MessageKind.EXPONENT_MISSING;
          break;
        case '"':
        case "'":
        case '"""':
        case "'''":
        case 'r"':
        case "r'":
        case 'r"""':
        case "r'''":
          kind = MessageKind.UNTERMINATED_STRING;
          arguments = {'quote': token.start};
          break;
        case '0x':
          kind = MessageKind.HEX_DIGIT_EXPECTED;
          break;
        case r'$':
          kind = MessageKind.MALFORMED_STRING_LITERAL;
          break;
        case '/*':
          kind = MessageKind.UNTERMINATED_COMMENT;
          break;
        default:
          kind = MessageKind.UNTERMINATED_TOKEN;
          break;
      }
      reportErrorHelper(token, kind, arguments);
    } else if (token is UnmatchedToken) {
      String begin = token.begin.value;
      String end = closeBraceFor(begin);
      reportErrorHelper(
          token, MessageKind.UNMATCHED_TOKEN, {'begin': begin, 'end': end});
    } else {
      throw new SpannableAssertionFailure(token, token.assertionMessage);
    }
  }
}

String closeBraceFor(String openBrace) {
  return const {
    '(': ')',
    '[': ']',
    '{': '}',
    '<': '>',
    r'${': '}',
  }[openBrace];
}

class ParserError {
  final String reason;
  ParserError(this.reason);
  toString() => reason;
}
