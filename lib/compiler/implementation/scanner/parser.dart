// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * An event generating parser of Dart programs. This parser expects
 * all tokens in a linked list (aka a token stream).
 *
 * The class [Scanner] is used to generate a token stream. See the
 * file scanner.dart.
 *
 * Subclasses of the class [Listener] are used to listen to events.
 */
class Parser {
  final Listener listener;
  bool mayParseFunctionExpressions = true;

  Parser(Listener this.listener);

  void parseUnit(Token token) {
    while (token.kind !== EOF_TOKEN) {
      token = parseTopLevelDeclaration(token);
    }
  }

  Token parseTopLevelDeclaration(Token token) {
    final String value = token.stringValue;
    if (value === 'interface') {
      return parseInterface(token);
    } else if ((value === 'abstract') || (value === 'class')) {
      return parseClass(token);
    } else if (value === 'typedef') {
      return parseNamedFunctionAlias(token);
    } else if (value === '#') {
      return parseScriptTags(token);
    } else {
      return parseTopLevelMember(token);
    }
  }

  Token parseInterface(Token token) {
    Token interfaceKeyword = token;
    listener.beginInterface(token);
    token = parseIdentifier(token.next);
    token = parseTypeVariablesOpt(token);
    int supertypeCount = 0;
    Token extendsKeyword = null;
    if (optional('extends', token)) {
      extendsKeyword = token;
      do {
        token = parseType(token.next);
        ++supertypeCount;
      } while (optional(',', token));
    }
    token = parseDefaultClauseOpt(token);
    token = parseInterfaceBody(token);
    listener.endInterface(supertypeCount, interfaceKeyword,
                          extendsKeyword, token);
    return token.next;
  }

  Token parseInterfaceBody(Token token) {
    return parseClassBody(token);
  }

  Token parseNamedFunctionAlias(Token token) {
    Token typedefKeyword = token;
    listener.beginFunctionTypeAlias(token);
    token = parseReturnTypeOpt(token.next);
    token = parseIdentifier(token);
    token = parseTypeVariablesOpt(token);
    token = parseFormalParameters(token);
    listener.endFunctionTypeAlias(typedefKeyword, token);
    return expect(';', token);
  }

  Token parseReturnTypeOpt(Token token) {
    if (token.stringValue === 'void') {
      listener.handleVoidKeyword(token);
      return token.next;
    } else {
      return parseTypeOpt(token);
    }
  }

  Token parseFormalParameters(Token token) {
    Token begin = token;
    listener.beginFormalParameters(begin);
    expect('(', token);
    int parameterCount = 0;
    if (optional(')', token.next)) {
      listener.endFormalParameters(parameterCount, begin, token.next);
      return token.next.next;
    }
    do {
      ++parameterCount;
      token = token.next;
      if (optional('[', token)) {
        token = parseOptionalFormalParameters(token);
        break;
      }
      token = parseFormalParameter(token);
    } while (optional(',', token));
    listener.endFormalParameters(parameterCount, begin, token);
    return expect(')', token);
  }

  Token parseFormalParameter(Token token) {
    listener.beginFormalParameter(token);
    token = parseModifiers(token);
    // TODO(ahe): Validate that there are formal parameters if void.
    token = parseReturnTypeOpt(token);
    Token thisKeyword = null;
    if (optional('this', token)) {
      thisKeyword = token;
      // TODO(ahe): Validate field initializers are only used in
      // constructors, and not for function-typed arguments.
      token = expect('.', token.next);
    }
    token = parseIdentifier(token);
    if (optional('(', token)) {
      token = parseFormalParameters(token);
      listener.handleFunctionTypedFormalParameter(token);
    }
    if (optional('=', token)) {
      // TODO(ahe): Validate that these are only used for optional parameters.
      Token equal = token;
      token = parseExpression(token.next);
      listener.handleValuedFormalParameter(equal, token);
    }
    listener.endFormalParameter(token, thisKeyword);
    return token;
  }

  Token parseOptionalFormalParameters(Token token) {
    Token begin = token;
    listener.beginOptionalFormalParameters(begin);
    assert(optional('[', token));
    int parameterCount = 0;
    do {
      token = token.next;
      token = parseFormalParameter(token);
      ++parameterCount;
    } while (optional(',', token));
    listener.endOptionalFormalParameters(parameterCount, begin, token);
    return expect(']', token);
  }

  Token parseTypeOpt(Token token) {
    String value = token.stringValue;
    if (value === 'var') return parseType(token);
    if (value !== 'this') {
      Token peek = peekAfterType(token);
      if (isIdentifier(peek) || optional('this', peek)) {
        return parseType(token);
      }
    }
    listener.handleNoType(token);
    return token;
  }

  bool isIdentifier(Token token) {
    final kind = token.kind;
    if (kind === IDENTIFIER_TOKEN) return true;
    if (kind === KEYWORD_TOKEN) return token.value.isPseudo;
    return false;
  }

  Token parseDefaultClauseOpt(Token token) {
    if (isDefaultKeyword(token)) {
      // TODO(ahe): Remove support for 'factory' in this position.
      Token defaultKeyword = token;
      listener.beginDefaultClause(defaultKeyword);
      token = parseIdentifier(token.next);
      token = parseQualifiedRestOpt(token);
      token = parseTypeVariablesOpt(token);
      listener.endDefaultClause(defaultKeyword);
    } else {
      listener.handleNoDefaultClause(token);
    }
    return token;
  }

  Token parseQualifiedRestOpt(Token token) {
    if (optional('.', token)) {
      Token period = token;
      token = parseIdentifier(token.next);
      listener.handleQualified(period);
    }
    return token;
  }

  bool isDefaultKeyword(Token token) {
    String value = token.stringValue;
    if (value === 'default') return true;
    if (value === 'factory') {
      listener.recoverableError("expected 'default'", token: token);
      return true;
    }
    return false;
  }

  Token skipBlock(Token token) {
    if (!optional('{', token)) {
      return listener.expectedBlockToSkip(token);
    }
    BeginGroupToken beginGroupToken = token;
    assert(beginGroupToken.endGroup === null ||
           beginGroupToken.endGroup.kind === $CLOSE_CURLY_BRACKET);
    return beginGroupToken.endGroup;
  }

