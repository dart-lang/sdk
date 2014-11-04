// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of scanner;

class FormalParameterType {
  final String type;
  const FormalParameterType(this.type);
  bool get isRequired => this == REQUIRED;
  bool get isPositional => this == POSITIONAL;
  bool get isNamed => this == NAMED;
  static final REQUIRED = const FormalParameterType('required');
  static final POSITIONAL = const FormalParameterType('positional');
  static final NAMED = const FormalParameterType('named');
}

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
  bool yieldIsKeyword = false;
  bool awaitIsKeyword = false;

  Parser(this.listener);

  Token parseUnit(Token token) {
    listener.beginCompilationUnit(token);
    int count = 0;
    while (!identical(token.kind, EOF_TOKEN)) {
      token = parseTopLevelDeclaration(token);
      listener.endTopLevelDeclaration(token);
      count++;
    }
    listener.endCompilationUnit(count, token);
    return token;
  }

  Token parseTopLevelDeclaration(Token token) {
    token = parseMetadataStar(token);
    final String value = token.stringValue;
    if ((identical(value, 'abstract') && optional('class', token.next))
        || identical(value, 'class')) {
      return parseClassOrNamedMixinApplication(token);
    } else if (identical(value, 'typedef')) {
      return parseTypedef(token);
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
    Token deferredKeyword;
    if (optional('deferred', token)) {
      deferredKeyword = token;
      token = token.next;
    }
    Token asKeyword;
    if (optional('as', token)) {
      asKeyword = token;
      token = parseIdentifier(token.next);
    }
    token = parseCombinators(token);
    Token semicolon = token;
    token = expect(';', token);
    listener.endImport(importKeyword, deferredKeyword, asKeyword, semicolon);
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
        break;
      }
      count++;
    }
    return token;
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

  /// type (, type)*
  Token parseTypeList(Token token) {
    listener.beginTypeList(token);
    token = parseType(token);
    int count = 1;
    while (optional(',', token)) {
      token = parseType(token.next);
      count++;
    }
    listener.endTypeList(count);
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

  Token parseMetadataStar(Token token, {bool forParameter: false}) {
    listener.beginMetadataStar(token);
    int count = 0;
    while (optional('@', token)) {
      token = parseMetadata(token);
      count++;
    }
    listener.endMetadataStar(count, forParameter);
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
    token = parseTypeArgumentsOpt(token);
    Token period = null;
    if (optional('.', token)) {
      period = token;
      token = parseIdentifier(token.next);
    }
    token = parseArgumentsOpt(token);
    listener.endMetadata(atToken, period, token);
    return token;
  }

  Token parseTypedef(Token token) {
    Token typedefKeyword = token;
    if (optional('=', peekAfterType(token.next))) {
      // TODO(aprelev@gmail.com): Remove deprecated 'typedef' mixin application,
      // remove corresponding diagnostic from members.dart.
      listener.beginNamedMixinApplication(token);
      token = parseIdentifier(token.next);
      token = parseTypeVariablesOpt(token);
      token = expect('=', token);
      token = parseModifiers(token);
      token = parseMixinApplication(token);
      Token implementsKeyword = null;
      if (optional('implements', token)) {
        implementsKeyword = token;
        token = parseTypeList(token.next);
      }
      listener.endNamedMixinApplication(
          typedefKeyword, implementsKeyword, token);
    } else {
      listener.beginFunctionTypeAlias(token);
      token = parseReturnTypeOpt(token.next);
      token = parseIdentifier(token);
      token = parseTypeVariablesOpt(token);
      token = parseFormalParameters(token);
      listener.endFunctionTypeAlias(typedefKeyword, token);
    }
    return expect(';', token);
  }

  Token parseMixinApplication(Token token) {
    listener.beginMixinApplication(token);
    token = parseType(token);
    token = expect('with', token);
    token = parseTypeList(token);
    listener.endMixinApplication();
    return token;
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
      token = parseFormalParameter(token, FormalParameterType.REQUIRED);
    } while (optional(',', token));
    listener.endFormalParameters(parameterCount, begin, token);
    return expect(')', token);
  }

  Token parseFormalParameter(Token token, FormalParameterType type) {
    token = parseMetadataStar(token, forParameter: true);
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
      if (type.isRequired) {
        listener.reportError(equal,
            MessageKind.REQUIRED_PARAMETER_WITH_DEFAULT);
      } else if (type.isNamed && identical('=', value)) {
        listener.reportError(equal, MessageKind.NAMED_PARAMETER_WITH_EQUALS);
      } else if (type.isPositional && identical(':', value)) {
        listener.reportError(equal,
            MessageKind.POSITIONAL_PARAMETER_WITH_EQUALS);
      }
    }
    listener.endFormalParameter(thisKeyword);
    return token;
  }

  Token parseOptionalFormalParameters(Token token, bool isNamed) {
    Token begin = token;
    listener.beginOptionalFormalParameters(begin);
    assert((isNamed && optional('{', token)) || optional('[', token));
    int parameterCount = 0;
    do {
      token = token.next;
      var type = isNamed ? FormalParameterType.NAMED
                         : FormalParameterType.POSITIONAL;
      token = parseFormalParameter(token, type);
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
    Token peek = peekAfterIfType(token);
    if (peek != null && (peek.isIdentifier() || optional('this', peek))) {
      return parseType(token);
    }
    listener.handleNoType(token);
    return token;
  }

  bool isValidTypeReference(Token token) {
    final kind = token.kind;
    if (identical(kind, IDENTIFIER_TOKEN)) return true;
    if (identical(kind, KEYWORD_TOKEN)) {
      Keyword keyword = (token as KeywordToken).keyword;
      String value = keyword.syntax;
      return keyword.isPseudo
          || (identical(value, 'dynamic'))
          || (identical(value, 'void'));
    }
    return false;
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

  Token parseClassOrNamedMixinApplication(Token token) {
    Token begin = token;
    Token abstractKeyword;
    if (optional('abstract', token)) {
      abstractKeyword = token;
      token = token.next;
    }
    Token classKeyword = token;
    var isMixinApplication = optional('=', peekAfterType(token.next));
    if (isMixinApplication) {
      listener.beginNamedMixinApplication(begin);
      token = parseIdentifier(token.next);
      token = parseTypeVariablesOpt(token);
      token = expect('=', token);
    } else {
      listener.beginClassDeclaration(begin);
    }

    // TODO(aprelev@gmail.com): Once 'typedef' named mixin application is
    // removed, move modifiers for named mixin application to the bottom of
    // listener stack. This is so stacks for class declaration and named
    // mixin application look similar.
    int modifierCount = 0;
    if (abstractKeyword != null) {
      parseModifier(abstractKeyword);
      modifierCount++;
    }
    listener.handleModifiers(modifierCount);

    if (isMixinApplication) {
      return parseNamedMixinApplication(token, classKeyword);
    } else {
      return parseClass(begin, classKeyword);
    }
  }

  Token parseNamedMixinApplication(Token token, Token classKeyword) {
    token = parseMixinApplication(token);
    Token implementsKeyword = null;
    if (optional('implements', token)) {
      implementsKeyword = token;
      token = parseTypeList(token.next);
    }
    listener.endNamedMixinApplication(
        classKeyword, implementsKeyword, token);
    return expect(';', token);
  }

  Token parseClass(Token begin, Token classKeyword) {
    Token token = parseIdentifier(classKeyword.next);
    token = parseTypeVariablesOpt(token);
    Token extendsKeyword;
    if (optional('extends', token)) {
      extendsKeyword = token;
      if (optional('with', peekAfterType(token.next))) {
        token = parseMixinApplication(token.next);
      } else {
        token = parseType(token.next);
      }
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
    if (!token.isIdentifier()) {
      token = listener.expectedIdentifier(token);
    }
    listener.handleIdentifier(token);
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
  bool optional(String value, Token token) {
    return identical(value, token.stringValue);
  }

  /**
   * Returns true if the stringValue of the [token] is either [value1],
   * [value2], [value3], or [value4].
   */
  bool isOneOf4(Token token,
                String value1, String value2, String value3, String value4) {
    String stringValue = token.stringValue;
    return identical(value1, stringValue) ||
           identical(value2, stringValue) ||
           identical(value3, stringValue) ||
           identical(value4, stringValue);
  }

  bool notEofOrValue(String value, Token token) {
    return !identical(token.kind, EOF_TOKEN) &&
           !identical(value, token.stringValue);
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
        token = new SymbolToken(GT_INFO, token.charOffset);
        token.next = new SymbolToken(GT_INFO, token.charOffset + 1);
        token.next.next = next;
      } else if (identical(token.stringValue, '>>>')) {
        token = new SymbolToken(GT_INFO, token.charOffset);
        token.next = new SymbolToken(GT_GT_INFO, token.charOffset + 1);
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
    if (identifiers.isEmpty) {
      return listener.expectedDeclaration(start);
    }
    Token name = identifiers.head;
    identifiers = identifiers.tail;
    Token getOrSet;
    if (!identifiers.isEmpty) {
      String value = identifiers.head.stringValue;
      if ((identical(value, 'get')) || (identical(value, 'set'))) {
        getOrSet = identifiers.head;
        identifiers = identifiers.tail;
      }
    }
    Token type;
    if (!identifiers.isEmpty) {
      if (isValidTypeReference(identifiers.head)) {
        type = identifiers.head;
        identifiers = identifiers.tail;
      }
    }

    token = name.next;
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
        if (identical(token.kind, EOF_TOKEN)) return token;
      }
    }
    var modifiers = identifiers.reverse();
    return isField
        ? parseFields(start, modifiers, type, getOrSet, name, true)
        : parseTopLevelMethod(start, modifiers, type, getOrSet, name);
  }

  bool isVarFinalOrConst(Token token) {
    String value = token.stringValue;
    return identical('var', value)
        || identical('final', value)
        || identical('const', value);
  }

  Token expectVarFinalOrConst(Link<Token> modifiers,
                              bool hasType,
                              bool allowStatic) {
    int modifierCount = 0;
    Token staticModifier;
    if (allowStatic && !modifiers.isEmpty
        && optional('static', modifiers.head)) {
      staticModifier = modifiers.head;
      modifierCount++;
      parseModifier(staticModifier);
      modifiers = modifiers.tail;
    }
    if (modifiers.isEmpty) {
      listener.handleModifiers(modifierCount);
      return null;
    }
    if (modifiers.tail.isEmpty) {
      Token modifier = modifiers.head;
      if (isVarFinalOrConst(modifier)) {
        modifierCount++;
        parseModifier(modifier);
        listener.handleModifiers(modifierCount);
        // TODO(ahe): The caller checks for "var Type name", perhaps we should
        // check here instead.
        return modifier;
      }
    }

    // Slow case to report errors.
    List<Token> modifierList = modifiers.toList();
    Token varFinalOrConst =
        modifierList.firstWhere(isVarFinalOrConst, orElse: () => null);
    if (allowStatic && staticModifier == null) {
      staticModifier =
          modifierList.firstWhere(
              (modifier) => optional('static', modifier), orElse: () => null);
      if (staticModifier != null) {
        modifierCount++;
        parseModifier(staticModifier);
        modifierList.remove(staticModifier);
      }
    }
    bool hasTypeOrModifier = hasType;
    if (varFinalOrConst != null) {
      parseModifier(varFinalOrConst);
      modifierCount++;
      hasTypeOrModifier = true;
      modifierList.remove(varFinalOrConst);
    }
    listener.handleModifiers(modifierCount);
    var kind = hasTypeOrModifier
        ? MessageKind.EXTRANEOUS_MODIFIER
        : MessageKind.EXTRANEOUS_MODIFIER_REPLACE;
    for (Token modifier in modifierList) {
      listener.reportError(modifier, kind, {'modifier': modifier});
    }
    return null;
  }

  Token parseFields(Token start,
                    Link<Token> modifiers,
                    Token type,
                    Token getOrSet,
                    Token name,
                    bool isTopLevel) {
    bool hasType = type != null;
    Token varFinalOrConst =
        expectVarFinalOrConst(modifiers, hasType, !isTopLevel);
    bool isVar = false;
    bool hasModifier = false;
    if (varFinalOrConst != null) {
      hasModifier = true;
      isVar = optional('var', varFinalOrConst);
    }

    if (getOrSet != null) {
      var kind = (hasModifier || hasType)
          ? MessageKind.EXTRANEOUS_MODIFIER
          : MessageKind.EXTRANEOUS_MODIFIER_REPLACE;
      listener.reportError(getOrSet, kind, {'modifier': getOrSet});
    }

    if (!hasType) {
      listener.handleNoType(name);
    } else if (optional('void', type)) {
      listener.handleNoType(name);
      // TODO(ahe): This error is reported twice, second time is from
      // [parseVariablesDeclarationMaybeSemicolon] via
      // [PartialFieldListElement.parseNode].
      listener.reportError(type, MessageKind.VOID_NOT_ALLOWED);
    } else {
      parseType(type);
      if (isVar) {
        listener.reportError(
            modifiers.head, MessageKind.EXTRANEOUS_MODIFIER,
            {'modifier': modifiers.head});
      }
    }

    Token token = parseIdentifier(name);

    int fieldCount = 1;
    token = parseVariableInitializerOpt(token);
    while (optional(',', token)) {
      token = parseIdentifier(token.next);
      token = parseVariableInitializerOpt(token);
      ++fieldCount;
    }
    Token semicolon = token;
    token = expectSemicolon(token);
    if (isTopLevel) {
      listener.endTopLevelFields(fieldCount, start, semicolon);
    } else {
      listener.endFields(fieldCount, start, semicolon);
    }
    return token;
  }

  Token parseTopLevelMethod(Token start,
                            Link<Token> modifiers,
                            Token type,
                            Token getOrSet,
                            Token name) {
    Token externalModifier;
    for (Token modifier in modifiers) {
      if (externalModifier == null && optional('external', modifier)) {
        externalModifier = modifier;
      } else {
        listener.reportError(
            modifier, MessageKind.EXTRANEOUS_MODIFIER, {'modifier': modifier});
      }
    }
    if (externalModifier != null) {
      parseModifier(externalModifier);
      listener.handleModifiers(1);
    } else {
      listener.handleModifiers(0);
    }

    if (type == null) {
      listener.handleNoType(name);
    } else {
      parseReturnTypeOpt(type);
    }
    Token token = parseIdentifier(name);

    token = parseFormalParametersOpt(token);
    bool previousYieldIsKeyword = yieldIsKeyword;
    bool previousAwaitIsKeyword = awaitIsKeyword;
    token = parseAsyncModifier(token);
    token = parseFunctionBody(token, false, externalModifier != null);
    yieldIsKeyword = previousYieldIsKeyword;
    awaitIsKeyword = previousAwaitIsKeyword;
    listener.endTopLevelMethod(start, getOrSet, token);
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
            if (beginGroup.endGroup == null) {
              listener.unmatched(beginGroup);
            }
            token = beginGroup.endGroup;
          }
        }
      }
      token = token.next;
    }
    return const Link<Token>();
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

  Token parseLiteralStringOrRecoverExpression(Token token) {
    if (identical(token.kind, STRING_TOKEN)) {
      return parseLiteralString(token);
    } else {
      listener.recoverableError(token, "unexpected");
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
    for (; !tokens.isEmpty; tokens = tokens.tail) {
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

  /**
   * Returns the first token after the type starting at [token].
   * This method assumes that [token] is an identifier (or void).
   * Use [peekAfterIfType] if [token] isn't known to be an identifier.
   */
  Token peekAfterType(Token token) {
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
   * If [token] is the start of a type, returns the token after that type.
   * If [token] is not the start of a type, null is returned.
   */
  Token peekAfterIfType(Token token) {
    if (!optional('void', token) && !token.isIdentifier()) {
      return null;
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
    expect('}', token);
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
    if (identifiers.isEmpty) {
      return listener.expectedDeclaration(start);
    }
    Token name = identifiers.head;
    Token afterName = name.next;
    identifiers = identifiers.tail;
    if (!identifiers.isEmpty) {
      if (optional('operator', identifiers.head)) {
        name = identifiers.head;
        identifiers = identifiers.tail;
      }
    }
    Token getOrSet;
    if (!identifiers.isEmpty) {
      if (isGetOrSet(identifiers.head)) {
        getOrSet = identifiers.head;
        identifiers = identifiers.tail;
      }
    }
    Token type;
    if (!identifiers.isEmpty) {
      if (isValidTypeReference(identifiers.head)) {
        type = identifiers.head;
        identifiers = identifiers.tail;
      }
    }

    token = afterName;
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

    var modifiers = identifiers.reverse();
    return isField
        ? parseFields(start, modifiers, type, getOrSet, name, false)
        : parseMethod(start, modifiers, type, getOrSet, name);

  }

  Token parseMethod(Token start,
                    Link<Token> modifiers,
                    Token type,
                    Token getOrSet,
                    Token name) {
    Token externalModifier;
    Token staticModifier;
    Token constModifier;
    int modifierCount = 0;
    int allowedModifierCount = 1;
    for (Token modifier in modifiers) {
      if (externalModifier == null && optional('external', modifier)) {
        modifierCount++;
        externalModifier = modifier;
        if (modifierCount != allowedModifierCount) {
          listener.reportError(
              modifier,
              MessageKind.EXTRANEOUS_MODIFIER, {'modifier': modifier});
        }
        allowedModifierCount++;
      } else if (staticModifier == null && optional('static', modifier)) {
        modifierCount++;
        staticModifier = modifier;
        if (modifierCount != allowedModifierCount) {
          listener.reportError(
              modifier,
              MessageKind.EXTRANEOUS_MODIFIER, {'modifier': modifier});
        }
      } else if (constModifier == null && optional('const', modifier)) {
        modifierCount++;
        constModifier = modifier;
        if (modifierCount != allowedModifierCount) {
          listener.reportError(
              modifier,
              MessageKind.EXTRANEOUS_MODIFIER, {'modifier': modifier});
        }
      } else {
        listener.reportError(
            modifier, MessageKind.EXTRANEOUS_MODIFIER, {'modifier': modifier});
      }
    }
    parseModifierList(modifiers);

    if (type == null) {
      listener.handleNoType(name);
    } else {
      parseReturnTypeOpt(type);
    }
    Token token;
    if (optional('operator', name)) {
      token = parseOperatorName(name);
      if (staticModifier != null) {
        // TODO(ahe): Consider a more specific error message.
        listener.reportError(
            staticModifier, MessageKind.EXTRANEOUS_MODIFIER,
            {'modifier': staticModifier});
      }
    } else {
      token = parseIdentifier(name);
    }

    token = parseQualifiedRestOpt(token);
    token = parseFormalParametersOpt(token);
    token = parseInitializersOpt(token);
    bool previousYieldIsKeyword = yieldIsKeyword;
    bool previousAwaitIsKeyword = awaitIsKeyword;
    token = parseAsyncModifier(token);
    if (optional('=', token)) {
      token = parseRedirectingFactoryBody(token);
    } else {
      token = parseFunctionBody(
          token, false, staticModifier == null || externalModifier != null);
    }
    yieldIsKeyword = previousYieldIsKeyword;
    awaitIsKeyword = previousAwaitIsKeyword;
    listener.endMethod(getOrSet, start, token);
    return token.next;
  }

  Token parseFactoryMethod(Token token) {
    assert(isFactoryDeclaration(token));
    Token start = token;
    Token externalModifier;
    if (identical(token.stringValue, 'external')) {
      externalModifier = token;
      token = token.next;
    }
    Token constKeyword = null;
    if (optional('const', token)) {
      constKeyword = token;
      token = token.next;
    }
    Token factoryKeyword = token;
    listener.beginFactoryMethod(factoryKeyword);
    token = token.next; // Skip 'factory'.
    token = parseConstructorReference(token);
    token = parseFormalParameters(token);
    bool previousYieldIsKeyword = yieldIsKeyword;
    bool previousAwaitIsKeyword = awaitIsKeyword;
    token = parseAsyncModifier(token);
    if (optional('=', token)) {
      token = parseRedirectingFactoryBody(token);
    } else {
      token = parseFunctionBody(token, false, externalModifier != null);
    }
    listener.endFactoryMethod(start, token);
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
    bool previousYieldIsKeyword = yieldIsKeyword;
    bool previousAwaitIsKeyword = awaitIsKeyword;
    token = parseAsyncModifier(token);
    if (optional('=', token)) {
      token = parseRedirectingFactoryBody(token);
    } else {
      token = parseFunctionBody(token, false, true);
    }
    yieldIsKeyword = previousYieldIsKeyword;
    awaitIsKeyword = previousAwaitIsKeyword;
    listener.endFunction(getOrSet, token);
    return token.next;
  }

  Token parseUnnamedFunction(Token token) {
    listener.beginUnnamedFunction(token);
    token = parseFormalParameters(token);
    bool previousYieldIsKeyword = yieldIsKeyword;
    bool previousAwaitIsKeyword = awaitIsKeyword;
    token = parseAsyncModifier(token);
    bool isBlock = optional('{', token);
    token = parseFunctionBody(token, true, false);
    yieldIsKeyword = previousYieldIsKeyword;
    awaitIsKeyword = previousAwaitIsKeyword;
    listener.endUnnamedFunction(token);
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
    bool previousYieldIsKeyword = yieldIsKeyword;
    bool previousAwaitIsKeyword = awaitIsKeyword;
    token = parseAsyncModifier(token);
    bool isBlock = optional('{', token);
    token = parseFunctionBody(token, true, false);
    yieldIsKeyword = previousYieldIsKeyword;
    awaitIsKeyword = previousAwaitIsKeyword;
    listener.endFunction(null, token);
    return isBlock ? token.next : token;
  }

  Token parseConstructorReference(Token token) {
    Token start = token;
    listener.beginConstructorReference(start);
    token = parseIdentifier(token);
    token = parseQualifiedRestOpt(token);
    token = parseTypeArgumentsOpt(token);
    Token period = null;
    if (optional('.', token)) {
      period = token;
      token = parseIdentifier(token.next);
    }
    listener.endConstructorReference(start, period, token);
    return token;
  }

  Token parseRedirectingFactoryBody(Token token) {
    listener.beginRedirectingFactoryBody(token);
    assert(optional('=', token));
    Token equals = token;
    token = parseConstructorReference(token.next);
    Token semicolon = token;
    expectSemicolon(token);
    listener.endRedirectingFactoryBody(equals, semicolon);
    return token;
  }

  Token parseFunctionBody(Token token, bool isExpression, bool allowAbstract) {
    if (optional(';', token)) {
      if (!allowAbstract) {
        listener.reportError(token, MessageKind.BODY_EXPECTED);
      }
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

  /// `async*` and `sync*` are parsed a two tokens, [token] and [star]. This
  /// method checks that there is no whitespace between [token] and [star].
  void checkStarredModifier(Token token, Token star, String name) {
    if (star.charOffset > token.charOffset + token.charCount) {
      listener.reportError(new TokenPair(token, star),
          MessageKind.INVALID_STARRED_KEYWORD, {'keyword': name});
    }
  }

  Token parseAsyncModifier(Token token) {
    Token async;
    Token star;
    awaitIsKeyword = false;
    yieldIsKeyword = false;
    if (optional('async', token)) {
      awaitIsKeyword = true;
      async = token;
      token = token.next;
      if (optional('*', token)) {
        yieldIsKeyword = true;
        star = token;
        token = token.next;
        checkStarredModifier(async, star, 'async*');
      }
    } else if (optional('sync', token)) {
      async = token;
      token = token.next;
      if (optional('*', token)) {
        yieldIsKeyword = true;
        star = token;
        token = token.next;

        checkStarredModifier(async, star, 'sync*');
      } else {
        listener.reportError(async,
            MessageKind.INVALID_SYNC_MODIFIER);
      }
    }
    listener.handleAsyncModifier(async, star);
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
    } else if (awaitIsKeyword && identical(value, 'await')) {
      if (identical(token.next.stringValue, 'for')) {
        return parseForStatement(token, token.next);
      } else {
        return parseExpressionStatement(token);
      }
    } else if (identical(value, 'for')) {
      return parseForStatement(null, token);
    } else if (identical(value, 'rethrow')) {
      return parseRethrowStatement(token);
    } else if (identical(value, 'throw') && optional(';', token.next)) {
      // TODO(kasperl): Stop dealing with throw here.
      return parseRethrowStatement(token);
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
    } else if (yieldIsKeyword && identical(value, 'yield')) {
      return parseYieldStatement(token);
    } else if (identical(value, 'const')) {
      return parseExpressionStatementOrConstDeclaration(token);
    } else if (token.isIdentifier()) {
      return parseExpressionStatementOrDeclaration(token);
    } else {
      return parseExpressionStatement(token);
    }
  }

  Token parseYieldStatement(Token token) {
    Token begin = token;
    listener.beginYieldStatement(begin);
    assert(identical('yield', token.stringValue));
    token = token.next;
    Token starToken;
    if (optional('*', token)) {
      starToken = token;
      token = token.next;
      checkStarredModifier(begin, starToken, 'yield*');
    }
    token = parseExpression(token);
    listener.endYieldStatement(begin, starToken, token);
    return expectSemicolon(token);
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
        if (optional('{', afterParens) ||
            optional('=>', afterParens) ||
            optional('async', afterParens) ||
            optional('sync', afterParens)) {
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
        if (identical(afterParens, '{') ||
            identical(afterParens, '=>') ||
            identical(afterParens, 'async') ||
            identical(afterParens, 'sync')) {
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
    return optional('throw', token)
        ? parseThrowExpression(token, true)
        : parsePrecedenceExpression(token, ASSIGNMENT_PRECEDENCE, true);
  }

  Token parseExpressionWithoutCascade(Token token) {
    return optional('throw', token)
        ? parseThrowExpression(token, false)
        : parsePrecedenceExpression(token, ASSIGNMENT_PRECEDENCE, false);
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
        if (level == EQUALITY_PRECEDENCE || level == RELATIONAL_PRECEDENCE) {
          // We don't allow (a == b == c) or (a < b < c).
          // Continue the outer loop if we have matched one equality or
          // relational operator.
          break;
        }
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
    if (awaitIsKeyword && optional('await', token)) {
      return parseAwaitExpression(token, allowCascades);
    } else if (identical(value, '+')) {
      // Dart no longer allows prefix-plus.
      listener.reportError(token, MessageKind.UNSUPPORTED_PREFIX_PLUS);
      return parseUnaryExpression(token.next, allowCascades);
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
    } else if (identical(kind, HASH_TOKEN)) {
      return parseLiteralSymbol(token);
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
    } else {
      return listener.expectedExpression(token);
    }
  }

  Token parseParenthesizedExpressionOrFunctionLiteral(Token token) {
    BeginGroupToken beginGroup = token;
    Token nextToken = beginGroup.endGroup.next;
    int kind = nextToken.kind;
    if (mayParseFunctionExpressions &&
        (identical(kind, FUNCTION_TOKEN) ||
         identical(kind, OPEN_CURLY_BRACKET_TOKEN) ||
         (identical(kind, KEYWORD_TOKEN) &&
             (nextToken.value == 'async' || nextToken.value == 'sync')))) {
      return parseUnnamedFunction(token);
    } else {
      bool old = mayParseFunctionExpressions;
      mayParseFunctionExpressions = true;
      token = parseParenthesizedExpression(token);
      mayParseFunctionExpressions = old;
      return token;
    }
  }

  Token parseParenthesizedExpression(Token token) {
    // We expect [begin] to be of type [BeginGroupToken], but we don't know for
    // sure until after calling expect.
    var begin = token;
    token = expect('(', token);
    // [begin] is now known to have type [BeginGroupToken].
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
      return null;
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
    Token peek = peekAfterIfType(token);
    if (peek != null &&
        identical(peek.kind, IDENTIFIER_TOKEN) &&
        isFunctionDeclaration(peek.next)) {
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
      if (identical(afterParens, '{') ||
          identical(afterParens, '=>') ||
          identical(afterParens, 'async') ||
          identical(afterParens, 'sync')) {
        return true;
      }
    }
    return false;
  }

  Token parseRequiredArguments(Token token) {
    if (optional('(', token)) {
      token = parseArguments(token);
    } else {
      listener.handleNoArguments(token);
      token = listener.unexpected(token);
    }
    return token;
  }

  Token parseNewExpression(Token token) {
    Token newKeyword = token;
    token = expect('new', token);
    token = parseConstructorReference(token);
    token = parseRequiredArguments(token);
    listener.handleNewExpression(newKeyword);
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
    token = parseConstructorReference(token);
    token = parseRequiredArguments(token);
    listener.handleConstExpression(constKeyword);
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
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    token = parseSingleLiteralString(token);
    int count = 1;
    while (identical(token.kind, STRING_TOKEN)) {
      token = parseSingleLiteralString(token);
      count++;
    }
    if (count > 1) {
      listener.handleStringJuxtaposition(count);
    }
    mayParseFunctionExpressions = old;
    return token;
  }

  Token parseLiteralSymbol(Token token) {
    Token hashToken = token;
    listener.beginLiteralSymbol(hashToken);
    token = token.next;
    if (isUserDefinableOperator(token.stringValue)) {
      listener.handleOperator(token);
      listener.endLiteralSymbol(hashToken, 1);
      return token.next;
    } else {
      int count = 1;
      token = parseIdentifier(token);
      while (identical(token.stringValue, '.')) {
        count++;
        token = parseIdentifier(token.next);
      }
      listener.endLiteralSymbol(hashToken, count);
      return token;
    }
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
    return parseVariablesDeclarationMaybeSemicolon(token, true);
  }

  Token parseVariablesDeclarationNoSemicolon(Token token) {
    // Only called when parsing a for loop, so this is for parsing locals.
    return parseVariablesDeclarationMaybeSemicolon(token, false);
  }

  Token parseVariablesDeclarationMaybeSemicolon(Token token,
                                                bool endWithSemicolon) {
    int count = 1;
    listener.beginVariablesDeclaration(token);
    token = parseModifiers(token);
    token = parseTypeOpt(token);
    token = parseOptionallyInitializedIdentifier(token);
    while (optional(',', token)) {
      token = parseOptionallyInitializedIdentifier(token.next);
      ++count;
    }
    if (endWithSemicolon) {
      Token semicolon = token;
      token = expectSemicolon(semicolon);
      listener.endVariablesDeclaration(count, semicolon);
      return token;
    } else {
      listener.endVariablesDeclaration(count, null);
      return token;
    }
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

  Token parseForStatement(Token awaitToken, Token token) {
    Token forToken = token;
    listener.beginForStatement(forToken);
    token = expect('for', token);
    token = expect('(', token);
    token = parseVariablesDeclarationOrExpressionOpt(token);
    if (optional('in', token)) {
      return parseForInRest(awaitToken, forToken, token);
    } else {
      if (awaitToken != null) {
        listener.reportError(awaitToken, MessageKind.INVALID_AWAIT_FOR);
      }
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
      if (isOneOf4(identifier.next, '=', ';', ',', 'in')) {
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

  Token parseForInRest(Token awaitToken, Token forToken, Token token) {
    assert(optional('in', token));
    Token inKeyword = token;
    token = parseExpression(token.next);
    token = expect(')', token);
    token = parseStatement(token);
    listener.endForIn(awaitToken, forToken, inKeyword, token);
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

  Token parseAwaitExpression(Token token, bool allowCascades) {
    Token awaitToken = token;
    listener.beginAwaitExpression(awaitToken);
    token = expect('await', token);
    token = parseUnaryExpression(token, allowCascades);
    listener.endAwaitExpression(awaitToken, token);
    return token;
  }

  Token parseThrowExpression(Token token, bool allowCascades) {
    Token throwToken = token;
    listener.beginThrowExpression(throwToken);
    token = expect('throw', token);
    token = allowCascades
        ? parseExpression(token)
        : parseExpressionWithoutCascade(token);
    listener.endThrowExpression(throwToken, token);
    return token;
  }

  Token parseRethrowStatement(Token token) {
    Token throwToken = token;
    listener.beginRethrowStatement(throwToken);
    // TODO(kasperl): Disallow throw here.
    if (identical(throwToken.stringValue, 'throw')) {
      token = expect('throw', token);
    } else {
      token = expect('rethrow', token);
    }
    listener.endRethrowStatement(throwToken, token);
    return expectSemicolon(token);
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
