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
 *
 * Most methods of this class belong in one of two major categories:
 * parse metods and peek methods. Parse methods all have the prefix
 * parse, and peek methods all have the prefix peek.
 *
 * Parse methods generate events (by calling methods on [listener])
 * and return the next token to parse. Peek methods do not generate
 * events (except for errors) and may return null.
 *
 * Parse methods are generally named parseGrammarProductionSuffix. The
 * suffix can be one of "opt", or "star". "opt" means zero or one
 * matches, "star" means zero or more matches. For example,
 * [parseMetadataStar] corresponds to this grammar snippet: [:
 * metadata* :], and [parseTypeOpt] corresponds to: [: type? :].
 */
class Parser {
  final Listener listener;
  bool mayParseFunctionExpressions = true;

  Parser(this.listener);

  Token parseUnit(Token token) {
    listener.beginCompilationUnit(token);
    int count = 0;
    while (!identical(token.kind, EOF_TOKEN)) {
      token = parseTopLevelDeclaration(token);
      count++;
    }
    listener.endCompilationUnit(count, token);
    return token;
  }

  Token parseTopLevelDeclaration(Token token) {
    token = parseMetadataStar(token);
    final String value = token.stringValue;
    if (identical(value, 'interface')) {
      return parseInterface(token);
    } else if ((identical(value, 'abstract')) || (identical(value, 'class'))) {
      return parseClass(token);
    } else if (identical(value, 'typedef')) {
      return parseNamedFunctionAlias(token);
    } else if (identical(value, '#')) {
      return parseScriptTags(token);
    } else if (identical(value, 'library')) {
      return parseLibraryName(token);
    } else if (identical(value, 'import')) {
      return parseImport(token);
    } else if (identical(value, 'export')) {
      return parseExport(token);
    } else if (identical(value, 'part')) {
      return parsePartOrPartOf(token);
    } else {
      return parseTopLevelMember(token);
    }
  }

  /// library qualified ';'
  Token parseLibraryName(Token token) {
    Token libraryKeyword = token;
    listener.beginLibraryName(libraryKeyword);
    assert(optional('library', token));
    token = parseQualified(token.next);
    Token semicolon = token;
    token = expect(';', token);
    listener.endLibraryName(libraryKeyword, semicolon);
    return token;
  }

  /// import uri (as identifier)? combinator* ';'
  Token parseImport(Token token) {
    Token importKeyword = token;
    listener.beginImport(importKeyword);
    assert(optional('import', token));
    token = parseLiteralStringOrRecoverExpression(token.next);
    Token asKeyword;
    if (optional('as', token)) {
      asKeyword = token;
      token = parseIdentifier(token.next);
    }
    token = parseCombinators(token);
    Token semicolon = token;
    token = expect(';', token);
    listener.endImport(importKeyword, asKeyword, semicolon);
    return token;
  }

  /// export uri combinator* ';'
  Token parseExport(Token token) {
    Token exportKeyword = token;
    listener.beginExport(exportKeyword);
    assert(optional('export', token));
    token = parseLiteralStringOrRecoverExpression(token.next);
    token = parseCombinators(token);
    Token semicolon = token;
    token = expect(';', token);
    listener.endExport(exportKeyword, semicolon);
    return token;
  }

  Token parseCombinators(Token token) {
    listener.beginCombinators(token);
    int count = 0;
    while (true) {
      String value = token.stringValue;
      if (identical('hide', value)) {
        token = parseHide(token);
      } else if (identical('show', value)) {
        token = parseShow(token);
      } else {
        listener.endCombinators(count);
        return token;
      }
      count++;
    }
  }

  /// hide identifierList
  Token parseHide(Token token) {
    Token hideKeyword = token;
    listener.beginHide(hideKeyword);
    assert(optional('hide', token));
    token = parseIdentifierList(token.next);
    listener.endHide(hideKeyword);
    return token;
  }

  /// show identifierList
  Token parseShow(Token token) {
    Token showKeyword = token;
    listener.beginShow(showKeyword);
    assert(optional('show', token));
    token = parseIdentifierList(token.next);
    listener.endShow(showKeyword);
    return token;
  }

  /// identifier (, identifier)*
  Token parseIdentifierList(Token token) {
    listener.beginIdentifierList(token);
    token = parseIdentifier(token);
    int count = 1;
    while (optional(',', token)) {
      token = parseIdentifier(token.next);
      count++;
    }
    listener.endIdentifierList(count);
    return token;
  }

  Token parsePartOrPartOf(Token token) {
    assert(optional('part', token));
    if (optional('of', token.next)) {
      return parsePartOf(token);
    } else {
      return parsePart(token);
    }
  }

  Token parsePart(Token token) {
    Token partKeyword = token;
    listener.beginPart(token);
    assert(optional('part', token));
    token = parseLiteralStringOrRecoverExpression(token.next);
    Token semicolon = token;
    token = expect(';', token);
    listener.endPart(partKeyword, semicolon);
    return token;
  }