  Token parseClass(Token token) {
    Token begin = token;
    listener.beginClassDeclaration(token);
    if (optional('abstract', token)) {
      // TODO(ahe): Notify listener about abstract modifier.
      token = token.next;
    }
    token = parseIdentifier(token.next);
    token = parseTypeVariablesOpt(token);
    Token extendsKeyword;
    if (optional('extends', token)) {
      extendsKeyword = token;
      token = parseType(token.next);
    } else {
      extendsKeyword = null;
      listener.handleNoType(token);
    }
    Token implementsKeyword;
    int interfacesCount = 0;
    if (optional('implements', token)) {
      do {
        token = parseType(token.next);
        ++interfacesCount;
      } while (optional(',', token));
    }
    token = parseClassBody(token);
    listener.endClassDeclaration(interfacesCount, begin, extendsKeyword,
                                 implementsKeyword, token);
    return token.next;
  }

  Token parseStringPart(Token token) {
    if (token.kind === STRING_TOKEN) {
      listener.handleStringPart(token);
      return token.next;
    } else {
      return listener.expected('string', token);
    }
  }

  Token parseIdentifier(Token token) {
    if (isIdentifier(token)) {
      listener.handleIdentifier(token);
    } else {
      listener.expectedIdentifier(token);
    }
    return token.next;
  }

  Token expect(String string, Token token) {
    if (string !== token.stringValue) {
      if (string === '>') {
        if (token.stringValue === '>>') {
          Token gt = new Token(GT_INFO, token.charOffset + 1);
          gt.next = token.next;
          return gt;
        } else if (token.stringValue === '>>>') {
          Token gtgt = new Token(GT_GT_INFO, token.charOffset + 1);
          gtgt.next = token.next;
          return gtgt;
        }
      }
      return listener.expected(string, token);
    }
    return token.next;
  }

  Token parseTypeVariable(Token token) {
    listener.beginTypeVariable(token);
    token = parseIdentifier(token);
    if (optional('extends', token)) {
      token = parseType(token.next);
    } else {
      listener.handleNoType(token);
    }
    listener.endTypeVariable(token);
    return token;
  }

  bool optional(String value, Token token) => value === token.stringValue;

  bool notEofOrValue(String value, Token token) {
    return token.kind !== EOF_TOKEN && value !== token.stringValue;
  }

  Token parseType(Token token) {
    Token begin = token;
    if (isIdentifier(token)) {
      token = parseIdentifier(token);
      token = parseQualifiedRestOpt(token);
    } else {
      token = listener.expectedType(token);
    }
    token = parseTypeArgumentsOpt(token);
    listener.endType(begin, token);
    return token;
  }

  Token parseTypeArgumentsOpt(Token token) {
    return parseStuff(token,
                      (t) => listener.beginTypeArguments(t),
                      (t) => parseType(t),
                      (c, bt, et) => listener.endTypeArguments(c, bt, et),
                      (t) => listener.handleNoTypeArguments(t));
  }

  Token parseTypeVariablesOpt(Token token) {
    return parseStuff(token,
                      (t) => listener.beginTypeVariables(t),
                      (t) => parseTypeVariable(t),
                      (c, bt, et) => listener.endTypeVariables(c, bt, et),
                      (t) => listener.handleNoTypeVariables(t));
  }

  // TODO(ahe): Clean this up.
  Token parseStuff(Token token, Function beginStuff, Function stuffParser,
                   Function endStuff, Function handleNoStuff) {
    if (optional('<', token)) {
      Token begin = token;
      beginStuff(begin);
      int count = 0;
      do {
        token = stuffParser(token.next);
        ++count;
      } while (optional(',', token));
      endStuff(count, begin, token);
      return expect('>', token);
    }
    handleNoStuff(token);
    return token;
  }

  Token parseTopLevelMember(Token token) {
    Token start = token;
    listener.beginTopLevelMember(token);
    token = parseModifiers(token);
    Token getOrSet = findGetOrSet(token);
    if (token === getOrSet) token = token.next;
    Token peek = peekAfterType(token);
    if (isIdentifier(peek)) {
      // Skip type.
      token = peek;
    }
    if (token === getOrSet) token = token.next;
    token = parseIdentifier(token);
    bool isField;
    while (true) {
      // Loop to allow the listener to rewrite the token stream for
      // error handling.
      final String value = token.stringValue;
      if (value === '(') {
        isField = false;
        break;
      } else if ((value === '=') || (value === ';') || (value === ',')) {
        isField = true;
        break;
      } else {
        token = listener.unexpected(token);
        if (token.kind === EOF_TOKEN) {
          // TODO(ahe): This is a hack. It would be better to tell the
          // listener more explicitly that it must pop an identifier.
          listener.endTopLevelFields(1, start, token);
          return token;
        }
      }
    }
    if (isField) {
      int fieldCount = 1;
      token = parseVariableInitializerOpt(token);
      while (optional(',', token)) {
        token = parseIdentifier(token.next);
        token = parseVariableInitializerOpt(token);
        ++fieldCount;
      }
      expectSemicolon(token);
      listener.endTopLevelFields(fieldCount, start, token);
    } else {
      token = parseFormalParameters(token);
      token = parseFunctionBody(token, false);
      listener.endTopLevelMethod(start, getOrSet, token);
    }
    return token.next;
  }

  Token parseVariableInitializerOpt(Token token) {
    if (optional('=', token)) {
      Token assignment = token;
      listener.beginInitializer(token);
      token = parseExpression(token.next);
      listener.endInitializer(assignment);
    }
    return token;
  }

  Token parseInitializersOpt(Token token) {
    if (optional(':', token)) {
      return parseInitializers(token);
    } else {
      listener.handleNoInitializers();
      return token;
    }
  }

  Token parseInitializers(Token token) {
    Token begin = token;
    listener.beginInitializers(begin);
    expect(':', token);
    int count = 0;
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = false;
    do {
      token = parseExpression(token.next);
      ++count;
    } while (optional(',', token));
    mayParseFunctionExpressions = old;
    listener.endInitializers(count, begin, token);
    return token;
  }

