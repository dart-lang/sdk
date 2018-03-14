// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.parser;

import 'dart:collection';
import "dart:math" as math;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/fasta/ast_builder.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:front_end/src/fasta/kernel/kernel_builder.dart';
import 'package:front_end/src/fasta/kernel/kernel_library_builder.dart';
import 'package:front_end/src/fasta/parser/identifier_context.dart' as fasta;
import 'package:front_end/src/fasta/parser/member_kind.dart' as fasta;
import 'package:front_end/src/fasta/parser/parser.dart' as fasta;
import 'package:front_end/src/fasta/scanner.dart' as fasta;

export 'package:analyzer/src/dart/ast/utilities.dart' show ResolutionCopier;
export 'package:analyzer/src/dart/error/syntactic_errors.dart';

part 'parser_fasta.dart';

/**
 * A simple data-holder for a method that needs to return multiple values.
 */
class CommentAndMetadata {
  /**
   * The documentation comment that was parsed, or `null` if none was given.
   */
  final Comment comment;

  /**
   * The metadata that was parsed, or `null` if none was given.
   */
  final List<Annotation> metadata;

  /**
   * Initialize a newly created holder with the given [comment] and [metadata].
   */
  CommentAndMetadata(this.comment, this.metadata);

  /**
   * Return `true` if some metadata was parsed.
   */
  bool get hasMetadata => metadata != null && metadata.isNotEmpty;
}

/**
 * A simple data-holder for a method that needs to return multiple values.
 */
class FinalConstVarOrType {
  /**
   * The 'final', 'const' or 'var' keyword, or `null` if none was given.
   */
  final Token keyword;

  /**
   * The type, or `null` if no type was specified.
   */
  final TypeAnnotation type;

  /**
   * Initialize a newly created holder with the given [keyword] and [type].
   */
  FinalConstVarOrType(this.keyword, this.type);
}

/**
 * A simple data-holder for a method that needs to return multiple values.
 */
class Modifiers {
  /**
   * The token representing the keyword 'abstract', or `null` if the keyword was
   * not found.
   */
  Token abstractKeyword;

  /**
   * The token representing the keyword 'const', or `null` if the keyword was
   * not found.
   */
  Token constKeyword;

  /**
   * The token representing the keyword 'covariant', or `null` if the keyword
   * was not found.
   */
  Token covariantKeyword;

  /**
   * The token representing the keyword 'external', or `null` if the keyword was
   * not found.
   */
  Token externalKeyword;

  /**
   * The token representing the keyword 'factory', or `null` if the keyword was
   * not found.
   */
  Token factoryKeyword;

  /**
   * The token representing the keyword 'final', or `null` if the keyword was
   * not found.
   */
  Token finalKeyword;

  /**
   * The token representing the keyword 'static', or `null` if the keyword was
   * not found.
   */
  Token staticKeyword;

  /**
   * The token representing the keyword 'var', or `null` if the keyword was not
   * found.
   */
  Token varKeyword;

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    bool needsSpace = _appendKeyword(buffer, false, abstractKeyword);
    needsSpace = _appendKeyword(buffer, needsSpace, constKeyword);
    needsSpace = _appendKeyword(buffer, needsSpace, externalKeyword);
    needsSpace = _appendKeyword(buffer, needsSpace, factoryKeyword);
    needsSpace = _appendKeyword(buffer, needsSpace, finalKeyword);
    needsSpace = _appendKeyword(buffer, needsSpace, staticKeyword);
    _appendKeyword(buffer, needsSpace, varKeyword);
    return buffer.toString();
  }

  /**
   * If the given [keyword] is not `null`, append it to the given [builder],
   * prefixing it with a space if [needsSpace] is `true`. Return `true` if
   * subsequent keywords need to be prefixed with a space.
   */
  bool _appendKeyword(StringBuffer buffer, bool needsSpace, Token keyword) {
    if (keyword != null) {
      if (needsSpace) {
        buffer.writeCharCode(0x20);
      }
      buffer.write(keyword.lexeme);
      return true;
    }
    return needsSpace;
  }
}

/**
 * A parser used to parse tokens into an AST structure.
 */
class Parser {
  static String ASYNC = Keyword.ASYNC.lexeme;

  static String _AWAIT = Keyword.AWAIT.lexeme;

  static String _HIDE = Keyword.HIDE.lexeme;

  static String _SHOW = Keyword.SHOW.lexeme;

  static String SYNC = Keyword.SYNC.lexeme;

  static String _YIELD = Keyword.YIELD.lexeme;

  static const int _MAX_TREE_DEPTH = 300;

  /**
   * A flag indicating whether the analyzer [Parser] factory method
   * will return a fasta based parser or an analyzer based parser.
   */
  static const bool useFasta = const bool.fromEnvironment("useFastaParser");

  /**
   * The source being parsed.
   */
  final Source _source;

  /**
   * The error listener that will be informed of any errors that are found
   * during the parse.
   */
  final AnalysisErrorListener _errorListener;

  /**
   * An [_errorListener] lock, if more than `0`, then errors are not reported.
   */
  int _errorListenerLock = 0;

  /**
   * A flag indicating whether the parser is to parse the non-nullable modifier
   * in type names.
   */
  bool _enableNnbd = false;

  /**
   * A flag indicating whether the parser should parse instance creation
   * expressions that lack either the `new` or `const` keyword.
   */
  bool _enableOptionalNewAndConst = false;

  /**
   * A flag indicating whether the parser is to allow URI's in part-of
   * directives.
   */
  bool _enableUriInPartOf = true;

  /**
   * A flag indicating whether parser is to parse function bodies.
   */
  bool _parseFunctionBodies = true;

  /**
   * The next token to be parsed.
   */
  Token _currentToken;

  /**
   * The depth of the current AST. When this depth is too high, so we're at the
   * risk of overflowing the stack, we stop parsing and report an error.
   */
  int _treeDepth = 0;

  /**
   * A flag indicating whether the parser is currently in a function body marked
   * as being 'async'.
   */
  bool _inAsync = false;

  /**
   * A flag indicating whether the parser is currently in a function body marked
   * (by a star) as being a generator.
   */
  bool _inGenerator = false;

  /**
   * A flag indicating whether the parser is currently in the body of a loop.
   */
  bool _inLoop = false;

  /**
   * A flag indicating whether the parser is currently in a switch statement.
   */
  bool _inSwitch = false;

  /**
   * A flag indicating whether the parser is currently in a constructor field
   * initializer, with no intervening parentheses, braces, or brackets.
   */
  bool _inInitializer = false;

  /**
   * A flag indicating whether the parser is to parse generic method syntax.
   */
  @deprecated
  bool parseGenericMethods = false;

