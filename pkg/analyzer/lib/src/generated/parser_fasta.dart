// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of analyzer.parser;

/**
 * Proxy implementation of the analyzer parser, implemented in terms of the
 * Fasta parser.
 */
abstract class ParserAdapter implements Parser {
  @override
  Token currentToken;

  /**
   * The fasta parser being wrapped.
   */
  final fasta.Parser fastaParser;

  /**
   * The builder which creates the analyzer AST data structures
   * based on the Fasta parser.
   */
  final AstBuilder astBuilder;

  ParserAdapter(this.currentToken, ErrorReporter errorReporter, Uri fileUri,
      {bool allowNativeClause: false, bool enableGenericMethodComments: false})
      : fastaParser = new fasta.Parser(null),
        astBuilder = new AstBuilder(errorReporter, fileUri, true) {
    fastaParser.listener = astBuilder;
    astBuilder.parser = fastaParser;
    astBuilder.allowNativeClause = allowNativeClause;
    astBuilder.parseGenericMethodComments = enableGenericMethodComments;
  }

  @override
  set allowNativeClause(bool value) {
    astBuilder.allowNativeClause = value;
  }

  @override
  bool get enableOptionalNewAndConst => false;

  @override
  void set enableOptionalNewAndConst(bool enable) {}

  @override
  void set parseFunctionBodies(bool parseFunctionBodies) {
    astBuilder.parseFunctionBodies = parseFunctionBodies;
  }

  @override
  bool get parseGenericMethodComments => astBuilder.parseGenericMethodComments;

  @override
  set parseGenericMethodComments(bool value) {
    astBuilder.parseGenericMethodComments = value;
  }

  @override
  set parseGenericMethods(_) {}

  /// Append the given token to the end of the token stream,
  /// and update the token's offset.
  appendToken(Token token, Token newToken) {
    while (!token.next.isEof) {
      token = token.next;
    }
    newToken
      ..offset = token.end
      ..setNext(token.next);
    token.setNext(newToken);
  }

  @override
  Expression parseAdditiveExpression() => parseExpression2();

  @override
  Annotation parseAnnotation() {
    currentToken = fastaParser
        .parseMetadata(fastaParser.syntheticPreviousToken(currentToken))
        .next;
    return astBuilder.pop();
  }

  @override
  Expression parseArgument() {
    currentToken = new SimpleToken(TokenType.OPEN_PAREN, 0)
      ..setNext(currentToken);
    appendToken(currentToken, new SimpleToken(TokenType.CLOSE_PAREN, 0));
    currentToken = fastaParser
        .parseArguments(fastaParser.syntheticPreviousToken(currentToken))
        .next;
    MethodInvocation invocation = astBuilder.pop();
    return invocation.argumentList.arguments[0];
  }

  @override
  ArgumentList parseArgumentList() {
    currentToken = fastaParser
        .parseArguments(fastaParser.syntheticPreviousToken(currentToken))
        .next;
    var result = astBuilder.pop();
    return result is MethodInvocation ? result.argumentList : result;
  }

  @override
  Expression parseAssignableExpression(bool primaryAllowed) =>
      parseExpression2();

  @override
  Expression parseBitwiseAndExpression() => parseExpression2();

  @override
  Expression parseBitwiseOrExpression() => parseExpression2();

  @override
  Expression parseBitwiseXorExpression() => parseExpression2();

  @override
  ClassMember parseClassMember(String className) {
    astBuilder.classDeclaration = astFactory.classDeclaration(
      null,
      null,
      null,
      new Token(Keyword.CLASS, 0),
      astFactory.simpleIdentifier(
          new fasta.StringToken.fromString(TokenType.IDENTIFIER, className, 6)),
      null,
      null,
      null,
      null,
      null /* leftBracket */,
      <ClassMember>[],
      null /* rightBracket */,
    );
    currentToken = fastaParser.parseClassMember(currentToken);
    ClassDeclaration declaration = astBuilder.classDeclaration;
    astBuilder.classDeclaration = null;
    return declaration.members.isNotEmpty ? declaration.members[0] : null;
  }

  @override
  List<Combinator> parseCombinators() {
    currentToken = fastaParser
        .parseCombinatorStar(fastaParser.syntheticPreviousToken(currentToken))
        .next;
    return astBuilder.pop();
  }

  @override
  CompilationUnit parseCompilationUnit(Token token) {
    currentToken = token;
    return parseCompilationUnit2();
  }

  @override
  CompilationUnit parseCompilationUnit2() {
    currentToken = fastaParser.parseUnit(currentToken);
    CompilationUnitImpl compilationUnit = astBuilder.pop();
    compilationUnit.localDeclarations = astBuilder.localDeclarations;
    return compilationUnit;
  }

  @override
  Expression parseConditionalExpression() => parseExpression2();

  @override
  Configuration parseConfiguration() {
    currentToken = fastaParser
        .parseConditionalUri(fastaParser.syntheticPreviousToken(currentToken))
        .next;
    return astBuilder.pop();
  }

  @override
  Expression parseConstExpression() => parseExpression2();

  @override
  CompilationUnit parseDirectives(Token token) {
    currentToken = token;
    return parseDirectives2();
  }

  @override
  CompilationUnit parseDirectives2() {
    currentToken = fastaParser.parseDirectives(currentToken);
    return astBuilder.pop();
  }

  @override
  DottedName parseDottedName() {
    currentToken = fastaParser
        .parseDottedName(fastaParser.syntheticPreviousToken(currentToken))
        .next;
    return astBuilder.pop();
  }

  @override
  Expression parseEqualityExpression() => parseExpression2();