  Token parseScriptTags(Token token) {
    Token begin = token;
    listener.beginScriptTag(token);
    token = parseIdentifier(token.next);
    token = expect('(', token);
    token = parseLiteralStringOrRecoverExpression(token);
    bool hasPrefix = false;
    if (optional(',', token)) {
      hasPrefix = true;
      token = parseIdentifier(token.next);
      token = expect(':', token);
      token = parseLiteralStringOrRecoverExpression(token);
    }
    token = expect(')', token);
    listener.endScriptTag(hasPrefix, begin, token);
    return expectSemicolon(token);
  }

  Token parseLiteralStringOrRecoverExpression(Token token) {
    if (token.kind === STRING_TOKEN) {
      return parseLiteralString(token);
    } else {
      listener.recoverableError("unexpected", token: token);
      return parseExpression(token);
    }
  }

  Token expectSemicolon(Token token) {
    return expect(';', token);
  }

  Token parseModifier(Token token) {
    assert(('final' === token.stringValue) ||
           ('var' === token.stringValue) ||
           ('const' === token.stringValue) ||
           ('abstract' === token.stringValue) ||
           ('static' === token.stringValue));
    listener.handleModifier(token);
    return token.next;
  }

  Token parseModifiers(Token token) {
    int count = 0;
    while (token.kind === KEYWORD_TOKEN) {
      final String value = token.stringValue;
      if (('final' !== value) &&
          ('var' !== value) &&
          ('const' !== value) &&
          ('abstract' !== value) &&
          ('static' !== value))
        break;
      token = parseModifier(token);
      count++;
    }
    listener.handleModifiers(count);
    return token;
  }

  Token peekAfterType(Token token) {
    // TODO(ahe): Also handle var?
    if ('void' !== token.stringValue && !isIdentifier(token)) {
      listener.unexpected(token);
    }
    // We are looking at "identifier ...".
    Token peek = token.next;
    if (peek.kind === PERIOD_TOKEN) {
      if (isIdentifier(peek.next)) {
        // Look past a library prefix.
        peek = peek.next.next;
      }
    }
    // We are looking at "qualified ...".
    if (peek.kind === LT_TOKEN) {
      // Possibly generic type.
      // We are looking at "qualified '<'".
      BeginGroupToken beginGroupToken = peek;
      Token gtToken = beginGroupToken.endGroup;
      if (gtToken !== null) {
        // We are looking at "qualified '<' ... '>' ...".
        return gtToken.next;
      }
    }
    return peek;
  }

  Token parseClassBody(Token token) {
    Token begin = token;
    listener.beginClassBody(token);
    if (!optional('{', token)) {
      token = listener.expectedClassBody(token);
    }
    token = token.next;
    int count = 0;
    while (notEofOrValue('}', token)) {
      token = parseMember(token);
      ++count;
    }
    listener.endClassBody(count, begin, token);
    return token;
  }

  bool isGetOrSet(Token token) {
    final String value = token.stringValue;
    return (value === 'get') || (value === 'set');
  }

  Token findGetOrSet(Token token) {
    if (isGetOrSet(token)) {
      if (optional('<', token.next)) {
        // For example: get<T> ...
        final Token peek = peekAfterType(token);
        if (isGetOrSet(peek) && isIdentifier(peek.next)) {
          // For example: get<T> get identifier
          return peek;
        }
      } else {
        // For example: get ...
        if (isGetOrSet(token.next) && isIdentifier(token.next.next)) {
          // For example: get get identifier
          return token.next;
        } else {
          // For example: get identifier
          return token;
        }
      }
    } else if (token.stringValue !== 'operator') {
      final Token peek = peekAfterType(token);
      if (isGetOrSet(peek) && isIdentifier(peek.next)) {
        // type? get identifier
        return peek;
      }
    }
    return null;
  }

  Token parseMember(Token token) {
    if (optional('factory', token)) {
      return parseFactoryMethod(token);
    }
    Token start = token;
    listener.beginMember(token);
    token = parseModifiers(token);
    Token getOrSet = findGetOrSet(token);
    if (token === getOrSet) token = token.next;
    Token peek = peekAfterType(token);
    if (isIdentifier(peek) && token.stringValue !== 'operator') {
      // Skip type.
      token = peek;
    }
    if (token === getOrSet) token = token.next;
    if (optional('operator', token)) {
      token = parseOperatorName(token);
    } else {
      token = parseIdentifier(token);
    }
    bool isField;
    while (true) {
      // Loop to allow the listener to rewrite the token stream for
      // error handling.
      final String value = token.stringValue;
      if ((value === '(') || (value === '.')) {
        isField = false;
        break;
      } else if ((value === '=') || (value === ';') || (value === ',')) {
        isField = true;
        break;
      } else {
        token = listener.unexpected(token);
        if (token.kind === EOF_TOKEN) {
          // TODO(ahe): This is a hack, see parseTopLevelMember.
          listener.endFields(1, start, token);
          return token;
        }
      }
    }
    if (isField) {
      int fieldCount = 1;
      token = parseVariableInitializerOpt(token);
      if (getOrSet !== null) {
        listener.recoverableError("unexpected", token: getOrSet);
      }
      while (optional(',', token)) {
        // TODO(ahe): Count these.
        token = parseIdentifier(token.next);
        token = parseVariableInitializerOpt(token);
        ++fieldCount;
      }
      expectSemicolon(token);
      listener.endFields(fieldCount, start, token);
    } else {
      token = parseQualifiedRestOpt(token);
      token = parseFormalParameters(token);
      token = parseInitializersOpt(token);
      token = parseFunctionBody(token, false);
      listener.endMethod(getOrSet, start, token);
    }
    return token.next;
  }

  Token parseFactoryMethod(Token token) {
    assert(optional('factory', token));
    Token factoryKeyword = token;
    listener.beginFactoryMethod(factoryKeyword);
    token = token.next; // Skip 'factory'.
    token = parseIdentifier(token);
    token = parseQualifiedRestOpt(token);
    token = parseTypeVariablesOpt(token);
    Token period = null;
    if (optional('.', token)) {
      period = token;
      token = parseIdentifier(token.next);
    }
    token = parseFormalParameters(token);
    token = parseFunctionBody(token, false);
    listener.endFactoryMethod(factoryKeyword, period, token);
    return token.next;
  }

