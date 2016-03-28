// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:logging/logging.dart' as logger;

final _log = new logger.Logger('dev_compiler.ast_builder');

// Wrappers around constructors for the dart ast.  The AstBuilder class
// provides a higher-level interface, abstracting both from the lexical
// details and some of helper classes.  The RawAstBuilder class provides
// a low-level wrapper class (below) abstracts from the lexical details
// but otherwise faithfully mirrors the construction API.
class AstBuilder {
  static SimpleIdentifier identifierFromString(String name) {
    return RawAstBuilder.identifierFromString(name);
  }

  static PrefixedIdentifier prefixedIdentifier(
      SimpleIdentifier pre, SimpleIdentifier id) {
    return RawAstBuilder.prefixedIdentifier(pre, id);
  }

  static TypeParameter typeParameter(SimpleIdentifier name,
      [TypeName bound = null]) {
    return RawAstBuilder.typeParameter(name, bound);
  }

  static TypeParameterList typeParameterList(List<TypeParameter> params) {
    return RawAstBuilder.typeParameterList(params);
  }

  static TypeArgumentList typeArgumentList(List<TypeName> args) {
    return RawAstBuilder.typeArgumentList(args);
  }

  static ArgumentList argumentList(List<Expression> args) {
    return RawAstBuilder.argumentList(args);
  }

  static TypeName typeName(Identifier id, List<TypeName> args) {
    TypeArgumentList argList = null;
    if (args != null && args.length > 0) argList = typeArgumentList(args);
    return RawAstBuilder.typeName(id, argList);
  }

  static FunctionTypeAlias functionTypeAlias(
      TypeName ret,
      SimpleIdentifier name,
      List<TypeParameter> tParams,
      List<FormalParameter> params) {
    TypeParameterList tps =
        (tParams.length == 0) ? null : typeParameterList(tParams);
    FormalParameterList fps = formalParameterList(params);
    return RawAstBuilder.functionTypeAlias(ret, name, tps, fps);
  }

  static BooleanLiteral booleanLiteral(bool b) {
    return RawAstBuilder.booleanLiteral(b);
  }

  static NullLiteral nullLiteral() {
    return RawAstBuilder.nullLiteral();
  }

  static IntegerLiteral integerLiteral(int i) {
    return RawAstBuilder.integerLiteral(i);
  }

  static StringLiteral stringLiteral(String s) {
    return RawAstBuilder.simpleStringLiteral(s);
  }

  static StringLiteral multiLineStringLiteral(String s) {
    return RawAstBuilder.tripleQuotedStringLiteral(s);
  }

  static AsExpression asExpression(Expression exp, TypeName type) {
    return RawAstBuilder.asExpression(exp, type);
  }

  static IsExpression isExpression(Expression exp, TypeName type) {
    return RawAstBuilder.isExpression(exp, type);
  }

  static ParenthesizedExpression parenthesizedExpression(Expression exp) {
    return RawAstBuilder.parenthesizedExpression(exp);
  }

  static Expression parenthesize(Expression exp) {
    if (exp is Identifier ||
        exp is ParenthesizedExpression ||
        exp is FunctionExpressionInvocation ||
        exp is MethodInvocation) return exp;
    return parenthesizedExpression(exp);
  }

  static PropertyAccess propertyAccess(
      Expression target, SimpleIdentifier name) {
    var p = new Token(TokenType.PERIOD, 0);
    return new PropertyAccess(target, p, name);
  }

  static MethodInvocation methodInvoke(
      Expression target, SimpleIdentifier name, NodeList<Expression> args) {
    var p = new Token(TokenType.PERIOD, 0);
    return new MethodInvocation(target, p, name, null, argumentList(args));
  }