  @override
  Expression parseExpression(Token token) {
    currentToken = token;
    return parseExpression2();
  }

  @override
  Expression parseExpression2() {
    currentToken = fastaParser
        .parseExpression(fastaParser.syntheticPreviousToken(currentToken))
        .next;
    return astBuilder.pop();
  }

  @override
  Expression parseExpressionWithoutCascade() => parseExpression2();

  @override
  FormalParameterList parseFormalParameterList({bool inFunctionType: false}) {
    currentToken = fastaParser
        .parseFormalParametersRequiredOpt(
            fastaParser.syntheticPreviousToken(currentToken),
            inFunctionType
                ? fasta.MemberKind.GeneralizedFunctionType
                : fasta.MemberKind.NonStaticMethod)
        .next;
    return astBuilder.pop();
  }

  @override
  FunctionBody parseFunctionBody(
      bool mayBeEmpty, ParserErrorCode emptyErrorCode, bool inExpression) {
    currentToken = fastaParser.parseAsyncModifierOpt(
        fastaParser.syntheticPreviousToken(currentToken));
    currentToken =
        fastaParser.parseFunctionBody(currentToken, inExpression, mayBeEmpty);
    return astBuilder.pop();
  }

  @override
  FunctionExpression parseFunctionExpression() => parseExpression2();

  @override
  Expression parseLogicalAndExpression() => parseExpression2();

  @override
  Expression parseLogicalOrExpression() => parseExpression2();

  @override
  Expression parseMultiplicativeExpression() => parseExpression2();

  @override
  InstanceCreationExpression parseNewExpression() => parseExpression2();

  @override
  Expression parsePostfixExpression() => parseExpression2();

  @override
  Identifier parsePrefixedIdentifier() => parseExpression2();

  @override
  Expression parsePrimaryExpression() {
    currentToken = fastaParser
        .parsePrimary(fastaParser.syntheticPreviousToken(currentToken),
            fasta.IdentifierContext.expression)
        .next;
    return astBuilder.pop();
  }

  @override
  Expression parseRelationalExpression() => parseExpression2();

  @override
  Expression parseRethrowExpression() => parseExpression2();

  @override
  Expression parseShiftExpression() => parseExpression2();

  @override
  SimpleIdentifier parseSimpleIdentifier(
          {bool allowKeyword: false, bool isDeclaration: false}) =>
      parseExpression2();

  @override
  Statement parseStatement(Token token) {
    currentToken = token;
    return parseStatement2();
  }

  @override
  Statement parseStatement2() {
    currentToken = fastaParser
        .parseStatement(fastaParser.syntheticPreviousToken(currentToken))
        .next;
    return astBuilder.pop();
  }

  @override
  StringLiteral parseStringLiteral() => parseExpression2();

  @override
  SymbolLiteral parseSymbolLiteral() => parseExpression2();

  @override
  Expression parseThrowExpression() => parseExpression2();

  @override
  Expression parseThrowExpressionWithoutCascade() => parseExpression2();

  AnnotatedNode parseTopLevelDeclaration(bool isDirective) {
    currentToken = fastaParser.parseTopLevelDeclaration(currentToken);
    return (isDirective ? astBuilder.directives : astBuilder.declarations)
        .removeLast();
  }

  @override
  TypeAnnotation parseTypeAnnotation(bool inExpression) {
    Token previous = fastaParser.syntheticPreviousToken(currentToken);
    currentToken = fasta
        .computeType(previous, true, !inExpression)
        .parseType(previous, fastaParser)
        .next;
    return astBuilder.pop();
  }

  @override
  TypeArgumentList parseTypeArgumentList() {
    Token previous = fastaParser.syntheticPreviousToken(currentToken);
    currentToken = fasta
        .computeTypeParamOrArg(previous)
        .parseArguments(previous, fastaParser)
        .next;
    return astBuilder.pop();
  }

  @override
  TypeName parseTypeName(bool inExpression) {
    Token previous = fastaParser.syntheticPreviousToken(currentToken);
    currentToken = fasta
        .computeType(previous, true, !inExpression)
        .parseType(previous, fastaParser)
        .next;
    return astBuilder.pop();
  }

  @override
  TypeParameter parseTypeParameter() {
    currentToken = new SyntheticBeginToken(TokenType.LT, 0)
      ..endGroup = new SyntheticToken(TokenType.GT, 0)
      ..setNext(currentToken);
    appendToken(currentToken, currentToken.endGroup);
    TypeParameterList typeParams = parseTypeParameterList();
    return typeParams.typeParameters[0];
  }

  @override
  TypeParameterList parseTypeParameterList() {
    Token token = fastaParser.syntheticPreviousToken(currentToken);
    currentToken = fasta
        .computeTypeParamOrArg(token, true)
        .parseVariables(token, fastaParser)
        .next;
    return astBuilder.pop();
  }

  @override
  Expression parseUnaryExpression() => parseExpression2();
}

/**
 * Replacement parser based on Fasta.
 */
class _Parser2 extends ParserAdapter {
  /**
   * The source being parsed.
   */
  final Source _source;

  @override
  bool enableUriInPartOf = true;

  @override
  bool enableNnbd = false;

  factory _Parser2(Source source, AnalysisErrorListener errorListener,
      {bool allowNativeClause: false}) {
    var errorReporter = new ErrorReporter(errorListener, source);
    return new _Parser2._(source, errorReporter, source.uri,
        allowNativeClause: allowNativeClause);
  }

  _Parser2._(this._source, ErrorReporter errorReporter, Uri fileUri,
      {bool allowNativeClause: false})
      : super(null, errorReporter, fileUri,
            allowNativeClause: allowNativeClause);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