  Token parseOperatorName(Token token) {
    assert(optional('operator', token));
    if (isUserDefinableOperator(token.next.stringValue)) {
      Token operator = token;
      token = token.next;
      listener.handleOperatorName(operator, token);
      return token.next;
    } else {
      return parseIdentifier(token);
    }
  }

  Token parseFunction(Token token, Token getOrSet) {
    listener.beginFunction(token);
    token = parseModifiers(token);
    if (getOrSet === token) token = token.next;
    token = parseReturnTypeOpt(token);
    if (getOrSet === token) token = token.next;
    listener.beginFunctionName(token);
    if (optional('operator', token)) {
      token = parseOperatorName(token);
    } else {
      token = parseIdentifier(token);
    }
    token = parseQualifiedRestOpt(token);
    listener.endFunctionName(token);
    token = parseFormalParameters(token);
    token = parseInitializersOpt(token);
    token = parseFunctionBody(token, false);
    listener.endFunction(getOrSet, token);
    return token.next;
  }

  Token parseUnamedFunction(Token token) {
    listener.beginUnamedFunction(token);
    token = parseFormalParameters(token);
    bool isBlock = optional('{', token);
    token = parseFunctionBody(token, true);
    listener.endUnamedFunction(token);
    return isBlock ? token.next : token;
  }

  Token parseFunctionDeclaration(Token token) {
    listener.beginFunctionDeclaration(token);
    token = parseFunction(token, null);
    listener.endFunctionDeclaration(token);
    return token;
  }

  Token parseFunctionExpression(Token token) {
    listener.beginFunction(token);
    listener.handleModifiers(0);
    token = parseReturnTypeOpt(token);
    listener.beginFunctionName(token);
    token = parseIdentifier(token);
    listener.endFunctionName(token);
    token = parseFormalParameters(token);
    listener.handleNoInitializers();
    bool isBlock = optional('{', token);
    token = parseFunctionBody(token, true);
    listener.endFunction(null, token);
    return isBlock ? token.next : token;
  }

  Token parseFunctionBody(Token token, bool isExpression) {
    if (optional(';', token)) {
      listener.endFunctionBody(0, null, token);
      return token;
    } else if (optional('=>', token)) {
      Token begin = token;
      token = parseExpression(token.next);
      if (!isExpression) {
        expectSemicolon(token);
        listener.endReturnStatement(true, begin, token);
      } else {
        listener.endReturnStatement(true, begin, null);
      }
      return token;
    }
    Token begin = token;
    int statementCount = 0;
    listener.beginFunctionBody(begin);
    if (!optional('{', token)) {
      return listener.expectedFunctionBody(token);
    } else {
      token = token.next;
    }
    while (notEofOrValue('}', token)) {
      token = parseStatement(token);
      ++statementCount;
    }
    listener.endFunctionBody(statementCount, begin, token);
    expect('}', token);
    return token;
  }

  Token parseStatement(Token token) {
    final value = token.stringValue;
    if (token.kind === IDENTIFIER_TOKEN) {
      return parseExpressionStatementOrDeclaration(token);
    } else if (value === '{') {
      return parseBlock(token);
    } else if (value === 'return') {
      return parseReturnStatement(token);
    } else if (value === 'var' || value === 'final') {
      return parseVariablesDeclaration(token);
    } else if (value === 'if') {
      return parseIfStatement(token);
    } else if (value === 'for') {
      return parseForStatement(token);
    } else if (value === 'throw') {
      return parseThrowStatement(token);
    } else if (value === 'void') {
      return parseExpressionStatementOrDeclaration(token);
    } else if (value === 'while') {
      return parseWhileStatement(token);
    } else if (value === 'do') {
      return parseDoWhileStatement(token);
    } else if (value === 'try') {
      return parseTryStatement(token);
    } else if (value === 'switch') {
      return parseSwitchStatement(token);
    } else if (value === 'break') {
      return parseBreakStatement(token);
    } else if (value === 'continue') {
      return parseContinueStatement(token);
    } else if (value === ';') {
      return parseEmptyStatement(token);
    } else {
      return parseExpressionStatement(token);
    }
  }

  Token parseReturnStatement(Token token) {
    Token begin = token;
    listener.beginReturnStatement(begin);
    assert('return' === token.stringValue);
    token = token.next;
    if (optional(';', token)) {
      listener.endReturnStatement(false, begin, token);
    } else {
      token = parseExpression(token);
      listener.endReturnStatement(true, begin, token);
    }
    return expectSemicolon(token);
  }

  Token peekIdentifierAfterType(Token token) {
    Token peek = peekAfterType(token);
    if (peek !== null && isIdentifier(peek)) {
      // We are looking at "type identifier".
      return peek;
    } else {
      return null;
    }
  }

  Token parseExpressionStatementOrDeclaration(Token token) {
    assert(isIdentifier(token) || token.stringValue === 'void');
    Token identifier = peekIdentifierAfterType(token);
    if (identifier !== null) {
      assert(isIdentifier(identifier));
      Token afterId = identifier.next;
      int afterIdKind = afterId.kind;
      if (afterIdKind === EQ_TOKEN ||
          afterIdKind === SEMICOLON_TOKEN ||
          afterIdKind === COMMA_TOKEN) {
        // We are looking at "type identifier" followed by '=', ';', ','.
        return parseVariablesDeclaration(token);
      } else if (afterIdKind === OPEN_PAREN_TOKEN) {
        // We are looking at "type identifier '('".
        BeginGroupToken beginParen = afterId;
        Token endParen = beginParen.endGroup;
        Token afterParens = endParen.next;
        if (optional('{', afterParens) || optional('=>', afterParens)) {
          // We are looking at "type identifier '(' ... ')'" followed
          // by '=>' or '{'.
          return parseFunctionDeclaration(token);
        }
      }
      // Fall-through to expression statement.
    } else {
      if (optional(':', token.next)) {
        return parseLabeledStatement(token);
      } else if (optional('(', token.next)) {
        BeginGroupToken begin = token.next;
        String afterParens = begin.endGroup.next.stringValue;
        if (afterParens === '{' || afterParens === '=>') {
          return parseFunctionDeclaration(token);
        }
      }
    }
    return parseExpressionStatement(token);
  }