  /**
   * A flag indicating whether to parse generic method comments, of the form
   * `/*=T*/` and `/*<T>*/`.
   */
  bool parseGenericMethodComments = false;

  bool allowNativeClause;

  /**
   * Initialize a newly created parser to parse tokens in the given [_source]
   * and to report any errors that are found to the given [_errorListener].
   */
  factory Parser(Source source, AnalysisErrorListener errorListener,
      {bool useFasta}) {
    if ((useFasta ?? false) || Parser.useFasta) {
      return new _Parser2(source, errorListener, allowNativeClause: true);
    } else {
      return new Parser.withoutFasta(source, errorListener);
    }
  }

  Parser.withoutFasta(this._source, this._errorListener);

  /**
   * Return the current token.
   */
  Token get currentToken => _currentToken;

  /**
   * Set the token with which the parse is to begin to the given [token].
   */
  void set currentToken(Token token) {
    this._currentToken = token;
  }

  /**
   * Return `true` if the parser is to parse asserts in the initializer list of
   * a constructor.
   */
  @deprecated
  bool get enableAssertInitializer => true;

  /**
   * Set whether the parser is to parse asserts in the initializer list of a
   * constructor to match the given [enable] flag.
   */
  @deprecated
  void set enableAssertInitializer(bool enable) {}

  /**
   * Return `true` if the parser is to parse the non-nullable modifier in type
   * names.
   */
  bool get enableNnbd => _enableNnbd;

  /**
   * Set whether the parser is to parse the non-nullable modifier in type names
   * to match the given [enable] flag.
   */
  void set enableNnbd(bool enable) {
    _enableNnbd = enable;
  }

  /**
   * Return `true` if the parser should parse instance creation expressions that
   * lack either the `new` or `const` keyword.
   */
  bool get enableOptionalNewAndConst => _enableOptionalNewAndConst;

  /**
   * Set whether the parser should parse instance creation expressions that lack
   * either the `new` or `const` keyword.
   */
  void set enableOptionalNewAndConst(bool enable) {
    _enableOptionalNewAndConst = enable;
  }

  /**
   * Return `true` if the parser is to allow URI's in part-of directives.
   */
  bool get enableUriInPartOf => _enableUriInPartOf;

  /**
   * Set whether the parser is to allow URI's in part-of directives to the given
   * [enable] flag.
   */
  void set enableUriInPartOf(bool enable) {
    _enableUriInPartOf = enable;
  }

  /**
   * Return `true` if the current token is the first token of a return type that
   * is followed by an identifier, possibly followed by a list of type
   * parameters, followed by a left-parenthesis. This is used by
   * [parseTypeAlias] to determine whether or not to parse a return type.
   */
  bool get hasReturnTypeInTypeAlias {
    // TODO(brianwilkerson) This is too expensive as implemented and needs to be
    // re-implemented or removed.
    Token next = skipTypeAnnotation(_currentToken);
    if (next == null) {
      return false;
    }
    return _tokenMatchesIdentifier(next);
  }

  /**
   * Set whether the parser is to parse the async support.
   *
   * Support for removing the 'async' library has been removed.
   */
  @deprecated
  void set parseAsync(bool parseAsync) {}

  @deprecated
  bool get parseConditionalDirectives => true;

  @deprecated
  void set parseConditionalDirectives(bool value) {}

  /**
   * Set whether parser is to parse function bodies.
   */
  void set parseFunctionBodies(bool parseFunctionBodies) {
    this._parseFunctionBodies = parseFunctionBodies;
  }

  /**
   * Return the content of a string with the given literal representation. The
   * [lexeme] is the literal representation of the string. The flag [isFirst] is
   * `true` if this is the first token in a string literal. The flag [isLast] is
   * `true` if this is the last token in a string literal.
   */
  String computeStringValue(String lexeme, bool isFirst, bool isLast) {
    StringLexemeHelper helper = new StringLexemeHelper(lexeme, isFirst, isLast);
    int start = helper.start;
    int end = helper.end;
    bool stringEndsAfterStart = end >= start;
    assert(stringEndsAfterStart);
    if (!stringEndsAfterStart) {
      AnalysisEngine.instance.logger.logError(
          "Internal error: computeStringValue($lexeme, $isFirst, $isLast)");
      return "";
    }
    if (helper.isRaw) {
      return lexeme.substring(start, end);
    }
    StringBuffer buffer = new StringBuffer();
    int index = start;
    while (index < end) {
      index = _translateCharacter(buffer, lexeme, index);
    }
    return buffer.toString();
  }

  /**
   * Return a synthetic identifier.
   */
  SimpleIdentifier createSyntheticIdentifier({bool isDeclaration: false}) {
    Token syntheticToken;
    if (_currentToken.type.isKeyword) {
      // Consider current keyword token as an identifier.
      // It is not always true, e.g. "^is T" where "^" is place the place for
      // synthetic identifier. By creating SyntheticStringToken we can
      // distinguish a real identifier from synthetic. In the code completion
      // behavior will depend on a cursor position - before or on "is".
      syntheticToken = _injectToken(new SyntheticStringToken(
          TokenType.IDENTIFIER, _currentToken.lexeme, _currentToken.offset));
    } else {
      syntheticToken = _createSyntheticToken(TokenType.IDENTIFIER);
    }
    return astFactory.simpleIdentifier(syntheticToken,
        isDeclaration: isDeclaration);
  }

  /**
   * Return a synthetic string literal.
   */
  SimpleStringLiteral createSyntheticStringLiteral() => astFactory
      .simpleStringLiteral(_createSyntheticToken(TokenType.STRING), "");

  /**
   * Advance to the next token in the token stream, making it the new current
   * token and return the token that was current before this method was invoked.
   */
  Token getAndAdvance() {
    Token token = _currentToken;
    _currentToken = _currentToken.next;
    return token;
  }

  /**
   * Return `true` if the current token appears to be the beginning of a
   * function declaration.
   */
  bool isFunctionDeclaration() {
    Keyword keyword = _currentToken.keyword;
    Token afterReturnType = skipTypeWithoutFunction(_currentToken);
    if (afterReturnType != null &&
        _tokenMatchesKeyword(afterReturnType, Keyword.FUNCTION)) {
      afterReturnType = skipGenericFunctionTypeAfterReturnType(afterReturnType);
    }
    if (afterReturnType == null) {
      // There was no return type, but it is optional, so go back to where we
      // started.
      afterReturnType = _currentToken;
    }
    Token afterIdentifier = skipSimpleIdentifier(afterReturnType);
    if (afterIdentifier == null) {
      // It's possible that we parsed the function name as if it were a type
      // name, so see whether it makes sense if we assume that there is no type.
      afterIdentifier = skipSimpleIdentifier(_currentToken);
    }
    if (afterIdentifier == null) {
      return false;
    }
    if (isFunctionExpression(afterIdentifier)) {
      return true;
    }
    // It's possible that we have found a getter. While this isn't valid at this
    // point we test for it in order to recover better.
    if (keyword == Keyword.GET) {
      Token afterName = skipSimpleIdentifier(_currentToken.next);
      if (afterName == null) {
        return false;
      }
      TokenType type = afterName.type;
      return type == TokenType.FUNCTION || type == TokenType.OPEN_CURLY_BRACKET;
    } else if (_tokenMatchesKeyword(afterReturnType, Keyword.GET)) {
      Token afterName = skipSimpleIdentifier(afterReturnType.next);
      if (afterName == null) {
        return false;
      }
      TokenType type = afterName.type;
      return type == TokenType.FUNCTION || type == TokenType.OPEN_CURLY_BRACKET;
    }
    return false;
  }

  /**
   * Return `true` if the given [token] appears to be the beginning of a
   * function expression.
   */
  bool isFunctionExpression(Token token) {
    // Function expressions aren't allowed in initializer lists.
    if (_inInitializer) {
      return false;
    }
    Token afterTypeParameters = _skipTypeParameterList(token);
    if (afterTypeParameters == null) {
      afterTypeParameters = token;
    }
    Token afterParameters = _skipFormalParameterList(afterTypeParameters);
    if (afterParameters == null) {
      return false;
    }
    if (afterParameters.matchesAny(
        const <TokenType>[TokenType.OPEN_CURLY_BRACKET, TokenType.FUNCTION])) {
      return true;
    }
    String lexeme = afterParameters.lexeme;
    return lexeme == ASYNC || lexeme == SYNC;
  }

  /**
   * Return `true` if the current token is the first token in an initialized
   * variable declaration rather than an expression. This method assumes that we
   * have already skipped past any metadata that might be associated with the
   * declaration.
   *
   *     initializedVariableDeclaration ::=
   *         declaredIdentifier ('=' expression)? (',' initializedIdentifier)*
   *
   *     declaredIdentifier ::=
   *         metadata finalConstVarOrType identifier
   *
   *     finalConstVarOrType ::=
   *         'final' type?
   *       | 'const' type?
   *       | 'var'
   *       | type
   *
   *     type ::=
   *         qualified typeArguments?
   *
   *     initializedIdentifier ::=
   *         identifier ('=' expression)?
   */
  bool isInitializedVariableDeclaration() {
    Keyword keyword = _currentToken.keyword;
    if (keyword == Keyword.FINAL ||
        keyword == Keyword.VAR ||
        keyword == Keyword.VOID) {
      // An expression cannot start with a keyword other than 'const',
      // 'rethrow', or 'throw'.
      return true;
    }
    if (keyword == Keyword.CONST) {
      // Look to see whether we might be at the start of a list or map literal,
      // otherwise this should be the start of a variable declaration.
      return !_peek().matchesAny(const <TokenType>[
        TokenType.LT,
        TokenType.OPEN_CURLY_BRACKET,
        TokenType.OPEN_SQUARE_BRACKET,
        TokenType.INDEX
      ]);
    }
    bool allowAdditionalTokens = true;
    // We know that we have an identifier, and need to see whether it might be
    // a type name.
    if (_currentToken.type != TokenType.IDENTIFIER) {
      allowAdditionalTokens = false;
    }
    Token token = skipTypeName(_currentToken);
    if (token == null) {
      // There was no type name, so this can't be a declaration.
      return false;
    }
    while (_atGenericFunctionTypeAfterReturnType(token)) {
      token = skipGenericFunctionTypeAfterReturnType(token);
      if (token == null) {
        // There was no type name, so this can't be a declaration.
        return false;
      }
    }
    if (token.type != TokenType.IDENTIFIER) {
      allowAdditionalTokens = false;
    }
    token = skipSimpleIdentifier(token);
    if (token == null) {
      return false;
    }
    TokenType type = token.type;
    // Usual cases in valid code:
    //     String v = '';
    //     String v, v2;
    //     String v;
    //     for (String item in items) {}
    if (type == TokenType.EQ ||
        type == TokenType.COMMA ||
        type == TokenType.SEMICOLON ||
        token.keyword == Keyword.IN) {
      return true;
    }
    // It is OK to parse as a variable declaration in these cases:
    //     String v }
    //     String v if (true) print('OK');
    //     String v { print(42); }
    // ...but not in these cases:
    //     get getterName {
    //     String get getterName
    if (allowAdditionalTokens) {
      if (type == TokenType.CLOSE_CURLY_BRACKET ||
          type.isKeyword ||
          type == TokenType.IDENTIFIER ||
          type == TokenType.OPEN_CURLY_BRACKET) {
        return true;
      }
    }
    return false;
  }

  /**
   * Return `true` if the current token appears to be the beginning of a switch
   * member.
   */
  bool isSwitchMember() {
    Token token = _currentToken;
    while (_tokenMatches(token, TokenType.IDENTIFIER) &&
        _tokenMatches(token.next, TokenType.COLON)) {
      token = token.next.next;
    }
    Keyword keyword = token.keyword;
    return keyword == Keyword.CASE || keyword == Keyword.DEFAULT;
  }

  /**
   * Parse an additive expression. Return the additive expression that was
   * parsed.
   *
   *     additiveExpression ::=
   *         multiplicativeExpression (additiveOperator multiplicativeExpression)*
   *       | 'super' (additiveOperator multiplicativeExpression)+
   */
  Expression parseAdditiveExpression() {
    Expression expression;
    if (_currentToken.keyword == Keyword.SUPER &&
        _currentToken.next.type.isAdditiveOperator) {
      expression = astFactory.superExpression(getAndAdvance());
    } else {
      expression = parseMultiplicativeExpression();
    }
    while (_currentToken.type.isAdditiveOperator) {
      expression = astFactory.binaryExpression(
          expression, getAndAdvance(), parseMultiplicativeExpression());
    }
    return expression;
  }

  /**
   * Parse an annotation. Return the annotation that was parsed.
   *
   * This method assumes that the current token matches [TokenType.AT].
   *
   *     annotation ::=
   *         '@' qualified ('.' identifier)? arguments?
   */
  Annotation parseAnnotation() {
    Token atSign = getAndAdvance();
    Identifier name = parsePrefixedIdentifier();
    Token period = null;
    SimpleIdentifier constructorName = null;
    if (_matches(TokenType.PERIOD)) {
      period = getAndAdvance();
      constructorName = parseSimpleIdentifier();
    }
    ArgumentList arguments = null;
    if (_matches(TokenType.OPEN_PAREN)) {
      arguments = parseArgumentList();
    }
    return astFactory.annotation(
        atSign, name, period, constructorName, arguments);
  }

  /**
   * Parse an argument. Return the argument that was parsed.
   *
   *     argument ::=
   *         namedArgument
   *       | expression
   *
   *     namedArgument ::=
   *         label expression
   */
  Expression parseArgument() {
    // TODO(brianwilkerson) Consider returning a wrapper indicating whether the
    // expression is a named expression in order to remove the 'is' check in
    // 'parseArgumentList'.
    //
    // Both namedArgument and expression can start with an identifier, but only
    // namedArgument can have an identifier followed by a colon.
    //
    if (_matchesIdentifier() && _tokenMatches(_peek(), TokenType.COLON)) {
      return astFactory.namedExpression(parseLabel(), parseExpression2());
    } else {
      return parseExpression2();
    }
  }

  /**
   * Parse a list of arguments. Return the argument list that was parsed.
   *
   * This method assumes that the current token matches [TokenType.OPEN_PAREN].
   *
   *     arguments ::=
   *         '(' argumentList? ')'
   *
   *     argumentList ::=
   *         namedArgument (',' namedArgument)*
   *       | expressionList (',' namedArgument)*
   */
  ArgumentList parseArgumentList() {
    Token leftParenthesis = getAndAdvance();
    if (_matches(TokenType.CLOSE_PAREN)) {
      return astFactory.argumentList(leftParenthesis, null, getAndAdvance());
    }

    /**
     * Return `true` if the parser appears to be at the beginning of an argument
     * even though there was no comma. This is a special case of the more
     * general recovery technique described below.
     */
    bool isLikelyMissingComma() {
      if (_matchesIdentifier() &&
          _tokenMatches(_currentToken.next, TokenType.COLON) &&
          leftParenthesis is BeginToken &&
          leftParenthesis.endToken != null) {
        _reportErrorForToken(
            ParserErrorCode.EXPECTED_TOKEN, _currentToken.previous, [',']);
        return true;
      }
      return false;
    }

    //
    // Even though unnamed arguments must all appear before any named arguments,
    // we allow them to appear in any order so that we can recover faster.
    //
    bool wasInInitializer = _inInitializer;
    _inInitializer = false;
    try {
      Token previousStartOfArgument = _currentToken;
      Expression argument = parseArgument();
      List<Expression> arguments = <Expression>[argument];
      bool foundNamedArgument = argument is NamedExpression;
      bool generatedError = false;
      while (_optional(TokenType.COMMA) ||
          (isLikelyMissingComma() &&
              previousStartOfArgument != _currentToken)) {
        if (_matches(TokenType.CLOSE_PAREN)) {
          break;
        }
        previousStartOfArgument = _currentToken;
        argument = parseArgument();
        arguments.add(argument);
        if (argument is NamedExpression) {
          foundNamedArgument = true;
        } else if (foundNamedArgument) {
          if (!generatedError) {
            if (!argument.isSynthetic) {
              // Report the error, once, but allow the arguments to be in any
              // order in the AST.
              _reportErrorForCurrentToken(
                  ParserErrorCode.POSITIONAL_AFTER_NAMED_ARGUMENT);
              generatedError = true;
            }
          }
        }
      }
      // Recovery: If the next token is not a right parenthesis, look at the
      // left parenthesis to see whether there is a matching right parenthesis.
      // If there is, then we're more likely missing a comma and should go back
      // to parsing arguments.
      Token rightParenthesis = _expect(TokenType.CLOSE_PAREN);
      return astFactory.argumentList(
          leftParenthesis, arguments, rightParenthesis);
    } finally {
      _inInitializer = wasInInitializer;
    }
  }

  /**
   * Parse an assert statement. Return the assert statement.
   *
   * This method assumes that the current token matches `Keyword.ASSERT`.
   *
   *     assertStatement ::=
   *         'assert' '(' expression [',' expression] ')' ';'
   */
  AssertStatement parseAssertStatement() {
    Token keyword = getAndAdvance();
    Token leftParen = _expect(TokenType.OPEN_PAREN);
    Expression expression = parseExpression2();
    Token comma;
    Expression message;
    if (_matches(TokenType.COMMA)) {
      comma = getAndAdvance();
      if (_matches(TokenType.CLOSE_PAREN)) {
        comma = null;
      } else {
        message = parseExpression2();
        if (_matches(TokenType.COMMA)) {
          getAndAdvance();
        }
      }
    }
    Token rightParen = _expect(TokenType.CLOSE_PAREN);
    Token semicolon = _expect(TokenType.SEMICOLON);
    // TODO(brianwilkerson) We should capture the trailing comma in the AST, but
    // that would be a breaking change, so we drop it for now.
    return astFactory.assertStatement(
        keyword, leftParen, expression, comma, message, rightParen, semicolon);
  }

  /**
   * Parse an assignable expression. The [primaryAllowed] is `true` if the
   * expression is allowed to be a primary without any assignable selector.
   * Return the assignable expression that was parsed.
   *
   *     assignableExpression ::=
   *         primary (arguments* assignableSelector)+
   *       | 'super' unconditionalAssignableSelector
   *       | identifier
   */
  Expression parseAssignableExpression(bool primaryAllowed) {
    //
    // A primary expression can start with an identifier. We resolve the
    // ambiguity by determining whether the primary consists of anything other
    // than an identifier and/or is followed by an assignableSelector.
    //
    Expression expression = parsePrimaryExpression();
    bool isOptional =
        primaryAllowed || _isValidAssignableExpression(expression);
    while (true) {
      while (_isLikelyArgumentList()) {
        TypeArgumentList typeArguments = _parseOptionalTypeArguments();
        ArgumentList argumentList = parseArgumentList();
        Expression currentExpression = expression;
        if (currentExpression is SimpleIdentifier) {
          expression = astFactory.methodInvocation(
              null, null, currentExpression, typeArguments, argumentList);
        } else if (currentExpression is PrefixedIdentifier) {
          expression = astFactory.methodInvocation(
              currentExpression.prefix,
              currentExpression.period,
              currentExpression.identifier,
              typeArguments,
              argumentList);
        } else if (currentExpression is PropertyAccess) {
          expression = astFactory.methodInvocation(
              currentExpression.target,
              currentExpression.operator,
              currentExpression.propertyName,
              typeArguments,
              argumentList);
        } else {
          expression = astFactory.functionExpressionInvocation(
              expression, typeArguments, argumentList);
        }
        if (!primaryAllowed) {
          isOptional = false;
        }
      }
      Expression selectorExpression = parseAssignableSelector(
          expression, isOptional || (expression is PrefixedIdentifier));
      if (identical(selectorExpression, expression)) {
        return expression;
      }
      expression = selectorExpression;
      isOptional = true;
    }
  }

  /**
   * Parse an assignable selector. The [prefix] is the expression preceding the
   * selector. The [optional] is `true` if the selector is optional. Return the
   * assignable selector that was parsed, or the original prefix if there was no
   * assignable selector.  If [allowConditional] is false, then the '?.'
   * operator will still be parsed, but a parse error will be generated.
   *
   *     unconditionalAssignableSelector ::=
   *         '[' expression ']'
   *       | '.' identifier
   *
   *     assignableSelector ::=
   *         unconditionalAssignableSelector
   *       | '?.' identifier
   */
  Expression parseAssignableSelector(Expression prefix, bool optional,
      {bool allowConditional: true}) {
    TokenType type = _currentToken.type;
    if (type == TokenType.OPEN_SQUARE_BRACKET) {
      Token leftBracket = getAndAdvance();
      bool wasInInitializer = _inInitializer;
      _inInitializer = false;
      try {
        Expression index = parseExpression2();
        Token rightBracket = _expect(TokenType.CLOSE_SQUARE_BRACKET);
        return astFactory.indexExpressionForTarget(
            prefix, leftBracket, index, rightBracket);
      } finally {
        _inInitializer = wasInInitializer;
      }
    } else {
      bool isQuestionPeriod = type == TokenType.QUESTION_PERIOD;
      if (type == TokenType.PERIOD || isQuestionPeriod) {
        if (isQuestionPeriod && !allowConditional) {
          _reportErrorForCurrentToken(
              ParserErrorCode.INVALID_OPERATOR_FOR_SUPER,
              [_currentToken.lexeme]);
        }
        Token operator = getAndAdvance();
        return astFactory.propertyAccess(
            prefix, operator, parseSimpleIdentifier());
      } else if (type == TokenType.INDEX) {
        _splitIndex();
        Token leftBracket = getAndAdvance();
        Expression index = parseSimpleIdentifier();
        Token rightBracket = getAndAdvance();
        return astFactory.indexExpressionForTarget(
            prefix, leftBracket, index, rightBracket);
      } else {
        if (!optional) {
          // Report the missing selector.
          _reportErrorForCurrentToken(
              ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR);
        }
        return prefix;
      }
    }
  }

  /**
   * Parse a await expression. Return the await expression that was parsed.
   *
   * This method assumes that the current token matches `_AWAIT`.
   *
   *     awaitExpression ::=
   *         'await' unaryExpression
   */
  AwaitExpression parseAwaitExpression() {
    Token awaitToken = getAndAdvance();
    Expression expression = parseUnaryExpression();
    return astFactory.awaitExpression(awaitToken, expression);
  }

  /**
   * Parse a bitwise and expression. Return the bitwise and expression that was
   * parsed.
   *
   *     bitwiseAndExpression ::=
   *         shiftExpression ('&' shiftExpression)*
   *       | 'super' ('&' shiftExpression)+
   */
  Expression parseBitwiseAndExpression() {
    Expression expression;
    if (_currentToken.keyword == Keyword.SUPER &&
        _currentToken.next.type == TokenType.AMPERSAND) {
      expression = astFactory.superExpression(getAndAdvance());
    } else {
      expression = parseShiftExpression();
    }
    while (_currentToken.type == TokenType.AMPERSAND) {
      expression = astFactory.binaryExpression(
          expression, getAndAdvance(), parseShiftExpression());
    }
    return expression;
  }

  /**
   * Parse a bitwise or expression. Return the bitwise or expression that was
   * parsed.
   *
   *     bitwiseOrExpression ::=
   *         bitwiseXorExpression ('|' bitwiseXorExpression)*
   *       | 'super' ('|' bitwiseXorExpression)+
   */
  Expression parseBitwiseOrExpression() {
    Expression expression;
    if (_currentToken.keyword == Keyword.SUPER &&
        _currentToken.next.type == TokenType.BAR) {
      expression = astFactory.superExpression(getAndAdvance());
    } else {
      expression = parseBitwiseXorExpression();
    }
    while (_currentToken.type == TokenType.BAR) {
      expression = astFactory.binaryExpression(
          expression, getAndAdvance(), parseBitwiseXorExpression());
    }
    return expression;
  }

  /**
   * Parse a bitwise exclusive-or expression. Return the bitwise exclusive-or
   * expression that was parsed.
   *
   *     bitwiseXorExpression ::=
   *         bitwiseAndExpression ('^' bitwiseAndExpression)*
   *       | 'super' ('^' bitwiseAndExpression)+
   */
  Expression parseBitwiseXorExpression() {
    Expression expression;
    if (_currentToken.keyword == Keyword.SUPER &&
        _currentToken.next.type == TokenType.CARET) {
      expression = astFactory.superExpression(getAndAdvance());
    } else {
      expression = parseBitwiseAndExpression();
    }
    while (_currentToken.type == TokenType.CARET) {
      expression = astFactory.binaryExpression(
          expression, getAndAdvance(), parseBitwiseAndExpression());
    }
    return expression;
  }

  /**
   * Parse a block. Return the block that was parsed.
   *
   * This method assumes that the current token matches
   * [TokenType.OPEN_CURLY_BRACKET].
   *
   *     block ::=
   *         '{' statements '}'
   */
  Block parseBlock() {
    bool isEndOfBlock() {
      TokenType type = _currentToken.type;
      return type == TokenType.EOF || type == TokenType.CLOSE_CURLY_BRACKET;
    }

    Token leftBracket = getAndAdvance();
    List<Statement> statements = <Statement>[];
    Token statementStart = _currentToken;
    while (!isEndOfBlock()) {
      Statement statement = parseStatement2();
      if (identical(_currentToken, statementStart)) {
        // Ensure that we are making progress and report an error if we're not.
        _reportErrorForToken(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken,
            [_currentToken.lexeme]);
        _advance();
      } else if (statement != null) {
        statements.add(statement);
      }
      statementStart = _currentToken;
    }
    // Recovery: If the next token is not a right curly bracket, look at the
    // left curly bracket to see whether there is a matching right bracket. If
    // there is, then we're more likely missing a semi-colon and should go back
    // to parsing statements.
    Token rightBracket = _expect(TokenType.CLOSE_CURLY_BRACKET);
    return astFactory.block(leftBracket, statements, rightBracket);
  }

  /**
   * Parse a break statement. Return the break statement that was parsed.
   *
   * This method assumes that the current token matches `Keyword.BREAK`.
   *
   *     breakStatement ::=
   *         'break' identifier? ';'
   */
  Statement parseBreakStatement() {
    Token breakKeyword = getAndAdvance();
    SimpleIdentifier label = null;
    if (_matchesIdentifier()) {
      label = _parseSimpleIdentifierUnchecked();
    }
    if (!_inLoop && !_inSwitch && label == null) {
      _reportErrorForToken(ParserErrorCode.BREAK_OUTSIDE_OF_LOOP, breakKeyword);
    }
    Token semicolon = _expect(TokenType.SEMICOLON);
    return astFactory.breakStatement(breakKeyword, label, semicolon);
  }

  /**
   * Parse a cascade section. Return the expression representing the cascaded
   * method invocation.
   *
   * This method assumes that the current token matches
   * `TokenType.PERIOD_PERIOD`.
   *
   *     cascadeSection ::=
   *         '..' (cascadeSelector typeArguments? arguments*)
   *         (assignableSelector typeArguments? arguments*)* cascadeAssignment?
   *
   *     cascadeSelector ::=
   *         '[' expression ']'
   *       | identifier
   *
   *     cascadeAssignment ::=
   *         assignmentOperator expressionWithoutCascade
   */
  Expression parseCascadeSection() {
    Token period = getAndAdvance();
    Expression expression = null;
    SimpleIdentifier functionName = null;
    if (_matchesIdentifier()) {
      functionName = _parseSimpleIdentifierUnchecked();
    } else if (_currentToken.type == TokenType.OPEN_SQUARE_BRACKET) {
      Token leftBracket = getAndAdvance();
      bool wasInInitializer = _inInitializer;
      _inInitializer = false;
      try {
        Expression index = parseExpression2();
        Token rightBracket = _expect(TokenType.CLOSE_SQUARE_BRACKET);
        expression = astFactory.indexExpressionForCascade(
            period, leftBracket, index, rightBracket);
        period = null;
      } finally {
        _inInitializer = wasInInitializer;
      }
    } else {
      _reportErrorForToken(ParserErrorCode.MISSING_IDENTIFIER, _currentToken,
          [_currentToken.lexeme]);
      functionName = createSyntheticIdentifier();
    }
    assert((expression == null && functionName != null) ||
        (expression != null && functionName == null));
    if (_isLikelyArgumentList()) {
      do {
        TypeArgumentList typeArguments = _parseOptionalTypeArguments();
        if (functionName != null) {
          expression = astFactory.methodInvocation(expression, period,
              functionName, typeArguments, parseArgumentList());
          period = null;
          functionName = null;
        } else if (expression == null) {
          // It should not be possible to get here.
          expression = astFactory.methodInvocation(expression, period,
              createSyntheticIdentifier(), typeArguments, parseArgumentList());
        } else {
          expression = astFactory.functionExpressionInvocation(
              expression, typeArguments, parseArgumentList());
        }
      } while (_isLikelyArgumentList());
    } else if (functionName != null) {
      expression = astFactory.propertyAccess(expression, period, functionName);
      period = null;
    }
    assert(expression != null);
    bool progress = true;
    while (progress) {
      progress = false;
      Expression selector = parseAssignableSelector(expression, true);
      if (!identical(selector, expression)) {
        expression = selector;
        progress = true;
        while (_isLikelyArgumentList()) {
          TypeArgumentList typeArguments = _parseOptionalTypeArguments();
          Expression currentExpression = expression;
          if (currentExpression is PropertyAccess) {
            expression = astFactory.methodInvocation(
                currentExpression.target,
                currentExpression.operator,
                currentExpression.propertyName,
                typeArguments,
                parseArgumentList());
          } else {
            expression = astFactory.functionExpressionInvocation(
                expression, typeArguments, parseArgumentList());
          }
        }
      }
    }
    if (_currentToken.type.isAssignmentOperator) {
      Token operator = getAndAdvance();
      _ensureAssignable(expression);
      expression = astFactory.assignmentExpression(
          expression, operator, parseExpressionWithoutCascade());
    }
    return expression;
  }

  /**
   * Parse a class declaration. The [commentAndMetadata] is the metadata to be
   * associated with the member. The [abstractKeyword] is the token for the
   * keyword 'abstract', or `null` if the keyword was not given. Return the
   * class declaration that was parsed.
   *
   * This method assumes that the current token matches `Keyword.CLASS`.
   *
   *     classDeclaration ::=
   *         metadata 'abstract'? 'class' name typeParameterList? (extendsClause withClause?)? implementsClause? '{' classMembers '}' |
   *         metadata 'abstract'? 'class' mixinApplicationClass
   */
  CompilationUnitMember parseClassDeclaration(
      CommentAndMetadata commentAndMetadata, Token abstractKeyword) {
    //
    // Parse the name and type parameters.
    //
    Token keyword = getAndAdvance();
    SimpleIdentifier name = parseSimpleIdentifier(isDeclaration: true);
    String className = name.name;
    TypeParameterList typeParameters = null;
    TokenType type = _currentToken.type;
    if (type == TokenType.LT) {
      typeParameters = parseTypeParameterList();
      type = _currentToken.type;
    }
    //
    // Check to see whether this might be a class type alias rather than a class
    // declaration.
    //
    if (type == TokenType.EQ) {
      return _parseClassTypeAliasAfterName(
          commentAndMetadata, abstractKeyword, keyword, name, typeParameters);
    }
    //
    // Parse the clauses. The parser accepts clauses in any order, but will
    // generate errors if they are not in the order required by the
    // specification.
    //
    ExtendsClause extendsClause = null;
    WithClause withClause = null;
    ImplementsClause implementsClause = null;
    bool foundClause = true;
    while (foundClause) {
      Keyword keyword = _currentToken.keyword;
      if (keyword == Keyword.EXTENDS) {
        if (extendsClause == null) {
          extendsClause = parseExtendsClause();
          if (withClause != null) {
            _reportErrorForToken(
                ParserErrorCode.WITH_BEFORE_EXTENDS, withClause.withKeyword);
          } else if (implementsClause != null) {
            _reportErrorForToken(ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS,
                implementsClause.implementsKeyword);
          }
        } else {
          _reportErrorForToken(ParserErrorCode.MULTIPLE_EXTENDS_CLAUSES,
              extendsClause.extendsKeyword);
          parseExtendsClause();
        }
      } else if (keyword == Keyword.WITH) {
        if (withClause == null) {
          withClause = parseWithClause();
          if (implementsClause != null) {
            _reportErrorForToken(ParserErrorCode.IMPLEMENTS_BEFORE_WITH,
                implementsClause.implementsKeyword);
          }
        } else {
          _reportErrorForToken(
              ParserErrorCode.MULTIPLE_WITH_CLAUSES, withClause.withKeyword);
          parseWithClause();
          // TODO(brianwilkerson) Should we merge the list of applied mixins
          // into a single list?
        }
      } else if (keyword == Keyword.IMPLEMENTS) {
        if (implementsClause == null) {
          implementsClause = parseImplementsClause();
        } else {
          _reportErrorForToken(ParserErrorCode.MULTIPLE_IMPLEMENTS_CLAUSES,
              implementsClause.implementsKeyword);
          parseImplementsClause();
          // TODO(brianwilkerson) Should we merge the list of implemented
          // classes into a single list?
        }
      } else {
        foundClause = false;
      }
    }
    if (withClause != null && extendsClause == null) {
      _reportErrorForToken(
          ParserErrorCode.WITH_WITHOUT_EXTENDS, withClause.withKeyword);
    }
    //
    // Look for and skip over the extra-lingual 'native' specification.
    //
    NativeClause nativeClause = null;
    if (_matchesKeyword(Keyword.NATIVE) &&
        _tokenMatches(_peek(), TokenType.STRING)) {
      nativeClause = _parseNativeClause();
    }
    //
    // Parse the body of the class.
    //
    Token leftBracket = null;
    List<ClassMember> members = null;
    Token rightBracket = null;
    if (_matches(TokenType.OPEN_CURLY_BRACKET)) {
      leftBracket = getAndAdvance();
      members = _parseClassMembers(className, _getEndToken(leftBracket));
      rightBracket = _expect(TokenType.CLOSE_CURLY_BRACKET);
    } else {
      // Recovery: Check for an unmatched closing curly bracket and parse
      // members until it is reached.
      leftBracket = _createSyntheticToken(TokenType.OPEN_CURLY_BRACKET);
      rightBracket = _createSyntheticToken(TokenType.CLOSE_CURLY_BRACKET);
      _reportErrorForCurrentToken(ParserErrorCode.MISSING_CLASS_BODY);
    }
    ClassDeclaration classDeclaration = astFactory.classDeclaration(
        commentAndMetadata.comment,
        commentAndMetadata.metadata,
        abstractKeyword,
        keyword,
        name,
        typeParameters,
        extendsClause,
        withClause,
        implementsClause,
        leftBracket,
        members,
        rightBracket);
    classDeclaration.nativeClause = nativeClause;
    return classDeclaration;
  }

  /**
   * Parse a class member. The [className] is the name of the class containing
   * the member being parsed. Return the class member that was parsed, or `null`
   * if what was found was not a valid class member.
   *
   *     classMemberDefinition ::=
   *         declaration ';'
   *       | methodSignature functionBody
   */
  ClassMember parseClassMember(String className) {
    CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
    Modifiers modifiers = parseModifiers();
    Keyword keyword = _currentToken.keyword;
    if (keyword == Keyword.VOID ||
        _atGenericFunctionTypeAfterReturnType(_currentToken)) {
      TypeAnnotation returnType;
      if (keyword == Keyword.VOID) {
        if (_atGenericFunctionTypeAfterReturnType(_peek())) {
          returnType = parseTypeAnnotation(false);
        } else {
          returnType = astFactory.typeName(
              astFactory.simpleIdentifier(getAndAdvance()), null);
        }
      } else {
        returnType = parseTypeAnnotation(false);
      }
      keyword = _currentToken.keyword;
      Token next = _peek();
      bool isFollowedByIdentifier = _tokenMatchesIdentifier(next);
      if (keyword == Keyword.GET && isFollowedByIdentifier) {
        _validateModifiersForGetterOrSetterOrMethod(modifiers);
        return parseGetter(commentAndMetadata, modifiers.externalKeyword,
            modifiers.staticKeyword, returnType);
      } else if (keyword == Keyword.SET && isFollowedByIdentifier) {
        _validateModifiersForGetterOrSetterOrMethod(modifiers);
        return parseSetter(commentAndMetadata, modifiers.externalKeyword,
            modifiers.staticKeyword, returnType);
      } else if (keyword == Keyword.OPERATOR &&
          (_isOperator(next) || next.type == TokenType.EQ_EQ_EQ)) {
        _validateModifiersForOperator(modifiers);
        return _parseOperatorAfterKeyword(commentAndMetadata,
            modifiers.externalKeyword, returnType, getAndAdvance());
      } else if (_matchesIdentifier() &&
          _peek().matchesAny(const <TokenType>[
            TokenType.OPEN_PAREN,
            TokenType.OPEN_CURLY_BRACKET,
            TokenType.FUNCTION,
            TokenType.LT
          ])) {
        _validateModifiersForGetterOrSetterOrMethod(modifiers);
        return _parseMethodDeclarationAfterReturnType(commentAndMetadata,
            modifiers.externalKeyword, modifiers.staticKeyword, returnType);
      } else if (_matchesIdentifier() &&
          _peek().matchesAny(const <TokenType>[
            TokenType.EQ,
            TokenType.COMMA,
            TokenType.SEMICOLON
          ])) {
        return parseInitializedIdentifierList(
            commentAndMetadata,
            modifiers.staticKeyword,
            modifiers.covariantKeyword,
            _validateModifiersForField(modifiers),
            returnType);
      } else {
        //
        // We have found an error of some kind. Try to recover.
        //
        if (_isOperator(_currentToken)) {
          //
          // We appear to have found an operator declaration without the
          // 'operator' keyword.
          //
          _validateModifiersForOperator(modifiers);
          return parseOperator(
              commentAndMetadata, modifiers.externalKeyword, returnType);
        }
        _reportErrorForToken(
            ParserErrorCode.EXPECTED_EXECUTABLE, _currentToken);
        return null;
      }
    }
    Token next = _peek();
    bool isFollowedByIdentifier = _tokenMatchesIdentifier(next);
    if (keyword == Keyword.GET && isFollowedByIdentifier) {
      _validateModifiersForGetterOrSetterOrMethod(modifiers);
      return parseGetter(commentAndMetadata, modifiers.externalKeyword,
          modifiers.staticKeyword, null);
    } else if (keyword == Keyword.SET && isFollowedByIdentifier) {
      _validateModifiersForGetterOrSetterOrMethod(modifiers);
      return parseSetter(commentAndMetadata, modifiers.externalKeyword,
          modifiers.staticKeyword, null);
    } else if (keyword == Keyword.OPERATOR && _isOperator(next)) {
      _validateModifiersForOperator(modifiers);
      return _parseOperatorAfterKeyword(
          commentAndMetadata, modifiers.externalKeyword, null, getAndAdvance());
    } else if (!_matchesIdentifier()) {
      //
      // Recover from an error.
      //
      if (_matchesKeyword(Keyword.CLASS)) {
        _reportErrorForCurrentToken(ParserErrorCode.CLASS_IN_CLASS);
        // TODO(brianwilkerson) We don't currently have any way to capture the
        // class that was parsed.
        parseClassDeclaration(commentAndMetadata, null);
        return null;
      } else if (_matchesKeyword(Keyword.ABSTRACT) &&
          _tokenMatchesKeyword(_peek(), Keyword.CLASS)) {
        _reportErrorForToken(ParserErrorCode.CLASS_IN_CLASS, _peek());
        // TODO(brianwilkerson) We don't currently have any way to capture the
        // class that was parsed.
        parseClassDeclaration(commentAndMetadata, getAndAdvance());
        return null;
      } else if (_matchesKeyword(Keyword.ENUM)) {
        _reportErrorForToken(ParserErrorCode.ENUM_IN_CLASS, _peek());
        // TODO(brianwilkerson) We don't currently have any way to capture the
        // enum that was parsed.
        parseEnumDeclaration(commentAndMetadata);
        return null;
      } else if (_isOperator(_currentToken)) {
        //
        // We appear to have found an operator declaration without the
        // 'operator' keyword.
        //
        _validateModifiersForOperator(modifiers);
        return parseOperator(
            commentAndMetadata, modifiers.externalKeyword, null);
      }
      Token keyword = modifiers.varKeyword ??
          modifiers.finalKeyword ??
          modifiers.constKeyword;
      if (keyword != null) {
        //
        // We appear to have found an incomplete field declaration.
        //
        _reportErrorForCurrentToken(ParserErrorCode.MISSING_IDENTIFIER);
        VariableDeclaration variable = astFactory.variableDeclaration(
            createSyntheticIdentifier(), null, null);
        List<VariableDeclaration> variables = <VariableDeclaration>[variable];
        return astFactory.fieldDeclaration2(
            comment: commentAndMetadata.comment,
            metadata: commentAndMetadata.metadata,
            covariantKeyword: modifiers.covariantKeyword,
            fieldList: astFactory.variableDeclarationList(
                null, null, keyword, null, variables),
            semicolon: _expect(TokenType.SEMICOLON));
      }
      _reportErrorForToken(
          ParserErrorCode.EXPECTED_CLASS_MEMBER, _currentToken);
      if (commentAndMetadata.comment != null ||
          commentAndMetadata.hasMetadata) {
        //
        // We appear to have found an incomplete declaration at the end of the
        // class. At this point it consists of a metadata, which we don't want
        // to loose, so we'll treat it as a method declaration with a missing
        // name, parameters and empty body.
        //
        return astFactory.methodDeclaration(
            commentAndMetadata.comment,
            commentAndMetadata.metadata,
            null,
            null,
            null,
            null,
            null,
            createSyntheticIdentifier(isDeclaration: true),
            null,
            astFactory.formalParameterList(
                _createSyntheticToken(TokenType.OPEN_PAREN),
                <FormalParameter>[],
                null,
                null,
                _createSyntheticToken(TokenType.CLOSE_PAREN)),
            astFactory
                .emptyFunctionBody(_createSyntheticToken(TokenType.SEMICOLON)));
      }
      return null;
    } else if (_tokenMatches(next, TokenType.PERIOD) &&
        _tokenMatchesIdentifierOrKeyword(_peekAt(2)) &&
        _tokenMatches(_peekAt(3), TokenType.OPEN_PAREN)) {
      if (!_tokenMatchesIdentifier(_peekAt(2))) {
        _reportErrorForToken(ParserErrorCode.INVALID_CONSTRUCTOR_NAME,
            _peekAt(2), [_peekAt(2).lexeme]);
      }
      return _parseConstructor(
          commentAndMetadata,
          modifiers.externalKeyword,
          _validateModifiersForConstructor(modifiers),
          modifiers.factoryKeyword,
          parseSimpleIdentifier(),
          getAndAdvance(),
          parseSimpleIdentifier(allowKeyword: true, isDeclaration: true),
          parseFormalParameterList());
    } else if (_tokenMatches(next, TokenType.OPEN_PAREN)) {
      TypeName returnType = _parseOptionalTypeNameComment();
      SimpleIdentifier methodName = parseSimpleIdentifier(isDeclaration: true);
      TypeParameterList typeParameters = _parseGenericCommentTypeParameters();
      FormalParameterList parameters = parseFormalParameterList();
      if (_matches(TokenType.COLON) ||
          modifiers.factoryKeyword != null ||
          methodName.name == className) {
        return _parseConstructor(
            commentAndMetadata,
            modifiers.externalKeyword,
            _validateModifiersForConstructor(modifiers),
            modifiers.factoryKeyword,
            astFactory.simpleIdentifier(methodName.token, isDeclaration: false),
            null,
            null,
            parameters);
      }
      _validateModifiersForGetterOrSetterOrMethod(modifiers);
      _validateFormalParameterList(parameters);
      return _parseMethodDeclarationAfterParameters(
          commentAndMetadata,
          modifiers.externalKeyword,
          modifiers.staticKeyword,
          returnType,
          methodName,
          typeParameters,
          parameters);
    } else if (next.matchesAny(const <TokenType>[
      TokenType.EQ,
      TokenType.COMMA,
      TokenType.SEMICOLON
    ])) {
      if (modifiers.constKeyword == null &&
          modifiers.finalKeyword == null &&
          modifiers.varKeyword == null) {
        _reportErrorForCurrentToken(
            ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE);
      }
      return parseInitializedIdentifierList(
          commentAndMetadata,
          modifiers.staticKeyword,
          modifiers.covariantKeyword,
          _validateModifiersForField(modifiers),
          null);
    } else if (keyword == Keyword.TYPEDEF) {
      _reportErrorForCurrentToken(ParserErrorCode.TYPEDEF_IN_CLASS);
      // TODO(brianwilkerson) We don't currently have any way to capture the
      // function type alias that was parsed.
      _parseFunctionTypeAlias(commentAndMetadata, getAndAdvance());
      return null;
    } else {
      Token token = _skipTypeParameterList(_peek());
      if (token != null && _tokenMatches(token, TokenType.OPEN_PAREN)) {
        return _parseMethodDeclarationAfterReturnType(commentAndMetadata,
            modifiers.externalKeyword, modifiers.staticKeyword, null);
      }
    }
    TypeAnnotation type = _parseTypeAnnotationAfterIdentifier();
    keyword = _currentToken.keyword;
    next = _peek();
    isFollowedByIdentifier = _tokenMatchesIdentifier(next);
    if (keyword == Keyword.GET && isFollowedByIdentifier) {
      _validateModifiersForGetterOrSetterOrMethod(modifiers);
      return parseGetter(commentAndMetadata, modifiers.externalKeyword,
          modifiers.staticKeyword, type);
    } else if (keyword == Keyword.SET && isFollowedByIdentifier) {
      _validateModifiersForGetterOrSetterOrMethod(modifiers);
      return parseSetter(commentAndMetadata, modifiers.externalKeyword,
          modifiers.staticKeyword, type);
    } else if (keyword == Keyword.OPERATOR && _isOperator(next)) {
      _validateModifiersForOperator(modifiers);
      return _parseOperatorAfterKeyword(
          commentAndMetadata, modifiers.externalKeyword, type, getAndAdvance());
    } else if (!_matchesIdentifier()) {
      if (_matches(TokenType.CLOSE_CURLY_BRACKET)) {
        //
        // We appear to have found an incomplete declaration at the end of the
        // class. At this point it consists of a type name, so we'll treat it as
        // a field declaration with a missing field name and semicolon.
        //
        return parseInitializedIdentifierList(
            commentAndMetadata,
            modifiers.staticKeyword,
            modifiers.covariantKeyword,
            _validateModifiersForField(modifiers),
            type);
      }
      if (_isOperator(_currentToken)) {
        //
        // We appear to have found an operator declaration without the
        // 'operator' keyword.
        //
        _validateModifiersForOperator(modifiers);
        return parseOperator(
            commentAndMetadata, modifiers.externalKeyword, type);
      }
      //
      // We appear to have found an incomplete declaration before another
      // declaration. At this point it consists of a type name, so we'll treat
      // it as a field declaration with a missing field name and semicolon.
      //
      _reportErrorForToken(
          ParserErrorCode.EXPECTED_CLASS_MEMBER, _currentToken);
      try {
        _lockErrorListener();
        return parseInitializedIdentifierList(
            commentAndMetadata,
            modifiers.staticKeyword,
            modifiers.covariantKeyword,
            _validateModifiersForField(modifiers),
            type);
      } finally {
        _unlockErrorListener();
      }
    } else if (_tokenMatches(next, TokenType.OPEN_PAREN)) {
      SimpleIdentifier methodName =
          _parseSimpleIdentifierUnchecked(isDeclaration: true);
      TypeParameterList typeParameters = _parseGenericCommentTypeParameters();
      FormalParameterList parameters = parseFormalParameterList();
      if (methodName.name == className) {
        _reportErrorForNode(ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE, type);
        return _parseConstructor(
            commentAndMetadata,
            modifiers.externalKeyword,
            _validateModifiersForConstructor(modifiers),
            modifiers.factoryKeyword,
            astFactory.simpleIdentifier(methodName.token, isDeclaration: true),
            null,
            null,
            parameters);
      }
      _validateModifiersForGetterOrSetterOrMethod(modifiers);
      _validateFormalParameterList(parameters);
      return _parseMethodDeclarationAfterParameters(
          commentAndMetadata,
          modifiers.externalKeyword,
          modifiers.staticKeyword,
          type,
          methodName,
          typeParameters,
          parameters);
    } else if (_tokenMatches(next, TokenType.LT)) {
      return _parseMethodDeclarationAfterReturnType(commentAndMetadata,
          modifiers.externalKeyword, modifiers.staticKeyword, type);
    } else if (_tokenMatches(next, TokenType.OPEN_CURLY_BRACKET)) {
      // We have found "TypeName identifier {", and are guessing that this is a
      // getter without the keyword 'get'.
      _validateModifiersForGetterOrSetterOrMethod(modifiers);
      _reportErrorForCurrentToken(ParserErrorCode.MISSING_GET);
      _currentToken = _injectToken(
          new SyntheticKeywordToken(Keyword.GET, _currentToken.offset));
      return parseGetter(commentAndMetadata, modifiers.externalKeyword,
          modifiers.staticKeyword, type);
    }
    return parseInitializedIdentifierList(
        commentAndMetadata,
        modifiers.staticKeyword,
        modifiers.covariantKeyword,
        _validateModifiersForField(modifiers),
        type);
  }

  /**
   * Parse a single combinator. Return the combinator that was parsed, or `null`
   * if no combinator is found.
   *
   *     combinator ::=
   *         'show' identifier (',' identifier)*
   *       | 'hide' identifier (',' identifier)*
   */
  Combinator parseCombinator() {
    if (_matchesKeyword(Keyword.SHOW)) {
      return astFactory.showCombinator(getAndAdvance(), parseIdentifierList());
    } else if (_matchesKeyword(Keyword.HIDE)) {
      return astFactory.hideCombinator(getAndAdvance(), parseIdentifierList());
    }
    return null;
  }

  /**
   * Parse a list of combinators in a directive. Return the combinators that
   * were parsed, or `null` if there are no combinators.
   *
   *     combinator ::=
   *         'show' identifier (',' identifier)*
   *       | 'hide' identifier (',' identifier)*
   */
  List<Combinator> parseCombinators() {
    List<Combinator> combinators = null;
    while (true) {
      Combinator combinator = parseCombinator();
      if (combinator == null) {
        break;
      }
      combinators ??= <Combinator>[];
      combinators.add(combinator);
    }
    return combinators;
  }

  /**
   * Parse the documentation comment and metadata preceding a declaration. This
   * method allows any number of documentation comments to occur before, after
   * or between the metadata, but only returns the last (right-most)
   * documentation comment that is found. Return the documentation comment and
   * metadata that were parsed.
   *
   *     metadata ::=
   *         annotation*
   */
  CommentAndMetadata parseCommentAndMetadata() {
    // TODO(brianwilkerson) Consider making the creation of documentation
    // comments be lazy.
    List<DocumentationCommentToken> tokens = parseDocumentationCommentTokens();
    List<Annotation> metadata = null;
    while (_matches(TokenType.AT)) {
      metadata ??= <Annotation>[];
      metadata.add(parseAnnotation());
      List<DocumentationCommentToken> optionalTokens =
          parseDocumentationCommentTokens();
      if (optionalTokens != null) {
        tokens = optionalTokens;
      }
    }
    return new CommentAndMetadata(parseDocumentationComment(tokens), metadata);
  }

  /**
   * Parse a comment reference from the source between square brackets. The
   * [referenceSource] is the source occurring between the square brackets
   * within a documentation comment. The [sourceOffset] is the offset of the
   * first character of the reference source. Return the comment reference that
   * was parsed, or `null` if no reference could be found.
   *
   *     commentReference ::=
   *         'new'? prefixedIdentifier
   */
  CommentReference parseCommentReference(
      String referenceSource, int sourceOffset) {
    // TODO(brianwilkerson) The errors are not getting the right offset/length
    // and are being duplicated.
    try {
      BooleanErrorListener listener = new BooleanErrorListener();
      Scanner scanner = new Scanner(
          null, new SubSequenceReader(referenceSource, sourceOffset), listener);
      scanner.setSourceStart(1, 1);
      Token firstToken = scanner.tokenize();
      if (listener.errorReported) {
        return null;
      }
      if (firstToken.type == TokenType.EOF) {
        Token syntheticToken =
            new SyntheticStringToken(TokenType.IDENTIFIER, "", sourceOffset);
        syntheticToken.setNext(firstToken);
        return astFactory.commentReference(
            null, astFactory.simpleIdentifier(syntheticToken));
      }
      Token newKeyword = null;
      if (_tokenMatchesKeyword(firstToken, Keyword.NEW)) {
        newKeyword = firstToken;
        firstToken = firstToken.next;
      }
      if (firstToken.isUserDefinableOperator) {
        if (firstToken.next.type != TokenType.EOF) {
          return null;
        }
        Identifier identifier = astFactory.simpleIdentifier(firstToken);
        return astFactory.commentReference(null, identifier);
      } else if (_tokenMatchesKeyword(firstToken, Keyword.OPERATOR)) {
        Token secondToken = firstToken.next;
        if (secondToken.isUserDefinableOperator) {
          if (secondToken.next.type != TokenType.EOF) {
            return null;
          }
          Identifier identifier = astFactory.simpleIdentifier(secondToken);
          return astFactory.commentReference(null, identifier);
        }
        return null;
      } else if (_tokenMatchesIdentifier(firstToken)) {
        Token secondToken = firstToken.next;
        Token thirdToken = secondToken.next;
        Token nextToken;
        Identifier identifier;
        if (_tokenMatches(secondToken, TokenType.PERIOD)) {
          if (thirdToken.isUserDefinableOperator) {
            identifier = astFactory.prefixedIdentifier(
                astFactory.simpleIdentifier(firstToken),
                secondToken,
                astFactory.simpleIdentifier(thirdToken));
            nextToken = thirdToken.next;
          } else if (_tokenMatchesKeyword(thirdToken, Keyword.OPERATOR)) {
            Token fourthToken = thirdToken.next;
            if (fourthToken.isUserDefinableOperator) {
              identifier = astFactory.prefixedIdentifier(
                  astFactory.simpleIdentifier(firstToken),
                  secondToken,
                  astFactory.simpleIdentifier(fourthToken));
              nextToken = fourthToken.next;
            } else {
              return null;
            }
          } else if (_tokenMatchesIdentifier(thirdToken)) {
            identifier = astFactory.prefixedIdentifier(
                astFactory.simpleIdentifier(firstToken),
                secondToken,
                astFactory.simpleIdentifier(thirdToken));
            nextToken = thirdToken.next;
          }
        } else {
          identifier = astFactory.simpleIdentifier(firstToken);
          nextToken = firstToken.next;
        }
        if (nextToken.type != TokenType.EOF) {
          return null;
        }
        return astFactory.commentReference(newKeyword, identifier);
      } else {
        Keyword keyword = firstToken.keyword;
        if (keyword == Keyword.THIS ||
            keyword == Keyword.NULL ||
            keyword == Keyword.TRUE ||
            keyword == Keyword.FALSE) {
          // TODO(brianwilkerson) If we want to support this we will need to
          // extend the definition of CommentReference to take an expression
          // rather than an identifier. For now we just ignore it to reduce the
          // number of errors produced, but that's probably not a valid long term
          // approach.
          return null;
        }
      }
    } catch (exception) {
      // Ignored because we assume that it wasn't a real comment reference.
    }
    return null;
  }

  /**
   * Parse all of the comment references occurring in the given array of
   * documentation comments. The [tokens] are the comment tokens representing
   * the documentation comments to be parsed. Return the comment references that
   * were parsed.
   *
   *     commentReference ::=
   *         '[' 'new'? qualified ']' libraryReference?
   *
   *     libraryReference ::=
   *          '(' stringLiteral ')'
   */
  List<CommentReference> parseCommentReferences(
      List<DocumentationCommentToken> tokens) {
    List<CommentReference> references = <CommentReference>[];
    bool isInGitHubCodeBlock = false;
    for (DocumentationCommentToken token in tokens) {
      String comment = token.lexeme;
      // Skip GitHub code blocks.
      // https://help.github.com/articles/creating-and-highlighting-code-blocks/
      if (tokens.length != 1) {
        if (comment.indexOf('```') != -1) {
          isInGitHubCodeBlock = !isInGitHubCodeBlock;
        }
        if (isInGitHubCodeBlock) {
          continue;
        }
      }
      // Remove GitHub include code.
      comment = _removeGitHubInlineCode(comment);
      // Find references.
      int length = comment.length;
      List<List<int>> codeBlockRanges = _getCodeBlockRanges(comment);
      int leftIndex = comment.indexOf('[');
      while (leftIndex >= 0 && leftIndex + 1 < length) {
        List<int> range = _findRange(codeBlockRanges, leftIndex);
        if (range == null) {
          int nameOffset = token.offset + leftIndex + 1;
          int rightIndex = comment.indexOf(']', leftIndex);
          if (rightIndex >= 0) {
            int firstChar = comment.codeUnitAt(leftIndex + 1);
            if (firstChar != 0x27 && firstChar != 0x22) {
              if (_isLinkText(comment, rightIndex)) {
                // TODO(brianwilkerson) Handle the case where there's a library
                // URI in the link text.
              } else {
                CommentReference reference = parseCommentReference(
                    comment.substring(leftIndex + 1, rightIndex), nameOffset);
                if (reference != null) {
                  references.add(reference);
                  token.references.add(reference.beginToken);
                }
              }
            }
          } else {
            // terminating ']' is not typed yet
            int charAfterLeft = comment.codeUnitAt(leftIndex + 1);
            Token nameToken;
            if (Character.isLetterOrDigit(charAfterLeft)) {
              int nameEnd = StringUtilities.indexOfFirstNotLetterDigit(
                  comment, leftIndex + 1);
              String name = comment.substring(leftIndex + 1, nameEnd);
              nameToken =
                  new StringToken(TokenType.IDENTIFIER, name, nameOffset);
            } else {
              nameToken = new SyntheticStringToken(
                  TokenType.IDENTIFIER, '', nameOffset);
            }
            nameToken.setNext(new Token.eof(nameToken.end));
            references.add(astFactory.commentReference(
                null, astFactory.simpleIdentifier(nameToken)));
            token.references.add(nameToken);
            // next character
            rightIndex = leftIndex + 1;
          }
          leftIndex = comment.indexOf('[', rightIndex);
        } else {
          leftIndex = comment.indexOf('[', range[1]);
        }
      }
    }
    return references;
  }

  /**
   * Parse a compilation unit, starting with the given [token]. Return the
   * compilation unit that was parsed.
   */
  CompilationUnit parseCompilationUnit(Token token) {
    _currentToken = token;
    return parseCompilationUnit2();
  }

  /**
   * Parse a compilation unit. Return the compilation unit that was parsed.
   *
   * Specified:
   *
   *     compilationUnit ::=
   *         scriptTag? directive* topLevelDeclaration*
   *
   * Actual:
   *
   *     compilationUnit ::=
   *         scriptTag? topLevelElement*
   *
   *     topLevelElement ::=
   *         directive
   *       | topLevelDeclaration
   */
  CompilationUnit parseCompilationUnit2() {
    Token firstToken = _currentToken;
    ScriptTag scriptTag = null;
    if (_matches(TokenType.SCRIPT_TAG)) {
      scriptTag = astFactory.scriptTag(getAndAdvance());
    }
    //
    // Even though all directives must appear before declarations and must occur
    // in a given order, we allow directives and declarations to occur in any
    // order so that we can recover better.
    //
    bool libraryDirectiveFound = false;
    bool partOfDirectiveFound = false;
    bool partDirectiveFound = false;
    bool directiveFoundAfterDeclaration = false;
    List<Directive> directives = <Directive>[];
    List<CompilationUnitMember> declarations = <CompilationUnitMember>[];
    Token memberStart = _currentToken;
    TokenType type = _currentToken.type;
    while (type != TokenType.EOF) {
      CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
      Keyword keyword = _currentToken.keyword;
      TokenType nextType = _currentToken.next.type;
      if ((keyword == Keyword.IMPORT ||
              keyword == Keyword.EXPORT ||
              keyword == Keyword.LIBRARY ||
              keyword == Keyword.PART) &&
          nextType != TokenType.PERIOD &&
          nextType != TokenType.LT &&
          nextType != TokenType.OPEN_PAREN) {
        Directive parseDirective() {
          if (keyword == Keyword.IMPORT) {
            if (partDirectiveFound) {
              _reportErrorForCurrentToken(
                  ParserErrorCode.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE);
            }
            return parseImportDirective(commentAndMetadata);
          } else if (keyword == Keyword.EXPORT) {
            if (partDirectiveFound) {
              _reportErrorForCurrentToken(
                  ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE);
            }
            return parseExportDirective(commentAndMetadata);
          } else if (keyword == Keyword.LIBRARY) {
            if (libraryDirectiveFound) {
              _reportErrorForCurrentToken(
                  ParserErrorCode.MULTIPLE_LIBRARY_DIRECTIVES);
            } else {
              if (directives.length > 0) {
                _reportErrorForCurrentToken(
                    ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST);
              }
              libraryDirectiveFound = true;
            }
            return parseLibraryDirective(commentAndMetadata);
          } else if (keyword == Keyword.PART) {
            if (_tokenMatchesKeyword(_peek(), Keyword.OF)) {
              partOfDirectiveFound = true;
              return _parsePartOfDirective(commentAndMetadata);
            } else {
              partDirectiveFound = true;
              return _parsePartDirective(commentAndMetadata);
            }
          } else {
            // Internal error: this method should not have been invoked if the
            // current token was something other than one of the above.
            throw new StateError(
                "parseDirective invoked in an invalid state (currentToken = $_currentToken)");
          }
        }

        Directive directive = parseDirective();
        if (declarations.length > 0 && !directiveFoundAfterDeclaration) {
          _reportErrorForToken(ParserErrorCode.DIRECTIVE_AFTER_DECLARATION,
              directive.beginToken);
          directiveFoundAfterDeclaration = true;
        }
        directives.add(directive);
      } else if (type == TokenType.SEMICOLON) {
        // TODO(brianwilkerson) Consider moving this error detection into
        // _parseCompilationUnitMember (in the places where EXPECTED_EXECUTABLE
        // is being generated).
        _reportErrorForToken(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken,
            [_currentToken.lexeme]);
        _advance();
      } else {
        CompilationUnitMember member;
        try {
          member = parseCompilationUnitMember(commentAndMetadata);
        } on _TooDeepTreeError {
          _reportErrorForToken(ParserErrorCode.STACK_OVERFLOW, _currentToken);
          Token eof = new Token.eof(0);
          return astFactory.compilationUnit(eof, null, null, null, eof);
        }
        if (member != null) {
          declarations.add(member);
        }
      }
      if (identical(_currentToken, memberStart)) {
        _reportErrorForToken(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken,
            [_currentToken.lexeme]);
        _advance();
        while (!_matches(TokenType.EOF) &&
            !_couldBeStartOfCompilationUnitMember()) {
          _advance();
        }
      }
      memberStart = _currentToken;
      type = _currentToken.type;
    }
    if (partOfDirectiveFound && directives.length > 1) {
      // TODO(brianwilkerson) Improve error reporting when both a library and
      // part-of directive are found.
//      if (libraryDirectiveFound) {
//        int directiveCount = directives.length;
//        for (int i = 0; i < directiveCount; i++) {
//          Directive directive = directives[i];
//          if (directive is PartOfDirective) {
//            _reportErrorForToken(
//                ParserErrorCode.PART_OF_IN_LIBRARY, directive.partKeyword);
//          }
//        }
//      } else {
      bool firstPartOf = true;
      int directiveCount = directives.length;
      for (int i = 0; i < directiveCount; i++) {
        Directive directive = directives[i];
        if (directive is PartOfDirective) {
          if (firstPartOf) {
            firstPartOf = false;
          } else {
            _reportErrorForToken(ParserErrorCode.MULTIPLE_PART_OF_DIRECTIVES,
                directive.partKeyword);
          }
        } else {
          _reportErrorForToken(ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART,
              directives[i].keyword);
        }
//        }
      }
    }
    return astFactory.compilationUnit(
        firstToken, scriptTag, directives, declarations, _currentToken);
  }

  /**
   * Parse a compilation unit member. The [commentAndMetadata] is the metadata
   * to be associated with the member. Return the compilation unit member that
   * was parsed, or `null` if what was parsed could not be represented as a
   * compilation unit member.
   *
   *     compilationUnitMember ::=
   *         classDefinition
   *       | functionTypeAlias
   *       | external functionSignature
   *       | external getterSignature
   *       | external setterSignature
   *       | functionSignature functionBody
   *       | returnType? getOrSet identifier formalParameterList functionBody
   *       | (final | const) type? staticFinalDeclarationList ';'
   *       | variableDeclaration ';'
   */
  CompilationUnitMember parseCompilationUnitMember(
      CommentAndMetadata commentAndMetadata) {
    Modifiers modifiers = parseModifiers();
    Keyword keyword = _currentToken.keyword;
    if (keyword == Keyword.CLASS) {
      return parseClassDeclaration(
          commentAndMetadata, _validateModifiersForClass(modifiers));
    }
    Token next = _peek();
    TokenType nextType = next.type;
    if (keyword == Keyword.TYPEDEF &&
        nextType != TokenType.PERIOD &&
        nextType != TokenType.LT &&
        nextType != TokenType.OPEN_PAREN) {
      _validateModifiersForTypedef(modifiers);
      return parseTypeAlias(commentAndMetadata);
    } else if (keyword == Keyword.ENUM) {
      _validateModifiersForEnum(modifiers);
      return parseEnumDeclaration(commentAndMetadata);
    } else if (keyword == Keyword.VOID ||
        _atGenericFunctionTypeAfterReturnType(_currentToken)) {
      TypeAnnotation returnType;
      if (keyword == Keyword.VOID) {
        if (_atGenericFunctionTypeAfterReturnType(next)) {
          returnType = parseTypeAnnotation(false);
        } else {
          returnType = astFactory.typeName(
              astFactory.simpleIdentifier(getAndAdvance()), null);
        }
      } else {
        returnType = parseTypeAnnotation(false);
      }
      keyword = _currentToken.keyword;
      next = _peek();
      if ((keyword == Keyword.GET || keyword == Keyword.SET) &&
          _tokenMatchesIdentifier(next)) {
        _validateModifiersForTopLevelFunction(modifiers);
        return parseFunctionDeclaration(
            commentAndMetadata, modifiers.externalKeyword, returnType);
      } else if (keyword == Keyword.OPERATOR && _isOperator(next)) {
        _reportErrorForToken(ParserErrorCode.TOP_LEVEL_OPERATOR, _currentToken);
        return _convertToFunctionDeclaration(_parseOperatorAfterKeyword(
            commentAndMetadata,
            modifiers.externalKeyword,
            returnType,
            getAndAdvance()));
      } else if (_matchesIdentifier() &&
          next.matchesAny(const <TokenType>[
            TokenType.OPEN_PAREN,
            TokenType.OPEN_CURLY_BRACKET,
            TokenType.FUNCTION,
            TokenType.LT
          ])) {
        _validateModifiersForTopLevelFunction(modifiers);
        return parseFunctionDeclaration(
            commentAndMetadata, modifiers.externalKeyword, returnType);
      } else if (_matchesIdentifier() &&
          next.matchesAny(const <TokenType>[
            TokenType.EQ,
            TokenType.COMMA,
            TokenType.SEMICOLON
          ])) {
        return astFactory.topLevelVariableDeclaration(
            commentAndMetadata.comment,
            commentAndMetadata.metadata,
            parseVariableDeclarationListAfterType(null,
                _validateModifiersForTopLevelVariable(modifiers), returnType),
            _expect(TokenType.SEMICOLON));
      } else {
        //
        // We have found an error of some kind. Try to recover.
        //
        _reportErrorForToken(
            ParserErrorCode.EXPECTED_EXECUTABLE, _currentToken);
        return null;
      }
    } else if ((keyword == Keyword.GET || keyword == Keyword.SET) &&
        _tokenMatchesIdentifier(next)) {
      _validateModifiersForTopLevelFunction(modifiers);
      return parseFunctionDeclaration(
          commentAndMetadata, modifiers.externalKeyword, null);
    } else if (keyword == Keyword.OPERATOR && _isOperator(next)) {
      _reportErrorForToken(ParserErrorCode.TOP_LEVEL_OPERATOR, _currentToken);
      return _convertToFunctionDeclaration(_parseOperatorAfterKeyword(
          commentAndMetadata,
          modifiers.externalKeyword,
          null,
          getAndAdvance()));
    } else if (!_matchesIdentifier()) {
      Token keyword = modifiers.varKeyword;
      if (keyword == null) {
        keyword = modifiers.finalKeyword;
      }
      if (keyword == null) {
        keyword = modifiers.constKeyword;
      }
      if (keyword != null) {
        //
        // We appear to have found an incomplete top-level variable declaration.
        //
        _reportErrorForCurrentToken(ParserErrorCode.MISSING_IDENTIFIER);
        VariableDeclaration variable = astFactory.variableDeclaration(
            createSyntheticIdentifier(), null, null);
        List<VariableDeclaration> variables = <VariableDeclaration>[variable];
        return astFactory.topLevelVariableDeclaration(
            commentAndMetadata.comment,
            commentAndMetadata.metadata,
            astFactory.variableDeclarationList(
                null, null, keyword, null, variables),
            _expect(TokenType.SEMICOLON));
      }
      _reportErrorForToken(ParserErrorCode.EXPECTED_EXECUTABLE, _currentToken);
      return null;
    } else if (_isPeekGenericTypeParametersAndOpenParen()) {
      return parseFunctionDeclaration(
          commentAndMetadata, modifiers.externalKeyword, null);
    } else if (_tokenMatches(next, TokenType.OPEN_PAREN)) {
      TypeName returnType = _parseOptionalTypeNameComment();
      _validateModifiersForTopLevelFunction(modifiers);
      return parseFunctionDeclaration(
          commentAndMetadata, modifiers.externalKeyword, returnType);
    } else if (next.matchesAny(const <TokenType>[
      TokenType.EQ,
      TokenType.COMMA,
      TokenType.SEMICOLON
    ])) {
      if (modifiers.constKeyword == null &&
          modifiers.finalKeyword == null &&
          modifiers.varKeyword == null) {
        _reportErrorForCurrentToken(
            ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE);
      }
      return astFactory.topLevelVariableDeclaration(
          commentAndMetadata.comment,
          commentAndMetadata.metadata,
          parseVariableDeclarationListAfterType(
              null, _validateModifiersForTopLevelVariable(modifiers), null),
          _expect(TokenType.SEMICOLON));
    }
    TypeAnnotation returnType = parseTypeAnnotation(false);
    keyword = _currentToken.keyword;
    next = _peek();
    if ((keyword == Keyword.GET || keyword == Keyword.SET) &&
        _tokenMatchesIdentifier(next)) {
      _validateModifiersForTopLevelFunction(modifiers);
      return parseFunctionDeclaration(
          commentAndMetadata, modifiers.externalKeyword, returnType);
    } else if (keyword == Keyword.OPERATOR && _isOperator(next)) {
      _reportErrorForToken(ParserErrorCode.TOP_LEVEL_OPERATOR, _currentToken);
      return _convertToFunctionDeclaration(_parseOperatorAfterKeyword(
          commentAndMetadata,
          modifiers.externalKeyword,
          returnType,
          getAndAdvance()));
    } else if (_matches(TokenType.AT)) {
      return astFactory.topLevelVariableDeclaration(
          commentAndMetadata.comment,
          commentAndMetadata.metadata,
          parseVariableDeclarationListAfterType(null,
              _validateModifiersForTopLevelVariable(modifiers), returnType),
          _expect(TokenType.SEMICOLON));
    } else if (!_matchesIdentifier()) {
      // TODO(brianwilkerson) Generalize this error. We could also be parsing a
      // top-level variable at this point.
      _reportErrorForToken(ParserErrorCode.EXPECTED_EXECUTABLE, _currentToken);
      Token semicolon;
      if (_matches(TokenType.SEMICOLON)) {
        semicolon = getAndAdvance();
      } else {
        semicolon = _createSyntheticToken(TokenType.SEMICOLON);
      }
      VariableDeclaration variable = astFactory.variableDeclaration(
          createSyntheticIdentifier(), null, null);
      List<VariableDeclaration> variables = <VariableDeclaration>[variable];
      return astFactory.topLevelVariableDeclaration(
          commentAndMetadata.comment,
          commentAndMetadata.metadata,
          astFactory.variableDeclarationList(
              null, null, null, returnType, variables),
          semicolon);
    } else if (next.matchesAny(const <TokenType>[
      TokenType.OPEN_PAREN,
      TokenType.FUNCTION,
      TokenType.OPEN_CURLY_BRACKET,
      TokenType.LT
    ])) {
      _validateModifiersForTopLevelFunction(modifiers);
      return parseFunctionDeclaration(
          commentAndMetadata, modifiers.externalKeyword, returnType);
    }
    return astFactory.topLevelVariableDeclaration(
        commentAndMetadata.comment,
        commentAndMetadata.metadata,
        parseVariableDeclarationListAfterType(
            null, _validateModifiersForTopLevelVariable(modifiers), returnType),
        _expect(TokenType.SEMICOLON));
  }

  /**
   * Parse a conditional expression. Return the conditional expression that was
   * parsed.
   *
   *     conditionalExpression ::=
   *         ifNullExpression ('?' expressionWithoutCascade ':' expressionWithoutCascade)?
   */
  Expression parseConditionalExpression() {
    Expression condition = parseIfNullExpression();
    if (_currentToken.type != TokenType.QUESTION) {
      return condition;
    }
    Token question = getAndAdvance();
    Expression thenExpression = parseExpressionWithoutCascade();
    Token colon = _expect(TokenType.COLON);
    Expression elseExpression = parseExpressionWithoutCascade();
    return astFactory.conditionalExpression(
        condition, question, thenExpression, colon, elseExpression);
  }

  /**
   * Parse a configuration in either an import or export directive.
   *
   * This method assumes that the current token matches `Keyword.IF`.
   *
   *     configuration ::=
   *         'if' '(' test ')' uri
   *
   *     test ::=
   *         dottedName ('==' stringLiteral)?
   *
   *     dottedName ::=
   *         identifier ('.' identifier)*
   */
  Configuration parseConfiguration() {
    Token ifKeyword = getAndAdvance();
    Token leftParenthesis = _expect(TokenType.OPEN_PAREN);
    DottedName name = parseDottedName();
    Token equalToken = null;
    StringLiteral value = null;
    if (_matches(TokenType.EQ_EQ)) {
      equalToken = getAndAdvance();
      value = parseStringLiteral();
      if (value is StringInterpolation) {
        _reportErrorForNode(
            ParserErrorCode.INVALID_LITERAL_IN_CONFIGURATION, value);
      }
    }
    Token rightParenthesis = _expect(TokenType.CLOSE_PAREN);
    StringLiteral libraryUri = _parseUri();
    return astFactory.configuration(ifKeyword, leftParenthesis, name,
        equalToken, value, rightParenthesis, libraryUri);
  }

  /**
   * Parse a const expression. Return the const expression that was parsed.
   *
   * This method assumes that the current token matches `Keyword.CONST`.
   *
   *     constExpression ::=
   *         instanceCreationExpression
   *       | listLiteral
   *       | mapLiteral
   */
  Expression parseConstExpression() {
    Token keyword = getAndAdvance();
    TokenType type = _currentToken.type;
    if (type == TokenType.LT || _injectGenericCommentTypeList()) {
      return parseListOrMapLiteral(keyword);
    } else if (type == TokenType.OPEN_SQUARE_BRACKET ||
        type == TokenType.INDEX) {
      return parseListLiteral(keyword, null);
    } else if (type == TokenType.OPEN_CURLY_BRACKET) {
      return parseMapLiteral(keyword, null);
    }
    return parseInstanceCreationExpression(keyword);
  }

  /**
   * Parse a field initializer within a constructor. The flag [hasThis] should
   * be true if the current token is `this`. Return the field initializer that
   * was parsed.
   *
   *     fieldInitializer:
   *         ('this' '.')? identifier '=' conditionalExpression cascadeSection*
   */
  ConstructorFieldInitializer parseConstructorFieldInitializer(bool hasThis) {
    Token keywordToken = null;
    Token period = null;
    if (hasThis) {
      keywordToken = getAndAdvance();
      period = _expect(TokenType.PERIOD);
    }
    SimpleIdentifier fieldName = parseSimpleIdentifier();
    Token equals = null;
    TokenType type = _currentToken.type;
    if (type == TokenType.EQ) {
      equals = getAndAdvance();
    } else {
      _reportErrorForCurrentToken(
          ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER);
      Keyword keyword = _currentToken.keyword;
      if (keyword != Keyword.THIS &&
          keyword != Keyword.SUPER &&
          type != TokenType.OPEN_CURLY_BRACKET &&
          type != TokenType.FUNCTION) {
        equals = _createSyntheticToken(TokenType.EQ);
      } else {
        return astFactory.constructorFieldInitializer(
            keywordToken,
            period,
            fieldName,
            _createSyntheticToken(TokenType.EQ),
            createSyntheticIdentifier());
      }
    }
    bool wasInInitializer = _inInitializer;
    _inInitializer = true;
    try {
      Expression expression = parseConditionalExpression();
      if (_matches(TokenType.PERIOD_PERIOD)) {
        List<Expression> cascadeSections = <Expression>[];
        do {
          Expression section = parseCascadeSection();
          if (section != null) {
            cascadeSections.add(section);
          }
        } while (_matches(TokenType.PERIOD_PERIOD));
        expression = astFactory.cascadeExpression(expression, cascadeSections);
      }
      return astFactory.constructorFieldInitializer(
          keywordToken, period, fieldName, equals, expression);
    } finally {
      _inInitializer = wasInInitializer;
    }
  }

  /**
   * Parse the name of a constructor. Return the constructor name that was
   * parsed.
   *
   *     constructorName:
   *         type ('.' identifier)?
   */
  ConstructorName parseConstructorName() {
    TypeName type = parseTypeName(false);
    Token period = null;
    SimpleIdentifier name = null;
    if (_matches(TokenType.PERIOD)) {
      period = getAndAdvance();
      name = parseSimpleIdentifier();
    }
    return astFactory.constructorName(type, period, name);
  }

  /**
   * Parse a continue statement. Return the continue statement that was parsed.
   *
   * This method assumes that the current token matches `Keyword.CONTINUE`.
   *
   *     continueStatement ::=
   *         'continue' identifier? ';'
   */
  Statement parseContinueStatement() {
    Token continueKeyword = getAndAdvance();
    if (!_inLoop && !_inSwitch) {
      _reportErrorForToken(
          ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP, continueKeyword);
    }
    SimpleIdentifier label = null;
    if (_matchesIdentifier()) {
      label = _parseSimpleIdentifierUnchecked();
    }
    if (_inSwitch && !_inLoop && label == null) {
      _reportErrorForToken(
          ParserErrorCode.CONTINUE_WITHOUT_LABEL_IN_CASE, continueKeyword);
    }
    Token semicolon = _expect(TokenType.SEMICOLON);
    return astFactory.continueStatement(continueKeyword, label, semicolon);
  }

  /**
   * Parse a directive. The [commentAndMetadata] is the metadata to be
   * associated with the directive. Return the directive that was parsed.
   *
   *     directive ::=
   *         exportDirective
   *       | libraryDirective
   *       | importDirective
   *       | partDirective
   */
  Directive parseDirective(CommentAndMetadata commentAndMetadata) {
    if (_matchesKeyword(Keyword.IMPORT)) {
      return parseImportDirective(commentAndMetadata);
    } else if (_matchesKeyword(Keyword.EXPORT)) {
      return parseExportDirective(commentAndMetadata);
    } else if (_matchesKeyword(Keyword.LIBRARY)) {
      return parseLibraryDirective(commentAndMetadata);
    } else if (_matchesKeyword(Keyword.PART)) {
      return parsePartOrPartOfDirective(commentAndMetadata);
    } else {
      // Internal error: this method should not have been invoked if the current
      // token was something other than one of the above.
      throw new StateError(
          "parseDirective invoked in an invalid state; currentToken = $_currentToken");
    }
  }

  /**
   * Parse the script tag and directives in a compilation unit, starting with
   * the given [token], until the first non-directive is encountered. The
   * remainder of the compilation unit will not be parsed. Specifically, if
   * there are directives later in the file, they will not be parsed. Return the
   * compilation unit that was parsed.
   */
  CompilationUnit parseDirectives(Token token) {
    _currentToken = token;
    return parseDirectives2();
  }

  /**
   * Parse the script tag and directives in a compilation unit until the first
   * non-directive is encountered. Return the compilation unit that was parsed.
   *
   *     compilationUnit ::=
   *         scriptTag? directive*
   */
  CompilationUnit parseDirectives2() {
    Token firstToken = _currentToken;
    ScriptTag scriptTag = null;
    if (_matches(TokenType.SCRIPT_TAG)) {
      scriptTag = astFactory.scriptTag(getAndAdvance());
    }
    List<Directive> directives = <Directive>[];
    while (!_matches(TokenType.EOF)) {
      CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
      Keyword keyword = _currentToken.keyword;
      TokenType type = _peek().type;
      if ((keyword == Keyword.IMPORT ||
              keyword == Keyword.EXPORT ||
              keyword == Keyword.LIBRARY ||
              keyword == Keyword.PART) &&
          type != TokenType.PERIOD &&
          type != TokenType.LT &&
          type != TokenType.OPEN_PAREN) {
        directives.add(parseDirective(commentAndMetadata));
      } else if (_matches(TokenType.SEMICOLON)) {
        _advance();
      } else {
        while (!_matches(TokenType.EOF)) {
          _advance();
        }
        return astFactory.compilationUnit(
            firstToken, scriptTag, directives, null, _currentToken);
      }
    }
    return astFactory.compilationUnit(
        firstToken, scriptTag, directives, null, _currentToken);
  }

  /**
   * Parse a documentation comment based on the given list of documentation
   * comment tokens. Return the documentation comment that was parsed, or `null`
   * if there was no comment.
   *
   *     documentationComment ::=
   *         multiLineComment?
   *       | singleLineComment*
   */
  Comment parseDocumentationComment(List<DocumentationCommentToken> tokens) {
    if (tokens == null) {
      return null;
    }
    List<CommentReference> references = parseCommentReferences(tokens);
    return astFactory.documentationComment(tokens, references);
  }

  /**
   * Parse a documentation comment. Return the documentation comment that was
   * parsed, or `null` if there was no comment.
   *
   *     documentationComment ::=
   *         multiLineComment?
   *       | singleLineComment*
   */
  List<DocumentationCommentToken> parseDocumentationCommentTokens() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[];
    CommentToken commentToken = _currentToken.precedingComments;
    while (commentToken != null) {
      if (commentToken is DocumentationCommentToken) {
        if (tokens.isNotEmpty) {
          if (commentToken.type == TokenType.SINGLE_LINE_COMMENT) {
            if (tokens[0].type != TokenType.SINGLE_LINE_COMMENT) {
              tokens.clear();
            }
          } else {
            tokens.clear();
          }
        }
        tokens.add(commentToken);
      }
      commentToken = commentToken.next;
    }
    return tokens.isEmpty ? null : tokens;
  }

  /**
   * Parse a do statement. Return the do statement that was parsed.
   *
   * This method assumes that the current token matches `Keyword.DO`.
   *
   *     doStatement ::=
   *         'do' statement 'while' '(' expression ')' ';'
   */
  Statement parseDoStatement() {
    bool wasInLoop = _inLoop;
    _inLoop = true;
    try {
      Token doKeyword = getAndAdvance();
      Statement body = parseStatement2();
      Token whileKeyword = _expectKeyword(Keyword.WHILE);
      Token leftParenthesis = _expect(TokenType.OPEN_PAREN);
      Expression condition = parseExpression2();
      Token rightParenthesis = _expect(TokenType.CLOSE_PAREN);
      Token semicolon = _expect(TokenType.SEMICOLON);
      return astFactory.doStatement(doKeyword, body, whileKeyword,
          leftParenthesis, condition, rightParenthesis, semicolon);
    } finally {
      _inLoop = wasInLoop;
    }
  }

  /**
   * Parse a dotted name. Return the dotted name that was parsed.
   *
   *     dottedName ::=
   *         identifier ('.' identifier)*
   */
  DottedName parseDottedName() {
    List<SimpleIdentifier> components = <SimpleIdentifier>[
      parseSimpleIdentifier()
    ];
    while (_optional(TokenType.PERIOD)) {
      components.add(parseSimpleIdentifier());
    }
    return astFactory.dottedName(components);
  }

  /**
   * Parse an empty statement. Return the empty statement that was parsed.
   *
   * This method assumes that the current token matches `TokenType.SEMICOLON`.
   *
   *     emptyStatement ::=
   *         ';'
   */
  Statement parseEmptyStatement() => astFactory.emptyStatement(getAndAdvance());

  /**
   * Parse an enum declaration. The [commentAndMetadata] is the metadata to be
   * associated with the member. Return the enum declaration that was parsed.
   *
   * This method assumes that the current token matches `Keyword.ENUM`.
   *
   *     enumType ::=
   *         metadata 'enum' id '{' id (',' id)* (',')? '}'
   */
  EnumDeclaration parseEnumDeclaration(CommentAndMetadata commentAndMetadata) {
    Token keyword = getAndAdvance();
    SimpleIdentifier name = parseSimpleIdentifier(isDeclaration: true);
    Token leftBracket = null;
    List<EnumConstantDeclaration> constants = <EnumConstantDeclaration>[];
    Token rightBracket = null;
    if (_matches(TokenType.OPEN_CURLY_BRACKET)) {
      leftBracket = getAndAdvance();
      if (_matchesIdentifier() || _matches(TokenType.AT)) {
        constants.add(_parseEnumConstantDeclaration());
      } else if (_matches(TokenType.COMMA) &&
          _tokenMatchesIdentifier(_peek())) {
        constants.add(_parseEnumConstantDeclaration());
        _reportErrorForCurrentToken(ParserErrorCode.MISSING_IDENTIFIER);
      } else {
        constants.add(_parseEnumConstantDeclaration());
        _reportErrorForCurrentToken(ParserErrorCode.EMPTY_ENUM_BODY);
      }
      while (_optional(TokenType.COMMA)) {
        if (_matches(TokenType.CLOSE_CURLY_BRACKET)) {
          break;
        }
        constants.add(_parseEnumConstantDeclaration());
      }
      rightBracket = _expect(TokenType.CLOSE_CURLY_BRACKET);
    } else {
      leftBracket = _createSyntheticToken(TokenType.OPEN_CURLY_BRACKET);
      rightBracket = _createSyntheticToken(TokenType.CLOSE_CURLY_BRACKET);
      _reportErrorForCurrentToken(ParserErrorCode.MISSING_ENUM_BODY);
    }
    return astFactory.enumDeclaration(
        commentAndMetadata.comment,
        commentAndMetadata.metadata,
        keyword,
        name,
        leftBracket,
        constants,
        rightBracket);
  }

  /**
   * Parse an equality expression. Return the equality expression that was
   * parsed.
   *
   *     equalityExpression ::=
   *         relationalExpression (equalityOperator relationalExpression)?
   *       | 'super' equalityOperator relationalExpression
   */
  Expression parseEqualityExpression() {
    Expression expression;
    if (_currentToken.keyword == Keyword.SUPER &&
        _currentToken.next.type.isEqualityOperator) {
      expression = astFactory.superExpression(getAndAdvance());
    } else {
      expression = parseRelationalExpression();
    }
    bool leftEqualityExpression = false;
    while (_currentToken.type.isEqualityOperator) {
      if (leftEqualityExpression) {
        _reportErrorForNode(
            ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND, expression);
      }
      expression = astFactory.binaryExpression(
          expression, getAndAdvance(), parseRelationalExpression());
      leftEqualityExpression = true;
    }
    return expression;
  }

  /**
   * Parse an export directive. The [commentAndMetadata] is the metadata to be
   * associated with the directive. Return the export directive that was parsed.
   *
   * This method assumes that the current token matches `Keyword.EXPORT`.
   *
   *     exportDirective ::=
   *         metadata 'export' stringLiteral configuration* combinator*';'
   */
  ExportDirective parseExportDirective(CommentAndMetadata commentAndMetadata) {
    Token exportKeyword = getAndAdvance();
    StringLiteral libraryUri = _parseUri();
    List<Configuration> configurations = _parseConfigurations();
    List<Combinator> combinators = parseCombinators();
    Token semicolon = _expect(TokenType.SEMICOLON);
    return astFactory.exportDirective(
        commentAndMetadata.comment,
        commentAndMetadata.metadata,
        exportKeyword,
        libraryUri,
        configurations,
        combinators,
        semicolon);
  }

  /**
   * Parse an expression, starting with the given [token]. Return the expression
   * that was parsed, or `null` if the tokens do not represent a recognizable
   * expression.
   */
  Expression parseExpression(Token token) {
    _currentToken = token;
    return parseExpression2();
  }

  /**
   * Parse an expression that might contain a cascade. Return the expression
   * that was parsed.
   *
   *     expression ::=
   *         assignableExpression assignmentOperator expression
   *       | conditionalExpression cascadeSection*
   *       | throwExpression
   */
  Expression parseExpression2() {
    if (_treeDepth > _MAX_TREE_DEPTH) {
      throw new _TooDeepTreeError();
    }
    _treeDepth++;
    try {
      Keyword keyword = _currentToken.keyword;
      if (keyword == Keyword.THROW) {
        return parseThrowExpression();
      } else if (keyword == Keyword.RETHROW) {
        // TODO(brianwilkerson) Rethrow is a statement again.
        return parseRethrowExpression();
      }
      //
      // assignableExpression is a subset of conditionalExpression, so we can
      // parse a conditional expression and then determine whether it is followed
      // by an assignmentOperator, checking for conformance to the restricted
      // grammar after making that determination.
      //
      Expression expression = parseConditionalExpression();
      TokenType type = _currentToken.type;
      if (type == TokenType.PERIOD_PERIOD) {
        List<Expression> cascadeSections = <Expression>[];
        do {
          Expression section = parseCascadeSection();
          if (section != null) {
            cascadeSections.add(section);
          }
        } while (_currentToken.type == TokenType.PERIOD_PERIOD);
        return astFactory.cascadeExpression(expression, cascadeSections);
      } else if (type.isAssignmentOperator) {
        Token operator = getAndAdvance();
        _ensureAssignable(expression);
        return astFactory.assignmentExpression(
            expression, operator, parseExpression2());
      }
      return expression;
    } finally {
      _treeDepth--;
    }
  }

  /**
   * Parse a list of expressions. Return the expression that was parsed.
   *
   *     expressionList ::=
   *         expression (',' expression)*
   */
  List<Expression> parseExpressionList() {
    List<Expression> expressions = <Expression>[parseExpression2()];
    while (_optional(TokenType.COMMA)) {
      expressions.add(parseExpression2());
    }
    return expressions;
  }

  /**
   * Parse an expression that does not contain any cascades. Return the
   * expression that was parsed.
   *
   *     expressionWithoutCascade ::=
   *         assignableExpression assignmentOperator expressionWithoutCascade
   *       | conditionalExpression
   *       | throwExpressionWithoutCascade
   */
  Expression parseExpressionWithoutCascade() {
    if (_matchesKeyword(Keyword.THROW)) {
      return parseThrowExpressionWithoutCascade();
    } else if (_matchesKeyword(Keyword.RETHROW)) {
      return parseRethrowExpression();
    }
    //
    // assignableExpression is a subset of conditionalExpression, so we can
    // parse a conditional expression and then determine whether it is followed
    // by an assignmentOperator, checking for conformance to the restricted
    // grammar after making that determination.
    //
    Expression expression = parseConditionalExpression();
    if (_currentToken.type.isAssignmentOperator) {
      Token operator = getAndAdvance();
      _ensureAssignable(expression);
      expression = astFactory.assignmentExpression(
          expression, operator, parseExpressionWithoutCascade());
    }
    return expression;
  }

  /**
   * Parse a class extends clause. Return the class extends clause that was
   * parsed.
   *
   * This method assumes that the current token matches `Keyword.EXTENDS`.
   *
   *     classExtendsClause ::=
   *         'extends' type
   */
  ExtendsClause parseExtendsClause() {
    Token keyword = getAndAdvance();
    TypeName superclass = parseTypeName(false);
    _mustNotBeNullable(superclass, ParserErrorCode.NULLABLE_TYPE_IN_EXTENDS);
    return astFactory.extendsClause(keyword, superclass);
  }

  /**
   * Parse the 'final', 'const', 'var' or type preceding a variable declaration.
   * The [optional] is `true` if the keyword and type are optional. Return the
   * 'final', 'const', 'var' or type that was parsed.
   *
   *     finalConstVarOrType ::=
   *         'final' type?
   *       | 'const' type?
   *       | 'var'
   *       | type
   */
  FinalConstVarOrType parseFinalConstVarOrType(bool optional,
      {bool inFunctionType: false}) {
    Token keywordToken = null;
    TypeAnnotation type = null;
    Keyword keyword = _currentToken.keyword;
    if (keyword == Keyword.FINAL || keyword == Keyword.CONST) {
      keywordToken = getAndAdvance();
      if (_isTypedIdentifier(_currentToken)) {
        type = parseTypeAnnotation(false);
      } else {
        // Support `final/*=T*/ x;`
        type = _parseOptionalTypeNameComment();
      }
    } else if (keyword == Keyword.VAR) {
      keywordToken = getAndAdvance();
      // Support `var/*=T*/ x;`
      type = _parseOptionalTypeNameComment();
      if (type != null) {
        // Clear the keyword to prevent an error.
        keywordToken = null;
      }
    } else if (_isTypedIdentifier(_currentToken)) {
      type = parseTypeAnnotation(false);
    } else if (inFunctionType && _matchesIdentifier()) {
      type = parseTypeAnnotation(false);
    } else if (!optional) {
      // If there is a valid type immediately following an unexpected token,
      // then report and skip the unexpected token.
      Token next = _peek();
      Keyword nextKeyword = next.keyword;
      if (nextKeyword == Keyword.FINAL ||
          nextKeyword == Keyword.CONST ||
          nextKeyword == Keyword.VAR ||
          _isTypedIdentifier(next) ||
          inFunctionType && _tokenMatchesIdentifier(next)) {
        _reportErrorForCurrentToken(
            ParserErrorCode.UNEXPECTED_TOKEN, [_currentToken.lexeme]);
        _advance();
        return parseFinalConstVarOrType(optional,
            inFunctionType: inFunctionType);
      }
      _reportErrorForCurrentToken(
          ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE);
    } else {
      // Support parameters such as `(/*=K*/ key, /*=V*/ value)`
      // This is not supported if the type is required.
      type = _parseOptionalTypeNameComment();
    }
    return new FinalConstVarOrType(keywordToken, type);
  }

  /**
   * Parse a formal parameter. At most one of `isOptional` and `isNamed` can be
   * `true`. The [kind] is the kind of parameter being expected based on the
   * presence or absence of group delimiters. Return the formal parameter that
   * was parsed.
   *
   *     defaultFormalParameter ::=
   *         normalFormalParameter ('=' expression)?
   *
   *     defaultNamedParameter ::=
   *         normalFormalParameter ('=' expression)?
   *         normalFormalParameter (':' expression)?
   */
  FormalParameter parseFormalParameter(ParameterKind kind,
      {bool inFunctionType: false}) {
    NormalFormalParameter parameter =
        parseNormalFormalParameter(inFunctionType: inFunctionType);
    TokenType type = _currentToken.type;
    if (type == TokenType.EQ) {
      if (inFunctionType) {
        _reportErrorForCurrentToken(
            ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE);
      }
      Token separator = getAndAdvance();
      Expression defaultValue = parseExpression2();
      if (kind == ParameterKind.REQUIRED) {
        _reportErrorForNode(
            ParserErrorCode.POSITIONAL_PARAMETER_OUTSIDE_GROUP, parameter);
        kind = ParameterKind.POSITIONAL;
      } else if (kind == ParameterKind.NAMED &&
          inFunctionType &&
          parameter.identifier == null) {
        _reportErrorForCurrentToken(
            ParserErrorCode.MISSING_NAME_FOR_NAMED_PARAMETER);
        parameter.identifier = createSyntheticIdentifier(isDeclaration: true);
      }
      return astFactory.defaultFormalParameter(
          parameter, kind, separator, defaultValue);
    } else if (type == TokenType.COLON) {
      if (inFunctionType) {
        _reportErrorForCurrentToken(
            ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE);
      }
      Token separator = getAndAdvance();
      Expression defaultValue = parseExpression2();
      if (kind == ParameterKind.REQUIRED) {
        _reportErrorForNode(
            ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP, parameter);
        kind = ParameterKind.NAMED;
      } else if (kind == ParameterKind.POSITIONAL) {
        _reportErrorForToken(
            ParserErrorCode.WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER,
            separator);
      } else if (kind == ParameterKind.NAMED &&
          inFunctionType &&
          parameter.identifier == null) {
        _reportErrorForCurrentToken(
            ParserErrorCode.MISSING_NAME_FOR_NAMED_PARAMETER);
        parameter.identifier = createSyntheticIdentifier(isDeclaration: true);
      }
      return astFactory.defaultFormalParameter(
          parameter, kind, separator, defaultValue);
    } else if (kind != ParameterKind.REQUIRED) {
      if (kind == ParameterKind.NAMED &&
          inFunctionType &&
          parameter.identifier == null) {
        _reportErrorForCurrentToken(
            ParserErrorCode.MISSING_NAME_FOR_NAMED_PARAMETER);
        parameter.identifier = createSyntheticIdentifier(isDeclaration: true);
      }
      return astFactory.defaultFormalParameter(parameter, kind, null, null);
    }
    return parameter;
  }

  /**
   * Parse a list of formal parameters. Return the formal parameters that were
   * parsed.
   *
   *     formalParameterList ::=
   *         '(' ')'
   *       | '(' normalFormalParameters (',' optionalFormalParameters)? ')'
   *       | '(' optionalFormalParameters ')'
   *
   *     normalFormalParameters ::=
   *         normalFormalParameter (',' normalFormalParameter)*
   *
   *     optionalFormalParameters ::=
   *         optionalPositionalFormalParameters
   *       | namedFormalParameters
   *
   *     optionalPositionalFormalParameters ::=
   *         '[' defaultFormalParameter (',' defaultFormalParameter)* ']'
   *
   *     namedFormalParameters ::=
   *         '{' defaultNamedParameter (',' defaultNamedParameter)* '}'
   */
  FormalParameterList parseFormalParameterList({bool inFunctionType: false}) {
    if (_matches(TokenType.OPEN_PAREN)) {
      return _parseFormalParameterListUnchecked(inFunctionType: inFunctionType);
    }
    // TODO(brianwilkerson) Improve the error message.
    _reportErrorForCurrentToken(
        ParserErrorCode.EXPECTED_TOKEN, [TokenType.OPEN_PAREN.lexeme]);
    // Recovery: Check for an unmatched closing paren and parse parameters until
    // it is reached.
    return _parseFormalParameterListAfterParen(
        _createSyntheticToken(TokenType.OPEN_PAREN));
  }

  /**
   * Parse a for statement. Return the for statement that was parsed.
   *
   *     forStatement ::=
   *         'for' '(' forLoopParts ')' statement
   *
   *     forLoopParts ::=
   *         forInitializerStatement expression? ';' expressionList?
   *       | declaredIdentifier 'in' expression
   *       | identifier 'in' expression
   *
   *     forInitializerStatement ::=
   *         localVariableDeclaration ';'
   *       | expression? ';'
   */
  Statement parseForStatement() {
    bool wasInLoop = _inLoop;
    _inLoop = true;
    try {
      Token awaitKeyword = null;
      if (_matchesKeyword(Keyword.AWAIT)) {
        awaitKeyword = getAndAdvance();
      }
      Token forKeyword = _expectKeyword(Keyword.FOR);
      Token leftParenthesis = _expect(TokenType.OPEN_PAREN);
      VariableDeclarationList variableList = null;
      Expression initialization = null;
      if (!_matches(TokenType.SEMICOLON)) {
        CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
        if (_matchesIdentifier() &&
            (_tokenMatchesKeyword(_peek(), Keyword.IN) ||
                _tokenMatches(_peek(), TokenType.COLON))) {
          SimpleIdentifier variableName = _parseSimpleIdentifierUnchecked();
          variableList = astFactory.variableDeclarationList(
              commentAndMetadata.comment,
              commentAndMetadata.metadata,
              null,
              null, <VariableDeclaration>[
            astFactory.variableDeclaration(variableName, null, null)
          ]);
        } else if (isInitializedVariableDeclaration()) {
          variableList =
              parseVariableDeclarationListAfterMetadata(commentAndMetadata);
        } else {
          initialization = parseExpression2();
        }
        TokenType type = _currentToken.type;
        if (_matchesKeyword(Keyword.IN) || type == TokenType.COLON) {
          if (type == TokenType.COLON) {
            _reportErrorForCurrentToken(ParserErrorCode.COLON_IN_PLACE_OF_IN);
          }
          DeclaredIdentifier loopVariable = null;
          SimpleIdentifier identifier = null;
          if (variableList == null) {
            // We found: <expression> 'in'
            _reportErrorForCurrentToken(
                ParserErrorCode.MISSING_VARIABLE_IN_FOR_EACH);
          } else {
            NodeList<VariableDeclaration> variables = variableList.variables;
            if (variables.length > 1) {
              _reportErrorForCurrentToken(
                  ParserErrorCode.MULTIPLE_VARIABLES_IN_FOR_EACH,
                  [variables.length.toString()]);
            }
            VariableDeclaration variable = variables[0];
            if (variable.initializer != null) {
              _reportErrorForCurrentToken(
                  ParserErrorCode.INITIALIZED_VARIABLE_IN_FOR_EACH);
            }
            Token keyword = variableList.keyword;
            TypeAnnotation type = variableList.type;
            if (keyword != null || type != null) {
              loopVariable = astFactory.declaredIdentifier(
                  commentAndMetadata.comment,
                  commentAndMetadata.metadata,
                  keyword,
                  type,
                  astFactory.simpleIdentifier(variable.name.token,
                      isDeclaration: true));
            } else {
              if (commentAndMetadata.hasMetadata) {
                // TODO(jwren) metadata isn't allowed before the identifier in
                // "identifier in expression", add warning if commentAndMetadata
                // has content
              }
              identifier = variable.name;
            }
          }
          Token inKeyword = getAndAdvance();
          Expression iterator = parseExpression2();
          Token rightParenthesis = _expect(TokenType.CLOSE_PAREN);
          Statement body = parseStatement2();
          if (loopVariable == null) {
            return astFactory.forEachStatementWithReference(
                awaitKeyword,
                forKeyword,
                leftParenthesis,
                identifier,
                inKeyword,
                iterator,
                rightParenthesis,
                body);
          }
          return astFactory.forEachStatementWithDeclaration(
              awaitKeyword,
              forKeyword,
              leftParenthesis,
              loopVariable,
              inKeyword,
              iterator,
              rightParenthesis,
              body);
        }
      }
      if (awaitKeyword != null) {
        _reportErrorForToken(
            ParserErrorCode.INVALID_AWAIT_IN_FOR, awaitKeyword);
      }
      Token leftSeparator = _expect(TokenType.SEMICOLON);
      Expression condition = null;
      if (!_matches(TokenType.SEMICOLON)) {
        condition = parseExpression2();
      }
      Token rightSeparator = _expect(TokenType.SEMICOLON);
      List<Expression> updaters = null;
      if (!_matches(TokenType.CLOSE_PAREN)) {
        updaters = parseExpressionList();
      }
      Token rightParenthesis = _expect(TokenType.CLOSE_PAREN);
      Statement body = parseStatement2();
      return astFactory.forStatement(
          forKeyword,
          leftParenthesis,
          variableList,
          initialization,
          leftSeparator,
          condition,
          rightSeparator,
          updaters,
          rightParenthesis,
          body);
    } finally {
      _inLoop = wasInLoop;
    }
  }

  /**
   * Parse a function body. The [mayBeEmpty] is `true` if the function body is
   * allowed to be empty. The [emptyErrorCode] is the error code to report if
   * function body expected, but not found. The [inExpression] is `true` if the
   * function body is being parsed as part of an expression and therefore does
   * not have a terminating semicolon. Return the function body that was parsed.
   *
   *     functionBody ::=
   *         '=>' expression ';'
   *       | block
   *
   *     functionExpressionBody ::=
   *         '=>' expression
   *       | block
   */
  FunctionBody parseFunctionBody(
      bool mayBeEmpty, ParserErrorCode emptyErrorCode, bool inExpression) {
    bool wasInAsync = _inAsync;
    bool wasInGenerator = _inGenerator;
    bool wasInLoop = _inLoop;
    bool wasInSwitch = _inSwitch;
    _inAsync = false;
    _inGenerator = false;
    _inLoop = false;
    _inSwitch = false;
    try {
      TokenType type = _currentToken.type;
      if (type == TokenType.SEMICOLON) {
        if (!mayBeEmpty) {
          _reportErrorForCurrentToken(emptyErrorCode);
        }
        return astFactory.emptyFunctionBody(getAndAdvance());
      }
      Token keyword = null;
      Token star = null;
      bool foundAsync = false;
      bool foundSync = false;
      if (type.isKeyword) {
        String lexeme = _currentToken.lexeme;
        if (lexeme == ASYNC) {
          foundAsync = true;
          keyword = getAndAdvance();
          if (_matches(TokenType.STAR)) {
            star = getAndAdvance();
            _inGenerator = true;
          }
          type = _currentToken.type;
          _inAsync = true;
        } else if (lexeme == SYNC) {
          foundSync = true;
          keyword = getAndAdvance();
          if (_matches(TokenType.STAR)) {
            star = getAndAdvance();
            _inGenerator = true;
          }
          type = _currentToken.type;
        }
      }
      if (type == TokenType.FUNCTION) {
        if (keyword != null) {
          if (!foundAsync) {
            _reportErrorForToken(ParserErrorCode.INVALID_SYNC, keyword);
            keyword = null;
          } else if (star != null) {
            _reportErrorForToken(
                ParserErrorCode.INVALID_STAR_AFTER_ASYNC, star);
          }
        }
        Token functionDefinition = getAndAdvance();
        if (_matchesKeyword(Keyword.RETURN)) {
          _reportErrorForToken(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken,
              [_currentToken.lexeme]);
          _advance();
        }
        Expression expression = parseExpression2();
        Token semicolon = null;
        if (!inExpression) {
          semicolon = _expect(TokenType.SEMICOLON);
        }
        if (!_parseFunctionBodies) {
          return astFactory
              .emptyFunctionBody(_createSyntheticToken(TokenType.SEMICOLON));
        }
        return astFactory.expressionFunctionBody(
            keyword, functionDefinition, expression, semicolon);
      } else if (type == TokenType.OPEN_CURLY_BRACKET) {
        if (keyword != null) {
          if (foundSync && star == null) {
            _reportErrorForToken(
                ParserErrorCode.MISSING_STAR_AFTER_SYNC, keyword);
          }
        }
        if (!_parseFunctionBodies) {
          _skipBlock();
          return astFactory
              .emptyFunctionBody(_createSyntheticToken(TokenType.SEMICOLON));
        }
        return astFactory.blockFunctionBody(keyword, star, parseBlock());
      } else if (_matchesKeyword(Keyword.NATIVE)) {
        Token nativeToken = getAndAdvance();
        StringLiteral stringLiteral = null;
        if (_matches(TokenType.STRING)) {
          stringLiteral = _parseStringLiteralUnchecked();
        }
        return astFactory.nativeFunctionBody(
            nativeToken, stringLiteral, _expect(TokenType.SEMICOLON));
      } else {
        // Invalid function body
        _reportErrorForCurrentToken(emptyErrorCode);
        return astFactory
            .emptyFunctionBody(_createSyntheticToken(TokenType.SEMICOLON));
      }
    } finally {
      _inAsync = wasInAsync;
      _inGenerator = wasInGenerator;
      _inLoop = wasInLoop;
      _inSwitch = wasInSwitch;
    }
  }

  /**
   * Parse a function declaration. The [commentAndMetadata] is the documentation
   * comment and metadata to be associated with the declaration. The
   * [externalKeyword] is the 'external' keyword, or `null` if the function is
   * not external. The [returnType] is the return type, or `null` if there is no
   * return type. The [isStatement] is `true` if the function declaration is
   * being parsed as a statement. Return the function declaration that was
   * parsed.
   *
   *     functionDeclaration ::=
   *         functionSignature functionBody
   *       | returnType? getOrSet identifier formalParameterList functionBody
   */
  FunctionDeclaration parseFunctionDeclaration(
      CommentAndMetadata commentAndMetadata,
      Token externalKeyword,
      TypeAnnotation returnType) {
    Token keywordToken = null;
    bool isGetter = false;
    Keyword keyword = _currentToken.keyword;
    SimpleIdentifier name = null;
    if (keyword == Keyword.GET) {
      keywordToken = getAndAdvance();
      isGetter = true;
    } else if (keyword == Keyword.SET) {
      keywordToken = getAndAdvance();
    }
    if (keywordToken != null && _matches(TokenType.OPEN_PAREN)) {
      name = astFactory.simpleIdentifier(keywordToken, isDeclaration: true);
      keywordToken = null;
      isGetter = false;
    } else {
      name = parseSimpleIdentifier(isDeclaration: true);
    }
    TypeParameterList typeParameters = _parseGenericMethodTypeParameters();
    FormalParameterList parameters = null;
    if (!isGetter) {
      if (_matches(TokenType.OPEN_PAREN)) {
        parameters = _parseFormalParameterListUnchecked();
        _validateFormalParameterList(parameters);
      } else {
        _reportErrorForCurrentToken(
            ParserErrorCode.MISSING_FUNCTION_PARAMETERS);
        parameters = astFactory.formalParameterList(
            _createSyntheticToken(TokenType.OPEN_PAREN),
            null,
            null,
            null,
            _createSyntheticToken(TokenType.CLOSE_PAREN));
      }
    } else if (_matches(TokenType.OPEN_PAREN)) {
      _reportErrorForCurrentToken(ParserErrorCode.GETTER_WITH_PARAMETERS);
      _parseFormalParameterListUnchecked();
    }
    FunctionBody body;
    if (externalKeyword == null) {
      body = parseFunctionBody(
          false, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    } else {
      body = astFactory.emptyFunctionBody(_expect(TokenType.SEMICOLON));
    }
//        if (!isStatement && matches(TokenType.SEMICOLON)) {
//          // TODO(brianwilkerson) Improve this error message.
//          reportError(ParserErrorCode.UNEXPECTED_TOKEN, currentToken.getLexeme());
//          advance();
//        }
    return astFactory.functionDeclaration(
        commentAndMetadata.comment,
        commentAndMetadata.metadata,
        externalKeyword,
        returnType,
        keywordToken,
        name,
        astFactory.functionExpression(typeParameters, parameters, body));
  }

  /**
   * Parse a function declaration statement. Return the function declaration
   * statement that was parsed.
   *
   *     functionDeclarationStatement ::=
   *         functionSignature functionBody
   */
  Statement parseFunctionDeclarationStatement() {
    Modifiers modifiers = parseModifiers();
    _validateModifiersForFunctionDeclarationStatement(modifiers);
    return _parseFunctionDeclarationStatementAfterReturnType(
        parseCommentAndMetadata(), _parseOptionalReturnType());
  }

  /**
   * Parse a function expression. Return the function expression that was
   * parsed.
   *
   *     functionExpression ::=
   *         typeParameters? formalParameterList functionExpressionBody
   */
  FunctionExpression parseFunctionExpression() {
    TypeParameterList typeParameters = _parseGenericMethodTypeParameters();
    FormalParameterList parameters = parseFormalParameterList();
    _validateFormalParameterList(parameters);
    FunctionBody body =
        parseFunctionBody(false, ParserErrorCode.MISSING_FUNCTION_BODY, true);
    return astFactory.functionExpression(typeParameters, parameters, body);
  }

  /**
   * Parse the portion of a generic function type following the [returnType].
   *
   *     functionType ::=
   *         returnType? 'Function' typeParameters? parameterTypeList
   *     parameterTypeList ::=
   *         '(' ')' |
   *       | '(' normalParameterTypes ','? ')' |
   *       | '(' normalParameterTypes ',' optionalParameterTypes ')' |
   *       | '(' optionalParameterTypes ')'
   *     normalParameterTypes ::=
   *         normalParameterType (',' normalParameterType)*
   *     normalParameterType ::=
   *         type | typedIdentifier
   *     optionalParameterTypes ::=
   *         optionalPositionalParameterTypes | namedParameterTypes
   *     optionalPositionalParameterTypes ::=
   *         '[' normalParameterTypes ','? ']'
   *     namedParameterTypes ::=
   *         '{' typedIdentifier (',' typedIdentifier)* ','? '}'
   *     typedIdentifier ::=
   *         type identifier
   */
  GenericFunctionType parseGenericFunctionTypeAfterReturnType(
      TypeAnnotation returnType) {
    Token functionKeyword = null;
    if (_matchesKeyword(Keyword.FUNCTION)) {
      functionKeyword = getAndAdvance();
    } else if (_matchesIdentifier()) {
      _reportErrorForCurrentToken(ParserErrorCode.NAMED_FUNCTION_TYPE);
    } else {
      _reportErrorForCurrentToken(ParserErrorCode.MISSING_FUNCTION_KEYWORD);
    }
    TypeParameterList typeParameters = null;
    if (_matches(TokenType.LT)) {
      typeParameters = parseTypeParameterList();
    }
    FormalParameterList parameters =
        parseFormalParameterList(inFunctionType: true);
    return astFactory.genericFunctionType(
        returnType, functionKeyword, typeParameters, parameters);
  }

  /**
   * Parse a generic function type alias.
   *
   * This method assumes that the current token is an identifier.
   *
   *     genericTypeAlias ::=
   *         'typedef' identifier typeParameterList? '=' functionType ';'
   */
  GenericTypeAlias parseGenericTypeAlias(
      CommentAndMetadata commentAndMetadata, Token keyword) {
    Identifier name = _parseSimpleIdentifierUnchecked(isDeclaration: true);
    TypeParameterList typeParameters = null;
    if (_matches(TokenType.LT)) {
      typeParameters = parseTypeParameterList();
    }
    Token equals = _expect(TokenType.EQ);
    TypeAnnotation functionType = parseTypeAnnotation(false);
    Token semicolon = _expect(TokenType.SEMICOLON);
    if (functionType is! GenericFunctionType) {
      // TODO(brianwilkerson) Generate a better error.
      _reportErrorForToken(
          ParserErrorCode.INVALID_GENERIC_FUNCTION_TYPE, semicolon);
      // TODO(brianwilkerson) Recover better than this.
      return astFactory.genericTypeAlias(
          commentAndMetadata.comment,
          commentAndMetadata.metadata,
          keyword,
          name,
          typeParameters,
          equals,
          null,
          semicolon);
    }
    return astFactory.genericTypeAlias(
        commentAndMetadata.comment,
        commentAndMetadata.metadata,
        keyword,
        name,
        typeParameters,
        equals,
        functionType,
        semicolon);
  }

  /**
   * Parse a getter. The [commentAndMetadata] is the documentation comment and
   * metadata to be associated with the declaration. The externalKeyword] is the
   * 'external' token. The staticKeyword] is the static keyword, or `null` if
   * the getter is not static. The [returnType] the return type that has already
   * been parsed, or `null` if there was no return type. Return the getter that
   * was parsed.
   *
   * This method assumes that the current token matches `Keyword.GET`.
   *
   *     getter ::=
   *         getterSignature functionBody?
   *
   *     getterSignature ::=
   *         'external'? 'static'? returnType? 'get' identifier
   */
  MethodDeclaration parseGetter(CommentAndMetadata commentAndMetadata,
      Token externalKeyword, Token staticKeyword, TypeAnnotation returnType) {
    Token propertyKeyword = getAndAdvance();
    SimpleIdentifier name = parseSimpleIdentifier(isDeclaration: true);
    if (_matches(TokenType.OPEN_PAREN) &&
        _tokenMatches(_peek(), TokenType.CLOSE_PAREN)) {
      _reportErrorForCurrentToken(ParserErrorCode.GETTER_WITH_PARAMETERS);
      _advance();
      _advance();
    }
    FunctionBody body = parseFunctionBody(
        externalKeyword != null || staticKeyword == null,
        ParserErrorCode.STATIC_GETTER_WITHOUT_BODY,
        false);
    if (externalKeyword != null && body is! EmptyFunctionBody) {
      _reportErrorForCurrentToken(ParserErrorCode.EXTERNAL_GETTER_WITH_BODY);
    }
    return astFactory.methodDeclaration(
        commentAndMetadata.comment,
        commentAndMetadata.metadata,
        externalKeyword,
        staticKeyword,
        returnType,
        propertyKeyword,
        null,
        name,
        null,
        null,
        body);
  }

  /**
   * Parse a list of identifiers. Return the list of identifiers that were
   * parsed.
   *
   *     identifierList ::=
   *         identifier (',' identifier)*
   */
  List<SimpleIdentifier> parseIdentifierList() {
    List<SimpleIdentifier> identifiers = <SimpleIdentifier>[
      parseSimpleIdentifier()
    ];
    while (_optional(TokenType.COMMA)) {
      identifiers.add(parseSimpleIdentifier());
    }
    return identifiers;
  }

  /**
   * Parse an if-null expression.  Return the if-null expression that was
   * parsed.
   *
   *     ifNullExpression ::= logicalOrExpression ('??' logicalOrExpression)*
   */
  Expression parseIfNullExpression() {
    Expression expression = parseLogicalOrExpression();
    while (_currentToken.type == TokenType.QUESTION_QUESTION) {
      expression = astFactory.binaryExpression(
          expression, getAndAdvance(), parseLogicalOrExpression());
    }
    return expression;
  }

  /**
   * Parse an if statement. Return the if statement that was parsed.
   *
   * This method assumes that the current token matches `Keyword.IF`.
   *
   *     ifStatement ::=
   *         'if' '(' expression ')' statement ('else' statement)?
   */
  Statement parseIfStatement() {
    Token ifKeyword = getAndAdvance();
    Token leftParenthesis = _expect(TokenType.OPEN_PAREN);
    Expression condition = parseExpression2();
    Token rightParenthesis = _expect(TokenType.CLOSE_PAREN);
    Statement thenStatement = parseStatement2();
    Token elseKeyword = null;
    Statement elseStatement = null;
    if (_matchesKeyword(Keyword.ELSE)) {
      elseKeyword = getAndAdvance();
      elseStatement = parseStatement2();
    }
    return astFactory.ifStatement(ifKeyword, leftParenthesis, condition,
        rightParenthesis, thenStatement, elseKeyword, elseStatement);
  }

  /**
   * Parse an implements clause. Return the implements clause that was parsed.
   *
   * This method assumes that the current token matches `Keyword.IMPLEMENTS`.
   *
   *     implementsClause ::=
   *         'implements' type (',' type)*
   */
  ImplementsClause parseImplementsClause() {
    Token keyword = getAndAdvance();
    List<TypeName> interfaces = <TypeName>[];
    do {
      TypeName typeName = parseTypeName(false);
      _mustNotBeNullable(typeName, ParserErrorCode.NULLABLE_TYPE_IN_IMPLEMENTS);
      interfaces.add(typeName);
    } while (_optional(TokenType.COMMA));
    return astFactory.implementsClause(keyword, interfaces);
  }

  /**
   * Parse an import directive. The [commentAndMetadata] is the metadata to be
   * associated with the directive. Return the import directive that was parsed.
   *
   * This method assumes that the current token matches `Keyword.IMPORT`.
   *
   *     importDirective ::=
   *         metadata 'import' stringLiteral configuration* (deferred)? ('as' identifier)? combinator*';'
   */
  ImportDirective parseImportDirective(CommentAndMetadata commentAndMetadata) {
    Token importKeyword = getAndAdvance();
    StringLiteral libraryUri = _parseUri();
    List<Configuration> configurations = _parseConfigurations();
    Token deferredToken = null;
    Token asToken = null;
    SimpleIdentifier prefix = null;
    if (_matchesKeyword(Keyword.DEFERRED)) {
      deferredToken = getAndAdvance();
    }
    if (_matchesKeyword(Keyword.AS)) {
      asToken = getAndAdvance();
      prefix = parseSimpleIdentifier(isDeclaration: true);
    } else if (deferredToken != null) {
      _reportErrorForCurrentToken(
          ParserErrorCode.MISSING_PREFIX_IN_DEFERRED_IMPORT);
    } else if (!_matches(TokenType.SEMICOLON) &&
        !_matchesKeyword(Keyword.SHOW) &&
        !_matchesKeyword(Keyword.HIDE)) {
      Token nextToken = _peek();
      if (_tokenMatchesKeyword(nextToken, Keyword.AS) ||
          _tokenMatchesKeyword(nextToken, Keyword.SHOW) ||
          _tokenMatchesKeyword(nextToken, Keyword.HIDE)) {
        _reportErrorForCurrentToken(
            ParserErrorCode.UNEXPECTED_TOKEN, [_currentToken]);
        _advance();
        if (_matchesKeyword(Keyword.AS)) {
          asToken = getAndAdvance();
          prefix = parseSimpleIdentifier(isDeclaration: true);
        }
      }
    }
    List<Combinator> combinators = parseCombinators();
    Token semicolon = _expect(TokenType.SEMICOLON);
    return astFactory.importDirective(
        commentAndMetadata.comment,
        commentAndMetadata.metadata,
        importKeyword,
        libraryUri,
        configurations,
        deferredToken,
        asToken,
        prefix,
        combinators,
        semicolon);
  }

  /**
   * Parse a list of initialized identifiers. The [commentAndMetadata] is the
   * documentation comment and metadata to be associated with the declaration.
   * The [staticKeyword] is the static keyword, or `null` if the getter is not
   * static. The [keyword] is the token representing the 'final', 'const' or
   * 'var' keyword, or `null` if there is no keyword. The [type] is the type
   * that has already been parsed, or `null` if 'var' was provided. Return the
   * getter that was parsed.
   *
   *     declaration ::=
   *         ('static' | 'covariant')? ('var' | type) initializedIdentifierList ';'
   *       | 'final' type? initializedIdentifierList ';'
   *
   *     initializedIdentifierList ::=
   *         initializedIdentifier (',' initializedIdentifier)*
   *
   *     initializedIdentifier ::=
   *         identifier ('=' expression)?
   */
  FieldDeclaration parseInitializedIdentifierList(
      CommentAndMetadata commentAndMetadata,
      Token staticKeyword,
      Token covariantKeyword,
      Token keyword,
      TypeAnnotation type) {
    VariableDeclarationList fieldList =
        parseVariableDeclarationListAfterType(null, keyword, type);
    return astFactory.fieldDeclaration2(
        comment: commentAndMetadata.comment,
        metadata: commentAndMetadata.metadata,
        covariantKeyword: covariantKeyword,
        staticKeyword: staticKeyword,
        fieldList: fieldList,
        semicolon: _expect(TokenType.SEMICOLON));
  }

  /**
   * Parse an instance creation expression. The [keyword] is the 'new' or
   * 'const' keyword that introduces the expression. Return the instance
   * creation expression that was parsed.
   *
   *     instanceCreationExpression ::=
   *         ('new' | 'const') type ('.' identifier)? argumentList
   */
  InstanceCreationExpression parseInstanceCreationExpression(Token keyword) {
    ConstructorName constructorName = parseConstructorName();
    ArgumentList argumentList = _parseArgumentListChecked();
    return astFactory.instanceCreationExpression(
        keyword, constructorName, argumentList);
  }

  /**
   * Parse a label. Return the label that was parsed.
   *
   * This method assumes that the current token matches an identifier and that
   * the following token matches `TokenType.COLON`.
   *
   *     label ::=
   *         identifier ':'
   */
  Label parseLabel({bool isDeclaration: false}) {
    SimpleIdentifier label =
        _parseSimpleIdentifierUnchecked(isDeclaration: isDeclaration);
    Token colon = getAndAdvance();
    return astFactory.label(label, colon);
  }

  /**
   * Parse a library directive. The [commentAndMetadata] is the metadata to be
   * associated with the directive. Return the library directive that was
   * parsed.
   *
   * This method assumes that the current token matches `Keyword.LIBRARY`.
   *
   *     libraryDirective ::=
   *         metadata 'library' identifier ';'
   */
  LibraryDirective parseLibraryDirective(
      CommentAndMetadata commentAndMetadata) {
    Token keyword = getAndAdvance();
    LibraryIdentifier libraryName = _parseLibraryName(
        ParserErrorCode.MISSING_NAME_IN_LIBRARY_DIRECTIVE, keyword);
    Token semicolon = _expect(TokenType.SEMICOLON);
    return astFactory.libraryDirective(commentAndMetadata.comment,
        commentAndMetadata.metadata, keyword, libraryName, semicolon);
  }

  /**
   * Parse a library identifier. Return the library identifier that was parsed.
   *
   *     libraryIdentifier ::=
   *         identifier ('.' identifier)*
   */
  LibraryIdentifier parseLibraryIdentifier() {
    List<SimpleIdentifier> components = <SimpleIdentifier>[];
    components.add(parseSimpleIdentifier());
    while (_optional(TokenType.PERIOD)) {
      components.add(parseSimpleIdentifier());
    }
    return astFactory.libraryIdentifier(components);
  }

  /**
   * Parse a list literal. The [modifier] is the 'const' modifier appearing
   * before the literal, or `null` if there is no modifier. The [typeArguments]
   * is the type arguments appearing before the literal, or `null` if there are
   * no type arguments. Return the list literal that was parsed.
   *
   * This method assumes that the current token matches either
   * `TokenType.OPEN_SQUARE_BRACKET` or `TokenType.INDEX`.
   *
   *     listLiteral ::=
   *         'const'? typeArguments? '[' (expressionList ','?)? ']'
   */
  ListLiteral parseListLiteral(Token modifier, TypeArgumentList typeArguments) {
    if (_matches(TokenType.INDEX)) {
      _splitIndex();
      return astFactory.listLiteral(
          modifier, typeArguments, getAndAdvance(), null, getAndAdvance());
    }
    Token leftBracket = getAndAdvance();
    if (_matches(TokenType.CLOSE_SQUARE_BRACKET)) {
      return astFactory.listLiteral(
          modifier, typeArguments, leftBracket, null, getAndAdvance());
    }
    bool wasInInitializer = _inInitializer;
    _inInitializer = false;
    try {
      List<Expression> elements = <Expression>[parseExpression2()];
      while (_optional(TokenType.COMMA)) {
        if (_matches(TokenType.CLOSE_SQUARE_BRACKET)) {
          return astFactory.listLiteral(
              modifier, typeArguments, leftBracket, elements, getAndAdvance());
        }
        elements.add(parseExpression2());
      }
      Token rightBracket = _expect(TokenType.CLOSE_SQUARE_BRACKET);
      return astFactory.listLiteral(
          modifier, typeArguments, leftBracket, elements, rightBracket);
    } finally {
      _inInitializer = wasInInitializer;
    }
  }

  /**
   * Parse a list or map literal. The [modifier] is the 'const' modifier
   * appearing before the literal, or `null` if there is no modifier. Return the
   * list or map literal that was parsed.
   *
   *     listOrMapLiteral ::=
   *         listLiteral
   *       | mapLiteral
   */
  TypedLiteral parseListOrMapLiteral(Token modifier) {
    TypeArgumentList typeArguments = _parseOptionalTypeArguments();
    if (_matches(TokenType.OPEN_CURLY_BRACKET)) {
      return parseMapLiteral(modifier, typeArguments);
    } else if (_matches(TokenType.OPEN_SQUARE_BRACKET) ||
        _matches(TokenType.INDEX)) {
      return parseListLiteral(modifier, typeArguments);
    }
    _reportErrorForCurrentToken(ParserErrorCode.EXPECTED_LIST_OR_MAP_LITERAL);
    return astFactory.listLiteral(
        modifier,
        typeArguments,
        _createSyntheticToken(TokenType.OPEN_SQUARE_BRACKET),
        null,
        _createSyntheticToken(TokenType.CLOSE_SQUARE_BRACKET));
  }

  /**
   * Parse a logical and expression. Return the logical and expression that was
   * parsed.
   *
   *     logicalAndExpression ::=
   *         equalityExpression ('&&' equalityExpression)*
   */
  Expression parseLogicalAndExpression() {
    Expression expression = parseEqualityExpression();
    while (_currentToken.type == TokenType.AMPERSAND_AMPERSAND) {
      expression = astFactory.binaryExpression(
          expression, getAndAdvance(), parseEqualityExpression());
    }
    return expression;
  }

  /**
   * Parse a logical or expression. Return the logical or expression that was
   * parsed.
   *
   *     logicalOrExpression ::=
   *         logicalAndExpression ('||' logicalAndExpression)*
   */
  Expression parseLogicalOrExpression() {
    Expression expression = parseLogicalAndExpression();
    while (_currentToken.type == TokenType.BAR_BAR) {
      expression = astFactory.binaryExpression(
          expression, getAndAdvance(), parseLogicalAndExpression());
    }
    return expression;
  }

  /**
   * Parse a map literal. The [modifier] is the 'const' modifier appearing
   * before the literal, or `null` if there is no modifier. The [typeArguments]
   * is the type arguments that were declared, or `null` if there are no type
   * arguments. Return the map literal that was parsed.
   *
   * This method assumes that the current token matches
   * `TokenType.OPEN_CURLY_BRACKET`.
   *
   *     mapLiteral ::=
   *         'const'? typeArguments? '{' (mapLiteralEntry (',' mapLiteralEntry)* ','?)? '}'
   */
  MapLiteral parseMapLiteral(Token modifier, TypeArgumentList typeArguments) {
    Token leftBracket = getAndAdvance();
    if (_matches(TokenType.CLOSE_CURLY_BRACKET)) {
      return astFactory.mapLiteral(
          modifier, typeArguments, leftBracket, null, getAndAdvance());
    }
    bool wasInInitializer = _inInitializer;
    _inInitializer = false;
    try {
      List<MapLiteralEntry> entries = <MapLiteralEntry>[parseMapLiteralEntry()];
      while (_optional(TokenType.COMMA)) {
        if (_matches(TokenType.CLOSE_CURLY_BRACKET)) {
          return astFactory.mapLiteral(
              modifier, typeArguments, leftBracket, entries, getAndAdvance());
        }
        entries.add(parseMapLiteralEntry());
      }
      Token rightBracket = _expect(TokenType.CLOSE_CURLY_BRACKET);
      return astFactory.mapLiteral(
          modifier, typeArguments, leftBracket, entries, rightBracket);
    } finally {
      _inInitializer = wasInInitializer;
    }
  }

  /**
   * Parse a map literal entry. Return the map literal entry that was parsed.
   *
   *     mapLiteralEntry ::=
   *         expression ':' expression
   */
  MapLiteralEntry parseMapLiteralEntry() {
    Expression key = parseExpression2();
    Token separator = _expect(TokenType.COLON);
    Expression value = parseExpression2();
    return astFactory.mapLiteralEntry(key, separator, value);
  }

  /**
   * Parse the modifiers preceding a declaration. This method allows the
   * modifiers to appear in any order but does generate errors for duplicated
   * modifiers. Checks for other problems, such as having the modifiers appear
   * in the wrong order or specifying both 'const' and 'final', are reported in
   * one of the methods whose name is prefixed with `validateModifiersFor`.
   * Return the modifiers that were parsed.
   *
   *     modifiers ::=
   *         ('abstract' | 'const' | 'external' | 'factory' | 'final' | 'static' | 'var')*
   */
  Modifiers parseModifiers() {
    Modifiers modifiers = new Modifiers();
    bool progress = true;
    while (progress) {
      TokenType nextType = _peek().type;
      if (nextType == TokenType.PERIOD ||
          nextType == TokenType.LT ||
          nextType == TokenType.OPEN_PAREN) {
        return modifiers;
      }
      Keyword keyword = _currentToken.keyword;
      if (keyword == Keyword.ABSTRACT) {
        if (modifiers.abstractKeyword != null) {
          _reportErrorForCurrentToken(
              ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          _advance();
        } else {
          modifiers.abstractKeyword = getAndAdvance();
        }
      } else if (keyword == Keyword.CONST) {
        if (modifiers.constKeyword != null) {
          _reportErrorForCurrentToken(
              ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          _advance();
        } else {
          modifiers.constKeyword = getAndAdvance();
        }
      } else if (keyword == Keyword.COVARIANT) {
        if (modifiers.covariantKeyword != null) {
          _reportErrorForCurrentToken(
              ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          _advance();
        } else {
          modifiers.covariantKeyword = getAndAdvance();
        }
      } else if (keyword == Keyword.EXTERNAL) {
        if (modifiers.externalKeyword != null) {
          _reportErrorForCurrentToken(
              ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          _advance();
        } else {
          modifiers.externalKeyword = getAndAdvance();
        }
      } else if (keyword == Keyword.FACTORY) {
        if (modifiers.factoryKeyword != null) {
          _reportErrorForCurrentToken(
              ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          _advance();
        } else {
          modifiers.factoryKeyword = getAndAdvance();
        }
      } else if (keyword == Keyword.FINAL) {
        if (modifiers.finalKeyword != null) {
          _reportErrorForCurrentToken(
              ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          _advance();
        } else {
          modifiers.finalKeyword = getAndAdvance();
        }
      } else if (keyword == Keyword.STATIC) {
        if (modifiers.staticKeyword != null) {
          _reportErrorForCurrentToken(
              ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          _advance();
        } else {
          modifiers.staticKeyword = getAndAdvance();
        }
      } else if (keyword == Keyword.VAR) {
        if (modifiers.varKeyword != null) {
          _reportErrorForCurrentToken(
              ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          _advance();
        } else {
          modifiers.varKeyword = getAndAdvance();
        }
      } else {
        progress = false;
      }
    }
    return modifiers;
  }

  /**
   * Parse a multiplicative expression. Return the multiplicative expression
   * that was parsed.
   *
   *     multiplicativeExpression ::=
   *         unaryExpression (multiplicativeOperator unaryExpression)*
   *       | 'super' (multiplicativeOperator unaryExpression)+
   */
  Expression parseMultiplicativeExpression() {
    Expression expression;
    if (_currentToken.keyword == Keyword.SUPER &&
        _currentToken.next.type.isMultiplicativeOperator) {
      expression = astFactory.superExpression(getAndAdvance());
    } else {
      expression = parseUnaryExpression();
    }
    while (_currentToken.type.isMultiplicativeOperator) {
      expression = astFactory.binaryExpression(
          expression, getAndAdvance(), parseUnaryExpression());
    }
    return expression;
  }

  /**
   * Parse a new expression. Return the new expression that was parsed.
   *
   * This method assumes that the current token matches `Keyword.NEW`.
   *
   *     newExpression ::=
   *         instanceCreationExpression
   */
  InstanceCreationExpression parseNewExpression() =>
      parseInstanceCreationExpression(getAndAdvance());

  /**
   * Parse a non-labeled statement. Return the non-labeled statement that was
   * parsed.
   *
   *     nonLabeledStatement ::=
   *         block
   *       | assertStatement
   *       | breakStatement
   *       | continueStatement
   *       | doStatement
   *       | forStatement
   *       | ifStatement
   *       | returnStatement
   *       | switchStatement
   *       | tryStatement
   *       | whileStatement
   *       | variableDeclarationList ';'
   *       | expressionStatement
   *       | functionSignature functionBody
   */
  Statement parseNonLabeledStatement() {
    // TODO(brianwilkerson) Pass the comment and metadata on where appropriate.
    CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
    TokenType type = _currentToken.type;
    if (type == TokenType.OPEN_CURLY_BRACKET) {
      if (_tokenMatches(_peek(), TokenType.STRING)) {
        Token afterString = skipStringLiteral(_currentToken.next);
        if (afterString != null && afterString.type == TokenType.COLON) {
          return astFactory.expressionStatement(
              parseExpression2(), _expect(TokenType.SEMICOLON));
        }
      }
      return parseBlock();
    } else if (type.isKeyword && !_currentToken.keyword.isBuiltInOrPseudo) {
      Keyword keyword = _currentToken.keyword;
      // TODO(jwren) compute some metrics to figure out a better order for this
      // if-then sequence to optimize performance
      if (keyword == Keyword.ASSERT) {
        return parseAssertStatement();
      } else if (keyword == Keyword.BREAK) {
        return parseBreakStatement();
      } else if (keyword == Keyword.CONTINUE) {
        return parseContinueStatement();
      } else if (keyword == Keyword.DO) {
        return parseDoStatement();
      } else if (keyword == Keyword.FOR) {
        return parseForStatement();
      } else if (keyword == Keyword.IF) {
        return parseIfStatement();
      } else if (keyword == Keyword.RETHROW) {
        return astFactory.expressionStatement(
            parseRethrowExpression(), _expect(TokenType.SEMICOLON));
      } else if (keyword == Keyword.RETURN) {
        return parseReturnStatement();
      } else if (keyword == Keyword.SWITCH) {
        return parseSwitchStatement();
      } else if (keyword == Keyword.THROW) {
        return astFactory.expressionStatement(
            parseThrowExpression(), _expect(TokenType.SEMICOLON));
      } else if (keyword == Keyword.TRY) {
        return parseTryStatement();
      } else if (keyword == Keyword.WHILE) {
        return parseWhileStatement();
      } else if (keyword == Keyword.VAR || keyword == Keyword.FINAL) {
        return parseVariableDeclarationStatementAfterMetadata(
            commentAndMetadata);
      } else if (keyword == Keyword.VOID) {
        TypeAnnotation returnType;
        if (_atGenericFunctionTypeAfterReturnType(_peek())) {
          returnType = parseTypeAnnotation(false);
        } else {
          returnType = astFactory.typeName(
              astFactory.simpleIdentifier(getAndAdvance()), null);
        }
        Token next = _currentToken.next;
        if (_matchesIdentifier() &&
            next.matchesAny(const <TokenType>[
              TokenType.OPEN_PAREN,
              TokenType.OPEN_CURLY_BRACKET,
              TokenType.FUNCTION,
              TokenType.LT
            ])) {
          return _parseFunctionDeclarationStatementAfterReturnType(
              commentAndMetadata, returnType);
        } else if (_matchesIdentifier() &&
            next.matchesAny(const <TokenType>[
              TokenType.EQ,
              TokenType.COMMA,
              TokenType.SEMICOLON
            ])) {
          return _parseVariableDeclarationStatementAfterType(
              commentAndMetadata, null, returnType);
        } else {
          //
          // We have found an error of some kind. Try to recover.
          //
          if (_matches(TokenType.CLOSE_CURLY_BRACKET)) {
            //
            // We appear to have found an incomplete statement at the end of a
            // block. Parse it as a variable declaration.
            //
            return _parseVariableDeclarationStatementAfterType(
                commentAndMetadata, null, returnType);
          }
          _reportErrorForCurrentToken(ParserErrorCode.MISSING_STATEMENT);
          // TODO(brianwilkerson) Recover from this error.
          return astFactory
              .emptyStatement(_createSyntheticToken(TokenType.SEMICOLON));
        }
      } else if (keyword == Keyword.CONST) {
        Token next = _currentToken.next;
        if (next.matchesAny(const <TokenType>[
          TokenType.LT,
          TokenType.OPEN_CURLY_BRACKET,
          TokenType.OPEN_SQUARE_BRACKET,
          TokenType.INDEX
        ])) {
          return astFactory.expressionStatement(
              parseExpression2(), _expect(TokenType.SEMICOLON));
        } else if (_tokenMatches(next, TokenType.IDENTIFIER)) {
          Token afterType = skipTypeName(next);
          if (afterType != null) {
            if (_tokenMatches(afterType, TokenType.OPEN_PAREN) ||
                (_tokenMatches(afterType, TokenType.PERIOD) &&
                    _tokenMatches(afterType.next, TokenType.IDENTIFIER) &&
                    _tokenMatches(afterType.next.next, TokenType.OPEN_PAREN))) {
              return astFactory.expressionStatement(
                  parseExpression2(), _expect(TokenType.SEMICOLON));
            }
          }
        }
        return parseVariableDeclarationStatementAfterMetadata(
            commentAndMetadata);
      } else if (keyword == Keyword.NEW ||
          keyword == Keyword.TRUE ||
          keyword == Keyword.FALSE ||
          keyword == Keyword.NULL ||
          keyword == Keyword.SUPER ||
          keyword == Keyword.THIS) {
        return astFactory.expressionStatement(
            parseExpression2(), _expect(TokenType.SEMICOLON));
      } else {
        //
        // We have found an error of some kind. Try to recover.
        //
        _reportErrorForCurrentToken(ParserErrorCode.MISSING_STATEMENT);
        return astFactory
            .emptyStatement(_createSyntheticToken(TokenType.SEMICOLON));
      }
    } else if (_atGenericFunctionTypeAfterReturnType(_currentToken)) {
      TypeAnnotation returnType = parseTypeAnnotation(false);
      Token next = _currentToken.next;
      if (_matchesIdentifier() &&
          next.matchesAny(const <TokenType>[
            TokenType.OPEN_PAREN,
            TokenType.OPEN_CURLY_BRACKET,
            TokenType.FUNCTION,
            TokenType.LT
          ])) {
        return _parseFunctionDeclarationStatementAfterReturnType(
            commentAndMetadata, returnType);
      } else if (_matchesIdentifier() &&
          next.matchesAny(const <TokenType>[
            TokenType.EQ,
            TokenType.COMMA,
            TokenType.SEMICOLON
          ])) {
        return _parseVariableDeclarationStatementAfterType(
            commentAndMetadata, null, returnType);
      } else {
        //
        // We have found an error of some kind. Try to recover.
        //
        if (_matches(TokenType.CLOSE_CURLY_BRACKET)) {
          //
          // We appear to have found an incomplete statement at the end of a
          // block. Parse it as a variable declaration.
          //
          return _parseVariableDeclarationStatementAfterType(
              commentAndMetadata, null, returnType);
        }
        _reportErrorForCurrentToken(ParserErrorCode.MISSING_STATEMENT);
        // TODO(brianwilkerson) Recover from this error.
        return astFactory
            .emptyStatement(_createSyntheticToken(TokenType.SEMICOLON));
      }
    } else if (_inGenerator && _matchesKeyword(Keyword.YIELD)) {
      return parseYieldStatement();
    } else if (_inAsync && _matchesKeyword(Keyword.AWAIT)) {
      if (_tokenMatchesKeyword(_peek(), Keyword.FOR)) {
        return parseForStatement();
      }
      return astFactory.expressionStatement(
          parseExpression2(), _expect(TokenType.SEMICOLON));
    } else if (_matchesKeyword(Keyword.AWAIT) &&
        _tokenMatchesKeyword(_peek(), Keyword.FOR)) {
      Token awaitToken = _currentToken;
      Statement statement = parseForStatement();
      if (statement is! ForStatement) {
        _reportErrorForToken(
            CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT, awaitToken);
      }
      return statement;
    } else if (type == TokenType.SEMICOLON) {
      return parseEmptyStatement();
    } else if (isInitializedVariableDeclaration()) {
      return parseVariableDeclarationStatementAfterMetadata(commentAndMetadata);
    } else if (isFunctionDeclaration()) {
      return parseFunctionDeclarationStatement();
    } else if (type == TokenType.CLOSE_CURLY_BRACKET) {
      _reportErrorForCurrentToken(ParserErrorCode.MISSING_STATEMENT);
      return astFactory
          .emptyStatement(_createSyntheticToken(TokenType.SEMICOLON));
    } else {
      return astFactory.expressionStatement(
          parseExpression2(), _expect(TokenType.SEMICOLON));
    }
  }

  /**
   * Parse a normal formal parameter. Return the normal formal parameter that
   * was parsed.
   *
   *     normalFormalParameter ::=
   *         functionSignature
   *       | fieldFormalParameter
   *       | simpleFormalParameter
   *
   *     functionSignature:
   *         metadata returnType? identifier typeParameters? formalParameterList
   *
   *     fieldFormalParameter ::=
   *         metadata finalConstVarOrType? 'this' '.' identifier
   *
   *     simpleFormalParameter ::=
   *         declaredIdentifier
   *       | metadata identifier
   */
  NormalFormalParameter parseNormalFormalParameter(
      {bool inFunctionType: false}) {
    Token covariantKeyword;
    CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
    if (_matchesKeyword(Keyword.COVARIANT)) {
      // Check to ensure that 'covariant' isn't being used as the parameter name.
      Token next = _peek();
      if (_tokenMatchesKeyword(next, Keyword.FINAL) ||
          _tokenMatchesKeyword(next, Keyword.CONST) ||
          _tokenMatchesKeyword(next, Keyword.VAR) ||
          _tokenMatchesKeyword(next, Keyword.THIS) ||
          _tokenMatchesKeyword(next, Keyword.VOID) ||
          _tokenMatchesIdentifier(next)) {
        covariantKeyword = getAndAdvance();
      }
    }
    FinalConstVarOrType holder = parseFinalConstVarOrType(!inFunctionType,
        inFunctionType: inFunctionType);
    Token thisKeyword = null;
    Token period = null;
    if (_matchesKeyword(Keyword.THIS)) {
      thisKeyword = getAndAdvance();
      period = _expect(TokenType.PERIOD);
    }
    if (!_matchesIdentifier() && inFunctionType) {
      return astFactory.simpleFormalParameter2(
          comment: commentAndMetadata.comment,
          metadata: commentAndMetadata.metadata,
          covariantKeyword: covariantKeyword,
          keyword: holder.keyword,
          type: holder.type,
          identifier: null);
    }
    SimpleIdentifier identifier = parseSimpleIdentifier();
    TypeParameterList typeParameters = _parseGenericMethodTypeParameters();
    if (_matches(TokenType.OPEN_PAREN)) {
      FormalParameterList parameters = _parseFormalParameterListUnchecked();
      if (thisKeyword == null) {
        if (holder.keyword != null) {
          _reportErrorForToken(
              ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR, holder.keyword);
        }
        Token question = null;
        if (enableNnbd && _matches(TokenType.QUESTION)) {
          question = getAndAdvance();
        }
        return astFactory.functionTypedFormalParameter2(
            comment: commentAndMetadata.comment,
            metadata: commentAndMetadata.metadata,
            covariantKeyword: covariantKeyword,
            returnType: holder.type,
            identifier: astFactory.simpleIdentifier(identifier.token,
                isDeclaration: true),
            typeParameters: typeParameters,
            parameters: parameters,
            question: question);
      } else {
        return astFactory.fieldFormalParameter2(
            comment: commentAndMetadata.comment,
            metadata: commentAndMetadata.metadata,
            covariantKeyword: covariantKeyword,
            keyword: holder.keyword,
            type: holder.type,
            thisKeyword: thisKeyword,
            period: period,
            identifier: identifier,
            typeParameters: typeParameters,
            parameters: parameters);
      }
    } else if (typeParameters != null) {
      // TODO(brianwilkerson) Report an error. It looks like a function-typed
      // parameter with no parameter list.
      //_reportErrorForToken(ParserErrorCode.MISSING_PARAMETERS, typeParameters.endToken);
    }
    TypeAnnotation type = holder.type;
    if (type != null &&
        holder.keyword != null &&
        _tokenMatchesKeyword(holder.keyword, Keyword.VAR)) {
      _reportErrorForToken(ParserErrorCode.VAR_AND_TYPE, holder.keyword);
    }
    if (thisKeyword != null) {
      // TODO(brianwilkerson) If there are type parameters but no parameters,
      // should we create a synthetic empty parameter list here so we can
      // capture the type parameters?
      return astFactory.fieldFormalParameter2(
          comment: commentAndMetadata.comment,
          metadata: commentAndMetadata.metadata,
          covariantKeyword: covariantKeyword,
          keyword: holder.keyword,
          type: type,
          thisKeyword: thisKeyword,
          period: period,
          identifier: identifier);
    }
    return astFactory.simpleFormalParameter2(
        comment: commentAndMetadata.comment,
        metadata: commentAndMetadata.metadata,
        covariantKeyword: covariantKeyword,
        keyword: holder.keyword,
        type: type,
        identifier:
            astFactory.simpleIdentifier(identifier.token, isDeclaration: true));
  }

  /**
   * Parse an operator declaration. The [commentAndMetadata] is the
   * documentation comment and metadata to be associated with the declaration.
   * The [externalKeyword] is the 'external' token. The [returnType] is the
   * return type that has already been parsed, or `null` if there was no return
   * type. Return the operator declaration that was parsed.
   *
   *     operatorDeclaration ::=
   *         operatorSignature (';' | functionBody)
   *
   *     operatorSignature ::=
   *         'external'? returnType? 'operator' operator formalParameterList
   */
  MethodDeclaration parseOperator(CommentAndMetadata commentAndMetadata,
      Token externalKeyword, TypeName returnType) {
    Token operatorKeyword;
    if (_matchesKeyword(Keyword.OPERATOR)) {
      operatorKeyword = getAndAdvance();
    } else {
      _reportErrorForToken(
          ParserErrorCode.MISSING_KEYWORD_OPERATOR, _currentToken);
      operatorKeyword = _createSyntheticKeyword(Keyword.OPERATOR);
    }
    return _parseOperatorAfterKeyword(
        commentAndMetadata, externalKeyword, returnType, operatorKeyword);
  }

  /**
   * Parse a part or part-of directive. The [commentAndMetadata] is the metadata
   * to be associated with the directive. Return the part or part-of directive
   * that was parsed.
   *
   * This method assumes that the current token matches `Keyword.PART`.
   *
   *     partDirective ::=
   *         metadata 'part' stringLiteral ';'
   *
   *     partOfDirective ::=
   *         metadata 'part' 'of' identifier ';'
   */
  Directive parsePartOrPartOfDirective(CommentAndMetadata commentAndMetadata) {
    if (_tokenMatchesKeyword(_peek(), Keyword.OF)) {
      return _parsePartOfDirective(commentAndMetadata);
    }
    return _parsePartDirective(commentAndMetadata);
  }

  /**
   * Parse a postfix expression. Return the postfix expression that was parsed.
   *
   *     postfixExpression ::=
   *         assignableExpression postfixOperator
   *       | primary selector*
   *
   *     selector ::=
   *         assignableSelector
   *       | argumentPart
   */
  Expression parsePostfixExpression() {
    Expression operand = parseAssignableExpression(true);
    TokenType type = _currentToken.type;
    if (type == TokenType.OPEN_SQUARE_BRACKET ||
        type == TokenType.PERIOD ||
        type == TokenType.QUESTION_PERIOD ||
        type == TokenType.OPEN_PAREN ||
        type == TokenType.LT ||
        type == TokenType.INDEX) {
      do {
        if (_isLikelyArgumentList()) {
          TypeArgumentList typeArguments = _parseOptionalTypeArguments();
          ArgumentList argumentList = parseArgumentList();
          Expression currentOperand = operand;
          if (currentOperand is PropertyAccess) {
            operand = astFactory.methodInvocation(
                currentOperand.target,
                currentOperand.operator,
                currentOperand.propertyName,
                typeArguments,
                argumentList);
          } else {
            operand = astFactory.functionExpressionInvocation(
                operand, typeArguments, argumentList);
          }
        } else if (enableOptionalNewAndConst &&
            operand is Identifier &&
            _isLikelyNamedInstanceCreation()) {
          TypeArgumentList typeArguments = _parseOptionalTypeArguments();
          Token period = _expect(TokenType.PERIOD);
          SimpleIdentifier name = parseSimpleIdentifier();
          ArgumentList argumentList = parseArgumentList();
          TypeName typeName = astFactory.typeName(operand, typeArguments);
          operand = astFactory.instanceCreationExpression(null,
              astFactory.constructorName(typeName, period, name), argumentList);
        } else {
          operand = parseAssignableSelector(operand, true);
        }
        type = _currentToken.type;
      } while (type == TokenType.OPEN_SQUARE_BRACKET ||
          type == TokenType.PERIOD ||
          type == TokenType.QUESTION_PERIOD ||
          type == TokenType.OPEN_PAREN ||
          type == TokenType.INDEX);
      return operand;
    }
    if (!_currentToken.type.isIncrementOperator) {
      return operand;
    }
    _ensureAssignable(operand);
    Token operator = getAndAdvance();
    return astFactory.postfixExpression(operand, operator);
  }

  /**
   * Parse a prefixed identifier. Return the prefixed identifier that was
   * parsed.
   *
   *     prefixedIdentifier ::=
   *         identifier ('.' identifier)?
   */
  Identifier parsePrefixedIdentifier() {
    return _parsePrefixedIdentifierAfterIdentifier(parseSimpleIdentifier());
  }

  /**
   * Parse a primary expression. Return the primary expression that was parsed.
   *
   *     primary ::=
   *         thisExpression
   *       | 'super' unconditionalAssignableSelector
   *       | functionExpression
   *       | literal
   *       | identifier
   *       | newExpression
   *       | constObjectExpression
   *       | '(' expression ')'
   *       | argumentDefinitionTest
   *
   *     literal ::=
   *         nullLiteral
   *       | booleanLiteral
   *       | numericLiteral
   *       | stringLiteral
   *       | symbolLiteral
   *       | mapLiteral
   *       | listLiteral
   */
  Expression parsePrimaryExpression() {
    if (_matchesIdentifier()) {
      // TODO(brianwilkerson) The code below was an attempt to recover from an
      // error case, but it needs to be applied as a recovery only after we
      // know that parsing it as an identifier doesn't work. Leaving the code as
      // a reminder of how to recover.
//      if (isFunctionExpression(_peek())) {
//        //
//        // Function expressions were allowed to have names at one point, but this is now illegal.
//        //
//        reportError(ParserErrorCode.NAMED_FUNCTION_EXPRESSION, getAndAdvance());
//        return parseFunctionExpression();
//      }
      return _parsePrefixedIdentifierUnchecked();
    }
    TokenType type = _currentToken.type;
    if (type == TokenType.STRING) {
      return parseStringLiteral();
    } else if (type == TokenType.INT) {
      Token token = getAndAdvance();
      int value = null;
      try {
        value = int.parse(token.lexeme);
      } on FormatException {
        // The invalid format should have been reported by the scanner.
      }
      return astFactory.integerLiteral(token, value);
    }
    Keyword keyword = _currentToken.keyword;
    if (keyword == Keyword.NULL) {
      return astFactory.nullLiteral(getAndAdvance());
    } else if (keyword == Keyword.NEW) {
      return parseNewExpression();
    } else if (keyword == Keyword.THIS) {
      return astFactory.thisExpression(getAndAdvance());
    } else if (keyword == Keyword.SUPER) {
      return parseAssignableSelector(
          astFactory.superExpression(getAndAdvance()), false,
          allowConditional: false);
    } else if (keyword == Keyword.FALSE) {
      return astFactory.booleanLiteral(getAndAdvance(), false);
    } else if (keyword == Keyword.TRUE) {
      return astFactory.booleanLiteral(getAndAdvance(), true);
    }
    if (type == TokenType.DOUBLE) {
      Token token = getAndAdvance();
      double value = 0.0;
      try {
        value = double.parse(token.lexeme);
      } on FormatException {
        // The invalid format should have been reported by the scanner.
      }
      return astFactory.doubleLiteral(token, value);
    } else if (type == TokenType.HEXADECIMAL) {
      Token token = getAndAdvance();
      int value = null;
      try {
        value = int.parse(token.lexeme.substring(2), radix: 16);
      } on FormatException {
        // The invalid format should have been reported by the scanner.
      }
      return astFactory.integerLiteral(token, value);
    } else if (keyword == Keyword.CONST) {
      return parseConstExpression();
    } else if (type == TokenType.OPEN_PAREN) {
      if (isFunctionExpression(_currentToken)) {
        return parseFunctionExpression();
      }
      Token leftParenthesis = getAndAdvance();
      bool wasInInitializer = _inInitializer;
      _inInitializer = false;
      try {
        Expression expression = parseExpression2();
        Token rightParenthesis = _expect(TokenType.CLOSE_PAREN);
        return astFactory.parenthesizedExpression(
            leftParenthesis, expression, rightParenthesis);
      } finally {
        _inInitializer = wasInInitializer;
      }
    } else if (type == TokenType.LT || _injectGenericCommentTypeList()) {
      if (isFunctionExpression(currentToken)) {
        return parseFunctionExpression();
      }
      return parseListOrMapLiteral(null);
    } else if (type == TokenType.OPEN_CURLY_BRACKET) {
      return parseMapLiteral(null, null);
    } else if (type == TokenType.OPEN_SQUARE_BRACKET ||
        type == TokenType.INDEX) {
      return parseListLiteral(null, null);
    } else if (type == TokenType.QUESTION &&
        _tokenMatches(_peek(), TokenType.IDENTIFIER)) {
      _reportErrorForCurrentToken(
          ParserErrorCode.UNEXPECTED_TOKEN, [_currentToken.lexeme]);
      _advance();
      return parsePrimaryExpression();
    } else if (keyword == Keyword.VOID) {
      //
      // Recover from having a return type of "void" where a return type is not
      // expected.
      //
      // TODO(brianwilkerson) Improve this error message.
      _reportErrorForCurrentToken(
          ParserErrorCode.UNEXPECTED_TOKEN, [_currentToken.lexeme]);
      _advance();
      return parsePrimaryExpression();
    } else if (type == TokenType.HASH) {
      return parseSymbolLiteral();
    } else {
      _reportErrorForCurrentToken(ParserErrorCode.MISSING_IDENTIFIER);
      return createSyntheticIdentifier();
    }
  }

  /**
   * Parse a redirecting constructor invocation. The flag [hasPeriod] should be
   * `true` if the `this` is followed by a period. Return the redirecting
   * constructor invocation that was parsed.
   *
   * This method assumes that the current token matches `Keyword.THIS`.
   *
   *     redirectingConstructorInvocation ::=
   *         'this' ('.' identifier)? arguments
   */
  RedirectingConstructorInvocation parseRedirectingConstructorInvocation(
      bool hasPeriod) {
    Token keyword = getAndAdvance();
    Token period = null;
    SimpleIdentifier constructorName = null;
    if (hasPeriod) {
      period = getAndAdvance();
      if (_matchesIdentifier()) {
        constructorName = _parseSimpleIdentifierUnchecked(isDeclaration: false);
      } else {
        _reportErrorForCurrentToken(ParserErrorCode.MISSING_IDENTIFIER);
        constructorName = createSyntheticIdentifier(isDeclaration: false);
        _advance();
      }
    }
    ArgumentList argumentList = _parseArgumentListChecked();
    return astFactory.redirectingConstructorInvocation(
        keyword, period, constructorName, argumentList);
  }

  /**
   * Parse a relational expression. Return the relational expression that was
   * parsed.
   *
   *     relationalExpression ::=
   *         bitwiseOrExpression ('is' '!'? type | 'as' type | relationalOperator bitwiseOrExpression)?
   *       | 'super' relationalOperator bitwiseOrExpression
   */
  Expression parseRelationalExpression() {
    if (_currentToken.keyword == Keyword.SUPER &&
        _currentToken.next.type.isRelationalOperator) {
      Expression expression = astFactory.superExpression(getAndAdvance());
      Token operator = getAndAdvance();
      return astFactory.binaryExpression(
          expression, operator, parseBitwiseOrExpression());
    }
    Expression expression = parseBitwiseOrExpression();
    Keyword keyword = _currentToken.keyword;
    if (keyword == Keyword.AS) {
      Token asOperator = getAndAdvance();
      return astFactory.asExpression(
          expression, asOperator, parseTypeNotVoid(true));
    } else if (keyword == Keyword.IS) {
      Token isOperator = getAndAdvance();
      Token notOperator = null;
      if (_matches(TokenType.BANG)) {
        notOperator = getAndAdvance();
      }
      TypeAnnotation type = parseTypeNotVoid(true);
      return astFactory.isExpression(expression, isOperator, notOperator, type);
    } else if (_currentToken.type.isRelationalOperator) {
      Token operator = getAndAdvance();
      return astFactory.binaryExpression(
          expression, operator, parseBitwiseOrExpression());
    }
    return expression;
  }

  /**
   * Parse a rethrow expression. Return the rethrow expression that was parsed.
   *
   * This method assumes that the current token matches `Keyword.RETHROW`.
   *
   *     rethrowExpression ::=
   *         'rethrow'
   */
  Expression parseRethrowExpression() =>
      astFactory.rethrowExpression(getAndAdvance());

  /**
   * Parse a return statement. Return the return statement that was parsed.
   *
   * This method assumes that the current token matches `Keyword.RETURN`.
   *
   *     returnStatement ::=
   *         'return' expression? ';'
   */
  Statement parseReturnStatement() {
    Token returnKeyword = getAndAdvance();
    if (_matches(TokenType.SEMICOLON)) {
      return astFactory.returnStatement(returnKeyword, null, getAndAdvance());
    }
    Expression expression = parseExpression2();
    Token semicolon = _expect(TokenType.SEMICOLON);
    return astFactory.returnStatement(returnKeyword, expression, semicolon);
  }

  /**
   * Parse a setter. The [commentAndMetadata] is the documentation comment and
   * metadata to be associated with the declaration. The [externalKeyword] is
   * the 'external' token. The [staticKeyword] is the static keyword, or `null`
   * if the setter is not static. The [returnType] is the return type that has
   * already been parsed, or `null` if there was no return type. Return the
   * setter that was parsed.
   *
   * This method assumes that the current token matches `Keyword.SET`.
   *
   *     setter ::=
   *         setterSignature functionBody?
   *
   *     setterSignature ::=
   *         'external'? 'static'? returnType? 'set' identifier formalParameterList
   */
  MethodDeclaration parseSetter(CommentAndMetadata commentAndMetadata,
      Token externalKeyword, Token staticKeyword, TypeAnnotation returnType) {
    Token propertyKeyword = getAndAdvance();
    SimpleIdentifier name = parseSimpleIdentifier(isDeclaration: true);
    FormalParameterList parameters = parseFormalParameterList();
    _validateFormalParameterList(parameters);
    FunctionBody body = parseFunctionBody(
        externalKeyword != null || staticKeyword == null,
        ParserErrorCode.STATIC_SETTER_WITHOUT_BODY,
        false);
    if (externalKeyword != null && body is! EmptyFunctionBody) {
      _reportErrorForCurrentToken(ParserErrorCode.EXTERNAL_SETTER_WITH_BODY);
    }
    return astFactory.methodDeclaration(
        commentAndMetadata.comment,
        commentAndMetadata.metadata,
        externalKeyword,
        staticKeyword,
        returnType,
        propertyKeyword,
        null,
        name,
        null,
        parameters,
        body);
  }

  /**
   * Parse a shift expression. Return the shift expression that was parsed.
   *
   *     shiftExpression ::=
   *         additiveExpression (shiftOperator additiveExpression)*
   *       | 'super' (shiftOperator additiveExpression)+
   */
  Expression parseShiftExpression() {
    Expression expression;
    if (_currentToken.keyword == Keyword.SUPER &&
        _currentToken.next.type.isShiftOperator) {
      expression = astFactory.superExpression(getAndAdvance());
    } else {
      expression = parseAdditiveExpression();
    }
    while (_currentToken.type.isShiftOperator) {
      expression = astFactory.binaryExpression(
          expression, getAndAdvance(), parseAdditiveExpression());
    }
    return expression;
  }

  /**
   * Parse a simple identifier. Return the simple identifier that was parsed.
   *
   *     identifier ::=
   *         IDENTIFIER
   */
  SimpleIdentifier parseSimpleIdentifier(
      {bool allowKeyword: false, bool isDeclaration: false}) {
    if (_matchesIdentifier() ||
        (allowKeyword && _tokenMatchesIdentifierOrKeyword(_currentToken))) {
      return _parseSimpleIdentifierUnchecked(isDeclaration: isDeclaration);
    }
    _reportErrorForCurrentToken(ParserErrorCode.MISSING_IDENTIFIER);
    return createSyntheticIdentifier(isDeclaration: isDeclaration);
  }

  /**
   * Parse a statement, starting with the given [token]. Return the statement
   * that was parsed, or `null` if the tokens do not represent a recognizable
   * statement.
   */
  Statement parseStatement(Token token) {
    _currentToken = token;
    return parseStatement2();
  }

  /**
   * Parse a statement. Return the statement that was parsed.
   *
   *     statement ::=
   *         label* nonLabeledStatement
   */
  Statement parseStatement2() {
    if (_treeDepth > _MAX_TREE_DEPTH) {
      throw new _TooDeepTreeError();
    }
    _treeDepth++;
    try {
      List<Label> labels = null;
      while (
          _matchesIdentifier() && _currentToken.next.type == TokenType.COLON) {
        Label label = parseLabel(isDeclaration: true);
        if (labels == null) {
          labels = <Label>[label];
        } else {
          labels.add(label);
        }
      }
      Statement statement = parseNonLabeledStatement();
      if (labels == null) {
        return statement;
      }
      return astFactory.labeledStatement(labels, statement);
    } finally {
      _treeDepth--;
    }
  }

  /**
   * Parse a sequence of statements, starting with the given [token]. Return the
   * statements that were parsed, or `null` if the tokens do not represent a
   * recognizable sequence of statements.
   */
  List<Statement> parseStatements(Token token) {
    _currentToken = token;
    return _parseStatementList();
  }

  /**
   * Parse a string literal. Return the string literal that was parsed.
   *
   *     stringLiteral ::=
   *         MULTI_LINE_STRING+
   *       | SINGLE_LINE_STRING+
   */
  StringLiteral parseStringLiteral() {
    if (_matches(TokenType.STRING)) {
      return _parseStringLiteralUnchecked();
    }
    _reportErrorForCurrentToken(ParserErrorCode.EXPECTED_STRING_LITERAL);
    return createSyntheticStringLiteral();
  }

  /**
   * Parse a super constructor invocation. Return the super constructor
   * invocation that was parsed.
   *
   * This method assumes that the current token matches [Keyword.SUPER].
   *
   *     superConstructorInvocation ::=
   *         'super' ('.' identifier)? arguments
   */
  SuperConstructorInvocation parseSuperConstructorInvocation() {
    Token keyword = getAndAdvance();
    Token period = null;
    SimpleIdentifier constructorName = null;
    if (_matches(TokenType.PERIOD)) {
      period = getAndAdvance();
      constructorName = parseSimpleIdentifier();
    }
    ArgumentList argumentList = _parseArgumentListChecked();
    return astFactory.superConstructorInvocation(
        keyword, period, constructorName, argumentList);
  }

  /**
   * Parse a switch statement. Return the switch statement that was parsed.
   *
   *     switchStatement ::=
   *         'switch' '(' expression ')' '{' switchCase* defaultCase? '}'
   *
   *     switchCase ::=
   *         label* ('case' expression ':') statements
   *
   *     defaultCase ::=
   *         label* 'default' ':' statements
   */
  SwitchStatement parseSwitchStatement() {
    bool wasInSwitch = _inSwitch;
    _inSwitch = true;
    try {
      HashSet<String> definedLabels = new HashSet<String>();
      Token keyword = _expectKeyword(Keyword.SWITCH);
      Token leftParenthesis = _expect(TokenType.OPEN_PAREN);
      Expression expression = parseExpression2();
      Token rightParenthesis = _expect(TokenType.CLOSE_PAREN);
      Token leftBracket = _expect(TokenType.OPEN_CURLY_BRACKET);
      Token defaultKeyword = null;
      List<SwitchMember> members = <SwitchMember>[];
      TokenType type = _currentToken.type;
      while (type != TokenType.EOF && type != TokenType.CLOSE_CURLY_BRACKET) {
        List<Label> labels = <Label>[];
        while (
            _matchesIdentifier() && _tokenMatches(_peek(), TokenType.COLON)) {
          SimpleIdentifier identifier =
              _parseSimpleIdentifierUnchecked(isDeclaration: true);
          String label = identifier.token.lexeme;
          if (definedLabels.contains(label)) {
            _reportErrorForToken(
                ParserErrorCode.DUPLICATE_LABEL_IN_SWITCH_STATEMENT,
                identifier.token,
                [label]);
          } else {
            definedLabels.add(label);
          }
          Token colon = getAndAdvance();
          labels.add(astFactory.label(identifier, colon));
        }
        Keyword keyword = _currentToken.keyword;
        if (keyword == Keyword.CASE) {
          Token caseKeyword = getAndAdvance();
          Expression caseExpression = parseExpression2();
          Token colon = _expect(TokenType.COLON);
          members.add(astFactory.switchCase(labels, caseKeyword, caseExpression,
              colon, _parseStatementList()));
          if (defaultKeyword != null) {
            _reportErrorForToken(
                ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE,
                caseKeyword);
          }
        } else if (keyword == Keyword.DEFAULT) {
          if (defaultKeyword != null) {
            _reportErrorForToken(
                ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES, _peek());
          }
          defaultKeyword = getAndAdvance();
          Token colon = _expect(TokenType.COLON);
          members.add(astFactory.switchDefault(
              labels, defaultKeyword, colon, _parseStatementList()));
        } else {
          // We need to advance, otherwise we could end up in an infinite loop,
          // but this could be a lot smarter about recovering from the error.
          _reportErrorForCurrentToken(ParserErrorCode.EXPECTED_CASE_OR_DEFAULT);
          bool atEndOrNextMember() {
            TokenType type = _currentToken.type;
            if (type == TokenType.EOF ||
                type == TokenType.CLOSE_CURLY_BRACKET) {
              return true;
            }
            Keyword keyword = _currentToken.keyword;
            return keyword == Keyword.CASE || keyword == Keyword.DEFAULT;
          }

          while (!atEndOrNextMember()) {
            _advance();
          }
        }
        type = _currentToken.type;
      }
      Token rightBracket = _expect(TokenType.CLOSE_CURLY_BRACKET);
      return astFactory.switchStatement(keyword, leftParenthesis, expression,
          rightParenthesis, leftBracket, members, rightBracket);
    } finally {
      _inSwitch = wasInSwitch;
    }
  }

  /**
   * Parse a symbol literal. Return the symbol literal that was parsed.
   *
   * This method assumes that the current token matches [TokenType.HASH].
   *
   *     symbolLiteral ::=
   *         '#' identifier ('.' identifier)*
   */
  SymbolLiteral parseSymbolLiteral() {
    Token poundSign = getAndAdvance();
    List<Token> components = <Token>[];
    if (_matchesIdentifier()) {
      components.add(getAndAdvance());
      while (_optional(TokenType.PERIOD)) {
        if (_matchesIdentifier()) {
          components.add(getAndAdvance());
        } else {
          _reportErrorForCurrentToken(ParserErrorCode.MISSING_IDENTIFIER);
          components.add(_createSyntheticToken(TokenType.IDENTIFIER));
          break;
        }
      }
    } else if (_currentToken.isOperator) {
      components.add(getAndAdvance());
    } else if (_matchesKeyword(Keyword.VOID)) {
      components.add(getAndAdvance());
    } else {
      _reportErrorForCurrentToken(ParserErrorCode.MISSING_IDENTIFIER);
      components.add(_createSyntheticToken(TokenType.IDENTIFIER));
    }
    return astFactory.symbolLiteral(poundSign, components);
  }

  /**
   * Parse a throw expression. Return the throw expression that was parsed.
   *
   * This method assumes that the current token matches [Keyword.THROW].
   *
   *     throwExpression ::=
   *         'throw' expression
   */
  Expression parseThrowExpression() {
    Token keyword = getAndAdvance();
    TokenType type = _currentToken.type;
    if (type == TokenType.SEMICOLON || type == TokenType.CLOSE_PAREN) {
      _reportErrorForToken(
          ParserErrorCode.MISSING_EXPRESSION_IN_THROW, _currentToken);
      return astFactory.throwExpression(keyword, createSyntheticIdentifier());
    }
    Expression expression = parseExpression2();
    return astFactory.throwExpression(keyword, expression);
  }

  /**
   * Parse a throw expression. Return the throw expression that was parsed.
   *
   * This method assumes that the current token matches [Keyword.THROW].
   *
   *     throwExpressionWithoutCascade ::=
   *         'throw' expressionWithoutCascade
   */
  Expression parseThrowExpressionWithoutCascade() {
    Token keyword = getAndAdvance();
    TokenType type = _currentToken.type;
    if (type == TokenType.SEMICOLON || type == TokenType.CLOSE_PAREN) {
      _reportErrorForToken(
          ParserErrorCode.MISSING_EXPRESSION_IN_THROW, _currentToken);
      return astFactory.throwExpression(keyword, createSyntheticIdentifier());
    }
    Expression expression = parseExpressionWithoutCascade();
    return astFactory.throwExpression(keyword, expression);
  }

  /**
   * Parse a try statement. Return the try statement that was parsed.
   *
   * This method assumes that the current token matches [Keyword.TRY].
   *
   *     tryStatement ::=
   *         'try' block (onPart+ finallyPart? | finallyPart)
   *
   *     onPart ::=
   *         catchPart block
   *       | 'on' type catchPart? block
   *
   *     catchPart ::=
   *         'catch' '(' identifier (',' identifier)? ')'
   *
   *     finallyPart ::=
   *         'finally' block
   */
  Statement parseTryStatement() {
    Token tryKeyword = getAndAdvance();
    Block body = _parseBlockChecked();
    List<CatchClause> catchClauses = <CatchClause>[];
    Block finallyClause = null;
    while (_matchesKeyword(Keyword.ON) || _matchesKeyword(Keyword.CATCH)) {
      Token onKeyword = null;
      TypeName exceptionType = null;
      if (_matchesKeyword(Keyword.ON)) {
        onKeyword = getAndAdvance();
        exceptionType = parseTypeNotVoid(false);
      }
      Token catchKeyword = null;
      Token leftParenthesis = null;
      SimpleIdentifier exceptionParameter = null;
      Token comma = null;
      SimpleIdentifier stackTraceParameter = null;
      Token rightParenthesis = null;
      if (_matchesKeyword(Keyword.CATCH)) {
        catchKeyword = getAndAdvance();
        leftParenthesis = _expect(TokenType.OPEN_PAREN);
        exceptionParameter = parseSimpleIdentifier(isDeclaration: true);
        if (_matches(TokenType.COMMA)) {
          comma = getAndAdvance();
          stackTraceParameter = parseSimpleIdentifier(isDeclaration: true);
        }
        rightParenthesis = _expect(TokenType.CLOSE_PAREN);
      }
      Block catchBody = _parseBlockChecked();
      catchClauses.add(astFactory.catchClause(
          onKeyword,
          exceptionType,
          catchKeyword,
          leftParenthesis,
          exceptionParameter,
          comma,
          stackTraceParameter,
          rightParenthesis,
          catchBody));
    }
    Token finallyKeyword = null;
    if (_matchesKeyword(Keyword.FINALLY)) {
      finallyKeyword = getAndAdvance();
      finallyClause = _parseBlockChecked();
    } else if (catchClauses.isEmpty) {
      _reportErrorForCurrentToken(ParserErrorCode.MISSING_CATCH_OR_FINALLY);
    }
    return astFactory.tryStatement(
        tryKeyword, body, catchClauses, finallyKeyword, finallyClause);
  }

  /**
   * Parse a type alias. The [commentAndMetadata] is the metadata to be
   * associated with the member. Return the type alias that was parsed.
   *
   * This method assumes that the current token matches [Keyword.TYPEDEF].
   *
   *     typeAlias ::=
   *         'typedef' typeAliasBody
   *       | genericTypeAlias
   *
   *     typeAliasBody ::=
   *         functionTypeAlias
   *
   *     functionTypeAlias ::=
   *         functionPrefix typeParameterList? formalParameterList ';'
   *
   *     functionPrefix ::=
   *         returnType? name
   */
  TypeAlias parseTypeAlias(CommentAndMetadata commentAndMetadata) {
    Token keyword = getAndAdvance();
    if (_matchesIdentifier()) {
      Token next = _peek();
      if (_tokenMatches(next, TokenType.LT)) {
        next = _skipTypeParameterList(next);
        if (next != null && _tokenMatches(next, TokenType.EQ)) {
          TypeAlias typeAlias =
              parseGenericTypeAlias(commentAndMetadata, keyword);
          return typeAlias;
        }
      } else if (_tokenMatches(next, TokenType.EQ)) {
        TypeAlias typeAlias =
            parseGenericTypeAlias(commentAndMetadata, keyword);
        return typeAlias;
      }
    }
    return _parseFunctionTypeAlias(commentAndMetadata, keyword);
  }

  /**
   * Parse a type.
   *
   *     type ::=
   *         typeWithoutFunction
   *       | functionType
   */
  TypeAnnotation parseTypeAnnotation(bool inExpression) {
    TypeAnnotation type = null;
    if (_atGenericFunctionTypeAfterReturnType(_currentToken)) {
      // Generic function type with no return type.
      type = parseGenericFunctionTypeAfterReturnType(null);
    } else {
      type = parseTypeWithoutFunction(inExpression);
    }
    while (_atGenericFunctionTypeAfterReturnType(_currentToken)) {
      type = parseGenericFunctionTypeAfterReturnType(type);
    }
    return type;
  }

  /**
   * Parse a list of type arguments. Return the type argument list that was
   * parsed.
   *
   * This method assumes that the current token matches `TokenType.LT`.
   *
   *     typeArguments ::=
   *         '<' typeList '>'
   *
   *     typeList ::=
   *         type (',' type)*
   */
  TypeArgumentList parseTypeArgumentList() {
    Token leftBracket = getAndAdvance();
    List<TypeAnnotation> arguments = <TypeAnnotation>[
      parseTypeAnnotation(false)
    ];
    while (_optional(TokenType.COMMA)) {
      arguments.add(parseTypeAnnotation(false));
    }
    Token rightBracket = _expectGt();
    return astFactory.typeArgumentList(leftBracket, arguments, rightBracket);
  }

  /**
   * Parse a type which is not void and is not a function type. Return the type
   * that was parsed.
   *
   *     typeNotVoidWithoutFunction ::=
   *         qualified typeArguments?
   */
  // TODO(eernst): Rename this to `parseTypeNotVoidWithoutFunction`?
  // Apparently,  it was named `parseTypeName` before type arguments existed.
  TypeName parseTypeName(bool inExpression) {
    TypeName realType = _parseTypeName(inExpression);
    // If this is followed by a generic method type comment, allow the comment
    // type to replace the real type name.
    // TODO(jmesserly): this feels like a big hammer. Can we restrict it to
    // only work inside generic methods?
    TypeName typeFromComment = _parseOptionalTypeNameComment();
    return typeFromComment ?? realType;
  }

  /**
   * Parse a type which is not `void`.
   *
   *     typeNotVoid ::=
   *         functionType
   *       | typeNotVoidWithoutFunction
   */
  TypeAnnotation parseTypeNotVoid(bool inExpression) {
    TypeAnnotation type = null;
    if (_atGenericFunctionTypeAfterReturnType(_currentToken)) {
      // Generic function type with no return type.
      type = parseGenericFunctionTypeAfterReturnType(null);
    } else if (_currentToken.keyword == Keyword.VOID &&
        _atGenericFunctionTypeAfterReturnType(_currentToken.next)) {
      type = astFactory.typeName(
          astFactory.simpleIdentifier(getAndAdvance()), null);
    } else {
      type = parseTypeName(inExpression);
    }
    while (_atGenericFunctionTypeAfterReturnType(_currentToken)) {
      type = parseGenericFunctionTypeAfterReturnType(type);
    }
    return type;
  }

  /**
   * Parse a type parameter. Return the type parameter that was parsed.
   *
   *     typeParameter ::=
   *         metadata name ('extends' bound)?
   */
  TypeParameter parseTypeParameter() {
    CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
    SimpleIdentifier name = parseSimpleIdentifier(isDeclaration: true);
    if (_matches(TokenType.QUESTION)) {
      _reportErrorForCurrentToken(ParserErrorCode.NULLABLE_TYPE_PARAMETER);
      _advance();
    }
    if (_matchesKeyword(Keyword.EXTENDS)) {
      Token keyword = getAndAdvance();
      TypeAnnotation bound = parseTypeNotVoid(false);
      return astFactory.typeParameter(commentAndMetadata.comment,
          commentAndMetadata.metadata, name, keyword, bound);
    }
    return astFactory.typeParameter(commentAndMetadata.comment,
        commentAndMetadata.metadata, name, null, null);
  }

  /**
   * Parse a list of type parameters. Return the list of type parameters that
   * were parsed.
   *
   * This method assumes that the current token matches `TokenType.LT`.
   *
   *     typeParameterList ::=
   *         '<' typeParameter (',' typeParameter)* '>'
   */
  TypeParameterList parseTypeParameterList() {
    Token leftBracket = getAndAdvance();
    List<TypeParameter> typeParameters = <TypeParameter>[parseTypeParameter()];
    while (_optional(TokenType.COMMA)) {
      typeParameters.add(parseTypeParameter());
    }
    Token rightBracket = _expectGt();
    return astFactory.typeParameterList(
        leftBracket, typeParameters, rightBracket);
  }

  /**
   * Parse a type which is not a function type.
   *
   *     typeWithoutFunction ::=
   *         `void`
   *       | typeNotVoidWithoutFunction
   */
  TypeAnnotation parseTypeWithoutFunction(bool inExpression) {
    if (_currentToken.keyword == Keyword.VOID) {
      return astFactory.typeName(
          astFactory.simpleIdentifier(getAndAdvance()), null);
    } else {
      return parseTypeName(inExpression);
    }
  }

  /**
   * Parse a unary expression. Return the unary expression that was parsed.
   *
   *     unaryExpression ::=
   *         prefixOperator unaryExpression
   *       | awaitExpression
   *       | postfixExpression
   *       | unaryOperator 'super'
   *       | '-' 'super'
   *       | incrementOperator assignableExpression
   */
  Expression parseUnaryExpression() {
    TokenType type = _currentToken.type;
    if (type == TokenType.MINUS ||
        type == TokenType.BANG ||
        type == TokenType.TILDE) {
      Token operator = getAndAdvance();
      if (_matchesKeyword(Keyword.SUPER)) {
        TokenType nextType = _peek().type;
        if (nextType == TokenType.OPEN_SQUARE_BRACKET ||
            nextType == TokenType.PERIOD) {
          //     "prefixOperator unaryExpression"
          // --> "prefixOperator postfixExpression"
          // --> "prefixOperator primary                    selector*"
          // --> "prefixOperator 'super' assignableSelector selector*"
          return astFactory.prefixExpression(operator, parseUnaryExpression());
        }
        return astFactory.prefixExpression(
            operator, astFactory.superExpression(getAndAdvance()));
      }
      return astFactory.prefixExpression(operator, parseUnaryExpression());
    } else if (_currentToken.type.isIncrementOperator) {
      Token operator = getAndAdvance();
      if (_matchesKeyword(Keyword.SUPER)) {
        TokenType nextType = _peek().type;
        if (nextType == TokenType.OPEN_SQUARE_BRACKET ||
            nextType == TokenType.PERIOD) {
          // --> "prefixOperator 'super' assignableSelector selector*"
          return astFactory.prefixExpression(operator, parseUnaryExpression());
        }
        //
        // Even though it is not valid to use an incrementing operator
        // ('++' or '--') before 'super', we can (and therefore must) interpret
        // "--super" as semantically equivalent to "-(-super)". Unfortunately,
        // we cannot do the same for "++super" because "+super" is also not
        // valid.
        //
        if (type == TokenType.MINUS_MINUS) {
          Token firstOperator = _createToken(operator, TokenType.MINUS);
          Token secondOperator =
              new Token(TokenType.MINUS, operator.offset + 1);
          secondOperator.setNext(_currentToken);
          firstOperator.setNext(secondOperator);
          operator.previous.setNext(firstOperator);
          return astFactory.prefixExpression(
              firstOperator,
              astFactory.prefixExpression(
                  secondOperator, astFactory.superExpression(getAndAdvance())));
        }
        // Invalid operator before 'super'
        _reportErrorForCurrentToken(
            ParserErrorCode.INVALID_OPERATOR_FOR_SUPER, [operator.lexeme]);
        return astFactory.prefixExpression(
            operator, astFactory.superExpression(getAndAdvance()));
      }
      return astFactory.prefixExpression(
          operator, parseAssignableExpression(false));
    } else if (type == TokenType.PLUS) {
      _reportErrorForCurrentToken(ParserErrorCode.MISSING_IDENTIFIER);
      return createSyntheticIdentifier();
    } else if (_inAsync && _matchesKeyword(Keyword.AWAIT)) {
      return parseAwaitExpression();
    }
    return parsePostfixExpression();
  }

  /**
   * Parse a variable declaration. Return the variable declaration that was
   * parsed.
   *
   *     variableDeclaration ::=
   *         identifier ('=' expression)?
   */
  VariableDeclaration parseVariableDeclaration() {
    // TODO(paulberry): prior to the fix for bug 23204, we permitted
    // annotations before variable declarations (e.g. "String @deprecated s;").
    // Although such constructions are prohibited by the spec, we may want to
    // consider handling them anyway to allow for better parser recovery in the
    // event that the user erroneously tries to use them.  However, as a
    // counterargument, this would likely degrade parser recovery in the event
    // of a construct like "class C { int @deprecated foo() {} }" (i.e. the
    // user is in the middle of inserting "int bar;" prior to
    // "@deprecated foo() {}").
    SimpleIdentifier name = parseSimpleIdentifier(isDeclaration: true);
    Token equals = null;
    Expression initializer = null;
    if (_matches(TokenType.EQ)) {
      equals = getAndAdvance();
      initializer = parseExpression2();
    }
    return astFactory.variableDeclaration(name, equals, initializer);
  }

  /**
   * Parse a variable declaration list. The [commentAndMetadata] is the metadata
   * to be associated with the variable declaration list. Return the variable
   * declaration list that was parsed.
   *
   *     variableDeclarationList ::=
   *         finalConstVarOrType variableDeclaration (',' variableDeclaration)*
   */
  VariableDeclarationList parseVariableDeclarationListAfterMetadata(
      CommentAndMetadata commentAndMetadata) {
    FinalConstVarOrType holder = parseFinalConstVarOrType(false);
    return parseVariableDeclarationListAfterType(
        commentAndMetadata, holder.keyword, holder.type);
  }

  /**
   * Parse a variable declaration list. The [commentAndMetadata] is the metadata
   * to be associated with the variable declaration list, or `null` if there is
   * no attempt at parsing the comment and metadata. The [keyword] is the token
   * representing the 'final', 'const' or 'var' keyword, or `null` if there is
   * no keyword. The [type] is the type of the variables in the list. Return the
   * variable declaration list that was parsed.
   *
   *     variableDeclarationList ::=
   *         finalConstVarOrType variableDeclaration (',' variableDeclaration)*
   */
  VariableDeclarationList parseVariableDeclarationListAfterType(
      CommentAndMetadata commentAndMetadata,
      Token keyword,
      TypeAnnotation type) {
    if (type != null &&
        keyword != null &&
        _tokenMatchesKeyword(keyword, Keyword.VAR)) {
      _reportErrorForToken(ParserErrorCode.VAR_AND_TYPE, keyword);
    }
    List<VariableDeclaration> variables = <VariableDeclaration>[
      parseVariableDeclaration()
    ];
    while (_optional(TokenType.COMMA)) {
      variables.add(parseVariableDeclaration());
    }
    return astFactory.variableDeclarationList(commentAndMetadata?.comment,
        commentAndMetadata?.metadata, keyword, type, variables);
  }

  /**
   * Parse a variable declaration statement. The [commentAndMetadata] is the
   * metadata to be associated with the variable declaration statement, or
   * `null` if there is no attempt at parsing the comment and metadata. Return
   * the variable declaration statement that was parsed.
   *
   *     variableDeclarationStatement ::=
   *         variableDeclarationList ';'
   */
  VariableDeclarationStatement parseVariableDeclarationStatementAfterMetadata(
      CommentAndMetadata commentAndMetadata) {
    //    Token startToken = currentToken;
    VariableDeclarationList variableList =
        parseVariableDeclarationListAfterMetadata(commentAndMetadata);
//        if (!matches(TokenType.SEMICOLON)) {
//          if (matches(startToken, Keyword.VAR) && isTypedIdentifier(startToken.getNext())) {
//            // TODO(brianwilkerson) This appears to be of the form "var type variable". We should do
//            // a better job of recovering in this case.
//          }
//        }
    Token semicolon = _expect(TokenType.SEMICOLON);
    return astFactory.variableDeclarationStatement(variableList, semicolon);
  }

  /**
   * Parse a while statement. Return the while statement that was parsed.
   *
   * This method assumes that the current token matches [Keyword.WHILE].
   *
   *     whileStatement ::=
   *         'while' '(' expression ')' statement
   */
  Statement parseWhileStatement() {
    bool wasInLoop = _inLoop;
    _inLoop = true;
    try {
      Token keyword = getAndAdvance();
      Token leftParenthesis = _expect(TokenType.OPEN_PAREN);
      Expression condition = parseExpression2();
      Token rightParenthesis = _expect(TokenType.CLOSE_PAREN);
      Statement body = parseStatement2();
      return astFactory.whileStatement(
          keyword, leftParenthesis, condition, rightParenthesis, body);
    } finally {
      _inLoop = wasInLoop;
    }
  }

  /**
   * Parse a with clause. Return the with clause that was parsed.
   *
   * This method assumes that the current token matches `Keyword.WITH`.
   *
   *     withClause ::=
   *         'with' typeName (',' typeName)*
   */
  WithClause parseWithClause() {
    Token withKeyword = getAndAdvance();
    List<TypeName> types = <TypeName>[];
    do {
      TypeName typeName = parseTypeName(false);
      _mustNotBeNullable(typeName, ParserErrorCode.NULLABLE_TYPE_IN_WITH);
      types.add(typeName);
    } while (_optional(TokenType.COMMA));
    return astFactory.withClause(withKeyword, types);
  }

  /**
   * Parse a yield statement. Return the yield statement that was parsed.
   *
   * This method assumes that the current token matches [Keyword.YIELD].
   *
   *     yieldStatement ::=
   *         'yield' '*'? expression ';'
   */
  YieldStatement parseYieldStatement() {
    Token yieldToken = getAndAdvance();
    Token star = null;
    if (_matches(TokenType.STAR)) {
      star = getAndAdvance();
    }
    Expression expression = parseExpression2();
    Token semicolon = _expect(TokenType.SEMICOLON);
    return astFactory.yieldStatement(yieldToken, star, expression, semicolon);
  }

  /**
   * Parse a formal parameter list, starting at the [startToken], without
   * actually creating a formal parameter list or changing the current token.
   * Return the token following the parameter list that was parsed, or `null`
   * if the given token is not the first token in a valid parameter list.
   *
   * This method must be kept in sync with [parseFormalParameterList].
   */
  Token skipFormalParameterList(Token startToken) {
    if (!_tokenMatches(startToken, TokenType.OPEN_PAREN)) {
      return null;
    }
    return (startToken as BeginToken).endToken?.next;
  }

  /**
   * Parse the portion of a generic function type after the return type,
   * starting at the [startToken], without actually creating a generic function
   * type or changing the current token. Return the token following the generic
   * function type that was parsed, or `null` if the given token is not the
   * first token in a valid generic function type.
   *
   * This method must be kept in sync with
   * [parseGenericFunctionTypeAfterReturnType].
   */
  Token skipGenericFunctionTypeAfterReturnType(Token startToken) {
    Token next = startToken.next; // Skip 'Function'
    if (_tokenMatches(next, TokenType.LT)) {
      next = skipTypeParameterList(next);
      if (next == null) {
        return null;
      }
    }
    return skipFormalParameterList(next);
  }

  /**
   * Parse a prefixed identifier, starting at the [startToken], without actually
   * creating a prefixed identifier or changing the current token. Return the
   * token following the prefixed identifier that was parsed, or `null` if the
   * given token is not the first token in a valid prefixed identifier.
   *
   * This method must be kept in sync with [parsePrefixedIdentifier].
   *
   *     prefixedIdentifier ::=
   *         identifier ('.' identifier)?
   */
  Token skipPrefixedIdentifier(Token startToken) {
    Token token = skipSimpleIdentifier(startToken);
    if (token == null) {
      return null;
    } else if (!_tokenMatches(token, TokenType.PERIOD)) {
      return token;
    }
    token = token.next;
    Token nextToken = skipSimpleIdentifier(token);
    if (nextToken != null) {
      return nextToken;
    } else if (_tokenMatches(token, TokenType.CLOSE_PAREN) ||
        _tokenMatches(token, TokenType.COMMA)) {
      // If the `id.` is followed by something that cannot produce a valid
      // structure then assume this is a prefixed identifier but missing the
      // trailing identifier
      return token;
    }
    return null;
  }

  /**
   * Parse a simple identifier, starting at the [startToken], without actually
   * creating a simple identifier or changing the current token. Return the
   * token following the simple identifier that was parsed, or `null` if the
   * given token is not the first token in a valid simple identifier.
   *
   * This method must be kept in sync with [parseSimpleIdentifier].
   *
   *     identifier ::=
   *         IDENTIFIER
   */
  Token skipSimpleIdentifier(Token startToken) {
    if (_tokenMatches(startToken, TokenType.IDENTIFIER) ||
        _tokenMatchesPseudoKeyword(startToken)) {
      return startToken.next;
    }
    return null;
  }

  /**
   * Parse a string literal, starting at the [startToken], without actually
   * creating a string literal or changing the current token. Return the token
   * following the string literal that was parsed, or `null` if the given token
   * is not the first token in a valid string literal.
   *
   * This method must be kept in sync with [parseStringLiteral].
   *
   *     stringLiteral ::=
   *         MULTI_LINE_STRING+
   *       | SINGLE_LINE_STRING+
   */
  Token skipStringLiteral(Token startToken) {
    Token token = startToken;
    while (token != null && _tokenMatches(token, TokenType.STRING)) {
      token = token.next;
      TokenType type = token.type;
      if (type == TokenType.STRING_INTERPOLATION_EXPRESSION ||
          type == TokenType.STRING_INTERPOLATION_IDENTIFIER) {
        token = _skipStringInterpolation(token);
      }
    }
    if (identical(token, startToken)) {
      return null;
    }
    return token;
  }

  /**
   * Parse a type annotation, starting at the [startToken], without actually
   * creating a type annotation or changing the current token. Return the token
   * following the type annotation that was parsed, or `null` if the given token
   * is not the first token in a valid type annotation.
   *
   * This method must be kept in sync with [parseTypeAnnotation].
   */
  Token skipTypeAnnotation(Token startToken) {
    Token next = null;
    if (_atGenericFunctionTypeAfterReturnType(startToken)) {
      // Generic function type with no return type.
      next = skipGenericFunctionTypeAfterReturnType(startToken);
    } else {
      next = skipTypeWithoutFunction(startToken);
    }
    while (next != null && _atGenericFunctionTypeAfterReturnType(next)) {
      next = skipGenericFunctionTypeAfterReturnType(next);
    }
    return next;
  }

  /**
   * Parse a list of type arguments, starting at the [startToken], without
   * actually creating a type argument list or changing the current token.
   * Return the token following the type argument list that was parsed, or
   * `null` if the given token is not the first token in a valid type argument
   * list.
   *
   * This method must be kept in sync with [parseTypeArgumentList].
   *
   *     typeArguments ::=
   *         '<' typeList '>'
   *
   *     typeList ::=
   *         type (',' type)*
   */
  Token skipTypeArgumentList(Token startToken) {
    Token token = startToken;
    if (!_tokenMatches(token, TokenType.LT) &&
        !_injectGenericCommentTypeList()) {
      return null;
    }
    token = skipTypeAnnotation(token.next);
    if (token == null) {
      // If the start token '<' is followed by '>'
      // then assume this should be type argument list but is missing a type
      token = startToken.next;
      if (_tokenMatches(token, TokenType.GT)) {
        return token.next;
      }
      return null;
    }
    while (_tokenMatches(token, TokenType.COMMA)) {
      token = skipTypeAnnotation(token.next);
      if (token == null) {
        return null;
      }
    }
    if (token.type == TokenType.GT) {
      return token.next;
    } else if (token.type == TokenType.GT_GT) {
      Token second = new Token(TokenType.GT, token.offset + 1);
      second.setNextWithoutSettingPrevious(token.next);
      return second;
    }
    return null;
  }

  /**
   * Parse a type name, starting at the [startToken], without actually creating
   * a type name or changing the current token. Return the token following the
   * type name that was parsed, or `null` if the given token is not the first
   * token in a valid type name.
   *
   * This method must be kept in sync with [parseTypeName].
   *
   *     type ::=
   *         qualified typeArguments?
   */
  Token skipTypeName(Token startToken) {
    Token token = skipPrefixedIdentifier(startToken);
    if (token == null) {
      return null;
    }
    if (_tokenMatches(token, TokenType.LT)) {
      token = skipTypeArgumentList(token);
    }
    return token;
  }

  /**
   * Parse a type parameter list, starting at the [startToken], without actually
   * creating a type parameter list or changing the current token. Return the
   * token following the type parameter list that was parsed, or `null` if the
   * given token is not the first token in a valid type parameter list.
   *
   * This method must be kept in sync with [parseTypeParameterList].
   */
  Token skipTypeParameterList(Token startToken) {
    if (!_tokenMatches(startToken, TokenType.LT)) {
      return null;
    }
    int depth = 1;
    Token previous = startToken;
    Token next = startToken.next;
    while (next != previous) {
      if (_tokenMatches(next, TokenType.LT)) {
        depth++;
      } else if (_tokenMatches(next, TokenType.GT)) {
        depth--;
        if (depth == 0) {
          return next.next;
        }
      }
      previous = next;
      next = next.next;
    }
    return null;
  }

  /**
   * Parse a typeWithoutFunction, starting at the [startToken], without actually
   * creating a TypeAnnotation or changing the current token. Return the token
   * following the typeWithoutFunction that was parsed, or `null` if the given
   * token is not the first token in a valid typeWithoutFunction.
   *
   * This method must be kept in sync with [parseTypeWithoutFunction].
   */
  Token skipTypeWithoutFunction(Token startToken) {
    if (startToken.keyword == Keyword.VOID) {
      return startToken.next;
    } else {
      return skipTypeName(startToken);
    }
  }

  /**
   * Advance to the next token in the token stream.
   */
  void _advance() {
    _currentToken = _currentToken.next;
  }

  /**
   * Append the character equivalent of the given [codePoint] to the given
   * [builder]. Use the [startIndex] and [endIndex] to report an error, and
   * don't append anything to the builder, if the code point is invalid. The
   * [escapeSequence] is the escape sequence that was parsed to produce the
   * code point (used for error reporting).
   */
  void _appendCodePoint(StringBuffer buffer, String source, int codePoint,
      int startIndex, int endIndex) {
    if (codePoint < 0 || codePoint > Character.MAX_CODE_POINT) {
      String escapeSequence = source.substring(startIndex, endIndex + 1);
      _reportErrorForCurrentToken(
          ParserErrorCode.INVALID_CODE_POINT, [escapeSequence]);
      return;
    }
    if (codePoint < Character.MAX_VALUE) {
      buffer.writeCharCode(codePoint);
    } else {
      buffer.write(Character.toChars(codePoint));
    }
  }

  /**
   * Return `true` if we are positioned at the keyword 'Function' in a generic
   * function type alias.
   */
  bool _atGenericFunctionTypeAfterReturnType(Token startToken) {
    if (_tokenMatchesKeyword(startToken, Keyword.FUNCTION)) {
      Token next = startToken.next;
      if (next != null &&
          (_tokenMatches(next, TokenType.OPEN_PAREN) ||
              _tokenMatches(next, TokenType.LT))) {
        return true;
      }
    }
    return false;
  }

  /**
   * Clone all token starting from the given [token] up to the end of the token
   * stream, and return the first token in the new token stream.
   */
  Token _cloneTokens(Token token) {
    if (token == null) {
      return null;
    }
    token = token is CommentToken ? token.parent : token;
    Token head = new Token.eof(-1);
    Token current = head;
    while (token.type != TokenType.EOF) {
      Token clone = token.copy();
      current.setNext(clone);
      current = clone;
      token = token.next;
    }
    Token tail = new Token.eof(0);
    current.setNext(tail);
    return head.next;
  }

  /**
   * Convert the given [method] declaration into the nearest valid top-level
   * function declaration (that is, the function declaration that most closely
   * captures the components of the given method declaration).
   */
  FunctionDeclaration _convertToFunctionDeclaration(MethodDeclaration method) =>
      astFactory.functionDeclaration(
          method.documentationComment,
          method.metadata,
          method.externalKeyword,
          method.returnType,
          method.propertyKeyword,
          method.name,
          astFactory.functionExpression(
              method.typeParameters, method.parameters, method.body));

  /**
   * Return `true` if the current token could be the start of a compilation unit
   * member. This method is used for recovery purposes to decide when to stop
   * skipping tokens after finding an error while parsing a compilation unit
   * member.
   */
  bool _couldBeStartOfCompilationUnitMember() {
    Keyword keyword = _currentToken.keyword;
    Token next = _currentToken.next;
    TokenType nextType = next.type;
    if ((keyword == Keyword.IMPORT ||
            keyword == Keyword.EXPORT ||
            keyword == Keyword.LIBRARY ||
            keyword == Keyword.PART) &&
        nextType != TokenType.PERIOD &&
        nextType != TokenType.LT) {
      // This looks like the start of a directive
      return true;
    } else if (keyword == Keyword.CLASS) {
      // This looks like the start of a class definition
      return true;
    } else if (keyword == Keyword.TYPEDEF &&
        nextType != TokenType.PERIOD &&
        nextType != TokenType.LT) {
      // This looks like the start of a typedef
      return true;
    } else if (keyword == Keyword.VOID ||
        ((keyword == Keyword.GET || keyword == Keyword.SET) &&
            _tokenMatchesIdentifier(next)) ||
        (keyword == Keyword.OPERATOR && _isOperator(next))) {
      // This looks like the start of a function
      return true;
    } else if (_matchesIdentifier()) {
      if (nextType == TokenType.OPEN_PAREN) {
        // This looks like the start of a function
        return true;
      }
      Token token = skipTypeAnnotation(_currentToken);
      if (token == null) {
        return false;
      }
      // TODO(brianwilkerson) This looks wrong; should we be checking 'token'?
      if (keyword == Keyword.GET ||
          keyword == Keyword.SET ||
          (keyword == Keyword.OPERATOR && _isOperator(next)) ||
          _matchesIdentifier()) {
        return true;
      }
    }
    return false;
  }

  /**
   * Return a synthetic token representing the given [keyword].
   */
  Token _createSyntheticKeyword(Keyword keyword) =>
      _injectToken(new SyntheticKeywordToken(keyword, _currentToken.offset));

  /**
   * Return a synthetic token with the given [type].
   */
  Token _createSyntheticToken(TokenType type) =>
      _injectToken(new StringToken(type, "", _currentToken.offset));

  /**
   * Create and return a new token with the given [type]. The token will replace
   * the first portion of the given [token], so it will have the same offset and
   * will have any comments that might have preceeded the token.
   */
  Token _createToken(Token token, TokenType type, {bool isBegin: false}) {
    CommentToken comments = token.precedingComments;
    if (comments == null) {
      if (isBegin) {
        return new BeginToken(type, token.offset);
      }
      return new Token(type, token.offset);
    } else if (isBegin) {
      return new BeginToken(type, token.offset, comments);
    }
    return new Token(type, token.offset, comments);
  }

  /**
   * Check that the given [expression] is assignable and report an error if it
   * isn't.
   *
   *     assignableExpression ::=
   *         primary (arguments* assignableSelector)+
   *       | 'super' unconditionalAssignableSelector
   *       | identifier
   *
   *     unconditionalAssignableSelector ::=
   *         '[' expression ']'
   *       | '.' identifier
   *
   *     assignableSelector ::=
   *         unconditionalAssignableSelector
   *       | '?.' identifier
   */
  void _ensureAssignable(Expression expression) {
    if (expression != null && !expression.isAssignable) {
      _reportErrorForCurrentToken(
          ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE);
    }
  }

  /**
   * If the current token has the expected type, return it after advancing to
   * the next token. Otherwise report an error and return the current token
   * without advancing.
   *
   * Note that the method [_expectGt] should be used if the argument to this
   * method would be [TokenType.GT].
   *
   * The [type] is the type of token that is expected.
   */
  Token _expect(TokenType type) {
    if (_matches(type)) {
      return getAndAdvance();
    }
    // Remove uses of this method in favor of matches?
    // Pass in the error code to use to report the error?
    if (type == TokenType.SEMICOLON) {
      if (_tokenMatches(_currentToken.next, TokenType.SEMICOLON)) {
        _reportErrorForCurrentToken(
            ParserErrorCode.UNEXPECTED_TOKEN, [_currentToken.lexeme]);
        _advance();
        return getAndAdvance();
      }
      _reportErrorForToken(ParserErrorCode.EXPECTED_TOKEN,
          _currentToken.previous, [type.lexeme]);
      return _createSyntheticToken(TokenType.SEMICOLON);
    }
    _reportErrorForCurrentToken(ParserErrorCode.EXPECTED_TOKEN, [type.lexeme]);
    return _createSyntheticToken(type);
  }

  /**
   * If the current token has the type [TokenType.GT], return it after advancing
   * to the next token. Otherwise report an error and create a synthetic token.
   */
  Token _expectGt() {
    if (_matchesGt()) {
      return getAndAdvance();
    }
    _reportErrorForCurrentToken(
        ParserErrorCode.EXPECTED_TOKEN, [TokenType.GT.lexeme]);
    return _createSyntheticToken(TokenType.GT);
  }

  /**
   * If the current token is a keyword matching the given [keyword], return it
   * after advancing to the next token. Otherwise report an error and return the
   * current token without advancing.
   */
  Token _expectKeyword(Keyword keyword) {
    if (_matchesKeyword(keyword)) {
      return getAndAdvance();
    }
    // Remove uses of this method in favor of matches?
    // Pass in the error code to use to report the error?
    _reportErrorForCurrentToken(
        ParserErrorCode.EXPECTED_TOKEN, [keyword.lexeme]);
    return _currentToken;
  }

  /**
   * Search the given list of [ranges] for a range that contains the given
   * [index]. Return the range that was found, or `null` if none of the ranges
   * contain the index.
   */
  List<int> _findRange(List<List<int>> ranges, int index) {
    int rangeCount = ranges.length;
    for (int i = 0; i < rangeCount; i++) {
      List<int> range = ranges[i];
      if (range[0] <= index && index <= range[1]) {
        return range;
      } else if (index < range[0]) {
        return null;
      }
    }
    return null;
  }

  /**
   * Return a list of the ranges of characters in the given [comment] that
   * should be treated as code blocks.
   */
  List<List<int>> _getCodeBlockRanges(String comment) {
    List<List<int>> ranges = <List<int>>[];
    int length = comment.length;
    if (length < 3) {
      return ranges;
    }
    int index = 0;
    int firstChar = comment.codeUnitAt(0);
    if (firstChar == 0x2F) {
      int secondChar = comment.codeUnitAt(1);
      int thirdChar = comment.codeUnitAt(2);
      if ((secondChar == 0x2A && thirdChar == 0x2A) ||
          (secondChar == 0x2F && thirdChar == 0x2F)) {
        index = 3;
      }
    }
    if (StringUtilities.startsWith4(comment, index, 0x20, 0x20, 0x20, 0x20)) {
      int end = index + 4;
      while (end < length &&
          comment.codeUnitAt(end) != 0xD &&
          comment.codeUnitAt(end) != 0xA) {
        end = end + 1;
      }
      ranges.add(<int>[index, end]);
      index = end;
    }
    while (index < length) {
      int currentChar = comment.codeUnitAt(index);
      if (currentChar == 0xD || currentChar == 0xA) {
        index = index + 1;
        while (index < length &&
            Character.isWhitespace(comment.codeUnitAt(index))) {
          index = index + 1;
        }
        if (StringUtilities.startsWith6(
            comment, index, 0x2A, 0x20, 0x20, 0x20, 0x20, 0x20)) {
          int end = index + 6;
          while (end < length &&
              comment.codeUnitAt(end) != 0xD &&
              comment.codeUnitAt(end) != 0xA) {
            end = end + 1;
          }
          ranges.add(<int>[index, end]);
          index = end;
        }
      } else if (index + 1 < length &&
          currentChar == 0x5B &&
          comment.codeUnitAt(index + 1) == 0x3A) {
        int end = StringUtilities.indexOf2(comment, index + 2, 0x3A, 0x5D);
        if (end < 0) {
          end = length;
        }
        ranges.add(<int>[index, end]);
        index = end + 1;
      } else {
        index = index + 1;
      }
    }
    return ranges;
  }

  /**
   * Return the end token associated with the given [beginToken], or `null` if
   * either the given token is not a begin token or it does not have an end
   * token associated with it.
   */
  Token _getEndToken(Token beginToken) {
    if (beginToken is BeginToken) {
      return beginToken.endToken;
    }
    return null;
  }

  bool _injectGenericComment(TokenType type, int prefixLen) {
    if (parseGenericMethodComments) {
      CommentToken t = _currentToken.precedingComments;
      for (; t != null; t = t.next) {
        if (t.type == type) {
          String comment = t.lexeme.substring(prefixLen, t.lexeme.length - 2);
          Token list = _scanGenericMethodComment(comment, t.offset + prefixLen);
          if (list != null) {
            _reportErrorForToken(HintCode.GENERIC_METHOD_COMMENT, t);
            // Remove the token from the comment stream.
            t.remove();
            // Insert the tokens into the stream.
            _injectTokenList(list);
            return true;
          }
        }
      }
    }
    return false;
  }

  /**
   * Matches a generic comment type substitution and injects it into the token
   * stream. Returns true if a match was injected, otherwise false.
   *
   * These comments are of the form `/*=T*/`, in other words, a [TypeName]
   * inside a slash-star comment, preceded by equals sign.
   */
  bool _injectGenericCommentTypeAssign() {
    return _injectGenericComment(TokenType.GENERIC_METHOD_TYPE_ASSIGN, 3);
  }

  /**
   * Matches a generic comment type parameters and injects them into the token
   * stream. Returns true if a match was injected, otherwise false.
   *
   * These comments are of the form `/*<K, V>*/`, in other words, a
   * [TypeParameterList] or [TypeArgumentList] inside a slash-star comment.
   */
  bool _injectGenericCommentTypeList() {
    return _injectGenericComment(TokenType.GENERIC_METHOD_TYPE_LIST, 2);
  }

  /**
   * Inject the given [token] into the token stream immediately before the
   * current token.
   */
  Token _injectToken(Token token) {
    Token previous = _currentToken.previous;
    token.setNext(_currentToken);
    previous.setNext(token);
    return token;
  }

  void _injectTokenList(Token firstToken) {
    // Scanner creates a cyclic EOF token.
    Token lastToken = firstToken;
    while (lastToken.next.type != TokenType.EOF) {
      lastToken = lastToken.next;
    }
    // Inject these new tokens into the stream.
    Token previous = _currentToken.previous;
    lastToken.setNext(_currentToken);
    previous.setNext(firstToken);
    _currentToken = firstToken;
  }

  /**
   * Return `true` if the current token could be the question mark in a
   * condition expression. The current token is assumed to be a question mark.
   */
  bool _isConditionalOperator() {
    void parseOperation(Parser parser) {
      parser.parseExpressionWithoutCascade();
    }

    Token token = _skip(_currentToken.next, parseOperation);
    if (token == null || !_tokenMatches(token, TokenType.COLON)) {
      return false;
    }
    token = _skip(token.next, parseOperation);
    return token != null;
  }

  /**
   * Return `true` if the given [character] is a valid hexadecimal digit.
   */
  bool _isHexDigit(int character) =>
      (0x30 <= character && character <= 0x39) ||
      (0x41 <= character && character <= 0x46) ||
      (0x61 <= character && character <= 0x66);

  bool _isLikelyArgumentList() {
    // Try to reduce the amount of lookahead required here before enabling
    // generic methods.
    if (_matches(TokenType.OPEN_PAREN)) {
      return true;
    }
    Token token = skipTypeArgumentList(_currentToken);
    return token != null && _tokenMatches(token, TokenType.OPEN_PAREN);
  }

  /**
   * Return `true` if it looks like we have found the invocation of a named
   * constructor following the name of the type:
   * ```
   * typeArguments? '.' identifier '('
   * ```
   */
  bool _isLikelyNamedInstanceCreation() {
    Token token = skipTypeArgumentList(_currentToken);
    if (token != null && _tokenMatches(token, TokenType.PERIOD)) {
      token = skipSimpleIdentifier(token.next);
      if (token != null && _tokenMatches(token, TokenType.OPEN_PAREN)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Given that we have just found bracketed text within the given [comment],
   * look to see whether that text is (a) followed by a parenthesized link
   * address, (b) followed by a colon, or (c) followed by optional whitespace
   * and another square bracket. The [rightIndex] is the index of the right
   * bracket. Return `true` if the bracketed text is followed by a link address.
   *
   * This method uses the syntax described by the
   * <a href="http://daringfireball.net/projects/markdown/syntax">markdown</a>
   * project.
   */
  bool _isLinkText(String comment, int rightIndex) {
    int length = comment.length;
    int index = rightIndex + 1;
    if (index >= length) {
      return false;
    }
    int nextChar = comment.codeUnitAt(index);
    if (nextChar == 0x28 || nextChar == 0x3A) {
      return true;
    }
    while (Character.isWhitespace(nextChar)) {
      index = index + 1;
      if (index >= length) {
        return false;
      }
      nextChar = comment.codeUnitAt(index);
    }
    return nextChar == 0x5B;
  }

  /**
   * Return `true` if the given [startToken] appears to be the beginning of an
   * operator declaration.
   */
  bool _isOperator(Token startToken) {
    // Accept any operator here, even if it is not user definable.
    if (!startToken.isOperator) {
      return false;
    }
    // Token "=" means that it is actually a field initializer.
    if (startToken.type == TokenType.EQ) {
      return false;
    }
    // Consume all operator tokens.
    Token token = startToken.next;
    while (token.isOperator) {
      token = token.next;
    }
    // Formal parameter list is expect now.
    return _tokenMatches(token, TokenType.OPEN_PAREN);
  }

  bool _isPeekGenericTypeParametersAndOpenParen() {
    Token token = _skipTypeParameterList(_peek());
    return token != null && _tokenMatches(token, TokenType.OPEN_PAREN);
  }

  /**
   * Return `true` if the [startToken] appears to be the first token of a type
   * name that is followed by a variable or field formal parameter.
   */
  bool _isTypedIdentifier(Token startToken) {
    Token token = skipTypeAnnotation(startToken);
    if (token == null) {
      return false;
    } else if (_tokenMatchesIdentifier(token)) {
      return true;
    } else if (_tokenMatchesKeyword(token, Keyword.THIS) &&
        _tokenMatches(token.next, TokenType.PERIOD) &&
        _tokenMatchesIdentifier(token.next.next)) {
      return true;
    } else if (startToken.next != token &&
        !_tokenMatches(token, TokenType.OPEN_PAREN)) {
      // The type is more than a simple identifier, so it should be assumed to
      // be a type name.
      return true;
    }
    return false;
  }

  /**
   * Return `true` if the given [expression] is a primary expression that is
   * allowed to be an assignable expression without any assignable selector.
   */
  bool _isValidAssignableExpression(Expression expression) {
    if (expression is SimpleIdentifier) {
      return true;
    } else if (expression is PropertyAccess) {
      return expression.target is SuperExpression;
    } else if (expression is IndexExpression) {
      return expression.target is SuperExpression;
    }
    return false;
  }

  /**
   * Increments the error reporting lock level. If level is more than `0`, then
   * [reportError] wont report any error.
   */
  void _lockErrorListener() {
    _errorListenerLock++;
  }

  /**
   * Return `true` if the current token has the given [type]. Note that the
   * method [_matchesGt] should be used if the argument to this method would be
   * [TokenType.GT].
   */
  bool _matches(TokenType type) => _currentToken.type == type;

  /**
   * Return `true` if the current token has a type of [TokenType.GT]. Note that
   * this method, unlike other variants, will modify the token stream if
   * possible to match desired type. In particular, if the next token is either
   * a '>>' or '>>>', the token stream will be re-written and `true` will be
   * returned.
   */
  bool _matchesGt() {
    TokenType currentType = _currentToken.type;
    if (currentType == TokenType.GT) {
      return true;
    } else if (currentType == TokenType.GT_GT) {
      Token first = _createToken(_currentToken, TokenType.GT);
      Token second = new Token(TokenType.GT, _currentToken.offset + 1);
      second.setNext(_currentToken.next);
      first.setNext(second);
      _currentToken.previous.setNext(first);
      _currentToken = first;
      return true;
    } else if (currentType == TokenType.GT_EQ) {
      Token first = _createToken(_currentToken, TokenType.GT);
      Token second = new Token(TokenType.EQ, _currentToken.offset + 1);
      second.setNext(_currentToken.next);
      first.setNext(second);
      _currentToken.previous.setNext(first);
      _currentToken = first;
      return true;
    } else if (currentType == TokenType.GT_GT_EQ) {
      int offset = _currentToken.offset;
      Token first = _createToken(_currentToken, TokenType.GT);
      Token second = new Token(TokenType.GT, offset + 1);
      Token third = new Token(TokenType.EQ, offset + 2);
      third.setNext(_currentToken.next);
      second.setNext(third);
      first.setNext(second);
      _currentToken.previous.setNext(first);
      _currentToken = first;
      return true;
    }
    return false;
  }

  /**
   * Return `true` if the current token is a valid identifier. Valid identifiers
   * include built-in identifiers (pseudo-keywords).
   */
  bool _matchesIdentifier() => _tokenMatchesIdentifier(_currentToken);

  /**
   * Return `true` if the current token matches the given [keyword].
   */
  bool _matchesKeyword(Keyword keyword) =>
      _tokenMatchesKeyword(_currentToken, keyword);

  /**
   * Report an error with the given [errorCode] if the given [typeName] has been
   * marked as nullable.
   */
  void _mustNotBeNullable(TypeName typeName, ParserErrorCode errorCode) {
    if (typeName.question != null) {
      _reportErrorForToken(errorCode, typeName.question);
    }
  }

  /**
   * If the current token has the given [type], then advance to the next token
   * and return `true`. Otherwise, return `false` without advancing. This method
   * should not be invoked with an argument value of [TokenType.GT].
   */
  bool _optional(TokenType type) {
    if (_currentToken.type == type) {
      _advance();
      return true;
    }
    return false;
  }

  /**
   * Parse an argument list when we need to check for an open paren and recover
   * when there isn't one. Return the argument list that was parsed.
   */
  ArgumentList _parseArgumentListChecked() {
    if (_matches(TokenType.OPEN_PAREN)) {
      return parseArgumentList();
    }
    _reportErrorForCurrentToken(
        ParserErrorCode.EXPECTED_TOKEN, [TokenType.OPEN_PAREN.lexeme]);
    // Recovery: Look to see whether there is a close paren that isn't matched
    // to an open paren and if so parse the list of arguments as normal.
    return astFactory.argumentList(_createSyntheticToken(TokenType.OPEN_PAREN),
        null, _createSyntheticToken(TokenType.CLOSE_PAREN));
  }

  /**
   * Parse an assert within a constructor's initializer list. Return the assert.
   *
   * This method assumes that the current token matches `Keyword.ASSERT`.
   *
   *     assertInitializer ::=
   *         'assert' '(' expression [',' expression] ')'
   */
  AssertInitializer _parseAssertInitializer() {
    Token keyword = getAndAdvance();
    Token leftParen = _expect(TokenType.OPEN_PAREN);
    Expression expression = parseExpression2();
    Token comma;
    Expression message;
    if (_matches(TokenType.COMMA)) {
      comma = getAndAdvance();
      if (_matches(TokenType.CLOSE_PAREN)) {
        comma = null;
      } else {
        message = parseExpression2();
        if (_matches(TokenType.COMMA)) {
          getAndAdvance();
        }
      }
    }
    Token rightParen = _expect(TokenType.CLOSE_PAREN);
    return astFactory.assertInitializer(
        keyword, leftParen, expression, comma, message, rightParen);
  }

  /**
   * Parse a block when we need to check for an open curly brace and recover
   * when there isn't one. Return the block that was parsed.
   *
   *     block ::=
   *         '{' statements '}'
   */
  Block _parseBlockChecked() {
    if (_matches(TokenType.OPEN_CURLY_BRACKET)) {
      return parseBlock();
    }
    // TODO(brianwilkerson) Improve the error message.
    _reportErrorForCurrentToken(
        ParserErrorCode.EXPECTED_TOKEN, [TokenType.OPEN_CURLY_BRACKET.lexeme]);
    // Recovery: Check for an unmatched closing curly bracket and parse
    // statements until it is reached.
    return astFactory.block(_createSyntheticToken(TokenType.OPEN_CURLY_BRACKET),
        null, _createSyntheticToken(TokenType.CLOSE_CURLY_BRACKET));
  }

  /**
   * Parse a list of class members. The [className] is the name of the class
   * whose members are being parsed. The [closingBracket] is the closing bracket
   * for the class, or `null` if the closing bracket is missing. Return the list
   * of class members that were parsed.
   *
   *     classMembers ::=
   *         (metadata memberDefinition)*
   */
  List<ClassMember> _parseClassMembers(String className, Token closingBracket) {
    List<ClassMember> members = <ClassMember>[];
    Token memberStart = _currentToken;
    TokenType type = _currentToken.type;
    Keyword keyword = _currentToken.keyword;
    while (type != TokenType.EOF &&
        type != TokenType.CLOSE_CURLY_BRACKET &&
        (closingBracket != null ||
            (keyword != Keyword.CLASS && keyword != Keyword.TYPEDEF))) {
      if (type == TokenType.SEMICOLON) {
        _reportErrorForToken(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken,
            [_currentToken.lexeme]);
        _advance();
      } else {
        ClassMember member = parseClassMember(className);
        if (member != null) {
          members.add(member);
        }
      }
      if (identical(_currentToken, memberStart)) {
        _reportErrorForToken(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken,
            [_currentToken.lexeme]);
        _advance();
      }
      memberStart = _currentToken;
      type = _currentToken.type;
      keyword = _currentToken.keyword;
    }
    return members;
  }

  /**
   * Parse a class type alias. The [commentAndMetadata] is the metadata to be
   * associated with the member. The [abstractKeyword] is the token representing
   * the 'abstract' keyword. The [classKeyword] is the token representing the
   * 'class' keyword. The [className] is the name of the alias, and the
   * [typeParameters] are the type parameters following the name. Return the
   * class type alias that was parsed.
   *
   *     classTypeAlias ::=
   *         identifier typeParameters? '=' 'abstract'? mixinApplication
   *
   *     mixinApplication ::=
   *         type withClause implementsClause? ';'
   */
  ClassTypeAlias _parseClassTypeAliasAfterName(
      CommentAndMetadata commentAndMetadata,
      Token abstractKeyword,
      Token classKeyword,
      SimpleIdentifier className,
      TypeParameterList typeParameters) {
    Token equals = _expect(TokenType.EQ);
    TypeName superclass = parseTypeName(false);
    WithClause withClause = null;
    if (_matchesKeyword(Keyword.WITH)) {
      withClause = parseWithClause();
    } else {
      _reportErrorForCurrentToken(
          ParserErrorCode.EXPECTED_TOKEN, [Keyword.WITH.lexeme]);
    }
    ImplementsClause implementsClause = null;
    if (_matchesKeyword(Keyword.IMPLEMENTS)) {
      implementsClause = parseImplementsClause();
    }
    Token semicolon;
    if (_matches(TokenType.SEMICOLON)) {
      semicolon = getAndAdvance();
    } else {
      if (_matches(TokenType.OPEN_CURLY_BRACKET)) {
        _reportErrorForCurrentToken(
            ParserErrorCode.EXPECTED_TOKEN, [TokenType.SEMICOLON.lexeme]);
        Token leftBracket = getAndAdvance();
        _parseClassMembers(className.name, _getEndToken(leftBracket));
        _expect(TokenType.CLOSE_CURLY_BRACKET);
      } else {
        _reportErrorForToken(ParserErrorCode.EXPECTED_TOKEN,
            _currentToken.previous, [TokenType.SEMICOLON.lexeme]);
      }
      semicolon = _createSyntheticToken(TokenType.SEMICOLON);
    }
    return astFactory.classTypeAlias(
        commentAndMetadata.comment,
        commentAndMetadata.metadata,
        classKeyword,
        className,
        typeParameters,
        equals,
        abstractKeyword,
        superclass,
        withClause,
        implementsClause,
        semicolon);
  }

  /**
   * Parse a list of configurations. Return the configurations that were parsed,
   * or `null` if there are no configurations.
   */
  List<Configuration> _parseConfigurations() {
    List<Configuration> configurations = null;
    while (_matchesKeyword(Keyword.IF)) {
      configurations ??= <Configuration>[];
      configurations.add(parseConfiguration());
    }
    return configurations;
  }

  ConstructorDeclaration _parseConstructor(
      CommentAndMetadata commentAndMetadata,
      Token externalKeyword,
      Token constKeyword,
      Token factoryKeyword,
      SimpleIdentifier returnType,
      Token period,
      SimpleIdentifier name,
      FormalParameterList parameters) {
    bool bodyAllowed = externalKeyword == null;
    Token separator = null;
    List<ConstructorInitializer> initializers = null;
    if (_matches(TokenType.COLON)) {
      separator = getAndAdvance();
      initializers = <ConstructorInitializer>[];
      do {
        Keyword keyword = _currentToken.keyword;
        if (keyword == Keyword.THIS) {
          TokenType nextType = _peek().type;
          if (nextType == TokenType.OPEN_PAREN) {
            bodyAllowed = false;
            initializers.add(parseRedirectingConstructorInvocation(false));
          } else if (nextType == TokenType.PERIOD &&
              _tokenMatches(_peekAt(3), TokenType.OPEN_PAREN)) {
            bodyAllowed = false;
            initializers.add(parseRedirectingConstructorInvocation(true));
          } else {
            initializers.add(parseConstructorFieldInitializer(true));
          }
        } else if (keyword == Keyword.SUPER) {
          initializers.add(parseSuperConstructorInvocation());
        } else if (_matches(TokenType.OPEN_CURLY_BRACKET) ||
            _matches(TokenType.FUNCTION)) {
          _reportErrorForCurrentToken(ParserErrorCode.MISSING_INITIALIZER);
        } else if (_matchesKeyword(Keyword.ASSERT)) {
          initializers.add(_parseAssertInitializer());
        } else {
          initializers.add(parseConstructorFieldInitializer(false));
        }
      } while (_optional(TokenType.COMMA));
      if (factoryKeyword != null) {
        _reportErrorForToken(
            ParserErrorCode.FACTORY_WITH_INITIALIZERS, factoryKeyword);
      }
    }
    ConstructorName redirectedConstructor = null;
    FunctionBody body;
    if (_matches(TokenType.EQ)) {
      separator = getAndAdvance();
      redirectedConstructor = parseConstructorName();
      body = astFactory.emptyFunctionBody(_expect(TokenType.SEMICOLON));
      if (factoryKeyword == null) {
        _reportErrorForNode(
            ParserErrorCode.REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR,
            redirectedConstructor);
      }
    } else {
      body =
          parseFunctionBody(true, ParserErrorCode.MISSING_FUNCTION_BODY, false);
      if (constKeyword != null &&
          factoryKeyword != null &&
          externalKeyword == null &&
          body is! NativeFunctionBody) {
        _reportErrorForToken(ParserErrorCode.CONST_FACTORY, factoryKeyword);
      } else if (body is EmptyFunctionBody) {
        if (factoryKeyword != null &&
            externalKeyword == null &&
            _parseFunctionBodies) {
          _reportErrorForToken(
              ParserErrorCode.FACTORY_WITHOUT_BODY, factoryKeyword);
        }
      } else {
        if (constKeyword != null && body is! NativeFunctionBody) {
          _reportErrorForNode(
              ParserErrorCode.CONST_CONSTRUCTOR_WITH_BODY, body);
        } else if (externalKeyword != null) {
          _reportErrorForNode(
              ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_BODY, body);
        } else if (!bodyAllowed) {
          _reportErrorForNode(
              ParserErrorCode.REDIRECTING_CONSTRUCTOR_WITH_BODY, body);
        }
      }
    }
    return astFactory.constructorDeclaration(
        commentAndMetadata.comment,
        commentAndMetadata.metadata,
        externalKeyword,
        constKeyword,
        factoryKeyword,
        returnType,
        period,
        name,
        parameters,
        separator,
        initializers,
        redirectedConstructor,
        body);
  }

  /**
   * Parse an enum constant declaration. Return the enum constant declaration
   * that was parsed.
   *
   * Specified:
   *
   *     enumConstant ::=
   *         id
   *
   * Actual:
   *
   *     enumConstant ::=
   *         metadata id
   */
  EnumConstantDeclaration _parseEnumConstantDeclaration() {
    CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
    SimpleIdentifier name;
    if (_matchesIdentifier()) {
      name = _parseSimpleIdentifierUnchecked(isDeclaration: true);
    } else {
      name = createSyntheticIdentifier();
    }
    if (commentAndMetadata.hasMetadata) {
      _reportErrorForNode(ParserErrorCode.ANNOTATION_ON_ENUM_CONSTANT,
          commentAndMetadata.metadata[0]);
    }
    return astFactory.enumConstantDeclaration(
        commentAndMetadata.comment, commentAndMetadata.metadata, name);
  }

  /**
   * Parse a list of formal parameters given that the list starts with the given
   * [leftParenthesis]. Return the formal parameters that were parsed.
   */
  FormalParameterList _parseFormalParameterListAfterParen(Token leftParenthesis,
      {bool inFunctionType: false}) {
    if (_matches(TokenType.CLOSE_PAREN)) {
      return astFactory.formalParameterList(
          leftParenthesis, null, null, null, getAndAdvance());
    }
    //
    // Even though it is invalid to have default parameters outside of brackets,
    // required parameters inside of brackets, or multiple groups of default and
    // named parameters, we allow all of these cases so that we can recover
    // better.
    //
    List<FormalParameter> parameters = <FormalParameter>[];
    Token leftSquareBracket = null;
    Token rightSquareBracket = null;
    Token leftCurlyBracket = null;
    Token rightCurlyBracket = null;
    ParameterKind kind = ParameterKind.REQUIRED;
    bool firstParameter = true;
    bool reportedMultiplePositionalGroups = false;
    bool reportedMultipleNamedGroups = false;
    bool reportedMixedGroups = false;
    bool wasOptionalParameter = false;
    Token initialToken = null;
    do {
      if (firstParameter) {
        firstParameter = false;
      } else if (!_optional(TokenType.COMMA)) {
        // TODO(brianwilkerson) The token is wrong, we need to recover from this
        // case.
        if (_getEndToken(leftParenthesis) != null) {
          _reportErrorForCurrentToken(
              ParserErrorCode.EXPECTED_TOKEN, [TokenType.COMMA.lexeme]);
        } else {
          _reportErrorForToken(ParserErrorCode.MISSING_CLOSING_PARENTHESIS,
              _currentToken.previous);
          break;
        }
      }
      initialToken = _currentToken;
      //
      // Handle the beginning of parameter groups.
      //
      TokenType type = _currentToken.type;
      if (type == TokenType.OPEN_SQUARE_BRACKET) {
        wasOptionalParameter = true;
        if (leftSquareBracket != null && !reportedMultiplePositionalGroups) {
          _reportErrorForCurrentToken(
              ParserErrorCode.MULTIPLE_POSITIONAL_PARAMETER_GROUPS);
          reportedMultiplePositionalGroups = true;
        }
        if (leftCurlyBracket != null && !reportedMixedGroups) {
          _reportErrorForCurrentToken(ParserErrorCode.MIXED_PARAMETER_GROUPS);
          reportedMixedGroups = true;
        }
        leftSquareBracket = getAndAdvance();
        kind = ParameterKind.POSITIONAL;
      } else if (type == TokenType.OPEN_CURLY_BRACKET) {
        wasOptionalParameter = true;
        if (leftCurlyBracket != null && !reportedMultipleNamedGroups) {
          _reportErrorForCurrentToken(
              ParserErrorCode.MULTIPLE_NAMED_PARAMETER_GROUPS);
          reportedMultipleNamedGroups = true;
        }
        if (leftSquareBracket != null && !reportedMixedGroups) {
          _reportErrorForCurrentToken(ParserErrorCode.MIXED_PARAMETER_GROUPS);
          reportedMixedGroups = true;
        }
        leftCurlyBracket = getAndAdvance();
        kind = ParameterKind.NAMED;
      }
      //
      // Parse and record the parameter.
      //
      FormalParameter parameter =
          parseFormalParameter(kind, inFunctionType: inFunctionType);
      parameters.add(parameter);
      if (kind == ParameterKind.REQUIRED && wasOptionalParameter) {
        _reportErrorForNode(
            ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS, parameter);
      }
      //
      // Handle the end of parameter groups.
      //
      // TODO(brianwilkerson) Improve the detection and reporting of missing and
      // mismatched delimiters.
      type = _currentToken.type;

      // Advance past trailing commas as appropriate.
      if (type == TokenType.COMMA) {
        // Only parse commas trailing normal (non-positional/named) params.
        if (rightSquareBracket == null && rightCurlyBracket == null) {
          Token next = _peek();
          if (next.type == TokenType.CLOSE_PAREN ||
              next.type == TokenType.CLOSE_CURLY_BRACKET ||
              next.type == TokenType.CLOSE_SQUARE_BRACKET) {
            _advance();
            type = _currentToken.type;
          }
        }
      }

      if (type == TokenType.CLOSE_SQUARE_BRACKET) {
        rightSquareBracket = getAndAdvance();
        if (leftSquareBracket == null) {
          if (leftCurlyBracket != null) {
            _reportErrorForCurrentToken(
                ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP,
                ['}', ']']);
            rightCurlyBracket = rightSquareBracket;
            rightSquareBracket = null;
            // Skip over synthetic closer inserted by fasta
            // since we've already reported an error
            if (_currentToken.type == TokenType.CLOSE_CURLY_BRACKET &&
                _currentToken.isSynthetic) {
              _advance();
            }
          } else {
            _reportErrorForCurrentToken(
                ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP,
                ["["]);
          }
        }
        kind = ParameterKind.REQUIRED;
      } else if (type == TokenType.CLOSE_CURLY_BRACKET) {
        rightCurlyBracket = getAndAdvance();
        if (leftCurlyBracket == null) {
          if (leftSquareBracket != null) {
            _reportErrorForCurrentToken(
                ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP,
                [']', '}']);
            rightSquareBracket = rightCurlyBracket;
            rightCurlyBracket = null;
            // Skip over synthetic closer inserted by fasta
            // since we've already reported an error
            if (_currentToken.type == TokenType.CLOSE_SQUARE_BRACKET &&
                _currentToken.isSynthetic) {
              _advance();
            }
          } else {
            _reportErrorForCurrentToken(
                ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP,
                ["{"]);
          }
        }
        kind = ParameterKind.REQUIRED;
      }
    } while (!_matches(TokenType.CLOSE_PAREN) &&
        !identical(initialToken, _currentToken));
    Token rightParenthesis = _expect(TokenType.CLOSE_PAREN);
    //
    // Check that the groups were closed correctly.
    //
    if (leftSquareBracket != null && rightSquareBracket == null) {
      _reportErrorForCurrentToken(
          ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP, ["]"]);
    }
    if (leftCurlyBracket != null && rightCurlyBracket == null) {
      _reportErrorForCurrentToken(
          ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP, ["}"]);
    }
    //
    // Build the parameter list.
    //
    leftSquareBracket ??= leftCurlyBracket;
    rightSquareBracket ??= rightCurlyBracket;
    return astFactory.formalParameterList(leftParenthesis, parameters,
        leftSquareBracket, rightSquareBracket, rightParenthesis);
  }

  /**
   * Parse a list of formal parameters. Return the formal parameters that were
   * parsed.
   *
   * This method assumes that the current token matches `TokenType.OPEN_PAREN`.
   */
  FormalParameterList _parseFormalParameterListUnchecked(
      {bool inFunctionType: false}) {
    return _parseFormalParameterListAfterParen(getAndAdvance(),
        inFunctionType: inFunctionType);
  }

  /**
   * Parse a function declaration statement. The [commentAndMetadata] is the
   * documentation comment and metadata to be associated with the declaration.
   * The [returnType] is the return type, or `null` if there is no return type.
   * Return the function declaration statement that was parsed.
   *
   *     functionDeclarationStatement ::=
   *         functionSignature functionBody
   */
  Statement _parseFunctionDeclarationStatementAfterReturnType(
      CommentAndMetadata commentAndMetadata, TypeAnnotation returnType) {
    FunctionDeclaration declaration =
        parseFunctionDeclaration(commentAndMetadata, null, returnType);
    Token propertyKeyword = declaration.propertyKeyword;
    if (propertyKeyword != null) {
      if (propertyKeyword.keyword == Keyword.GET) {
        _reportErrorForToken(
            ParserErrorCode.GETTER_IN_FUNCTION, propertyKeyword);
      } else {
        _reportErrorForToken(
            ParserErrorCode.SETTER_IN_FUNCTION, propertyKeyword);
      }
    }
    return astFactory.functionDeclarationStatement(declaration);
  }

  /**
   * Parse a function type alias. The [commentAndMetadata] is the metadata to be
   * associated with the member. The [keyword] is the token representing the
   * 'typedef' keyword. Return the function type alias that was parsed.
   *
   *     functionTypeAlias ::=
   *         functionPrefix typeParameterList? formalParameterList ';'
   *
   *     functionPrefix ::=
   *         returnType? name
   */
  FunctionTypeAlias _parseFunctionTypeAlias(
      CommentAndMetadata commentAndMetadata, Token keyword) {
    TypeAnnotation returnType = null;
    if (hasReturnTypeInTypeAlias) {
      returnType = parseTypeAnnotation(false);
    }
    SimpleIdentifier name = parseSimpleIdentifier(isDeclaration: true);
    TypeParameterList typeParameters = null;
    if (_matches(TokenType.LT)) {
      typeParameters = parseTypeParameterList();
    }
    TokenType type = _currentToken.type;
    if (type == TokenType.SEMICOLON || type == TokenType.EOF) {
      _reportErrorForCurrentToken(ParserErrorCode.MISSING_TYPEDEF_PARAMETERS);
      FormalParameterList parameters = astFactory.formalParameterList(
          _createSyntheticToken(TokenType.OPEN_PAREN),
          null,
          null,
          null,
          _createSyntheticToken(TokenType.CLOSE_PAREN));
      Token semicolon = _expect(TokenType.SEMICOLON);
      return astFactory.functionTypeAlias(
          commentAndMetadata.comment,
          commentAndMetadata.metadata,
          keyword,
          returnType,
          name,
          typeParameters,
          parameters,
          semicolon);
    } else if (type == TokenType.OPEN_PAREN) {
      FormalParameterList parameters = _parseFormalParameterListUnchecked();
      _validateFormalParameterList(parameters);
      Token semicolon = _expect(TokenType.SEMICOLON);
      return astFactory.functionTypeAlias(
          commentAndMetadata.comment,
          commentAndMetadata.metadata,
          keyword,
          returnType,
          name,
          typeParameters,
          parameters,
          semicolon);
    } else {
      _reportErrorForCurrentToken(ParserErrorCode.MISSING_TYPEDEF_PARAMETERS);
      // Recovery: At the very least we should skip to the start of the next
      // valid compilation unit member, allowing for the possibility of finding
      // the typedef parameters before that point.
      return astFactory.functionTypeAlias(
          commentAndMetadata.comment,
          commentAndMetadata.metadata,
          keyword,
          returnType,
          name,
          typeParameters,
          astFactory.formalParameterList(
              _createSyntheticToken(TokenType.OPEN_PAREN),
              null,
              null,
              null,
              _createSyntheticToken(TokenType.CLOSE_PAREN)),
          _createSyntheticToken(TokenType.SEMICOLON));
    }
  }

  /**
   * Parses generic type parameters from a comment.
   *
   * Normally this is handled by [_parseGenericMethodTypeParameters], but if the
   * code already handles the normal generic type parameters, the comment
   * matcher can be called directly. For example, we may have already tried
   * matching `<` (less than sign) in a method declaration, and be currently
   * on the `(` (open paren) because we didn't find it. In that case, this
   * function will parse the preceding comment such as `/*<T, R>*/`.
   */
  TypeParameterList _parseGenericCommentTypeParameters() {
    if (_injectGenericCommentTypeList()) {
      return parseTypeParameterList();
    }
    return null;
  }

  /**
   * Parse the generic method or function's type parameters.
   *
   * For backwards compatibility this can optionally use comments.
   * See [parseGenericMethodComments].
   */
  TypeParameterList _parseGenericMethodTypeParameters() {
    if (_matches(TokenType.LT) || _injectGenericCommentTypeList()) {
      return parseTypeParameterList();
    }
    return null;
  }

  /**
   * Parse a library name. The [missingNameError] is the error code to be used
   * if the library name is missing. The [missingNameToken] is the token
   * associated with the error produced if the library name is missing. Return
   * the library name that was parsed.
   *
   *     libraryName ::=
   *         libraryIdentifier
   */
  LibraryIdentifier _parseLibraryName(
      ParserErrorCode missingNameError, Token missingNameToken) {
    if (_matchesIdentifier()) {
      return parseLibraryIdentifier();
    } else if (_matches(TokenType.STRING)) {
      // Recovery: This should be extended to handle arbitrary tokens until we
      // can find a token that can start a compilation unit member.
      StringLiteral string = parseStringLiteral();
      _reportErrorForNode(ParserErrorCode.NON_IDENTIFIER_LIBRARY_NAME, string);
    } else {
      _reportErrorForToken(missingNameError, missingNameToken);
    }
    return astFactory
        .libraryIdentifier(<SimpleIdentifier>[createSyntheticIdentifier()]);
  }

  /**
   * Parse a method declaration. The [commentAndMetadata] is the documentation
   * comment and metadata to be associated with the declaration. The
   * [externalKeyword] is the 'external' token. The [staticKeyword] is the
   * static keyword, or `null` if the getter is not static. The [returnType] is
   * the return type of the method. The [name] is the name of the method. The
   * [parameters] is the parameters to the method. Return the method declaration
   * that was parsed.
   *
   *     functionDeclaration ::=
   *         ('external' 'static'?)? functionSignature functionBody
   *       | 'external'? functionSignature ';'
   */
  MethodDeclaration _parseMethodDeclarationAfterParameters(
      CommentAndMetadata commentAndMetadata,
      Token externalKeyword,
      Token staticKeyword,
      TypeAnnotation returnType,
      SimpleIdentifier name,
      TypeParameterList typeParameters,
      FormalParameterList parameters) {
    FunctionBody body = parseFunctionBody(
        externalKeyword != null || staticKeyword == null,
        ParserErrorCode.MISSING_FUNCTION_BODY,
        false);
    if (externalKeyword != null) {
      if (body is! EmptyFunctionBody) {
        _reportErrorForNode(ParserErrorCode.EXTERNAL_METHOD_WITH_BODY, body);
      }
    } else if (staticKeyword != null) {
      if (body is EmptyFunctionBody && _parseFunctionBodies) {
        _reportErrorForNode(ParserErrorCode.ABSTRACT_STATIC_METHOD, body);
      }
    }
    return astFactory.methodDeclaration(
        commentAndMetadata.comment,
        commentAndMetadata.metadata,
        externalKeyword,
        staticKeyword,
        returnType,
        null,
        null,
        name,
        typeParameters,
        parameters,
        body);
  }

  /**
   * Parse a method declaration. The [commentAndMetadata] is the documentation
   * comment and metadata to be associated with the declaration. The
   * [externalKeyword] is the 'external' token. The [staticKeyword] is the
   * static keyword, or `null` if the getter is not static. The [returnType] is
   * the return type of the method. Return the method declaration that was
   * parsed.
   *
   *     functionDeclaration ::=
   *         'external'? 'static'? functionSignature functionBody
   *       | 'external'? functionSignature ';'
   */
  MethodDeclaration _parseMethodDeclarationAfterReturnType(
      CommentAndMetadata commentAndMetadata,
      Token externalKeyword,
      Token staticKeyword,
      TypeAnnotation returnType) {
    SimpleIdentifier methodName = parseSimpleIdentifier(isDeclaration: true);
    TypeParameterList typeParameters = _parseGenericMethodTypeParameters();
    FormalParameterList parameters;
    TokenType type = _currentToken.type;
    // TODO(brianwilkerson) Figure out why we care what the current token is if
    // it isn't a paren.
    if (type != TokenType.OPEN_PAREN &&
        (type == TokenType.OPEN_CURLY_BRACKET || type == TokenType.FUNCTION)) {
      _reportErrorForToken(
          ParserErrorCode.MISSING_METHOD_PARAMETERS, _currentToken.previous);
      parameters = astFactory.formalParameterList(
          _createSyntheticToken(TokenType.OPEN_PAREN),
          null,
          null,
          null,
          _createSyntheticToken(TokenType.CLOSE_PAREN));
    } else {
      parameters = parseFormalParameterList();
    }
    _validateFormalParameterList(parameters);
    return _parseMethodDeclarationAfterParameters(
        commentAndMetadata,
        externalKeyword,
        staticKeyword,
        returnType,
        methodName,
        typeParameters,
        parameters);
  }

  /**
   * Parse a class native clause. Return the native clause that was parsed.
   *
   * This method assumes that the current token matches `_NATIVE`.
   *
   *     classNativeClause ::=
   *         'native' name
   */
  NativeClause _parseNativeClause() {
    Token keyword = getAndAdvance();
    StringLiteral name = parseStringLiteral();
    return astFactory.nativeClause(keyword, name);
  }

  /**
   * Parse an operator declaration starting after the 'operator' keyword. The
   * [commentAndMetadata] is the documentation comment and metadata to be
   * associated with the declaration. The [externalKeyword] is the 'external'
   * token. The [returnType] is the return type that has already been parsed, or
   * `null` if there was no return type. The [operatorKeyword] is the 'operator'
   * keyword. Return the operator declaration that was parsed.
   *
   *     operatorDeclaration ::=
   *         operatorSignature (';' | functionBody)
   *
   *     operatorSignature ::=
   *         'external'? returnType? 'operator' operator formalParameterList
   */
  MethodDeclaration _parseOperatorAfterKeyword(
      CommentAndMetadata commentAndMetadata,
      Token externalKeyword,
      TypeAnnotation returnType,
      Token operatorKeyword) {
    if (!_currentToken.isUserDefinableOperator) {
      _reportErrorForCurrentToken(
          _currentToken.type == TokenType.EQ_EQ_EQ
              ? ParserErrorCode.INVALID_OPERATOR
              : ParserErrorCode.NON_USER_DEFINABLE_OPERATOR,
          [_currentToken.lexeme]);
    }
    SimpleIdentifier name =
        astFactory.simpleIdentifier(getAndAdvance(), isDeclaration: true);
    if (_matches(TokenType.EQ)) {
      Token previous = _currentToken.previous;
      if ((_tokenMatches(previous, TokenType.EQ_EQ) ||
              _tokenMatches(previous, TokenType.BANG_EQ)) &&
          _currentToken.offset == previous.offset + 2) {
        _reportErrorForCurrentToken(ParserErrorCode.INVALID_OPERATOR,
            ["${previous.lexeme}${_currentToken.lexeme}"]);
        _advance();
      }
    }
    FormalParameterList parameters = parseFormalParameterList();
    _validateFormalParameterList(parameters);
    FunctionBody body =
        parseFunctionBody(true, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    if (externalKeyword != null && body is! EmptyFunctionBody) {
      _reportErrorForCurrentToken(ParserErrorCode.EXTERNAL_OPERATOR_WITH_BODY);
    }
    return astFactory.methodDeclaration(
        commentAndMetadata.comment,
        commentAndMetadata.metadata,
        externalKeyword,
        null,
        returnType,
        null,
        operatorKeyword,
        name,
        null,
        parameters,
        body);
  }

  /**
   * Parse a return type if one is given, otherwise return `null` without
   * advancing. Return the return type that was parsed.
   */
  TypeAnnotation _parseOptionalReturnType() {
    TypeName typeComment = _parseOptionalTypeNameComment();
    if (typeComment != null) {
      return typeComment;
    }
    Keyword keyword = _currentToken.keyword;
    if (keyword == Keyword.VOID) {
      if (_atGenericFunctionTypeAfterReturnType(_peek())) {
        return parseTypeAnnotation(false);
      }
      return astFactory.typeName(
          astFactory.simpleIdentifier(getAndAdvance()), null);
    } else if (_matchesIdentifier()) {
      Token next = _peek();
      if (keyword != Keyword.GET &&
          keyword != Keyword.SET &&
          keyword != Keyword.OPERATOR &&
          (_tokenMatchesIdentifier(next) ||
              _tokenMatches(next, TokenType.LT))) {
        Token afterTypeParameters = _skipTypeParameterList(next);
        if (afterTypeParameters != null &&
            _tokenMatches(afterTypeParameters, TokenType.OPEN_PAREN)) {
          // If the identifier is followed by type parameters and a parenthesis,
          // then the identifier is the name of a generic method, not a return
          // type.
          return null;
        }
        return parseTypeAnnotation(false);
      }
      Token next2 = next.next;
      Token next3 = next2.next;
      if (_tokenMatches(next, TokenType.PERIOD) &&
          _tokenMatchesIdentifier(next2) &&
          (_tokenMatchesIdentifier(next3) ||
              _tokenMatches(next3, TokenType.LT))) {
        return parseTypeAnnotation(false);
      }
    }
    return null;
  }

  /**
   * Parse a [TypeArgumentList] if present, otherwise return null.
   * This also supports the comment form, if enabled: `/*<T>*/`
   */
  TypeArgumentList _parseOptionalTypeArguments() {
    if (_matches(TokenType.LT) || _injectGenericCommentTypeList()) {
      return parseTypeArgumentList();
    }
    return null;
  }

  TypeName _parseOptionalTypeNameComment() {
    if (_injectGenericCommentTypeAssign()) {
      return _parseTypeName(false);
    }
    return null;
  }

  /**
   * Parse a part directive. The [commentAndMetadata] is the metadata to be
   * associated with the directive. Return the part or part-of directive that
   * was parsed.
   *
   * This method assumes that the current token matches `Keyword.PART`.
   *
   *     partDirective ::=
   *         metadata 'part' stringLiteral ';'
   */
  Directive _parsePartDirective(CommentAndMetadata commentAndMetadata) {
    Token partKeyword = getAndAdvance();
    StringLiteral partUri = _parseUri();
    Token semicolon = _expect(TokenType.SEMICOLON);
    return astFactory.partDirective(commentAndMetadata.comment,
        commentAndMetadata.metadata, partKeyword, partUri, semicolon);
  }

  /**
   * Parse a part-of directive. The [commentAndMetadata] is the metadata to be
   * associated with the directive. Return the part or part-of directive that
   * was parsed.
   *
   * This method assumes that the current token matches [Keyword.PART] and that
   * the following token matches the identifier 'of'.
   *
   *     partOfDirective ::=
   *         metadata 'part' 'of' identifier ';'
   */
  Directive _parsePartOfDirective(CommentAndMetadata commentAndMetadata) {
    Token partKeyword = getAndAdvance();
    Token ofKeyword = getAndAdvance();
    if (enableUriInPartOf && _matches(TokenType.STRING)) {
      StringLiteral libraryUri = _parseUri();
      Token semicolon = _expect(TokenType.SEMICOLON);
      return astFactory.partOfDirective(
          commentAndMetadata.comment,
          commentAndMetadata.metadata,
          partKeyword,
          ofKeyword,
          libraryUri,
          null,
          semicolon);
    }
    LibraryIdentifier libraryName = _parseLibraryName(
        ParserErrorCode.MISSING_NAME_IN_PART_OF_DIRECTIVE, ofKeyword);
    Token semicolon = _expect(TokenType.SEMICOLON);
    return astFactory.partOfDirective(
        commentAndMetadata.comment,
        commentAndMetadata.metadata,
        partKeyword,
        ofKeyword,
        null,
        libraryName,
        semicolon);
  }

  /**
   * Parse a prefixed identifier given that the given [qualifier] was already
   * parsed. Return the prefixed identifier that was parsed.
   *
   *     prefixedIdentifier ::=
   *         identifier ('.' identifier)?
   */
  Identifier _parsePrefixedIdentifierAfterIdentifier(
      SimpleIdentifier qualifier) {
    if (!_matches(TokenType.PERIOD) || _injectGenericCommentTypeList()) {
      return qualifier;
    }
    Token period = getAndAdvance();
    SimpleIdentifier qualified = parseSimpleIdentifier();
    return astFactory.prefixedIdentifier(qualifier, period, qualified);
  }

  /**
   * Parse a prefixed identifier. Return the prefixed identifier that was
   * parsed.
   *
   * This method assumes that the current token matches an identifier.
   *
   *     prefixedIdentifier ::=
   *         identifier ('.' identifier)?
   */
  Identifier _parsePrefixedIdentifierUnchecked() {
    return _parsePrefixedIdentifierAfterIdentifier(
        _parseSimpleIdentifierUnchecked());
  }

  /**
   * Parse a simple identifier. Return the simple identifier that was parsed.
   *
   * This method assumes that the current token matches an identifier.
   *
   *     identifier ::=
   *         IDENTIFIER
   */
  SimpleIdentifier _parseSimpleIdentifierUnchecked(
      {bool isDeclaration: false}) {
    String lexeme = _currentToken.lexeme;
    if ((_inAsync || _inGenerator) &&
        (lexeme == ASYNC || lexeme == _AWAIT || lexeme == _YIELD)) {
      _reportErrorForCurrentToken(
          ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER);
    }
    return astFactory.simpleIdentifier(getAndAdvance(),
        isDeclaration: isDeclaration);
  }

  /**
   * Parse a list of statements within a switch statement. Return the statements
   * that were parsed.
   *
   *     statements ::=
   *         statement*
   */
  List<Statement> _parseStatementList() {
    List<Statement> statements = <Statement>[];
    Token statementStart = _currentToken;
    TokenType type = _currentToken.type;
    while (type != TokenType.EOF &&
        type != TokenType.CLOSE_CURLY_BRACKET &&
        !isSwitchMember()) {
      statements.add(parseStatement2());
      if (identical(_currentToken, statementStart)) {
        _reportErrorForToken(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken,
            [_currentToken.lexeme]);
        _advance();
      }
      statementStart = _currentToken;
      type = _currentToken.type;
    }
    return statements;
  }

  /**
   * Parse a string literal that contains interpolations. Return the string
   * literal that was parsed.
   *
   * This method assumes that the current token matches either
   * [TokenType.STRING_INTERPOLATION_EXPRESSION] or
   * [TokenType.STRING_INTERPOLATION_IDENTIFIER].
   */
  StringInterpolation _parseStringInterpolation(Token string) {
    List<InterpolationElement> elements = <InterpolationElement>[
      astFactory.interpolationString(
          string, computeStringValue(string.lexeme, true, false))
    ];
    bool hasMore = true;
    bool isExpression = _matches(TokenType.STRING_INTERPOLATION_EXPRESSION);
    while (hasMore) {
      if (isExpression) {
        Token openToken = getAndAdvance();
        bool wasInInitializer = _inInitializer;
        _inInitializer = false;
        try {
          Expression expression = parseExpression2();
          Token rightBracket = _expect(TokenType.CLOSE_CURLY_BRACKET);
          elements.add(astFactory.interpolationExpression(
              openToken, expression, rightBracket));
        } finally {
          _inInitializer = wasInInitializer;
        }
      } else {
        Token openToken = getAndAdvance();
        Expression expression = null;
        if (_matchesKeyword(Keyword.THIS)) {
          expression = astFactory.thisExpression(getAndAdvance());
        } else {
          expression = parseSimpleIdentifier();
        }
        elements.add(
            astFactory.interpolationExpression(openToken, expression, null));
      }
      if (_matches(TokenType.STRING)) {
        string = getAndAdvance();
        isExpression = _matches(TokenType.STRING_INTERPOLATION_EXPRESSION);
        hasMore =
            isExpression || _matches(TokenType.STRING_INTERPOLATION_IDENTIFIER);
        elements.add(astFactory.interpolationString(
            string, computeStringValue(string.lexeme, false, !hasMore)));
      } else {
        hasMore = false;
      }
    }
    return astFactory.stringInterpolation(elements);
  }

  /**
   * Parse a string literal. Return the string literal that was parsed.
   *
   * This method assumes that the current token matches `TokenType.STRING`.
   *
   *     stringLiteral ::=
   *         MULTI_LINE_STRING+
   *       | SINGLE_LINE_STRING+
   */
  StringLiteral _parseStringLiteralUnchecked() {
    List<StringLiteral> strings = <StringLiteral>[];
    do {
      Token string = getAndAdvance();
      if (_matches(TokenType.STRING_INTERPOLATION_EXPRESSION) ||
          _matches(TokenType.STRING_INTERPOLATION_IDENTIFIER)) {
        strings.add(_parseStringInterpolation(string));
      } else {
        strings.add(astFactory.simpleStringLiteral(
            string, computeStringValue(string.lexeme, true, true)));
      }
    } while (_matches(TokenType.STRING));
    return strings.length == 1
        ? strings[0]
        : astFactory.adjacentStrings(strings);
  }

  /**
   * Parse a type annotation, possibly superseded by a type name in a comment.
   * Return the type name that was parsed.
   *
   * This method assumes that the current token is an identifier.
   *
   *     type ::=
   *         qualified typeArguments?
   */
  TypeAnnotation _parseTypeAnnotationAfterIdentifier() {
    TypeAnnotation type = parseTypeAnnotation(false);
    // If this is followed by a generic method type comment, allow the comment
    // type to replace the real type name.
    TypeName typeFromComment = _parseOptionalTypeNameComment();
    return typeFromComment ?? type;
  }

  TypeName _parseTypeName(bool inExpression) {
    Identifier typeName;
    if (_matchesIdentifier()) {
      typeName = _parsePrefixedIdentifierUnchecked();
    } else if (_matchesKeyword(Keyword.VAR)) {
      _reportErrorForCurrentToken(ParserErrorCode.VAR_AS_TYPE_NAME);
      typeName = astFactory.simpleIdentifier(getAndAdvance());
    } else {
      typeName = createSyntheticIdentifier();
      _reportErrorForCurrentToken(ParserErrorCode.EXPECTED_TYPE_NAME);
    }
    TypeArgumentList typeArguments = _parseOptionalTypeArguments();
    Token question = null;
    if (enableNnbd && _matches(TokenType.QUESTION)) {
      if (!inExpression || !_isConditionalOperator()) {
        question = getAndAdvance();
      }
    }
    return astFactory.typeName(typeName, typeArguments, question: question);
  }

  /**
   * Parse a string literal representing a URI. Return the string literal that
   * was parsed.
   */
  StringLiteral _parseUri() {
    // TODO(brianwilkerson) Should this function also return true for valid
    // top-level keywords?
    bool isKeywordAfterUri(Token token) =>
        token.lexeme == Keyword.AS.lexeme ||
        token.lexeme == _HIDE ||
        token.lexeme == _SHOW;
    TokenType type = _currentToken.type;
    if (type != TokenType.STRING &&
        type != TokenType.SEMICOLON &&
        !isKeywordAfterUri(_currentToken)) {
      // Attempt to recover in the case where the URI was not enclosed in
      // quotes.
      Token token = _currentToken;
      bool isValidInUri(Token token) {
        TokenType type = token.type;
        return type == TokenType.COLON ||
            type == TokenType.SLASH ||
            type == TokenType.PERIOD ||
            type == TokenType.PERIOD_PERIOD ||
            type == TokenType.PERIOD_PERIOD_PERIOD ||
            type == TokenType.INT ||
            type == TokenType.DOUBLE;
      }

      while ((_tokenMatchesIdentifier(token) && !isKeywordAfterUri(token)) ||
          isValidInUri(token)) {
        token = token.next;
      }
      if (_tokenMatches(token, TokenType.SEMICOLON) ||
          isKeywordAfterUri(token)) {
        Token endToken = token.previous;
        token = _currentToken;
        int endOffset = token.end;
        StringBuffer buffer = new StringBuffer();
        buffer.write(token.lexeme);
        while (token != endToken) {
          token = token.next;
          if (token.offset != endOffset || token.precedingComments != null) {
            return parseStringLiteral();
          }
          buffer.write(token.lexeme);
          endOffset = token.end;
        }
        String value = buffer.toString();
        Token newToken =
            new StringToken(TokenType.STRING, "'$value'", _currentToken.offset);
        _reportErrorForToken(
            ParserErrorCode.NON_STRING_LITERAL_AS_URI, newToken);
        _currentToken = endToken.next;
        return astFactory.simpleStringLiteral(newToken, value);
      }
    }
    return parseStringLiteral();
  }

  /**
   * Parse a variable declaration statement. The [commentAndMetadata] is the
   * metadata to be associated with the variable declaration statement, or
   * `null` if there is no attempt at parsing the comment and metadata. The
   * [keyword] is the token representing the 'final', 'const' or 'var' keyword,
   * or `null` if there is no keyword. The [type] is the type of the variables
   * in the list. Return the variable declaration statement that was parsed.
   *
   *     variableDeclarationStatement ::=
   *         variableDeclarationList ';'
   */
  VariableDeclarationStatement _parseVariableDeclarationStatementAfterType(
      CommentAndMetadata commentAndMetadata,
      Token keyword,
      TypeAnnotation type) {
    VariableDeclarationList variableList =
        parseVariableDeclarationListAfterType(
            commentAndMetadata, keyword, type);
    Token semicolon = _expect(TokenType.SEMICOLON);
    return astFactory.variableDeclarationStatement(variableList, semicolon);
  }

  /**
   * Return the token that is immediately after the current token. This is
   * equivalent to [_peekAt](1).
   */
  Token _peek() => _currentToken.next;

  /**
   * Return the token that is the given [distance] after the current token,
   * where the distance is the number of tokens to look ahead. A distance of `0`
   * is the current token, `1` is the next token, etc.
   */
  Token _peekAt(int distance) {
    Token token = _currentToken;
    for (int i = 0; i < distance; i++) {
      token = token.next;
    }
    return token;
  }

  String _removeGitHubInlineCode(String comment) {
    int index = 0;
    while (true) {
      int beginIndex = comment.indexOf('`', index);
      if (beginIndex == -1) {
        break;
      }
      int endIndex = comment.indexOf('`', beginIndex + 1);
      if (endIndex == -1) {
        break;
      }
      comment = comment.substring(0, beginIndex + 1) +
          ' ' * (endIndex - beginIndex - 1) +
          comment.substring(endIndex);
      index = endIndex + 1;
    }
    return comment;
  }

  /**
   * Report the given [error].
   */
  void _reportError(AnalysisError error) {
    if (_errorListenerLock != 0) {
      return;
    }
    _errorListener.onError(error);
  }

  /**
   * Report an error with the given [errorCode] and [arguments] associated with
   * the current token.
   */
  void _reportErrorForCurrentToken(ParserErrorCode errorCode,
      [List<Object> arguments]) {
    _reportErrorForToken(errorCode, _currentToken, arguments);
  }

  /**
   * Report an error with the given [errorCode] and [arguments] associated with
   * the given [node].
   */
  void _reportErrorForNode(ParserErrorCode errorCode, AstNode node,
      [List<Object> arguments]) {
    _reportError(new AnalysisError(
        _source, node.offset, node.length, errorCode, arguments));
  }

  /**
   * Report an error with the given [errorCode] and [arguments] associated with
   * the given [token].
   */
  void _reportErrorForToken(ErrorCode errorCode, Token token,
      [List<Object> arguments]) {
    if (token.type == TokenType.EOF) {
      token = token.previous;
    }
    _reportError(new AnalysisError(_source, token.offset,
        math.max(token.length, 1), errorCode, arguments));
  }

  /**
   * Scans the generic method comment, and returns the tokens, otherwise
   * returns null.
   */
  Token _scanGenericMethodComment(String code, int offset) {
    BooleanErrorListener listener = new BooleanErrorListener();
    Scanner scanner =
        new Scanner(null, new SubSequenceReader(code, offset), listener);
    scanner.setSourceStart(1, 1);
    Token firstToken = scanner.tokenize();
    if (listener.errorReported) {
      return null;
    }
    return firstToken;
  }

  /**
   * Execute the given [parseOperation] in a temporary parser whose current
   * token has been set to the given [startToken]. If the parse does not
   * generate any errors or exceptions, then return the token following the
   * matching portion of the token stream. Otherwise, return `null`.
   *
   * Note: This is an extremely inefficient way of testing whether the tokens in
   * the token stream match a given production. It should not be used for
   * production code.
   */
  Token _skip(Token startToken, parseOperation(Parser parser)) {
    BooleanErrorListener listener = new BooleanErrorListener();
    Parser parser = new Parser(_source, listener);
    parser._currentToken = _cloneTokens(startToken);
    parser._enableNnbd = _enableNnbd;
    parser._enableOptionalNewAndConst = _enableOptionalNewAndConst;
    parser._inAsync = _inAsync;
    parser._inGenerator = _inGenerator;
    parser._inInitializer = _inInitializer;
    parser._inLoop = _inLoop;
    parser._inSwitch = _inSwitch;
    parser._parseFunctionBodies = _parseFunctionBodies;
    try {
      parseOperation(parser);
    } catch (exception) {
      return null;
    }
    if (listener.errorReported) {
      return null;
    }
    return parser._currentToken;
  }

  /**
   * Skips a block with all containing blocks.
   */
  void _skipBlock() {
    Token endToken = (_currentToken as BeginToken).endToken;
    if (endToken == null) {
      endToken = _currentToken.next;
      while (!identical(endToken, _currentToken)) {
        _currentToken = endToken;
        endToken = _currentToken.next;
      }
      _reportErrorForToken(
          ParserErrorCode.EXPECTED_TOKEN, _currentToken.previous, ["}"]);
    } else {
      _currentToken = endToken.next;
    }
  }

  /**
   * Parse the 'final', 'const', 'var' or type preceding a variable declaration,
   * starting at the given token, without actually creating a type or changing
   * the current token. Return the token following the type that was parsed, or
   * `null` if the given token is not the first token in a valid type. The
   * [startToken] is the token at which parsing is to begin. Return the token
   * following the type that was parsed.
   *
   * finalConstVarOrType ::=
   *   | 'final' type?
   *   | 'const' type?
   *   | 'var'
   *   | type
   */
  Token _skipFinalConstVarOrType(Token startToken) {
    Keyword keyword = startToken.keyword;
    if (keyword == Keyword.FINAL || keyword == Keyword.CONST) {
      Token next = startToken.next;
      if (_tokenMatchesIdentifier(next)) {
        Token next2 = next.next;
        // "Type parameter" or "Type<" or "prefix.Type"
        if (_tokenMatchesIdentifier(next2) ||
            _tokenMatches(next2, TokenType.LT) ||
            _tokenMatches(next2, TokenType.PERIOD)) {
          return skipTypeName(next);
        }
        // "parameter"
        return next;
      }
    } else if (keyword == Keyword.VAR) {
      return startToken.next;
    } else if (_tokenMatchesIdentifier(startToken)) {
      Token next = startToken.next;
      if (_tokenMatchesIdentifier(next) ||
          _tokenMatches(next, TokenType.LT) ||
          _tokenMatchesKeyword(next, Keyword.THIS) ||
          (_tokenMatches(next, TokenType.PERIOD) &&
              _tokenMatchesIdentifier(next.next) &&
              (_tokenMatchesIdentifier(next.next.next) ||
                  _tokenMatches(next.next.next, TokenType.LT) ||
                  _tokenMatchesKeyword(next.next.next, Keyword.THIS)))) {
        return skipTypeAnnotation(startToken);
      }
    }
    return null;
  }

  /**
   * Parse a list of formal parameters, starting at the [startToken], without
   * actually creating a formal parameter list or changing the current token.
   * Return the token following the formal parameter list that was parsed, or
   * `null` if the given token is not the first token in a valid list of formal
   * parameter.
   *
   * Note that unlike other skip methods, this method uses a heuristic. In the
   * worst case, the parameters could be prefixed by metadata, which would
   * require us to be able to skip arbitrary expressions. Rather than duplicate
   * the logic of most of the parse methods we simply look for something that is
   * likely to be a list of parameters and then skip to returning the token
   * after the closing parenthesis.
   *
   * This method must be kept in sync with [parseFormalParameterList].
   *
   *     formalParameterList ::=
   *         '(' ')'
   *       | '(' normalFormalParameters (',' optionalFormalParameters)? ')'
   *       | '(' optionalFormalParameters ')'
   *
   *     normalFormalParameters ::=
   *         normalFormalParameter (',' normalFormalParameter)*
   *
   *     optionalFormalParameters ::=
   *         optionalPositionalFormalParameters
   *       | namedFormalParameters
   *
   *     optionalPositionalFormalParameters ::=
   *         '[' defaultFormalParameter (',' defaultFormalParameter)* ']'
   *
   *     namedFormalParameters ::=
   *         '{' defaultNamedParameter (',' defaultNamedParameter)* '}'
   */
  Token _skipFormalParameterList(Token startToken) {
    if (!_tokenMatches(startToken, TokenType.OPEN_PAREN)) {
      return null;
    }
    Token next = startToken.next;
    if (_tokenMatches(next, TokenType.CLOSE_PAREN)) {
      return next.next;
    }
    //
    // Look to see whether the token after the open parenthesis is something
    // that should only occur at the beginning of a parameter list.
    //
    if (next.matchesAny(const <TokenType>[
          TokenType.AT,
          TokenType.OPEN_SQUARE_BRACKET,
          TokenType.OPEN_CURLY_BRACKET
        ]) ||
        _tokenMatchesKeyword(next, Keyword.VOID) ||
        (_tokenMatchesIdentifier(next) &&
            (next.next.matchesAny(
                const <TokenType>[TokenType.COMMA, TokenType.CLOSE_PAREN])))) {
      return _skipPastMatchingToken(startToken);
    }
    //
    // Look to see whether the first parameter is a function typed parameter
    // without a return type.
    //
    if (_tokenMatchesIdentifier(next) &&
        _tokenMatches(next.next, TokenType.OPEN_PAREN)) {
      Token afterParameters = _skipFormalParameterList(next.next);
      if (afterParameters != null &&
          afterParameters.matchesAny(
              const <TokenType>[TokenType.COMMA, TokenType.CLOSE_PAREN])) {
        return _skipPastMatchingToken(startToken);
      }
    }
    //
    // Look to see whether the first parameter has a type or is a function typed
    // parameter with a return type.
    //
    Token afterType = _skipFinalConstVarOrType(next);
    if (afterType == null) {
      return null;
    }
    if (skipSimpleIdentifier(afterType) == null) {
      return null;
    }
    return _skipPastMatchingToken(startToken);
  }

  /**
   * If the [startToken] is a begin token with an associated end token, then
   * return the token following the end token. Otherwise, return `null`.
   */
  Token _skipPastMatchingToken(Token startToken) {
    if (startToken is! BeginToken) {
      return null;
    }
    Token closeParen = (startToken as BeginToken).endToken;
    if (closeParen == null) {
      return null;
    }
    return closeParen.next;
  }

  /**
   * Parse a string literal that contains interpolations, starting at the
   * [startToken], without actually creating a string literal or changing the
   * current token. Return the token following the string literal that was
   * parsed, or `null` if the given token is not the first token in a valid
   * string literal.
   *
   * This method must be kept in sync with [parseStringInterpolation].
   */
  Token _skipStringInterpolation(Token startToken) {
    Token token = startToken;
    TokenType type = token.type;
    while (type == TokenType.STRING_INTERPOLATION_EXPRESSION ||
        type == TokenType.STRING_INTERPOLATION_IDENTIFIER) {
      if (type == TokenType.STRING_INTERPOLATION_EXPRESSION) {
        token = token.next;
        type = token.type;
        //
        // Rather than verify that the following tokens represent a valid
        // expression, we simply skip tokens until we reach the end of the
        // interpolation, being careful to handle nested string literals.
        //
        int bracketNestingLevel = 1;
        while (bracketNestingLevel > 0) {
          if (type == TokenType.EOF) {
            return null;
          } else if (type == TokenType.OPEN_CURLY_BRACKET) {
            bracketNestingLevel++;
            token = token.next;
          } else if (type == TokenType.CLOSE_CURLY_BRACKET) {
            bracketNestingLevel--;
            token = token.next;
          } else if (type == TokenType.STRING) {
            token = skipStringLiteral(token);
            if (token == null) {
              return null;
            }
          } else {
            token = token.next;
          }
          type = token.type;
        }
        token = token.next;
        type = token.type;
      } else {
        token = token.next;
        if (token.type != TokenType.IDENTIFIER) {
          return null;
        }
        token = token.next;
      }
      type = token.type;
      if (type == TokenType.STRING) {
        token = token.next;
        type = token.type;
      }
    }
    return token;
  }

  /**
   * Parse a list of type parameters, starting at the [startToken], without
   * actually creating a type parameter list or changing the current token.
   * Return the token following the type parameter list that was parsed, or
   * `null` if the given token is not the first token in a valid type parameter
   * list.
   *
   * This method must be kept in sync with [parseTypeParameterList].
   *
   *     typeParameterList ::=
   *         '<' typeParameter (',' typeParameter)* '>'
   */
  Token _skipTypeParameterList(Token startToken) {
    if (!_tokenMatches(startToken, TokenType.LT)) {
      return null;
    }
    //
    // We can't skip a type parameter because it can be preceeded by metadata,
    // so we just assume that everything before the matching end token is valid.
    //
    int depth = 1;
    Token next = startToken.next;
    while (depth > 0) {
      if (_tokenMatches(next, TokenType.EOF)) {
        return null;
      } else if (_tokenMatches(next, TokenType.LT)) {
        depth++;
      } else if (_tokenMatches(next, TokenType.GT)) {
        depth--;
      } else if (_tokenMatches(next, TokenType.GT_EQ)) {
        if (depth == 1) {
          Token fakeEquals = new Token(TokenType.EQ, next.offset + 2);
          fakeEquals.setNextWithoutSettingPrevious(next.next);
          return fakeEquals;
        }
        depth--;
      } else if (_tokenMatches(next, TokenType.GT_GT)) {
        depth -= 2;
      } else if (_tokenMatches(next, TokenType.GT_GT_EQ)) {
        if (depth < 2) {
          return null;
        } else if (depth == 2) {
          Token fakeEquals = new Token(TokenType.EQ, next.offset + 2);
          fakeEquals.setNextWithoutSettingPrevious(next.next);
          return fakeEquals;
        }
        depth -= 2;
      }
      next = next.next;
    }
    return next;
  }

  /**
   * Assuming that the current token is an index token ('[]'), split it into two
   * tokens ('[' and ']'), leaving the left bracket as the current token.
   */
  void _splitIndex() {
    // Split the token into two separate tokens.
    BeginToken leftBracket = _createToken(
        _currentToken, TokenType.OPEN_SQUARE_BRACKET,
        isBegin: true);
    Token rightBracket =
        new Token(TokenType.CLOSE_SQUARE_BRACKET, _currentToken.offset + 1);
    leftBracket.endToken = rightBracket;
    rightBracket.setNext(_currentToken.next);
    leftBracket.setNext(rightBracket);
    _currentToken.previous.setNext(leftBracket);
    _currentToken = leftBracket;
  }

  /**
   * Return `true` if the given [token] has the given [type].
   */
  bool _tokenMatches(Token token, TokenType type) => token.type == type;

  /**
   * Return `true` if the given [token] is a valid identifier. Valid identifiers
   * include built-in identifiers (pseudo-keywords).
   */
  bool _tokenMatchesIdentifier(Token token) =>
      _tokenMatches(token, TokenType.IDENTIFIER) ||
      _tokenMatchesPseudoKeyword(token);

  /**
   * Return `true` if the given [token] is either an identifier or a keyword.
   */
  bool _tokenMatchesIdentifierOrKeyword(Token token) =>
      _tokenMatches(token, TokenType.IDENTIFIER) || token.type.isKeyword;

  /**
   * Return `true` if the given [token] matches the given [keyword].
   */
  bool _tokenMatchesKeyword(Token token, Keyword keyword) =>
      token.keyword == keyword;

  /**
   * Return `true` if the given [token] matches a pseudo keyword.
   */
  bool _tokenMatchesPseudoKeyword(Token token) =>
      token.keyword?.isBuiltInOrPseudo ?? false;

  /**
   * Translate the characters at the given [index] in the given [lexeme],
   * appending the translated character to the given [buffer]. The index is
   * assumed to be valid.
   */
  int _translateCharacter(StringBuffer buffer, String lexeme, int index) {
    int currentChar = lexeme.codeUnitAt(index);
    if (currentChar != 0x5C) {
      buffer.writeCharCode(currentChar);
      return index + 1;
    }
    //
    // We have found an escape sequence, so we parse the string to determine
    // what kind of escape sequence and what character to add to the builder.
    //
    int length = lexeme.length;
    int currentIndex = index + 1;
    if (currentIndex >= length) {
      // Illegal escape sequence: no char after escape.
      // This cannot actually happen because it would require the escape
      // character to be the last character in the string, but if it were it
      // would escape the closing quote, leaving the string unclosed.
      // reportError(ParserErrorCode.MISSING_CHAR_IN_ESCAPE_SEQUENCE);
      return length;
    }
    currentChar = lexeme.codeUnitAt(currentIndex);
    if (currentChar == 0x6E) {
      buffer.writeCharCode(0xA);
      // newline
    } else if (currentChar == 0x72) {
      buffer.writeCharCode(0xD);
      // carriage return
    } else if (currentChar == 0x66) {
      buffer.writeCharCode(0xC);
      // form feed
    } else if (currentChar == 0x62) {
      buffer.writeCharCode(0x8);
      // backspace
    } else if (currentChar == 0x74) {
      buffer.writeCharCode(0x9);
      // tab
    } else if (currentChar == 0x76) {
      buffer.writeCharCode(0xB);
      // vertical tab
    } else if (currentChar == 0x78) {
      if (currentIndex + 2 >= length) {
        // Illegal escape sequence: not enough hex digits
        _reportErrorForCurrentToken(ParserErrorCode.INVALID_HEX_ESCAPE);
        return length;
      }
      int firstDigit = lexeme.codeUnitAt(currentIndex + 1);
      int secondDigit = lexeme.codeUnitAt(currentIndex + 2);
      if (!_isHexDigit(firstDigit) || !_isHexDigit(secondDigit)) {
        // Illegal escape sequence: invalid hex digit
        _reportErrorForCurrentToken(ParserErrorCode.INVALID_HEX_ESCAPE);
      } else {
        int charCode = (Character.digit(firstDigit, 16) << 4) +
            Character.digit(secondDigit, 16);
        buffer.writeCharCode(charCode);
      }
      return currentIndex + 3;
    } else if (currentChar == 0x75) {
      currentIndex++;
      if (currentIndex >= length) {
        // Illegal escape sequence: not enough hex digits
        _reportErrorForCurrentToken(ParserErrorCode.INVALID_UNICODE_ESCAPE);
        return length;
      }
      currentChar = lexeme.codeUnitAt(currentIndex);
      if (currentChar == 0x7B) {
        currentIndex++;
        if (currentIndex >= length) {
          // Illegal escape sequence: incomplete escape
          _reportErrorForCurrentToken(ParserErrorCode.INVALID_UNICODE_ESCAPE);
          return length;
        }
        currentChar = lexeme.codeUnitAt(currentIndex);
        int digitCount = 0;
        int value = 0;
        while (currentChar != 0x7D) {
          if (!_isHexDigit(currentChar)) {
            // Illegal escape sequence: invalid hex digit
            _reportErrorForCurrentToken(ParserErrorCode.INVALID_UNICODE_ESCAPE);
            currentIndex++;
            while (currentIndex < length &&
                lexeme.codeUnitAt(currentIndex) != 0x7D) {
              currentIndex++;
            }
            return currentIndex + 1;
          }
          digitCount++;
          value = (value << 4) + Character.digit(currentChar, 16);
          currentIndex++;
          if (currentIndex >= length) {
            // Illegal escape sequence: incomplete escape
            _reportErrorForCurrentToken(ParserErrorCode.INVALID_UNICODE_ESCAPE);
            return length;
          }
          currentChar = lexeme.codeUnitAt(currentIndex);
        }
        if (digitCount < 1 || digitCount > 6) {
          // Illegal escape sequence: not enough or too many hex digits
          _reportErrorForCurrentToken(ParserErrorCode.INVALID_UNICODE_ESCAPE);
        }
        _appendCodePoint(buffer, lexeme, value, index, currentIndex);
        return currentIndex + 1;
      } else {
        if (currentIndex + 3 >= length) {
          // Illegal escape sequence: not enough hex digits
          _reportErrorForCurrentToken(ParserErrorCode.INVALID_UNICODE_ESCAPE);
          return length;
        }
        int firstDigit = currentChar;
        int secondDigit = lexeme.codeUnitAt(currentIndex + 1);
        int thirdDigit = lexeme.codeUnitAt(currentIndex + 2);
        int fourthDigit = lexeme.codeUnitAt(currentIndex + 3);
        if (!_isHexDigit(firstDigit) ||
            !_isHexDigit(secondDigit) ||
            !_isHexDigit(thirdDigit) ||
            !_isHexDigit(fourthDigit)) {
          // Illegal escape sequence: invalid hex digits
          _reportErrorForCurrentToken(ParserErrorCode.INVALID_UNICODE_ESCAPE);
        } else {
          _appendCodePoint(
              buffer,
              lexeme,
              (((((Character.digit(firstDigit, 16) << 4) +
                                  Character.digit(secondDigit, 16)) <<
                              4) +
                          Character.digit(thirdDigit, 16)) <<
                      4) +
                  Character.digit(fourthDigit, 16),
              index,
              currentIndex + 3);
        }
        return currentIndex + 4;
      }
    } else {
      buffer.writeCharCode(currentChar);
    }
    return currentIndex + 1;
  }

  /**
   * Decrements the error reporting lock level. If level is more than `0`, then
   * [reportError] wont report any error.
   */
  void _unlockErrorListener() {
    if (_errorListenerLock == 0) {
      throw new StateError("Attempt to unlock not locked error listener.");
    }
    _errorListenerLock--;
  }

  /**
   * Validate that the given [parameterList] does not contain any field
   * initializers.
   */
  void _validateFormalParameterList(FormalParameterList parameterList) {
    for (FormalParameter parameter in parameterList.parameters) {
      if (parameter is FieldFormalParameter) {
        _reportErrorForNode(
            ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR,
            parameter.identifier);
      }
    }
  }

  /**
   * Validate that the given set of [modifiers] is appropriate for a class and
   * return the 'abstract' keyword if there is one.
   */
  Token _validateModifiersForClass(Modifiers modifiers) {
    _validateModifiersForTopLevelDeclaration(modifiers);
    if (modifiers.constKeyword != null) {
      _reportErrorForToken(ParserErrorCode.CONST_CLASS, modifiers.constKeyword);
    }
    if (modifiers.externalKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.EXTERNAL_CLASS, modifiers.externalKeyword);
    }
    if (modifiers.finalKeyword != null) {
      _reportErrorForToken(ParserErrorCode.FINAL_CLASS, modifiers.finalKeyword);
    }
    if (modifiers.varKeyword != null) {
      _reportErrorForToken(ParserErrorCode.VAR_CLASS, modifiers.varKeyword);
    }
    return modifiers.abstractKeyword;
  }

  /**
   * Validate that the given set of [modifiers] is appropriate for a constructor
   * and return the 'const' keyword if there is one.
   */
  Token _validateModifiersForConstructor(Modifiers modifiers) {
    if (modifiers.abstractKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.ABSTRACT_CLASS_MEMBER, modifiers.abstractKeyword);
    }
    if (modifiers.covariantKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.COVARIANT_CONSTRUCTOR, modifiers.covariantKeyword);
    }
    if (modifiers.finalKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.FINAL_CONSTRUCTOR, modifiers.finalKeyword);
    }
    if (modifiers.staticKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.STATIC_CONSTRUCTOR, modifiers.staticKeyword);
    }
    if (modifiers.varKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE, modifiers.varKeyword);
    }
    Token externalKeyword = modifiers.externalKeyword;
    Token constKeyword = modifiers.constKeyword;
    Token factoryKeyword = modifiers.factoryKeyword;
    if (externalKeyword != null &&
        constKeyword != null &&
        constKeyword.offset < externalKeyword.offset) {
      _reportErrorForToken(
          ParserErrorCode.EXTERNAL_AFTER_CONST, externalKeyword);
    }
    if (externalKeyword != null &&
        factoryKeyword != null &&
        factoryKeyword.offset < externalKeyword.offset) {
      _reportErrorForToken(
          ParserErrorCode.EXTERNAL_AFTER_FACTORY, externalKeyword);
    }
    return constKeyword;
  }

  /**
   * Validate that the given set of [modifiers] is appropriate for an enum and
   * return the 'abstract' keyword if there is one.
   */
  void _validateModifiersForEnum(Modifiers modifiers) {
    _validateModifiersForTopLevelDeclaration(modifiers);
    if (modifiers.abstractKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.ABSTRACT_ENUM, modifiers.abstractKeyword);
    }
    if (modifiers.constKeyword != null) {
      _reportErrorForToken(ParserErrorCode.CONST_ENUM, modifiers.constKeyword);
    }
    if (modifiers.externalKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.EXTERNAL_ENUM, modifiers.externalKeyword);
    }
    if (modifiers.finalKeyword != null) {
      _reportErrorForToken(ParserErrorCode.FINAL_ENUM, modifiers.finalKeyword);
    }
    if (modifiers.varKeyword != null) {
      _reportErrorForToken(ParserErrorCode.VAR_ENUM, modifiers.varKeyword);
    }
  }

  /**
   * Validate that the given set of [modifiers] is appropriate for a field and
   * return the 'final', 'const' or 'var' keyword if there is one.
   */
  Token _validateModifiersForField(Modifiers modifiers) {
    if (modifiers.abstractKeyword != null) {
      _reportErrorForCurrentToken(ParserErrorCode.ABSTRACT_CLASS_MEMBER);
    }
    if (modifiers.externalKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.EXTERNAL_FIELD, modifiers.externalKeyword);
    }
    if (modifiers.factoryKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.NON_CONSTRUCTOR_FACTORY, modifiers.factoryKeyword);
    }
    Token staticKeyword = modifiers.staticKeyword;
    Token covariantKeyword = modifiers.covariantKeyword;
    Token constKeyword = modifiers.constKeyword;
    Token finalKeyword = modifiers.finalKeyword;
    Token varKeyword = modifiers.varKeyword;
    if (constKeyword != null) {
      if (covariantKeyword != null) {
        _reportErrorForToken(
            ParserErrorCode.CONST_AND_COVARIANT, covariantKeyword);
      }
      if (finalKeyword != null) {
        _reportErrorForToken(ParserErrorCode.CONST_AND_FINAL, finalKeyword);
      }
      if (varKeyword != null) {
        _reportErrorForToken(ParserErrorCode.CONST_AND_VAR, varKeyword);
      }
      if (staticKeyword != null && constKeyword.offset < staticKeyword.offset) {
        _reportErrorForToken(ParserErrorCode.STATIC_AFTER_CONST, staticKeyword);
      }
    } else if (finalKeyword != null) {
      if (covariantKeyword != null) {
        _reportErrorForToken(
            ParserErrorCode.FINAL_AND_COVARIANT, covariantKeyword);
      }
      if (varKeyword != null) {
        _reportErrorForToken(ParserErrorCode.FINAL_AND_VAR, varKeyword);
      }
      if (staticKeyword != null && finalKeyword.offset < staticKeyword.offset) {
        _reportErrorForToken(ParserErrorCode.STATIC_AFTER_FINAL, staticKeyword);
      }
    } else if (varKeyword != null) {
      if (staticKeyword != null && varKeyword.offset < staticKeyword.offset) {
        _reportErrorForToken(ParserErrorCode.STATIC_AFTER_VAR, staticKeyword);
      }
      if (covariantKeyword != null &&
          varKeyword.offset < covariantKeyword.offset) {
        _reportErrorForToken(
            ParserErrorCode.COVARIANT_AFTER_VAR, covariantKeyword);
      }
    }
    if (covariantKeyword != null && staticKeyword != null) {
      _reportErrorForToken(ParserErrorCode.COVARIANT_AND_STATIC, staticKeyword);
    }
    return Token.lexicallyFirst([constKeyword, finalKeyword, varKeyword]);
  }

  /**
   * Validate that the given set of [modifiers] is appropriate for a local
   * function.
   */
  void _validateModifiersForFunctionDeclarationStatement(Modifiers modifiers) {
    if (modifiers.abstractKeyword != null ||
        modifiers.constKeyword != null ||
        modifiers.externalKeyword != null ||
        modifiers.factoryKeyword != null ||
        modifiers.finalKeyword != null ||
        modifiers.staticKeyword != null ||
        modifiers.varKeyword != null) {
      _reportErrorForCurrentToken(
          ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER);
    }
  }

  /**
   * Validate that the given set of [modifiers] is appropriate for a getter,
   * setter, or method.
   */
  void _validateModifiersForGetterOrSetterOrMethod(Modifiers modifiers) {
    if (modifiers.abstractKeyword != null) {
      _reportErrorForCurrentToken(ParserErrorCode.ABSTRACT_CLASS_MEMBER);
    }
    if (modifiers.constKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.CONST_METHOD, modifiers.constKeyword);
    }
    if (modifiers.covariantKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.COVARIANT_MEMBER, modifiers.covariantKeyword);
    }
    if (modifiers.factoryKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.NON_CONSTRUCTOR_FACTORY, modifiers.factoryKeyword);
    }
    if (modifiers.finalKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.FINAL_METHOD, modifiers.finalKeyword);
    }
    if (modifiers.varKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.VAR_RETURN_TYPE, modifiers.varKeyword);
    }
    Token externalKeyword = modifiers.externalKeyword;
    Token staticKeyword = modifiers.staticKeyword;
    if (externalKeyword != null &&
        staticKeyword != null &&
        staticKeyword.offset < externalKeyword.offset) {
      _reportErrorForToken(
          ParserErrorCode.EXTERNAL_AFTER_STATIC, externalKeyword);
    }
  }

  /**
   * Validate that the given set of [modifiers] is appropriate for a getter,
   * setter, or method.
   */
  void _validateModifiersForOperator(Modifiers modifiers) {
    if (modifiers.abstractKeyword != null) {
      _reportErrorForCurrentToken(ParserErrorCode.ABSTRACT_CLASS_MEMBER);
    }
    if (modifiers.constKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.CONST_METHOD, modifiers.constKeyword);
    }
    if (modifiers.factoryKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.NON_CONSTRUCTOR_FACTORY, modifiers.factoryKeyword);
    }
    if (modifiers.finalKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.FINAL_METHOD, modifiers.finalKeyword);
    }
    if (modifiers.staticKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.STATIC_OPERATOR, modifiers.staticKeyword);
    }
    if (modifiers.varKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.VAR_RETURN_TYPE, modifiers.varKeyword);
    }
  }

  /**
   * Validate that the given set of [modifiers] is appropriate for a top-level
   * declaration.
   */
  void _validateModifiersForTopLevelDeclaration(Modifiers modifiers) {
    if (modifiers.covariantKeyword != null) {
      _reportErrorForToken(ParserErrorCode.COVARIANT_TOP_LEVEL_DECLARATION,
          modifiers.covariantKeyword);
    }
    if (modifiers.factoryKeyword != null) {
      _reportErrorForToken(ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION,
          modifiers.factoryKeyword);
    }
    if (modifiers.staticKeyword != null) {
      _reportErrorForToken(ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION,
          modifiers.staticKeyword);
    }
  }

  /**
   * Validate that the given set of [modifiers] is appropriate for a top-level
   * function.
   */
  void _validateModifiersForTopLevelFunction(Modifiers modifiers) {
    _validateModifiersForTopLevelDeclaration(modifiers);
    if (modifiers.abstractKeyword != null) {
      _reportErrorForCurrentToken(ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION);
    }
    if (modifiers.constKeyword != null) {
      _reportErrorForToken(ParserErrorCode.CONST_CLASS, modifiers.constKeyword);
    }
    if (modifiers.finalKeyword != null) {
      _reportErrorForToken(ParserErrorCode.FINAL_CLASS, modifiers.finalKeyword);
    }
    if (modifiers.varKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.VAR_RETURN_TYPE, modifiers.varKeyword);
    }
  }

  /**
   * Validate that the given set of [modifiers] is appropriate for a field and
   * return the 'final', 'const' or 'var' keyword if there is one.
   */
  Token _validateModifiersForTopLevelVariable(Modifiers modifiers) {
    _validateModifiersForTopLevelDeclaration(modifiers);
    if (modifiers.abstractKeyword != null) {
      _reportErrorForCurrentToken(ParserErrorCode.ABSTRACT_TOP_LEVEL_VARIABLE);
    }
    if (modifiers.externalKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.EXTERNAL_FIELD, modifiers.externalKeyword);
    }
    Token constKeyword = modifiers.constKeyword;
    Token finalKeyword = modifiers.finalKeyword;
    Token varKeyword = modifiers.varKeyword;
    if (constKeyword != null) {
      if (finalKeyword != null) {
        _reportErrorForToken(ParserErrorCode.CONST_AND_FINAL, finalKeyword);
      }
      if (varKeyword != null) {
        _reportErrorForToken(ParserErrorCode.CONST_AND_VAR, varKeyword);
      }
    } else if (finalKeyword != null) {
      if (varKeyword != null) {
        _reportErrorForToken(ParserErrorCode.FINAL_AND_VAR, varKeyword);
      }
    }
    return Token.lexicallyFirst([constKeyword, finalKeyword, varKeyword]);
  }

  /**
   * Validate that the given set of [modifiers] is appropriate for a class and
   * return the 'abstract' keyword if there is one.
   */
  void _validateModifiersForTypedef(Modifiers modifiers) {
    _validateModifiersForTopLevelDeclaration(modifiers);
    if (modifiers.abstractKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.ABSTRACT_TYPEDEF, modifiers.abstractKeyword);
    }
    if (modifiers.constKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.CONST_TYPEDEF, modifiers.constKeyword);
    }
    if (modifiers.externalKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.EXTERNAL_TYPEDEF, modifiers.externalKeyword);
    }
    if (modifiers.finalKeyword != null) {
      _reportErrorForToken(
          ParserErrorCode.FINAL_TYPEDEF, modifiers.finalKeyword);
    }
    if (modifiers.varKeyword != null) {
      _reportErrorForToken(ParserErrorCode.VAR_TYPEDEF, modifiers.varKeyword);
    }
  }
}

/**
 * Instances of this class are thrown when the parser detects that AST has
 * too many nested expressions to be parsed safely and avoid possibility of
 * [StackOverflowError] in the parser or during later analysis.
 */
class _TooDeepTreeError {}