  Token parsePartOf(Token token) {
    listener.beginPartOf(token);
    assert(optional('part', token));
    assert(optional('of', token.next));
    Token partKeyword = token;
    token = parseQualified(token.next.next);
    Token semicolon = token;
    token = expect(';', token);
    listener.endPartOf(partKeyword, semicolon);
    return token;
  }

  Token parseMetadataStar(Token token) {
    while (optional('@', token)) {
      token = parseMetadata(token);
    }
    return token;
  }

  /**
   * Parse
   * [: '@' qualified (‘.’ identifier)? (arguments)? :]
   */
  Token parseMetadata(Token token) {
    listener.beginMetadata(token);
    Token atToken = token;
    assert(optional('@', token));
    token = parseIdentifier(token.next);
    token = parseQualifiedRestOpt(token);
    token = parseQualifiedRestOpt(token);
    token = parseArgumentsOpt(token);
    listener.endMetadata(atToken, token);
    return token;
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
    if (identical(token.stringValue, 'void')) {
      listener.handleVoidKeyword(token);
      return token.next;
    } else {
      return parseTypeOpt(token);
    }
  }

  Token parseFormalParametersOpt(Token token) {
    if (optional('(', token)) {
      return parseFormalParameters(token);
    } else {
      listener.handleNoFormalParameters(token);
      return token;
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
      String value = token.stringValue;
      if (identical(value, '[')) {
        token = parseOptionalFormalParameters(token, false);
        break;
      } else if (identical(value, '{')) {
        token = parseOptionalFormalParameters(token, true);
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
    String value = token.stringValue;
    if ((identical('=', value)) || (identical(':', value))) {
      // TODO(ahe): Validate that these are only used for optional parameters.
      Token equal = token;
      token = parseExpression(token.next);
      listener.handleValuedFormalParameter(equal, token);
    }
    listener.endFormalParameter(token, thisKeyword);
    return token;
  }

  Token parseOptionalFormalParameters(Token token, bool isNamed) {
    Token begin = token;
    listener.beginOptionalFormalParameters(begin);
    assert((isNamed && optional('{', token)) || optional('[', token));
    int parameterCount = 0;
    do {
      token = token.next;
      token = parseFormalParameter(token);
      ++parameterCount;
    } while (optional(',', token));
    listener.endOptionalFormalParameters(parameterCount, begin, token);
    if (isNamed) {
      return expect('}', token);
    } else {
      return expect(']', token);
    }
  }

  Token parseTypeOpt(Token token) {
    String value = token.stringValue;
    if (!identical(value, 'this')) {
      Token peek = peekAfterExpectedType(token);
      if (peek.isIdentifier() || optional('this', peek)) {
        return parseType(token);
      }
    }
    listener.handleNoType(token);
    return token;
  }

  bool isValidTypeReference(Token token) {
    final kind = token.kind;
    if (identical(kind, IDENTIFIER_TOKEN)) return true;
    if (identical(kind, KEYWORD_TOKEN)) {
      Keyword keyword = token.value;
      String value = keyword.stringValue;
      // TODO(aprelev@gmail.com): Remove deprecated Dynamic keyword support.
      return keyword.isPseudo
          || (identical(value, 'dynamic'))
          || (identical(value, 'Dynamic'))
          || (identical(value, 'void'));
    }
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

  Token parseQualified(Token token) {
    token = parseIdentifier(token);
    while (optional('.', token)) {
      token = parseQualifiedRest(token);
    }
    return token;
  }

  Token parseQualifiedRestOpt(Token token) {
    if (optional('.', token)) {
      return parseQualifiedRest(token);
    } else {
      return token;
    }
  }

  Token parseQualifiedRest(Token token) {
    assert(optional('.', token));
    Token period = token;
    token = parseIdentifier(token.next);
    listener.handleQualified(period);
    return token;
  }

  bool isDefaultKeyword(Token token) {
    String value = token.stringValue;
    if (identical(value, 'default')) return true;
    if (identical(value, 'factory')) {
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
    Token endGroup = beginGroupToken.endGroup;
    if (endGroup == null) {
      return listener.unmatched(beginGroupToken);
    } else if (!identical(endGroup.kind, $CLOSE_CURLY_BRACKET)) {
      return listener.unmatched(beginGroupToken);
    }
    return beginGroupToken.endGroup;
  }

  Token parseClass(Token token) {
    Token begin = token;
    listener.beginClassDeclaration(token);
    int modifierCount = 0;
    if (optional('abstract', token)) {
      listener.handleModifier(token);
      modifierCount++;
      token = token.next;
    }
    listener.handleModifiers(modifierCount);
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
      implementsKeyword = token;
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
    if (identical(token.kind, STRING_TOKEN)) {
      listener.handleStringPart(token);
      return token.next;
    } else {
      return listener.expected('string', token);
    }
  }

  Token parseIdentifier(Token token) {
    if (token.isIdentifier()) {
      listener.handleIdentifier(token);
    } else {
      listener.expectedIdentifier(token);
    }
    return token.next;
  }

  Token expect(String string, Token token) {
    if (!identical(string, token.stringValue)) {
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

  /**
   * Returns true if the stringValue of the [token] is [value].
   */
  bool optional(String value, Token token) => identical(value, token.stringValue);

  bool notEofOrValue(String value, Token token) {
    return !identical(token.kind, EOF_TOKEN) && !identical(value, token.stringValue);
  }

  Token parseType(Token token) {
    Token begin = token;
    if (isValidTypeReference(token)) {
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
      Token next = token.next;
      if (identical(token.stringValue, '>>')) {
        token = new Token(GT_INFO, token.charOffset);
        token.next = new Token(GT_INFO, token.charOffset + 1);
        token.next.next = next;
      } else if (identical(token.stringValue, '>>>')) {
        token = new Token(GT_INFO, token.charOffset);
        token.next = new Token(GT_GT_INFO, token.charOffset + 1);
        token.next.next = next;
      }
      endStuff(count, begin, token);
      return expect('>', token);
    }
    handleNoStuff(token);
    return token;
  }

  Token parseTopLevelMember(Token token) {
    Token start = token;
    listener.beginTopLevelMember(token);

    Link<Token> identifiers = findMemberName(token);
    if (identifiers.isEmpty()) {
      return listener.unexpected(start);
    }
    Token name = identifiers.head;
    identifiers = identifiers.tail;
    Token getOrSet;
    if (!identifiers.isEmpty()) {
      String value = identifiers.head.stringValue;
      if ((identical(value, 'get')) || (identical(value, 'set'))) {
        getOrSet = identifiers.head;
        identifiers = identifiers.tail;
      }
    }
    Token type;
    if (!identifiers.isEmpty()) {
      if (isValidTypeReference(identifiers.head)) {
        type = identifiers.head;
        identifiers = identifiers.tail;
      }
    }
    parseModifierList(identifiers.reverse());
    if (type == null) {
      listener.handleNoType(token);
    } else {
      parseReturnTypeOpt(type);
    }
    token = parseIdentifier(name);

    bool isField;
    while (true) {
      // Loop to allow the listener to rewrite the token stream for
      // error handling.
      final String value = token.stringValue;
      if ((identical(value, '(')) || (identical(value, '{'))
          || (identical(value, '=>'))) {
        isField = false;
        break;
      } else if ((identical(value, '=')) || (identical(value, ','))) {
        isField = true;
        break;
      } else if (identical(value, ';')) {
        if (getOrSet != null) {
          // If we found a "get" keyword, this must be an abstract
          // getter.
          isField = (!identical(getOrSet.stringValue, 'get'));
          // TODO(ahe): This feels like a hack.
        } else {
          isField = true;
        }
        break;
      } else {
        token = listener.unexpected(token);
        if (identical(token.kind, EOF_TOKEN)) {
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
      token = parseFormalParametersOpt(token);
      token = parseFunctionBody(token, false);
      listener.endTopLevelMethod(start, getOrSet, token);
    }
    return token.next;
  }

  Link<Token> findMemberName(Token token) {
    Token start = token;
    Link<Token> identifiers = const Link<Token>();
    while (!identical(token.kind, EOF_TOKEN)) {
      String value = token.stringValue;
      if ((identical(value, '(')) || (identical(value, '{')) 
          || (identical(value, '=>'))) {
        // A method.
        return identifiers;
      } else if ((identical(value, '=')) || (identical(value, ';'))
          || (identical(value, ','))) {
        // A field or abstract getter.
        return identifiers;
      }
      identifiers = identifiers.prepend(token);
      if (isValidTypeReference(token)) {
        // type ...
        if (optional('.', token.next)) {
          // type '.' ...
          if (token.next.next.isIdentifier()) {
            // type '.' identifier
            token = token.next.next;
          }
        }
        if (optional('<', token.next)) {
          if (token.next is BeginGroupToken) {
            BeginGroupToken beginGroup = token.next;
            token = beginGroup.endGroup;
          }
        }
      }
      token = token.next;
    }
    return listener.expectedDeclaration(start);
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
    if (identical(token.kind, STRING_TOKEN)) {
      return parseLiteralString(token);
    } else {
      listener.recoverableError("unexpected", token: token);
      return parseExpression(token);
    }
  }

  Token expectSemicolon(Token token) {
    return expect(';', token);
  }

  bool isModifier(Token token) {
    final String value = token.stringValue;
    return (identical('final', value)) ||
           (identical('var', value)) ||
           (identical('const', value)) ||
           (identical('abstract', value)) ||
           (identical('static', value)) ||
           (identical('external', value));
  }

  Token parseModifier(Token token) {
    assert(isModifier(token));
    listener.handleModifier(token);
    return token.next;
  }

  void parseModifierList(Link<Token> tokens) {
    int count = 0;
    for (; !tokens.isEmpty(); tokens = tokens.tail) {
      Token token = tokens.head;
      if (isModifier(token)) {
        parseModifier(token);
      } else {
        listener.unexpected(token);
      }
      count++;
    }
    listener.handleModifiers(count);
  }

  Token parseModifiers(Token token) {
    int count = 0;
    while (identical(token.kind, KEYWORD_TOKEN)) {
      if (!isModifier(token))
        break;
      token = parseModifier(token);
      count++;
    }
    listener.handleModifiers(count);
    return token;
  }

  Token peekAfterType(Token token) {
    // TODO(ahe): Also handle var?
    // We are looking at "identifier ...".
    Token peek = token.next;
    if (identical(peek.kind, PERIOD_TOKEN)) {
      if (peek.next.isIdentifier()) {
        // Look past a library prefix.
        peek = peek.next.next;
      }
    }
    // We are looking at "qualified ...".
    if (identical(peek.kind, LT_TOKEN)) {
      // Possibly generic type.
      // We are looking at "qualified '<'".
      BeginGroupToken beginGroupToken = peek;
      Token gtToken = beginGroupToken.endGroup;
      if (gtToken != null) {
        // We are looking at "qualified '<' ... '>' ...".
        return gtToken.next;
      }
    }
    return peek;
  }

  /**
   * Returns the token after the type which is expected to begin at [token].
   * If [token] is not the start of a type, [Listener.unexpectedType] is called.
   */
  Token peekAfterExpectedType(Token token) {
    if (!identical('void', token.stringValue) && !token.isIdentifier()) {
      return listener.expectedType(token);
    }
    return peekAfterType(token);
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
    return (identical(value, 'get')) || (identical(value, 'set'));
  }

  bool isFactoryDeclaration(Token token) {
    if (optional('external', token)) token = token.next;
    if (optional('const', token)) token = token.next;
    return optional('factory', token);
  }

  Token parseMember(Token token) {
    token = parseMetadataStar(token);
    String value = token.stringValue;
    if (isFactoryDeclaration(token)) {
      return parseFactoryMethod(token);
    }
    Token start = token;
    listener.beginMember(token);

    Link<Token> identifiers = findMemberName(token);
    if (identifiers.isEmpty()) {
      return listener.unexpected(start);
    }
    Token name = identifiers.head;
    identifiers = identifiers.tail;
    if (!identifiers.isEmpty()) {
      if (optional('operator', identifiers.head)) {
        name = identifiers.head;
        identifiers = identifiers.tail;
      }
    }
    Token getOrSet;
    if (!identifiers.isEmpty()) {
      if (isGetOrSet(identifiers.head)) {
        getOrSet = identifiers.head;
        identifiers = identifiers.tail;
      }
    }
    Token type;
    if (!identifiers.isEmpty()) {
      if (isValidTypeReference(identifiers.head)) {
        type = identifiers.head;
        identifiers = identifiers.tail;
      }
    }
    parseModifierList(identifiers.reverse());
    if (type == null) {
      listener.handleNoType(token);
    } else {
      parseReturnTypeOpt(type);
    }

    if (optional('operator', name)) {
      token = parseOperatorName(name);
    } else {
      token = parseIdentifier(name);
    }
    bool isField;
    while (true) {
      // Loop to allow the listener to rewrite the token stream for
      // error handling.
      final String value = token.stringValue;
      if ((identical(value, '(')) || (identical(value, '.'))
          || (identical(value, '{')) || (identical(value, '=>'))) {
        isField = false;
        break;
      } else if (identical(value, ';')) {
        if (getOrSet != null) {
          // If we found a "get" keyword, this must be an abstract
          // getter.
          isField = (!identical(getOrSet.stringValue, 'get'));
          // TODO(ahe): This feels like a hack.
        } else {
          isField = true;
        }
        break;
      } else if ((identical(value, '=')) || (identical(value, ','))) {
        isField = true;
        break;
      } else {
        token = listener.unexpected(token);
        if (identical(token.kind, EOF_TOKEN)) {
          // TODO(ahe): This is a hack, see parseTopLevelMember.
          listener.endFields(1, start, token);
          return token;
        }
      }
    }
    if (isField) {
      int fieldCount = 1;
      token = parseVariableInitializerOpt(token);
      if (getOrSet != null) {
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
      token = parseFormalParametersOpt(token);
      token = parseInitializersOpt(token);
      token = parseFunctionBody(token, false);
      listener.endMethod(getOrSet, start, token);
    }
    return token.next;
  }

  Token parseFactoryMethod(Token token) {
    assert(isFactoryDeclaration(token));
    Token start = token;
    if (identical(token.stringValue, 'external')) token = token.next;
    Token constKeyword = null;
    if (optional('const', token)) {
      constKeyword = token;
      token = token.next;
    }
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
    if (optional('=', token)) {
      token = parseRedirectingFactoryBody(token);
    } else {
      token = parseFunctionBody(token, false);
    }
    listener.endFactoryMethod(start, period, token);
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
    if (identical(getOrSet, token)) token = token.next;
    if (optional('operator', token)) {
      listener.handleNoType(token);
      listener.beginFunctionName(token);
      token = parseOperatorName(token);
    } else {
      token = parseReturnTypeOpt(token);
      if (identical(getOrSet, token)) token = token.next;
      listener.beginFunctionName(token);
      if (optional('operator', token)) {
        token = parseOperatorName(token);
      } else {
        token = parseIdentifier(token);
      }
    }
    token = parseQualifiedRestOpt(token);
    listener.endFunctionName(token);
    token = parseFormalParametersOpt(token);
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

  Token parseQualifiedList(Token token) {
    listener.beginQualifiedList(token);
    Token parseQualifiedPart(Token token) {
      Token start = token;
      token = parseIdentifier(token);
      token = parseTypeVariablesOpt(token);
      listener.endType(start, null);
      return token;
    }
    Token beginToken = token;
    token = parseQualifiedPart(token);
    int count = 1;
    while (optional('.', token)) {
      token = parseQualifiedPart(token.next);
      count++;
    }
    listener.endQualifiedList(count);
    return token;
  }

  Token parseRedirectingFactoryBody(Token token) {
    listener.beginRedirectingFactoryBody(token);
    assert(optional('=', token));
    Token equals = token;
    token = parseQualifiedList(token.next);
    Token semicolon = token;
    expectSemicolon(token);
    listener.endRedirectingFactoryBody(equals, semicolon);
    return token;
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
    if (!optional('{', token)) {
      return listener.expectedFunctionBody(token);
    }

    listener.beginFunctionBody(begin);
    token = token.next;
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
    if (identical(token.kind, IDENTIFIER_TOKEN)) {
      return parseExpressionStatementOrDeclaration(token);
    } else if (identical(value, '{')) {
      return parseBlock(token);
    } else if (identical(value, 'return')) {
      return parseReturnStatement(token);
    } else if (identical(value, 'var') || identical(value, 'final')) {
      return parseVariablesDeclaration(token);
    } else if (identical(value, 'if')) {
      return parseIfStatement(token);
    } else if (identical(value, 'for')) {
      return parseForStatement(token);
    } else if (identical(value, 'throw')) {
      return parseThrowStatement(token);
    } else if (identical(value, 'void')) {
      return parseExpressionStatementOrDeclaration(token);
    } else if (identical(value, 'while')) {
      return parseWhileStatement(token);
    } else if (identical(value, 'do')) {
      return parseDoWhileStatement(token);
    } else if (identical(value, 'try')) {
      return parseTryStatement(token);
    } else if (identical(value, 'switch')) {
      return parseSwitchStatement(token);
    } else if (identical(value, 'break')) {
      return parseBreakStatement(token);
    } else if (identical(value, 'continue')) {
      return parseContinueStatement(token);
    } else if (identical(value, 'assert')) {
      return parseAssertStatement(token);
    } else if (identical(value, ';')) {
      return parseEmptyStatement(token);
    } else if (identical(value, 'const')) {
      return parseExpressionStatementOrConstDeclaration(token);
    } else if (token.isIdentifier()) {
      return parseExpressionStatementOrDeclaration(token);
    } else {
      return parseExpressionStatement(token);
    }
  }

  Token parseReturnStatement(Token token) {
    Token begin = token;
    listener.beginReturnStatement(begin);
    assert(identical('return', token.stringValue));
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
    if (peek != null && peek.isIdentifier()) {
      // We are looking at "type identifier".
      return peek;
    } else {
      return null;
    }
  }

  Token peekIdentifierAfterOptionalType(Token token) {
    Token peek = peekIdentifierAfterType(token);
    if (peek != null) {
      // We are looking at "type identifier".
      return peek;
    } else if (token.isIdentifier()) {
      // We are looking at "identifier".
      return token;
    } else {
      return null;
    }
  }

  Token parseExpressionStatementOrDeclaration(Token token) {
    assert(token.isIdentifier() || identical(token.stringValue, 'void'));
    Token identifier = peekIdentifierAfterType(token);
    if (identifier != null) {
      assert(identifier.isIdentifier());
      Token afterId = identifier.next;
      int afterIdKind = afterId.kind;
      if (identical(afterIdKind, EQ_TOKEN) ||
          identical(afterIdKind, SEMICOLON_TOKEN) ||
          identical(afterIdKind, COMMA_TOKEN)) {
        // We are looking at "type identifier" followed by '=', ';', ','.
        return parseVariablesDeclaration(token);
      } else if (identical(afterIdKind, OPEN_PAREN_TOKEN)) {
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
        if (identical(afterParens, '{') || identical(afterParens, '=>')) {
          return parseFunctionDeclaration(token);
        }
      }
    }
    return parseExpressionStatement(token);
  }

  Token parseExpressionStatementOrConstDeclaration(Token token) {
    assert(identical(token.stringValue, 'const'));
    if (isModifier(token.next)) {
      return parseVariablesDeclaration(token);
    }
    Token identifier = peekIdentifierAfterOptionalType(token.next);
    if (identifier != null) {
      assert(identifier.isIdentifier());
      Token afterId = identifier.next;
      int afterIdKind = afterId.kind;
      if (identical(afterIdKind, EQ_TOKEN) ||
          identical(afterIdKind, SEMICOLON_TOKEN) ||
          identical(afterIdKind, COMMA_TOKEN)) {
        // We are looking at "const type identifier" followed by '=', ';', or
        // ','.
        return parseVariablesDeclaration(token);
      }
      // Fall-through to expression statement.
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
    int labelCount = 0;
    do {
      token = parseLabel(token);
      labelCount++;
    } while (token.isIdentifier() && optional(':', token.next));
    listener.beginLabeledStatement(token, labelCount);
    token = parseStatement(token);
    listener.endLabeledStatement(labelCount);
    return token;
  }

  Token parseExpressionStatement(Token token) {
    listener.beginExpressionStatement(token);
    token = parseExpression(token);
    listener.endExpressionStatement(token);
    return expectSemicolon(token);
  }

  Token parseExpression(Token token) {
    return parsePrecedenceExpression(token, ASSIGNMENT_PRECEDENCE, true);
  }

  Token parseExpressionWithoutCascade(Token token) {
    return parsePrecedenceExpression(token, ASSIGNMENT_PRECEDENCE, false);
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
                                  bool allowCascades) {
    assert(precedence >= 1);
    assert(precedence <= POSTFIX_PRECEDENCE);
    token = parseUnaryExpression(token, allowCascades);
    PrecedenceInfo info = token.info;
    int tokenLevel = info.precedence;
    for (int level = tokenLevel; level >= precedence; --level) {
      while (identical(tokenLevel, level)) {
        Token operator = token;
        if (identical(tokenLevel, CASCADE_PRECEDENCE)) {
          if (!allowCascades) {
            return token;
          }
          token = parseCascadeExpression(token);
        } else if (identical(tokenLevel, ASSIGNMENT_PRECEDENCE)) {
          // Right associative, so we recurse at the same precedence
          // level.
          token = parsePrecedenceExpression(token.next, level, allowCascades);
          listener.handleAssignmentExpression(operator);
        } else if (identical(tokenLevel, POSTFIX_PRECEDENCE)) {
          if (identical(info, PERIOD_INFO)) {
            // Left associative, so we recurse at the next higher
            // precedence level. However, POSTFIX_PRECEDENCE is the
            // highest level, so we just call parseUnaryExpression
            // directly.
            token = parseUnaryExpression(token.next, allowCascades);
            listener.handleBinaryExpression(operator);
          } else if ((identical(info, OPEN_PAREN_INFO)) ||
                     (identical(info, OPEN_SQUARE_BRACKET_INFO))) {
            token = parseArgumentOrIndexStar(token);
          } else if ((identical(info, PLUS_PLUS_INFO)) ||
                     (identical(info, MINUS_MINUS_INFO))) {
            listener.handleUnaryPostfixAssignmentExpression(token);
            token = token.next;
          } else {
            token = listener.unexpected(token);
          }
        } else if (identical(info, IS_INFO)) {
          token = parseIsOperatorRest(token);
        } else if (identical(info, AS_INFO)) {
          token = parseAsOperatorRest(token);
        } else if (identical(info, QUESTION_INFO)) {
          token = parseConditionalExpressionRest(token);
        } else {
          // Left associative, so we recurse at the next higher
          // precedence level.
          token = parsePrecedenceExpression(token.next, level + 1,
                                            allowCascades);
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
    } else if (token.isIdentifier()) {
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
    } while (!identical(mark, token));

    if (identical(token.info.precedence, ASSIGNMENT_PRECEDENCE)) {
      Token assignment = token;
      token = parseExpressionWithoutCascade(token.next);
      listener.handleAssignmentExpression(assignment);
    }
    listener.endCascade();
    return token;
  }

  Token parseUnaryExpression(Token token, bool allowCascades) {
    String value = token.stringValue;
    // Prefix:
    if (identical(value, '+')) {
      // Dart only allows "prefix plus" as an initial part of a
      // decimal literal. We scan it as a separate token and let
      // the parser listener combine it with the digits.
      Token next = token.next;
      if (identical(next.charOffset, token.charOffset + 1)) {
        if (identical(next.kind, INT_TOKEN)) {
          listener.handleLiteralInt(token);
          return next.next;
        }
        if (identical(next.kind, DOUBLE_TOKEN)) {
          listener.handleLiteralDouble(token);
          return next.next;
        }
      }
      listener.recoverableError("Unexpected token '+'", token: token);
      return parsePrecedenceExpression(next, POSTFIX_PRECEDENCE,
                                       allowCascades);
    } else if ((identical(value, '!')) ||
               (identical(value, '-')) ||
               (identical(value, '~'))) {
      Token operator = token;
      // Right associative, so we recurse at the same precedence
      // level.
      token = parsePrecedenceExpression(token.next, POSTFIX_PRECEDENCE,
                                        allowCascades);
      listener.handleUnaryPrefixExpression(operator);
    } else if ((identical(value, '++')) || identical(value, '--')) {
      // TODO(ahe): Validate this is used correctly.
      Token operator = token;
      // Right associative, so we recurse at the same precedence
      // level.
      token = parsePrecedenceExpression(token.next, POSTFIX_PRECEDENCE,
                                        allowCascades);
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
    if (identical(kind, IDENTIFIER_TOKEN)) {
      return parseSendOrFunctionLiteral(token);
    } else if (identical(kind, INT_TOKEN)
        || identical(kind, HEXADECIMAL_TOKEN)) {
      return parseLiteralInt(token);
    } else if (identical(kind, DOUBLE_TOKEN)) {
      return parseLiteralDouble(token);
    } else if (identical(kind, STRING_TOKEN)) {
      return parseLiteralString(token);
    } else if (identical(kind, KEYWORD_TOKEN)) {
      final value = token.stringValue;
      if ((identical(value, 'true')) || (identical(value, 'false'))) {
        return parseLiteralBool(token);
      } else if (identical(value, 'null')) {
        return parseLiteralNull(token);
      } else if (identical(value, 'this')) {
        return parseThisExpression(token);
      } else if (identical(value, 'super')) {
        return parseSuperExpression(token);
      } else if (identical(value, 'new')) {
        return parseNewExpression(token);
      } else if (identical(value, 'const')) {
        return parseConstExpression(token);
      } else if (identical(value, 'void')) {
        return parseFunctionExpression(token);
      } else if (token.isIdentifier()) {
        return parseSendOrFunctionLiteral(token);
      } else {
        return listener.expectedExpression(token);
      }
    } else if (identical(kind, OPEN_PAREN_TOKEN)) {
      return parseParenthesizedExpressionOrFunctionLiteral(token);
    } else if ((identical(kind, LT_TOKEN)) ||
               (identical(kind, OPEN_SQUARE_BRACKET_TOKEN)) ||
               (identical(kind, OPEN_CURLY_BRACKET_TOKEN)) ||
               identical(token.stringValue, '[]')) {
      return parseLiteralListOrMap(token);
    } else if (identical(kind, QUESTION_TOKEN)) {
      return parseArgumentDefinitionTest(token);
    } else {
      return listener.expectedExpression(token);
    }
  }

  Token parseArgumentDefinitionTest(Token token) {
    Token questionToken = token;
    listener.beginArgumentDefinitionTest(questionToken);
    assert(optional('?', token));
    token = parseIdentifier(token.next);
    listener.endArgumentDefinitionTest(questionToken, token);
    return token;
  }

  Token parseParenthesizedExpressionOrFunctionLiteral(Token token) {
    BeginGroupToken beginGroup = token;
    int kind = beginGroup.endGroup.next.kind;
    if (mayParseFunctionExpressions &&
        (identical(kind, FUNCTION_TOKEN)
            || identical(kind, OPEN_CURLY_BRACKET_TOKEN))) {
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
    Token begin = token;
    token = expect('(', token);
    token = parseExpression(token);
    if (!identical(begin.endGroup, token)) {
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
    Token peek = peekAfterExpectedType(token);
    if (identical(peek.kind, IDENTIFIER_TOKEN) && isFunctionDeclaration(peek.next)) {
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
      if (identical(afterParens, '{') || identical(afterParens, '=>')) {
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
    if ((identical(value, '<')) ||
        (identical(value, '[')) ||
        (identical(value, '[]')) ||
        (identical(value, '{'))) {
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
    while (identical(token.kind, STRING_TOKEN)) {
      token = parseSingleLiteralString(token);
      count++;
    }
    if (count > 1) {
      listener.handleStringJuxtaposition(count);
    }
    return token;
  }

  /**
   * Only called when [:token.kind === STRING_TOKEN:].
   */
  Token parseSingleLiteralString(Token token) {
    listener.beginLiteralString(token);
    // Parsing the prefix, for instance 'x of 'x${id}y${id}z'
    token = token.next;
    int interpolationCount = 0;
    var kind = token.kind;
    while (kind != EOF_TOKEN) {
      if (identical(kind, STRING_INTERPOLATION_TOKEN)) {
        // Parsing ${expression}.
        token = token.next;
        token = parseExpression(token);
        token = expect('}', token);
      } else if (identical(kind, STRING_INTERPOLATION_IDENTIFIER_TOKEN)) {
        // Parsing $identifier.
        token = token.next;
        token = parseExpression(token);
      } else {
        break;
      }
      ++interpolationCount;
      // Parsing the infix/suffix, for instance y and z' of 'x${id}y${id}z'
      token = parseStringPart(token);
      kind = token.kind;
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
    assert(identical('(', token.stringValue));
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
      if (colon != null) listener.handleNamedArgument(colon);
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
    String value = token.stringValue;
    if (identical(value, 'is') || identical(value, 'as')) {
      // The is- and as-operators cannot be chained, but they can take part of
      // expressions like: foo is Foo || foo is Bar.
      listener.unexpected(token);
    }
    return token;
  }

  Token parseAsOperatorRest(Token token) {
    assert(optional('as', token));
    Token operator = token;
    token = parseType(token.next);
    listener.handleAsOperator(operator, token);
    String value = token.stringValue;
    if (identical(value, 'is') || identical(value, 'as')) {
      // The is- and as-operators cannot be chained.
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
    if (identical(value, ';')) {
      listener.handleNoExpression(token);
      return token;
    } else if ((identical(value, 'var')) || (identical(value, 'final'))) {
      return parseVariablesDeclarationNoSemicolon(token);
    }
    Token identifier = peekIdentifierAfterType(token);
    if (identifier != null) {
      assert(identifier.isIdentifier());
      Token afterId = identifier.next;
      int afterIdKind = afterId.kind;
      if (identical(afterIdKind, EQ_TOKEN) || identical(afterIdKind, SEMICOLON_TOKEN) ||
          identical(afterIdKind, COMMA_TOKEN) || optional('in', afterId)) {
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

    String value = token.stringValue;
    while (identical(value, 'catch') || identical(value, 'on')) {
      var onKeyword = null;
      if (identical(value, 'on')) {
        // on qualified catchPart?
        onKeyword = token;
        token = parseType(token.next);
        value = token.stringValue;
      }
      Token catchKeyword = null;
      if (identical(value, 'catch')) {
        catchKeyword = token;
        // TODO(ahe): Validate the "parameters".
        token = parseFormalParameters(token.next);
      }
      token = parseBlock(token);
      ++catchCount;
      listener.handleCatchBlock(onKeyword, catchKeyword);
      value = token.stringValue; // while condition
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
    while (!identical(token.kind, EOF_TOKEN)) {
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

  /**
   * Peek after the following labels (if any). The following token
   * is used to determine if the labels belong to a statement or a
   * switch case.
   */
  Token peekPastLabels(Token token) {
    while (token.isIdentifier() && optional(':', token.next)) {
      token = token.next.next;
    }
    return token;
  }

  /**
   * Parse a group of labels, cases and possibly a default keyword and
   * the statements that they select.
   */
  Token parseSwitchCase(Token token) {
    Token begin = token;
    Token defaultKeyword = null;
    int expressionCount = 0;
    int labelCount = 0;
    Token peek = peekPastLabels(token);
    while (true) {
      // Loop until we find something that can't be part of a switch case.
      String value = peek.stringValue;
      if (identical(value, 'default')) {
        while (!identical(token, peek)) {
          token = parseLabel(token);
          labelCount++;
        }
        defaultKeyword = token;
        token = expect(':', token.next);
        peek = token;
        break;
      } else if (identical(value, 'case')) {
        while (!identical(token, peek)) {
          token = parseLabel(token);
          labelCount++;
        }
        Token caseKeyword = token;
        token = parseExpression(token.next);
        Token colonToken = token;
        token = expect(':', token);
        listener.handleCaseMatch(caseKeyword, colonToken);
        expressionCount++;
        peek = peekPastLabels(token);
      } else {
        if (expressionCount == 0) {
          listener.expected("case", token);
        }
        break;
      }
    }
    // Finally zero or more statements.
    int statementCount = 0;
    while (!identical(token.kind, EOF_TOKEN)) {
      String value = peek.stringValue;
      if ((identical(value, 'case')) ||
          (identical(value, 'default')) ||
          ((identical(value, '}')) && (identical(token, peek)))) {
        // A label just before "}" will be handled as a statement error.
        break;
      } else {
        token = parseStatement(token);
      }
      statementCount++;
      peek = peekPastLabels(token);
    }
    listener.handleSwitchCase(labelCount, expressionCount, defaultKeyword,
                              statementCount, begin, token);
    return token;
  }

  Token parseBreakStatement(Token token) {
    assert(optional('break', token));
    Token breakKeyword = token;
    token = token.next;
    bool hasTarget = false;
    if (token.isIdentifier()) {
      token = parseIdentifier(token);
      hasTarget = true;
    }
    listener.handleBreakStatement(hasTarget, breakKeyword, token);
    return expectSemicolon(token);
  }

  Token parseAssertStatement(Token token) {
    Token assertKeyword = token;
    token = expect('assert', token);
    expect('(', token);
    token = parseArguments(token);
    listener.handleAssertStatement(assertKeyword, token);
    return expectSemicolon(token);
  }

  Token parseContinueStatement(Token token) {
    assert(optional('continue', token));
    Token continueKeyword = token;
    token = token.next;
    bool hasTarget = false;
    if (token.isIdentifier()) {
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