  Token parseLabel(Token token) {
    token = parseIdentifier(token);
    Token colon = token;
    token = expect(':', token);
    listener.handleLabel(colon);
    return token;
  }

  Token parseLabeledStatement(Token token) {
    listener.beginLabeledStatement(token);
    token = parseLabel(token);
    token = parseStatement(token);
    listener.endLabeledStatement();
    return token;
  }

  Token parseExpressionStatement(Token token) {
    listener.beginExpressionStatement(token);
    token = parseExpression(token);
    listener.endExpressionStatement(token);
    return expectSemicolon(token);
  }

  Token parseExpression(Token token) {
    return parsePrecedenceExpression(token, ASSIGNMENT_PRECEDENCE,
                                     withoutCascades: false);
  }

  Token parseExpressionWithoutCascade(Token token) {
    return parsePrecedenceExpression(token, ASSIGNMENT_PRECEDENCE,
                                     withoutCascades: true);
  }

  Token parseConditionalExpressionRest(Token token) {
    assert(optional('?', token));
    Token question = token;
    token = parseExpressionWithoutCascade(token.next);
    Token colon = token;
    token = expect(':', token);
    token = parseExpressionWithoutCascade(token);
    listener.handleConditionalExpression(question, colon);
    return token;
  }

  Token parsePrecedenceExpression(Token token, int precedence,
                                  [bool withoutCascades]) {
    assert(precedence >= 1);
    assert(precedence <= POSTFIX_PRECEDENCE);
    token = parseUnaryExpression(token, withoutCascades);
    PrecedenceInfo info = token.info;
    int tokenLevel = info.precedence;
    for (int level = tokenLevel; level >= precedence; --level) {
      while (tokenLevel === level) {
        Token operator = token;
        if (tokenLevel === CASCADE_PRECEDENCE) {
          if (withoutCascades) {
            return token;
          }
          token = parseCascadeExpression(token);
        } else if (tokenLevel === ASSIGNMENT_PRECEDENCE) {
          // Right associative, so we recurse at the same precedence
          // level.
          token = parsePrecedenceExpression(token.next, level, withoutCascades);
          listener.handleAssignmentExpression(operator);
        } else if (tokenLevel === POSTFIX_PRECEDENCE) {
          if (info === PERIOD_INFO) {
            // Left associative, so we recurse at the next higher
            // precedence level. However, POSTFIX_PRECEDENCE is the
            // highest level, so we just call parseUnaryExpression
            // directly.
            token = parseUnaryExpression(token.next, withoutCascades);
            listener.handleBinaryExpression(operator);
          } else if ((info === OPEN_PAREN_INFO) ||
                     (info === OPEN_SQUARE_BRACKET_INFO)) {
            token = parseArgumentOrIndexStar(token);
          } else if ((info === PLUS_PLUS_INFO) ||
                     (info === MINUS_MINUS_INFO)) {
            listener.handleUnaryPostfixAssignmentExpression(token);
            token = token.next;
          } else {
            token = listener.unexpected(token);
          }
        } else if (info === IS_INFO) {
          token = parseIsOperatorRest(token);
        } else if (info === QUESTION_INFO) {
          token = parseConditionalExpressionRest(token);
        } else {
          // Left associative, so we recurse at the next higher
          // precedence level.
          token = parsePrecedenceExpression(token.next, level + 1,
                                            withoutCascades);
          listener.handleBinaryExpression(operator);
        }
        info = token.info;
        tokenLevel = info.precedence;
      }
    }
    return token;
  }

  Token parseCascadeExpression(Token token) {
    listener.beginCascade(token);
    assert(optional('..', token));
    Token cascadeOperator = token;
    token = token.next;
    if (optional('[', token)) {
      token = parseArgumentOrIndexStar(token);
    } else if (isIdentifier(token)) {
      token = parseSend(token);
      listener.handleBinaryExpression(cascadeOperator);
    } else {
      return listener.unexpected(token);
    }
    Token mark;
    do {
      mark = token;
      if (optional('.', token)) {
        Token period = token;
        token = parseSend(token.next);
        listener.handleBinaryExpression(period);
      }
      token = parseArgumentOrIndexStar(token);
    } while (mark !== token);

    if (token.info.precedence === ASSIGNMENT_PRECEDENCE) {
      Token assignment = token;
      token = parseExpressionWithoutCascade(token.next);
      listener.handleAssignmentExpression(assignment);
    }
    listener.endCascade();
    return token;
  }

  Token parseUnaryExpression(Token token, bool withoutCascades) {
    String value = token.stringValue;
    // Prefix:
    if (value === '+') {
      // Dart only allows "prefix plus" as an initial part of a
      // decimal literal. We scan it as a separate token and let
      // the parser listener combine it with the digits.
      Token next = token.next;
      if (next.charOffset === token.charOffset + 1) {
        if (next.kind === INT_TOKEN) {
          listener.handleLiteralInt(token);
          return next.next;
        }
        if (next.kind === DOUBLE_TOKEN) {
          listener.handleLiteralDouble(token);
          return next.next;
        }
      }
      listener.recoverableError("Unexpected token '+'", token: token);
      return parsePrecedenceExpression(next, POSTFIX_PRECEDENCE,
                                       withoutCascades);
    } else if ((value === '!') ||
               (value === '-') ||
               (value === '~')) {
      Token operator = token;
      // Right associative, so we recurse at the same precedence
      // level.
      token = parsePrecedenceExpression(token.next, POSTFIX_PRECEDENCE,
                                        withoutCascades);
      listener.handleUnaryPrefixExpression(operator);
    } else if ((value === '++') || value === '--') {
      // TODO(ahe): Validate this is used correctly.
      Token operator = token;
      // Right associative, so we recurse at the same precedence
      // level.
      token = parsePrecedenceExpression(token.next, POSTFIX_PRECEDENCE,
                                        withoutCascades);
      listener.handleUnaryPrefixAssignmentExpression(operator);
    } else {
      token = parsePrimary(token);
    }
    return token;
  }

