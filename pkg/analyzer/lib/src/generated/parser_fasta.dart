// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of analyzer.parser;

class _Builder implements Builder {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _KernelLibraryBuilder implements KernelLibraryBuilder {
  @override
  final uri;

  _KernelLibraryBuilder(this.uri);

  @override
  Uri get fileUri => uri;

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

  ParserAdapter(this.currentToken, ErrorReporter errorReporter,
      KernelLibraryBuilder library, Builder member, Scope scope,
      {bool allowNativeClause: false, bool enableGenericMethodComments: false})
      : fastaParser = new fasta.Parser(null),
        astBuilder =
            new AstBuilder(errorReporter, library, member, scope, true) {
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
  bool get parseGenericMethodComments => astBuilder.parseGenericMethodComments;

  @override
  set parseGenericMethodComments(bool value) {
    astBuilder.parseGenericMethodComments = value;
  }

  @override
  void set parseFunctionBodies(bool parseFunctionBodies) {
    // ignored
  }

  @override
  Annotation parseAnnotation() {
    currentToken = fastaParser
        .parseMetadata(fastaParser.syntheticPreviousToken(currentToken))
        .next;
    return astBuilder.pop();
  }

  @override
  ArgumentList parseArgumentList() {
    currentToken = fastaParser.parseArguments(currentToken).next;
    var result = astBuilder.pop();
    return result is MethodInvocation ? result.argumentList : result;
  }

  @override
  Expression parseAssignableExpression(bool primaryAllowed) =>
      parseExpression2();

  @override
  Expression parseAdditiveExpression() => parseExpression2();

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
    currentToken = fastaParser
        .parseClassMember(fastaParser.syntheticPreviousToken(currentToken))
        .next;
    ClassDeclaration declaration = astBuilder.classDeclaration;
    astBuilder.classDeclaration = null;
    return declaration.members[0];
  }

  @override
  List<Combinator> parseCombinators() {
    currentToken = fastaParser
        .parseCombinators(fastaParser.syntheticPreviousToken(currentToken))
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
    return astBuilder.pop();
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
  DottedName parseDottedName() {
    currentToken = fastaParser
        .parseDottedName(fastaParser.syntheticPreviousToken(currentToken))
        .next;
    return astBuilder.pop();
  }

  @override
  Expression parseEqualityExpression() => parseExpression2();

  @override
  Expression parseExpression2() {
    currentToken = fastaParser.parseExpression(currentToken).next;
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
    currentToken = fastaParser
        .parseAsyncModifier(fastaParser.syntheticPreviousToken(currentToken));
    currentToken =
        fastaParser.parseFunctionBody(currentToken, inExpression, mayBeEmpty);
    if (inExpression) {
      currentToken = currentToken.next;
    }
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
    currentToken = fastaParser.parsePrimary(
        fastaParser.syntheticPreviousToken(currentToken),
        fasta.IdentifierContext.expression);
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
        .parseStatementOpt(fastaParser.syntheticPreviousToken(currentToken))
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
    currentToken = fastaParser.parseType(currentToken).next;
    return astBuilder.pop();
  }

  @override
  TypeArgumentList parseTypeArgumentList() {
    currentToken = fastaParser
        .parseTypeArgumentsOpt(fastaParser.syntheticPreviousToken(currentToken))
        .next;
    return astBuilder.pop();
  }

  @override
  TypeName parseTypeName(bool inExpression) {
    currentToken = fastaParser.parseType(currentToken).next;
    return astBuilder.pop();
  }

  @override
  TypeParameter parseTypeParameter() {
    currentToken = fastaParser
        .parseTypeVariable(fastaParser.syntheticPreviousToken(currentToken))
        .next;
    return astBuilder.pop();
  }

  @override
  TypeParameterList parseTypeParameterList() {
    currentToken = fastaParser
        .parseTypeVariablesOpt(fastaParser.syntheticPreviousToken(currentToken))
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

  factory _Parser2(Source source, AnalysisErrorListener errorListener) {
    var errorReporter = new ErrorReporter(errorListener, source);
    var library = new _KernelLibraryBuilder(source.uri);
    var member = new _Builder();
    var scope = new Scope.top(isModifiable: true);
    return new _Parser2._(source, errorReporter, library, member, scope);
  }

  _Parser2._(this._source, ErrorReporter errorReporter,
      KernelLibraryBuilder library, Builder member, Scope scope)
      : super(null, errorReporter, library, member, scope);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