  static TokenType getTokenType(String lexeme) {
    switch (lexeme) {
      case "&":
        return TokenType.AMPERSAND;
      case "&&":
        return TokenType.AMPERSAND_AMPERSAND;
      case "&=":
        return TokenType.AMPERSAND_EQ;
      case "@":
        return TokenType.AT;
      case "!":
        return TokenType.BANG;
      case "!=":
        return TokenType.BANG_EQ;
      case "|":
        return TokenType.BAR;
      case "||":
        return TokenType.BAR_BAR;
      case "|=":
        return TokenType.BAR_EQ;
      case ":":
        return TokenType.COLON;
      case ",":
        return TokenType.COMMA;
      case "^":
        return TokenType.CARET;
      case "^=":
        return TokenType.CARET_EQ;
      case "}":
        return TokenType.CLOSE_CURLY_BRACKET;
      case ")":
        return TokenType.CLOSE_PAREN;
      case "]":
        return TokenType.CLOSE_SQUARE_BRACKET;
      case "=":
        return TokenType.EQ;
      case "==":
        return TokenType.EQ_EQ;
      case "=>":
        return TokenType.FUNCTION;
      case ">":
        return TokenType.GT;
      case ">=":
        return TokenType.GT_EQ;
      case ">>":
        return TokenType.GT_GT;
      case ">>=":
        return TokenType.GT_GT_EQ;
      case "#":
        return TokenType.HASH;
      case "[]":
        return TokenType.INDEX;
      case "[]=":
        return TokenType.INDEX_EQ;
      case "is":
        return TokenType.IS;
      case "<":
        return TokenType.LT;
      case "<=":
        return TokenType.LT_EQ;
      case "<<":
        return TokenType.LT_LT;
      case "<<=":
        return TokenType.LT_LT_EQ;
      case "-":
        return TokenType.MINUS;
      case "-=":
        return TokenType.MINUS_EQ;
      case "--":
        return TokenType.MINUS_MINUS;
      case "{":
        return TokenType.OPEN_CURLY_BRACKET;
      case "(":
        return TokenType.OPEN_PAREN;
      case "[":
        return TokenType.OPEN_SQUARE_BRACKET;
      case "%":
        return TokenType.PERCENT;
      case "%=":
        return TokenType.PERCENT_EQ;
      case ".":
        return TokenType.PERIOD;
      case "..":
        return TokenType.PERIOD_PERIOD;
      case "+":
        return TokenType.PLUS;
      case "+=":
        return TokenType.PLUS_EQ;
      case "++":
        return TokenType.PLUS_PLUS;
      case "?":
        return TokenType.QUESTION;
      case ";":
        return TokenType.SEMICOLON;
      case "/":
        return TokenType.SLASH;
      case "/=":
        return TokenType.SLASH_EQ;
      case "*":
        return TokenType.STAR;
      case "*=":
        return TokenType.STAR_EQ;
      case "\${":
        return TokenType.STRING_INTERPOLATION_EXPRESSION;
      case "\$":
        return TokenType.STRING_INTERPOLATION_IDENTIFIER;
      case "~":
        return TokenType.TILDE;
      case "~/":
        return TokenType.TILDE_SLASH;
      case "~/=":
        return TokenType.TILDE_SLASH_EQ;
      case "`":
        return TokenType.BACKPING;
      case "\\":
        return TokenType.BACKSLASH;
      case "...":
        return TokenType.PERIOD_PERIOD_PERIOD;
      case "??":
        return TokenType.QUESTION_QUESTION;
      case "??=":
        return TokenType.QUESTION_QUESTION_EQ;
      default:
        return null;
    }
  }

  static Token _binaryOperation(String oper) {
    var type = getTokenType(oper);
    assert(type != null);
    return new Token(type, 0);
  }

  static BinaryExpression binaryExpression(
      Expression l, String oper, Expression r) {
    Token token = _binaryOperation(oper);
    return RawAstBuilder.binaryExpression(l, token, r);
  }

  static ConditionalExpression conditionalExpression(
      Expression cond, Expression tExp, Expression fExp) {
    return RawAstBuilder.conditionalExpression(cond, tExp, fExp);
  }

  static Expression application(Expression function, List<Expression> es) {
    ArgumentList args = argumentList(es);
    return RawAstBuilder.functionExpressionInvocation(function, args);
  }

  static FormalParameterList formalParameterList(List<FormalParameter> params) {
    return RawAstBuilder.formalParameterList(params);
  }

  static Block block(List<Statement> statements) {
    return RawAstBuilder.block(statements);
  }

  static MethodDeclaration blockMethodDeclaration(
      TypeName rt,
      SimpleIdentifier m,
      List<FormalParameter> params,
      List<Statement> statements,
      {bool isStatic: false}) {
    FormalParameterList fl = formalParameterList(params);
    Block b = block(statements);
    BlockFunctionBody body = RawAstBuilder.blockFunctionBody(b);
    return RawAstBuilder.methodDeclaration(rt, m, fl, body, isStatic: isStatic);
  }