  Token parseArgumentOrIndexStar(Token token) {
    while (true) {
      if (optional('[', token)) {
        Token openSquareBracket = token;
        bool old = mayParseFunctionExpressions;
        mayParseFunctionExpressions = true;
        token = parseExpression(token.next);
        mayParseFunctionExpressions = old;
        listener.handleIndexedExpression(openSquareBracket, token);
        token = expect(']', token);
      } else if (optional('(', token)) {
        token = parseArguments(token);
        listener.endSend(token);
      } else {
        break;
      }
    }
    return token;
  }

  Token parsePrimary(Token token) {
    final kind = token.kind;
    if (kind === IDENTIFIER_TOKEN) {
      return parseSendOrFunctionLiteral(token);
    } else if (kind === INT_TOKEN || kind === HEXADECIMAL_TOKEN) {
      return parseLiteralInt(token);
    } else if (kind === DOUBLE_TOKEN) {
      return parseLiteralDouble(token);
    } else if (kind === STRING_TOKEN) {
      return parseLiteralString(token);
    } else if (kind === KEYWORD_TOKEN) {
      final value = token.stringValue;
      if ((value === 'true') || (value === 'false')) {
        return parseLiteralBool(token);
      } else if (value === 'null') {
        return parseLiteralNull(token);
      } else if (value === 'this') {
        return parseThisExpression(token);
      } else if (value === 'super') {
        return parseSuperExpression(token);
      } else if (value === 'new') {
        return parseNewExpression(token);
      } else if (value === 'const') {
        return parseConstExpression(token);
      } else if (value === 'void') {
        return parseFunctionExpression(token);
      } else if (isIdentifier(token)) {
        return parseSendOrFunctionLiteral(token);
      } else {
        return listener.expectedExpression(token);
      }
    } else if (kind === OPEN_PAREN_TOKEN) {
      return parseParenthesizedExpressionOrFunctionLiteral(token);
    } else if ((kind === LT_TOKEN) ||
               (kind === OPEN_SQUARE_BRACKET_TOKEN) ||
               (kind === OPEN_CURLY_BRACKET_TOKEN) ||
               token.stringValue === '[]') {
      return parseLiteralListOrMap(token);
    } else {
      return listener.expectedExpression(token);
    }
  }

  Token parseParenthesizedExpressionOrFunctionLiteral(Token token) {
    BeginGroupToken beginGroup = token;
    int kind = beginGroup.endGroup.next.kind;
    if (mayParseFunctionExpressions &&
        (kind === FUNCTION_TOKEN || kind === OPEN_CURLY_BRACKET_TOKEN)) {
      return parseUnamedFunction(token);
    } else {
      bool old = mayParseFunctionExpressions;
      mayParseFunctionExpressions = true;
      token = parseParenthesizedExpression(token);
      mayParseFunctionExpressions = old;
      return token;
    }
  }

  Token parseParenthesizedExpression(Token token) {
    BeginGroupToken begin = token;
    token = expect('(', token);
    token = parseExpression(token);
    if (begin.endGroup !== token) {
      listener.unexpected(token);
      token = begin.endGroup;
    }
    listener.handleParenthesizedExpression(begin);
    return expect(')', token);
  }

  Token parseThisExpression(Token token) {
    listener.handleThisExpression(token);
    token = token.next;
    if (optional('(', token)) {
      // Constructor forwarding.
      token = parseArguments(token);
      listener.endSend(token);
    }
    return token;
  }

  Token parseSuperExpression(Token token) {
    listener.handleSuperExpression(token);
    token = token.next;
    if (optional('(', token)) {
      // Super constructor.
      token = parseArguments(token);
      listener.endSend(token);
    }
    return token;
  }

  Token parseLiteralListOrMap(Token token) {
    Token constKeyword = null;
    if (optional('const', token)) {
      constKeyword = token;
      token = token.next;
    }
    token = parseTypeArgumentsOpt(token);
    Token beginToken = token;
    int count = 0;
    if (optional('{', token)) {
      bool old = mayParseFunctionExpressions;
      mayParseFunctionExpressions = true;
      do {
        if (optional('}', token.next)) {
          token = token.next;
          break;
        }
        token = parseMapLiteralEntry(token.next);
        ++count;
      } while (optional(',', token));
      mayParseFunctionExpressions = old;
      listener.handleLiteralMap(count, beginToken, constKeyword, token);
      return expect('}', token);
    } else if (optional('[', token)) {
      bool old = mayParseFunctionExpressions;
      mayParseFunctionExpressions = true;
      do {
        if (optional(']', token.next)) {
          token = token.next;
          break;
        }
        token = parseExpression(token.next);
        ++count;
      } while (optional(',', token));
      mayParseFunctionExpressions = old;
      listener.handleLiteralList(count, beginToken, constKeyword, token);
      return expect(']', token);
    } else if (optional('[]', token)) {
      listener.handleLiteralList(0, token, constKeyword, token);
      return token.next;
    } else {
      listener.unexpected(token);
    }
  }

  Token parseMapLiteralEntry(Token token) {
    listener.beginLiteralMapEntry(token);
    // Assume the listener rejects non-string keys.
    token = parseExpression(token);
    Token colon = token;
    token = expect(':', token);
    token = parseExpression(token);
    listener.endLiteralMapEntry(colon, token);
    return token;
  }

  Token parseSendOrFunctionLiteral(Token token) {
    if (!mayParseFunctionExpressions) return parseSend(token);
    Token peek = peekAfterType(token);
    if (peek.kind === IDENTIFIER_TOKEN && isFunctionDeclaration(peek.next)) {
      return parseFunctionExpression(token);
    } else if (isFunctionDeclaration(token.next)) {
      return parseFunctionExpression(token);
    } else {
      return parseSend(token);
    }
  }

  bool isFunctionDeclaration(Token token) {
    if (optional('(', token)) {
      BeginGroupToken begin = token;
      String afterParens = begin.endGroup.next.stringValue;
      if (afterParens === '{' || afterParens === '=>') {
        return true;
      }
    }
    return false;
  }

  Token parseNewExpression(Token token) {
    Token newKeyword = token;
    token = expect('new', token);
    token = parseType(token);
    bool named = false;
    if (optional('.', token)) {
      named = true;
      token = parseIdentifier(token.next);
    }
    if (optional('(', token)) {
      token = parseArguments(token);
    } else {
      listener.handleNoArguments(token);
      token = listener.unexpected(token);
    }
    listener.handleNewExpression(newKeyword, named);
    return token;
  }

  Token parseConstExpression(Token token) {
    Token constKeyword = token;
    token = expect('const', token);
    final String value = token.stringValue;
    if ((value === '<') ||
        (value === '[') ||
        (value === '[]') ||
        (value === '{')) {
      return parseLiteralListOrMap(constKeyword);
    }
    token = parseType(token);
    bool named = false;
    if (optional('.', token)) {
      named = true;
      token = parseIdentifier(token.next);
    }
    expect('(', token);
    token = parseArguments(token);
    listener.handleConstExpression(constKeyword, named);
    return token;
  }

  Token parseLiteralInt(Token token) {
    listener.handleLiteralInt(token);
    return token.next;
  }

  Token parseLiteralDouble(Token token) {
    listener.handleLiteralDouble(token);
    return token.next;
  }

  Token parseLiteralString(Token token) {
    token = parseSingleLiteralString(token);
    int count = 1;
    while (token.kind === STRING_TOKEN) {
      token = parseSingleLiteralString(token);
      count++;
    }
    if (count > 1) {
      listener.handleStringJuxtaposition(count);
    }
    return token;
  }

  Token parseSingleLiteralString(Token token) {
    listener.beginLiteralString(token);
    token = token.next;
    int interpolationCount = 0;
    while (optional('\${', token)) {
      token = token.next;
      token = parseExpression(token);
      token = expect('}', token);
      token = parseStringPart(token);
      ++interpolationCount;
    }
    listener.endLiteralString(interpolationCount);
    return token;
  }

  Token parseLiteralBool(Token token) {
    listener.handleLiteralBool(token);
    return token.next;
  }

  Token parseLiteralNull(Token token) {
    listener.handleLiteralNull(token);
    return token.next;
  }

  Token parseSend(Token token) {
    listener.beginSend(token);
    token = parseIdentifier(token);
    token = parseArgumentsOpt(token);
    listener.endSend(token);
    return token;
  }

  Token parseArgumentsOpt(Token token) {
    if (!optional('(', token)) {
      listener.handleNoArguments(token);
      return token;
    } else {
      return parseArguments(token);
    }
  }

  Token parseArguments(Token token) {
    Token begin = token;
    listener.beginArguments(begin);
    assert('(' === token.stringValue);
    int argumentCount = 0;
    if (optional(')', token.next)) {
      listener.endArguments(argumentCount, begin, token.next);
      return token.next.next;
    }
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    do {
      Token colon = null;
      if (optional(':', token.next.next)) {
        token = parseIdentifier(token.next);
        colon = token;
      }
      token = parseExpression(token.next);
      if (colon !== null) listener.handleNamedArgument(colon);
      ++argumentCount;
    } while (optional(',', token));
    mayParseFunctionExpressions = old;
    listener.endArguments(argumentCount, begin, token);
    return expect(')', token);
  }

  Token parseIsOperatorRest(Token token) {
    assert(optional('is', token));
    Token operator = token;
    Token not = null;
    if (optional('!', token.next)) {
      token = token.next;
      not = token;
    }
    token = parseType(token.next);
    listener.handleIsOperator(operator, not, token);
    if (optional('is', token)) {
      // The is-operator cannot be chained, but it can take part of
      // expressions like: foo is Foo || foo is Bar.
      listener.unexpected(token);
    }
    return token;
  }

  Token parseVariablesDeclaration(Token token) {
    token = parseVariablesDeclarationNoSemicolon(token);
    return expectSemicolon(token);
  }

  Token parseVariablesDeclarationNoSemicolon(Token token) {
    int count = 1;
    listener.beginVariablesDeclaration(token);
    token = parseModifiers(token);
    token = parseTypeOpt(token);
    token = parseOptionallyInitializedIdentifier(token);
    while (optional(',', token)) {
      token = parseOptionallyInitializedIdentifier(token.next);
      ++count;
    }
    listener.endVariablesDeclaration(count, token);
    return token;
  }

  Token parseOptionallyInitializedIdentifier(Token token) {
    listener.beginInitializedIdentifier(token);
    token = parseIdentifier(token);
    token = parseVariableInitializerOpt(token);
    listener.endInitializedIdentifier();
    return token;
  }

  Token parseIfStatement(Token token) {
    Token ifToken = token;
    listener.beginIfStatement(ifToken);
    token = expect('if', token);
    token = parseParenthesizedExpression(token);
    token = parseStatement(token);
    Token elseToken = null;
    if (optional('else', token)) {
      elseToken = token;
      token = parseStatement(token.next);
    }
    listener.endIfStatement(ifToken, elseToken);
    return token;
  }

  Token parseForStatement(Token token) {
    Token forToken = token;
    listener.beginForStatement(forToken);
    token = expect('for', token);
    token = expect('(', token);
    token = parseVariablesDeclarationOrExpressionOpt(token);
    if (optional('in', token)) {
      return parseForInRest(forToken, token);
    } else {
      return parseForRest(forToken, token);
    }
  }

  Token parseVariablesDeclarationOrExpressionOpt(Token token) {
    final String value = token.stringValue;
    if (value === ';') {
      listener.handleNoExpression(token);
      return token;
    } else if ((value === 'var') || (value === 'final')) {
      return parseVariablesDeclarationNoSemicolon(token);
    }
    Token identifier = peekIdentifierAfterType(token);
    if (identifier !== null) {
      assert(isIdentifier(identifier));
      Token afterId = identifier.next;
      int afterIdKind = afterId.kind;
      if (afterIdKind === EQ_TOKEN || afterIdKind === SEMICOLON_TOKEN ||
          afterIdKind === COMMA_TOKEN || optional('in', afterId)) {
        return parseVariablesDeclarationNoSemicolon(token);
      }
    }
    return parseExpression(token);
  }