  static FunctionDeclaration blockFunctionDeclaration(
      TypeName rt,
      SimpleIdentifier f,
      List<FormalParameter> params,
      List<Statement> statements) {
    FunctionExpression fexp = blockFunction(params, statements);
    return RawAstBuilder.functionDeclaration(rt, f, fexp);
  }

  static FunctionExpression blockFunction(
      List<FormalParameter> params, List<Statement> statements) {
    FormalParameterList fl = formalParameterList(params);
    Block b = block(statements);
    BlockFunctionBody body = RawAstBuilder.blockFunctionBody(b);
    return RawAstBuilder.functionExpression(fl, body);
  }

  static FunctionExpression expressionFunction(
      List<FormalParameter> params, Expression body,
      [bool decl = false]) {
    FormalParameterList fl = formalParameterList(params);
    ExpressionFunctionBody b = RawAstBuilder.expressionFunctionBody(body, decl);
    return RawAstBuilder.functionExpression(fl, b);
  }

  static FunctionDeclarationStatement functionDeclarationStatement(
      TypeName rType, SimpleIdentifier name, FunctionExpression fe) {
    var fd = RawAstBuilder.functionDeclaration(rType, name, fe);
    return RawAstBuilder.functionDeclarationStatement(fd);
  }

  static Statement returnExpression([Expression e]) {
    return RawAstBuilder.returnExpression(e);
  }

  // let b = e1 in e2 == (\b.e2)(e1)
  static Expression letExpression(
      FormalParameter b, Expression e1, Expression e2) {
    FunctionExpression l = expressionFunction(<FormalParameter>[b], e2);
    return application(parenthesize(l), <Expression>[e1]);
  }

  static SimpleFormalParameter simpleFormal(SimpleIdentifier v, TypeName t) {
    return RawAstBuilder.simpleFormalParameter(v, t);
  }

  static FunctionTypedFormalParameter functionTypedFormal(
      TypeName ret, SimpleIdentifier v, List<FormalParameter> params) {
    FormalParameterList ps = formalParameterList(params);
    return RawAstBuilder.functionTypedFormalParameter(ret, v, ps);
  }

  static FormalParameter requiredFormal(NormalFormalParameter fp) {
    return RawAstBuilder.requiredFormalParameter(fp);
  }

  static FormalParameter optionalFormal(NormalFormalParameter fp) {
    return RawAstBuilder.optionalFormalParameter(fp);
  }

  static FormalParameter namedFormal(NormalFormalParameter fp) {
    return RawAstBuilder.namedFormalParameter(fp);
  }

  static NamedExpression namedParameter(String s, Expression e) {
    return namedExpression(s, e);
  }

  static NamedExpression namedExpression(String s, Expression e) {
    return RawAstBuilder.namedExpression(identifierFromString(s), e);
  }

  /// Declares a single variable `var <name> = <init>` with the type and name
  /// specified by the VariableElement. See also [variableStatement].
  static VariableDeclarationList declareVariable(SimpleIdentifier name,
      [Expression init]) {
    var eqToken = init != null ? new Token(TokenType.EQ, 0) : null;
    var varToken = new KeywordToken(Keyword.VAR, 0);
    return new VariableDeclarationList(null, null, varToken, null,
        [new VariableDeclaration(name, eqToken, init)]);
  }

  static VariableDeclarationStatement variableStatement(SimpleIdentifier name,
      [Expression init]) {
    return RawAstBuilder
        .variableDeclarationStatement(declareVariable(name, init));
  }

  static InstanceCreationExpression instanceCreation(
      ConstructorName ctor, List<Expression> args) {
    var newToken = new KeywordToken(Keyword.NEW, 0);
    return new InstanceCreationExpression(
        newToken, ctor, RawAstBuilder.argumentList(args));
  }
}

// This class provides a low-level wrapper around the constructors for
// the AST.  It mostly simply abstracts from the lexical tokens.
class RawAstBuilder {
  static ConstructorName constructorName(TypeName type,
      [SimpleIdentifier name]) {
    Token period = name != null ? new Token(TokenType.PERIOD, 0) : null;
    return new ConstructorName(type, period, name);
  }