  Token parseForRest(Token forToken, Token token) {
    token = expectSemicolon(token);
    if (optional(';', token)) {
      token = parseEmptyStatement(token);
    } else {
      token = parseExpressionStatement(token);
    }
    int expressionCount = 0;
    while (true) {
      if (optional(')', token)) break;
      token = parseExpression(token);
      ++expressionCount;
      if (optional(',', token)) {
        token = token.next;
      } else {
        break;
      }
    }
    token = expect(')', token);
    token = parseStatement(token);
    listener.endForStatement(expressionCount, forToken, token);
    return token;
  }

  Token parseForInRest(Token forToken, Token token) {
    assert(optional('in', token));
    Token inKeyword = token;
    token = parseExpression(token.next);
    token = expect(')', token);
    token = parseStatement(token);
    listener.endForIn(forToken, inKeyword, token);
    return token;
  }

  Token parseWhileStatement(Token token) {
    Token whileToken = token;
    listener.beginWhileStatement(whileToken);
    token = expect('while', token);
    token = parseParenthesizedExpression(token);
    token = parseStatement(token);
    listener.endWhileStatement(whileToken, token);
    return token;
  }

  Token parseDoWhileStatement(Token token) {
    Token doToken = token;
    listener.beginDoWhileStatement(doToken);
    token = expect('do', token);
    token = parseStatement(token);
    Token whileToken = token;
    token = expect('while', token);
    token = parseParenthesizedExpression(token);
    listener.endDoWhileStatement(doToken, whileToken, token);
    return expectSemicolon(token);
  }

  Token parseBlock(Token token) {
    Token begin = token;
    listener.beginBlock(begin);
    int statementCount = 0;
    token = expect('{', token);
    while (notEofOrValue('}', token)) {
      token = parseStatement(token);
      ++statementCount;
    }
    listener.endBlock(statementCount, begin, token);
    return expect('}', token);
  }

  Token parseThrowStatement(Token token) {
    Token throwToken = token;
    listener.beginThrowStatement(throwToken);
    token = expect('throw', token);
    if (optional(';', token)) {
      listener.endRethrowStatement(throwToken, token);
      return token.next;
    } else {
      token = parseExpression(token);
      listener.endThrowStatement(throwToken, token);
      return expectSemicolon(token);
    }
  }

  Token parseTryStatement(Token token) {
    assert(optional('try', token));
    Token tryKeyword = token;
    listener.beginTryStatement(tryKeyword);
    token = parseBlock(token.next);
    int catchCount = 0;
    while (optional('catch', token)) {
      Token catchKeyword = token;
      // TODO(ahe): Validate the "parameters".
      token = parseFormalParameters(token.next);
      token = parseBlock(token);
      ++catchCount;
      listener.handleCatchBlock(catchKeyword);
    }
    Token finallyKeyword = null;
    if (optional('finally', token)) {
      finallyKeyword = token;
      token = parseBlock(token.next);
      listener.handleFinallyBlock(finallyKeyword);
    }
    listener.endTryStatement(catchCount, tryKeyword, finallyKeyword);
    return token;
  }

  Token parseSwitchStatement(Token token) {
    assert(optional('switch', token));
    Token switchKeyword = token;
    listener.beginSwitchStatement(switchKeyword);
    token = parseParenthesizedExpression(token.next);
    token = parseSwitchBlock(token);
    listener.endSwitchStatement(switchKeyword, token);
    return token.next;
  }

  Token parseSwitchBlock(Token token) {
    Token begin = token;
    listener.beginSwitchBlock(begin);
    token = expect('{', token);
    int caseCount = 0;
    while (token.kind !== EOF_TOKEN) {
      if (optional('}', token)) {
        break;
      }
      token = parseSwitchCase(token);
      ++caseCount;
    }
    listener.endSwitchBlock(caseCount, begin, token);
    expect('}', token);
    return token;
  }

  Token parseSwitchCase(Token token) {
    Token begin = token;
    Token defaultKeyword = null;
    Token label = null;
    // First an optional label.
    if (isIdentifier(token)) {
      label = token;
      token = parseLabel(token);
    }
    // Then one or more case expressions, the last of which may be
    // 'default' instead.
    int expressionCount = 0;
    {
      String value = token.stringValue;
      do {
        if (value === 'default') {
          defaultKeyword = token;
          token = expect(':', token.next);
          break;
        }
        token = expect('case', token);
        token = parseExpression(token);
        token = expect(':', token);
        expressionCount++;
        value = token.stringValue;
      } while (value === 'case' || value === 'default');
    }
    // Finally zero or more statements.
    int statementCount = 0;
    while (token.kind !== EOF_TOKEN) {
      String value;
      if (isIdentifier(token) && optional(':', token.next)) {
        // Skip label.
        value = token.next.next.stringValue;
      } else {
        value = token.stringValue;
      }
      if (value === 'case' || value === 'default' || value === '}') {
        break;
      } else {
        token = parseStatement(token);
        ++statementCount;
      }
    }
    listener.handleSwitchCase(label, expressionCount, defaultKeyword,
                              statementCount, begin, token);
    return token;
  }

  Token parseBreakStatement(Token token) {
    assert(optional('break', token));
    Token breakKeyword = token;
    token = token.next;
    bool hasTarget = false;
    if (isIdentifier(token)) {
      token = parseIdentifier(token);
      hasTarget = true;
    }
    listener.handleBreakStatement(hasTarget, breakKeyword, token);
    return expectSemicolon(token);
  }

  Token parseContinueStatement(Token token) {
    assert(optional('continue', token));
    Token continueKeyword = token;
    token = token.next;
    bool hasTarget = false;
    if (isIdentifier(token)) {
      token = parseIdentifier(token);
      hasTarget = true;
    }
    listener.handleContinueStatement(hasTarget, continueKeyword, token);
    return expectSemicolon(token);
  }

  Token parseEmptyStatement(Token token) {
    listener.handleEmptyStatement(token);
    return expectSemicolon(token);
  }
}