  static SimpleIdentifier identifierFromString(String name) {
    StringToken token = new SyntheticStringToken(TokenType.IDENTIFIER, name, 0);
    return new SimpleIdentifier(token);
  }

  static PrefixedIdentifier prefixedIdentifier(
      SimpleIdentifier pre, SimpleIdentifier id) {
    Token period = new Token(TokenType.PERIOD, 0);
    return new PrefixedIdentifier(pre, period, id);
  }

  static TypeParameter typeParameter(SimpleIdentifier name,
      [TypeName bound = null]) {
    Token keyword =
        (bound == null) ? null : new KeywordToken(Keyword.EXTENDS, 0);
    return new TypeParameter(null, null, name, keyword, bound);
  }

  static TypeParameterList typeParameterList(List<TypeParameter> params) {
    Token lb = new Token(TokenType.LT, 0);
    Token rb = new Token(TokenType.GT, 0);
    return new TypeParameterList(lb, params, rb);
  }

  static TypeArgumentList typeArgumentList(List<TypeName> args) {
    Token lb = new Token(TokenType.LT, 0);
    Token rb = new Token(TokenType.GT, 0);
    return new TypeArgumentList(lb, args, rb);
  }

  static ArgumentList argumentList(List<Expression> args) {
    Token lp = new BeginToken(TokenType.OPEN_PAREN, 0);
    Token rp = new Token(TokenType.CLOSE_PAREN, 0);
    return new ArgumentList(lp, args, rp);
  }

  static TypeName typeName(Identifier id, TypeArgumentList l) {
    return new TypeName(id, l);
  }

  static FunctionTypeAlias functionTypeAlias(TypeName ret,
      SimpleIdentifier name, TypeParameterList tps, FormalParameterList fps) {
    Token semi = new Token(TokenType.SEMICOLON, 0);
    Token td = new KeywordToken(Keyword.TYPEDEF, 0);
    return new FunctionTypeAlias(null, null, td, ret, name, tps, fps, semi);
  }

  static BooleanLiteral booleanLiteral(bool b) {
    var k = new KeywordToken(b ? Keyword.TRUE : Keyword.FALSE, 0);
    return new BooleanLiteral(k, b);
  }

  static NullLiteral nullLiteral() {
    var n = new KeywordToken(Keyword.NULL, 0);
    return new NullLiteral(n);
  }

  static IntegerLiteral integerLiteral(int i) {
    StringToken token = new StringToken(TokenType.INT, '$i', 0);
    return new IntegerLiteral(token, i);
  }

  static SimpleStringLiteral simpleStringLiteral(String s) {
    StringToken token = new StringToken(TokenType.STRING, "\"" + s + "\"", 0);
    return new SimpleStringLiteral(token, s);
  }

  static SimpleStringLiteral tripleQuotedStringLiteral(String s) {
    StringToken token = new StringToken(TokenType.STRING, '"""' + s + '"""', 0);
    return new SimpleStringLiteral(token, s);
  }

  static AsExpression asExpression(Expression exp, TypeName type) {
    Token token = new KeywordToken(Keyword.AS, 0);
    return new AsExpression(exp, token, type);
  }

  static IsExpression isExpression(Expression exp, TypeName type) {
    Token token = new KeywordToken(Keyword.IS, 0);
    return new IsExpression(exp, token, null, type);
  }

  static ParenthesizedExpression parenthesizedExpression(Expression exp) {
    Token lp = new BeginToken(TokenType.OPEN_PAREN, exp.offset);
    Token rp = new Token(TokenType.CLOSE_PAREN, exp.end);
    return new ParenthesizedExpression(lp, exp, rp);
  }

  static BinaryExpression binaryExpression(
      Expression l, Token op, Expression r) {
    return new BinaryExpression(l, op, r);
  }

  static ConditionalExpression conditionalExpression(
      Expression cond, Expression tExp, Expression fExp) {
    var q = new Token(TokenType.QUESTION, 0);
    var c = new Token(TokenType.COLON, 0);
    return new ConditionalExpression(cond, q, tExp, c, fExp);
  }

  static Expression functionExpressionInvocation(
      Expression function, ArgumentList es) {
    return new FunctionExpressionInvocation(function, null, es);
  }

  static FormalParameterList formalParameterList(List<FormalParameter> params) {
    Token lp = new BeginToken(TokenType.OPEN_PAREN, 0);
    Token rp = new Token(TokenType.CLOSE_PAREN, 0);
    bool hasOptional = params.any((p) => p.kind == ParameterKind.POSITIONAL);
    bool hasNamed = params.any((p) => p.kind == ParameterKind.NAMED);
    assert(!(hasOptional && hasNamed));
    Token ld = null;
    Token rd = null;
    if (hasOptional) {
      ld = new BeginToken(TokenType.OPEN_SQUARE_BRACKET, 0);
      rd = new Token(TokenType.CLOSE_SQUARE_BRACKET, 0);
    }
    if (hasNamed) {
      ld = new BeginToken(TokenType.OPEN_CURLY_BRACKET, 0);
      rd = new Token(TokenType.CLOSE_CURLY_BRACKET, 0);
    }
    return new FormalParameterList(lp, params, ld, rd, rp);
  }

  static Block block(List<Statement> statements) {
    Token ld = new BeginToken(TokenType.OPEN_CURLY_BRACKET, 0);
    Token rd = new Token(TokenType.CLOSE_CURLY_BRACKET, 0);
    return new Block(ld, statements, rd);
  }

  static BlockFunctionBody blockFunctionBody(Block b) {
    return new BlockFunctionBody(null, null, b);
  }

  static ExpressionFunctionBody expressionFunctionBody(Expression body,
      [bool decl = false]) {
    Token semi = (decl) ? new Token(TokenType.SEMICOLON, 0) : null;
    return new ExpressionFunctionBody(null, null, body, semi);
  }

  static ExpressionStatement expressionStatement(Expression expression) {
    Token semi = new Token(TokenType.SEMICOLON, 0);
    return new ExpressionStatement(expression, semi);
  }

  static FunctionDeclaration functionDeclaration(
      TypeName rt, SimpleIdentifier f, FunctionExpression fexp) {
    return new FunctionDeclaration(null, null, null, rt, null, f, fexp);
  }

  static MethodDeclaration methodDeclaration(TypeName rt, SimpleIdentifier m,
      FormalParameterList fl, FunctionBody body,
      {bool isStatic: false}) {
    Token st = isStatic ? new KeywordToken(Keyword.STATIC, 0) : null;
    return new MethodDeclaration(
        null, null, null, st, rt, null, null, m, null, fl, body);
  }

  static FunctionExpression functionExpression(
      FormalParameterList fl, FunctionBody body) {
    return new FunctionExpression(null, fl, body);
  }

  static FunctionDeclarationStatement functionDeclarationStatement(
      FunctionDeclaration fd) {
    return new FunctionDeclarationStatement(fd);
  }

  static Statement returnExpression([Expression e]) {
    Token ret = new KeywordToken(Keyword.RETURN, 0);
    Token semi = new Token(TokenType.SEMICOLON, 0);
    return new ReturnStatement(ret, e, semi);
  }

  static SimpleFormalParameter simpleFormalParameter(
      SimpleIdentifier v, TypeName t) {
    return new SimpleFormalParameter(null, <Annotation>[], null, t, v);
  }

  static FunctionTypedFormalParameter functionTypedFormalParameter(
      TypeName ret, SimpleIdentifier v, FormalParameterList ps) {
    return new FunctionTypedFormalParameter(
        null, <Annotation>[], ret, v, null, ps);
  }

  static FormalParameter requiredFormalParameter(NormalFormalParameter fp) {
    return fp;
  }

  static FormalParameter optionalFormalParameter(NormalFormalParameter fp) {
    return new DefaultFormalParameter(fp, ParameterKind.POSITIONAL, null, null);
  }

  static FormalParameter namedFormalParameter(NormalFormalParameter fp) {
    return new DefaultFormalParameter(fp, ParameterKind.NAMED, null, null);
  }

  static NamedExpression namedParameter(SimpleIdentifier s, Expression e) {
    return namedExpression(s, e);
  }

  static NamedExpression namedExpression(SimpleIdentifier s, Expression e) {
    Label l = new Label(s, new Token(TokenType.COLON, 0));
    return new NamedExpression(l, e);
  }

  static VariableDeclarationStatement variableDeclarationStatement(
      VariableDeclarationList varDecl) {
    var semi = new Token(TokenType.SEMICOLON, 0);
    return new VariableDeclarationStatement(varDecl, semi);
  }
}
