// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.testing.ast_test_factory;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

/**
 * The class `AstTestFactory` defines utility methods that can be used to create AST nodes. The
 * nodes that are created are complete in the sense that all of the tokens that would have been
 * associated with the nodes by a parser are also created, but the token stream is not constructed.
 * None of the nodes are resolved.
 *
 * The general pattern is for the name of the factory method to be the same as the name of the class
 * of AST node being created. There are two notable exceptions. The first is for methods creating
 * nodes that are part of a cascade expression. These methods are all prefixed with 'cascaded'. The
 * second is places where a shorter name seemed unambiguous and easier to read, such as using
 * 'identifier' rather than 'prefixedIdentifier', or 'integer' rather than 'integerLiteral'.
 */
class AstTestFactory {
  static AdjacentStrings adjacentStrings(List<StringLiteral> strings) =>
      astFactory.adjacentStrings(strings);

  static Annotation annotation(Identifier name) => astFactory.annotation(
      TokenFactory.tokenFromType(TokenType.AT), name, null, null, null);

  static Annotation annotation2(Identifier name,
          SimpleIdentifier constructorName, ArgumentList arguments) =>
      astFactory.annotation(
          TokenFactory.tokenFromType(TokenType.AT),
          name,
          constructorName == null
              ? null
              : TokenFactory.tokenFromType(TokenType.PERIOD),
          constructorName,
          arguments);

  static ArgumentList argumentList([List<Expression> arguments]) =>
      astFactory.argumentList(TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          arguments, TokenFactory.tokenFromType(TokenType.CLOSE_PAREN));

  static AsExpression asExpression(
          Expression expression, TypeAnnotation type) =>
      astFactory.asExpression(
          expression, TokenFactory.tokenFromKeyword(Keyword.AS), type);

  static AssertInitializer assertInitializer(
          Expression condition, Expression message) =>
      astFactory.assertInitializer(
          TokenFactory.tokenFromKeyword(Keyword.ASSERT),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          condition,
          TokenFactory.tokenFromType(TokenType.COMMA),
          message,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN));

  static AssertStatement assertStatement(Expression condition,
          [Expression message]) =>
      astFactory.assertStatement(
          TokenFactory.tokenFromKeyword(Keyword.ASSERT),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          condition,
          message == null ? null : TokenFactory.tokenFromType(TokenType.COMMA),
          message,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static AssignmentExpression assignmentExpression(Expression leftHandSide,
          TokenType operator, Expression rightHandSide) =>
      astFactory.assignmentExpression(
          leftHandSide, TokenFactory.tokenFromType(operator), rightHandSide);

  static BlockFunctionBody asyncBlockFunctionBody(
          [List<Statement> statements]) =>
      astFactory.blockFunctionBody(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "async"),
          null,
          block(statements));

  static ExpressionFunctionBody asyncExpressionFunctionBody(
          Expression expression) =>
      astFactory.expressionFunctionBody(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "async"),
          TokenFactory.tokenFromType(TokenType.FUNCTION),
          expression,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static BlockFunctionBody asyncGeneratorBlockFunctionBody(
          [List<Statement> statements]) =>
      astFactory.blockFunctionBody(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "async"),
          TokenFactory.tokenFromType(TokenType.STAR),
          block(statements));

  static AwaitExpression awaitExpression(Expression expression) =>
      astFactory.awaitExpression(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "await"),
          expression);

  static BinaryExpression binaryExpression(Expression leftOperand,
          TokenType operator, Expression rightOperand) =>
      astFactory.binaryExpression(
          leftOperand, TokenFactory.tokenFromType(operator), rightOperand);

  static Block block([List<Statement> statements]) => astFactory.block(
      TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET),
      statements,
      TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static BlockFunctionBody blockFunctionBody(Block block) =>
      astFactory.blockFunctionBody(null, null, block);

  static BlockFunctionBody blockFunctionBody2([List<Statement> statements]) =>
      astFactory.blockFunctionBody(null, null, block(statements));

  static BooleanLiteral booleanLiteral(bool value) => astFactory.booleanLiteral(
      value
          ? TokenFactory.tokenFromKeyword(Keyword.TRUE)
          : TokenFactory.tokenFromKeyword(Keyword.FALSE),
      value);

  static BreakStatement breakStatement() => astFactory.breakStatement(
      TokenFactory.tokenFromKeyword(Keyword.BREAK),
      null,
      TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static BreakStatement breakStatement2(String label) =>
      astFactory.breakStatement(TokenFactory.tokenFromKeyword(Keyword.BREAK),
          identifier3(label), TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static IndexExpression cascadedIndexExpression(Expression index) =>
      astFactory.indexExpressionForCascade(
          TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD),
          TokenFactory.tokenFromType(TokenType.OPEN_SQUARE_BRACKET),
          index,
          TokenFactory.tokenFromType(TokenType.CLOSE_SQUARE_BRACKET));

  static MethodInvocation cascadedMethodInvocation(String methodName,
          [List<Expression> arguments]) =>
      astFactory.methodInvocation(
          null,
          TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD),
          identifier3(methodName),
          null,
          argumentList(arguments));

  static PropertyAccess cascadedPropertyAccess(String propertyName) =>
      astFactory.propertyAccess(
          null,
          TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD),
          identifier3(propertyName));

  static CascadeExpression cascadeExpression(Expression target,
          [List<Expression> cascadeSections]) =>
      astFactory.cascadeExpression(target, cascadeSections);

  static CatchClause catchClause(String exceptionParameter,
          [List<Statement> statements]) =>
      catchClause5(null, exceptionParameter, null, statements);

  static CatchClause catchClause2(
          String exceptionParameter, String stackTraceParameter,
          [List<Statement> statements]) =>
      catchClause5(null, exceptionParameter, stackTraceParameter, statements);

  static CatchClause catchClause3(TypeAnnotation exceptionType,
          [List<Statement> statements]) =>
      catchClause5(exceptionType, null, null, statements);

  static CatchClause catchClause4(
          TypeAnnotation exceptionType, String exceptionParameter,
          [List<Statement> statements]) =>
      catchClause5(exceptionType, exceptionParameter, null, statements);

  static CatchClause catchClause5(TypeAnnotation exceptionType,
          String exceptionParameter, String stackTraceParameter,
          [List<Statement> statements]) =>
      astFactory.catchClause(
          exceptionType == null
              ? null
              : TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "on"),
          exceptionType,
          exceptionParameter == null
              ? null
              : TokenFactory.tokenFromKeyword(Keyword.CATCH),
          exceptionParameter == null
              ? null
              : TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          exceptionParameter == null ? null : identifier3(exceptionParameter),
          stackTraceParameter == null
              ? null
              : TokenFactory.tokenFromType(TokenType.COMMA),
          stackTraceParameter == null ? null : identifier3(stackTraceParameter),
          exceptionParameter == null
              ? null
              : TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          block(statements));

  static ClassDeclaration classDeclaration(
          Keyword abstractKeyword,
          String name,
          TypeParameterList typeParameters,
          ExtendsClause extendsClause,
          WithClause withClause,
          ImplementsClause implementsClause,
          [List<ClassMember> members]) =>
      astFactory.classDeclaration(
          null,
          null,
          abstractKeyword == null
              ? null
              : TokenFactory.tokenFromKeyword(abstractKeyword),
          TokenFactory.tokenFromKeyword(Keyword.CLASS),
          identifier3(name),
          typeParameters,
          extendsClause,
          withClause,
          implementsClause,
          TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET),
          members,
          TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static ClassTypeAlias classTypeAlias(
          String name,
          TypeParameterList typeParameters,
          Keyword abstractKeyword,
          TypeName superclass,
          WithClause withClause,
          ImplementsClause implementsClause) =>
      astFactory.classTypeAlias(
          null,
          null,
          TokenFactory.tokenFromKeyword(Keyword.CLASS),
          identifier3(name),
          typeParameters,
          TokenFactory.tokenFromType(TokenType.EQ),
          abstractKeyword == null
              ? null
              : TokenFactory.tokenFromKeyword(abstractKeyword),
          superclass,
          withClause,
          implementsClause,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static CompilationUnit compilationUnit() =>
      compilationUnit8(null, null, null);

  static CompilationUnit compilationUnit2(
          List<CompilationUnitMember> declarations) =>
      compilationUnit8(null, null, declarations);

  static CompilationUnit compilationUnit3(List<Directive> directives) =>
      compilationUnit8(null, directives, null);

  static CompilationUnit compilationUnit4(List<Directive> directives,
          List<CompilationUnitMember> declarations) =>
      compilationUnit8(null, directives, declarations);

  static CompilationUnit compilationUnit5(String scriptTag) =>
      compilationUnit8(scriptTag, null, null);

  static CompilationUnit compilationUnit6(
          String scriptTag, List<CompilationUnitMember> declarations) =>
      compilationUnit8(scriptTag, null, declarations);

  static CompilationUnit compilationUnit7(
          String scriptTag, List<Directive> directives) =>
      compilationUnit8(scriptTag, directives, null);

  static CompilationUnit compilationUnit8(
          String scriptTag,
          List<Directive> directives,
          List<CompilationUnitMember> declarations) =>
      astFactory.compilationUnit(
          TokenFactory.tokenFromType(TokenType.EOF),
          scriptTag == null ? null : AstTestFactory.scriptTag(scriptTag),
          directives == null ? new List<Directive>() : directives,
          declarations == null
              ? new List<CompilationUnitMember>()
              : declarations,
          TokenFactory.tokenFromType(TokenType.EOF));

  static ConditionalExpression conditionalExpression(Expression condition,
          Expression thenExpression, Expression elseExpression) =>
      astFactory.conditionalExpression(
          condition,
          TokenFactory.tokenFromType(TokenType.QUESTION),
          thenExpression,
          TokenFactory.tokenFromType(TokenType.COLON),
          elseExpression);

  static ConstructorDeclaration constructorDeclaration(
          Identifier returnType,
          String name,
          FormalParameterList parameters,
          List<ConstructorInitializer> initializers) =>
      astFactory.constructorDeclaration(
          null,
          null,
          TokenFactory.tokenFromKeyword(Keyword.EXTERNAL),
          null,
          null,
          returnType,
          name == null ? null : TokenFactory.tokenFromType(TokenType.PERIOD),
          name == null ? null : identifier3(name),
          parameters,
          initializers == null || initializers.isEmpty
              ? null
              : TokenFactory.tokenFromType(TokenType.PERIOD),
          initializers == null
              ? new List<ConstructorInitializer>()
              : initializers,
          null,
          emptyFunctionBody());

  static ConstructorDeclaration constructorDeclaration2(
          Keyword constKeyword,
          Keyword factoryKeyword,
          Identifier returnType,
          String name,
          FormalParameterList parameters,
          List<ConstructorInitializer> initializers,
          FunctionBody body) =>
      astFactory.constructorDeclaration(
          null,
          null,
          null,
          constKeyword == null
              ? null
              : TokenFactory.tokenFromKeyword(constKeyword),
          factoryKeyword == null
              ? null
              : TokenFactory.tokenFromKeyword(factoryKeyword),
          returnType,
          name == null ? null : TokenFactory.tokenFromType(TokenType.PERIOD),
          name == null ? null : identifier3(name),
          parameters,
          initializers == null || initializers.isEmpty
              ? null
              : TokenFactory.tokenFromType(TokenType.PERIOD),
          initializers == null
              ? new List<ConstructorInitializer>()
              : initializers,
          null,
          body);

  static ConstructorFieldInitializer constructorFieldInitializer(
          bool prefixedWithThis, String fieldName, Expression expression) =>
      astFactory.constructorFieldInitializer(
          prefixedWithThis ? TokenFactory.tokenFromKeyword(Keyword.THIS) : null,
          prefixedWithThis
              ? TokenFactory.tokenFromType(TokenType.PERIOD)
              : null,
          identifier3(fieldName),
          TokenFactory.tokenFromType(TokenType.EQ),
          expression);

  static ConstructorName constructorName(TypeName type, String name) =>
      astFactory.constructorName(
          type,
          name == null ? null : TokenFactory.tokenFromType(TokenType.PERIOD),
          name == null ? null : identifier3(name));

  static ContinueStatement continueStatement([String label]) =>
      astFactory.continueStatement(
          TokenFactory.tokenFromKeyword(Keyword.CONTINUE),
          label == null ? null : identifier3(label),
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static DeclaredIdentifier declaredIdentifier(
          Keyword keyword, String identifier) =>
      declaredIdentifier2(keyword, null, identifier);

  static DeclaredIdentifier declaredIdentifier2(
          Keyword keyword, TypeAnnotation type, String identifier) =>
      astFactory.declaredIdentifier(
          null,
          null,
          keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
          type,
          identifier3(identifier));

  static DeclaredIdentifier declaredIdentifier3(String identifier) =>
      declaredIdentifier2(Keyword.VAR, null, identifier);

  static DeclaredIdentifier declaredIdentifier4(
          TypeAnnotation type, String identifier) =>
      declaredIdentifier2(null, type, identifier);

  static Comment documentationComment(
      List<Token> tokens, List<CommentReference> references) {
    return astFactory.documentationComment(tokens, references);
  }

  static DoStatement doStatement(Statement body, Expression condition) =>
      astFactory.doStatement(
          TokenFactory.tokenFromKeyword(Keyword.DO),
          body,
          TokenFactory.tokenFromKeyword(Keyword.WHILE),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          condition,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static DoubleLiteral doubleLiteral(double value) => astFactory.doubleLiteral(
      TokenFactory.tokenFromString(value.toString()), value);

  static EmptyFunctionBody emptyFunctionBody() => astFactory
      .emptyFunctionBody(TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static EmptyStatement emptyStatement() => astFactory
      .emptyStatement(TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static EnumDeclaration enumDeclaration(
          SimpleIdentifier name, List<EnumConstantDeclaration> constants) =>
      astFactory.enumDeclaration(
          null,
          null,
          TokenFactory.tokenFromKeyword(Keyword.ENUM),
          name,
          TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET),
          constants,
          TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static EnumDeclaration enumDeclaration2(
      String name, List<String> constantNames) {
    int count = constantNames.length;
    List<EnumConstantDeclaration> constants =
        new List<EnumConstantDeclaration>(count);
    for (int i = 0; i < count; i++) {
      constants[i] = astFactory.enumConstantDeclaration(
          null, null, identifier3(constantNames[i]));
    }
    return enumDeclaration(identifier3(name), constants);
  }

  static ExportDirective exportDirective(List<Annotation> metadata, String uri,
          [List<Combinator> combinators]) =>
      astFactory.exportDirective(
          null,
          metadata,
          TokenFactory.tokenFromKeyword(Keyword.EXPORT),
          string2(uri),
          null,
          combinators,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static ExportDirective exportDirective2(String uri,
          [List<Combinator> combinators]) =>
      exportDirective(null, uri, combinators);

  static ExpressionFunctionBody expressionFunctionBody(Expression expression) =>
      astFactory.expressionFunctionBody(
          null,
          TokenFactory.tokenFromType(TokenType.FUNCTION),
          expression,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static ExpressionStatement expressionStatement(Expression expression) =>
      astFactory.expressionStatement(
          expression, TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static ExtendsClause extendsClause(TypeName type) => astFactory.extendsClause(
      TokenFactory.tokenFromKeyword(Keyword.EXTENDS), type);

  static FieldDeclaration fieldDeclaration(bool isStatic, Keyword keyword,
          TypeAnnotation type, List<VariableDeclaration> variables) =>
      astFactory.fieldDeclaration2(
          staticKeyword:
              isStatic ? TokenFactory.tokenFromKeyword(Keyword.STATIC) : null,
          fieldList: variableDeclarationList(keyword, type, variables),
          semicolon: TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static FieldDeclaration fieldDeclaration2(bool isStatic, Keyword keyword,
          List<VariableDeclaration> variables) =>
      fieldDeclaration(isStatic, keyword, null, variables);

  static FieldFormalParameter fieldFormalParameter(
          Keyword keyword, TypeAnnotation type, String identifier,
          [FormalParameterList parameterList]) =>
      astFactory.fieldFormalParameter2(
          keyword:
              keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
          type: type,
          thisKeyword: TokenFactory.tokenFromKeyword(Keyword.THIS),
          period: TokenFactory.tokenFromType(TokenType.PERIOD),
          identifier: identifier3(identifier),
          parameters: parameterList);

  static FieldFormalParameter fieldFormalParameter2(String identifier) =>
      fieldFormalParameter(null, null, identifier);

  static ForEachStatement forEachStatement(DeclaredIdentifier loopVariable,
          Expression iterator, Statement body) =>
      astFactory.forEachStatementWithDeclaration(
          null,
          TokenFactory.tokenFromKeyword(Keyword.FOR),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          loopVariable,
          TokenFactory.tokenFromKeyword(Keyword.IN),
          iterator,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          body);

  static ForEachStatement forEachStatement2(
          SimpleIdentifier identifier, Expression iterator, Statement body) =>
      astFactory.forEachStatementWithReference(
          null,
          TokenFactory.tokenFromKeyword(Keyword.FOR),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          identifier,
          TokenFactory.tokenFromKeyword(Keyword.IN),
          iterator,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          body);

  static FormalParameterList formalParameterList(
          [List<FormalParameter> parameters]) =>
      astFactory.formalParameterList(
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          parameters,
          null,
          null,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN));

  static ForStatement forStatement(Expression initialization,
          Expression condition, List<Expression> updaters, Statement body) =>
      astFactory.forStatement(
          TokenFactory.tokenFromKeyword(Keyword.FOR),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          null,
          initialization,
          TokenFactory.tokenFromType(TokenType.SEMICOLON),
          condition,
          TokenFactory.tokenFromType(TokenType.SEMICOLON),
          updaters,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          body);

  static ForStatement forStatement2(VariableDeclarationList variableList,
          Expression condition, List<Expression> updaters, Statement body) =>
      astFactory.forStatement(
          TokenFactory.tokenFromKeyword(Keyword.FOR),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          variableList,
          null,
          TokenFactory.tokenFromType(TokenType.SEMICOLON),
          condition,
          TokenFactory.tokenFromType(TokenType.SEMICOLON),
          updaters,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          body);

  static FunctionDeclaration functionDeclaration(
          TypeAnnotation type,
          Keyword keyword,
          String name,
          FunctionExpression functionExpression) =>
      astFactory.functionDeclaration(
          null,
          null,
          null,
          type,
          keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
          identifier3(name),
          functionExpression);

  static FunctionDeclarationStatement functionDeclarationStatement(
          TypeAnnotation type,
          Keyword keyword,
          String name,
          FunctionExpression functionExpression) =>
      astFactory.functionDeclarationStatement(
          functionDeclaration(type, keyword, name, functionExpression));

  static FunctionExpression functionExpression() => astFactory
      .functionExpression(null, formalParameterList(), blockFunctionBody2());

  static FunctionExpression functionExpression2(
          FormalParameterList parameters, FunctionBody body) =>
      astFactory.functionExpression(null, parameters, body);

  static FunctionExpression functionExpression3(
          TypeParameterList typeParameters,
          FormalParameterList parameters,
          FunctionBody body) =>
      astFactory.functionExpression(typeParameters, parameters, body);

  static FunctionExpressionInvocation functionExpressionInvocation(
          Expression function,
          [List<Expression> arguments]) =>
      functionExpressionInvocation2(function, null, arguments);

  static FunctionExpressionInvocation functionExpressionInvocation2(
          Expression function,
          [TypeArgumentList typeArguments,
          List<Expression> arguments]) =>
      astFactory.functionExpressionInvocation(
          function, typeArguments, argumentList(arguments));

  static FunctionTypedFormalParameter functionTypedFormalParameter(
          TypeAnnotation returnType, String identifier,
          [List<FormalParameter> parameters]) =>
      astFactory.functionTypedFormalParameter2(
          returnType: returnType,
          identifier: identifier3(identifier),
          parameters: formalParameterList(parameters));

  static GenericFunctionType genericFunctionType(TypeAnnotation returnType,
          TypeParameterList typeParameters, FormalParameterList parameters) =>
      astFactory.genericFunctionType(returnType,
          TokenFactory.tokenFromString("Function"), typeParameters, parameters);

  static GenericTypeAlias genericTypeAlias(String name,
          TypeParameterList typeParameters, GenericFunctionType functionType) =>
      astFactory.genericTypeAlias(
          null,
          null,
          TokenFactory.tokenFromKeyword(Keyword.TYPEDEF),
          identifier3(name),
          typeParameters,
          TokenFactory.tokenFromType(TokenType.EQ),
          functionType,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static HideCombinator hideCombinator(List<SimpleIdentifier> identifiers) =>
      astFactory.hideCombinator(
          TokenFactory.tokenFromString("hide"), identifiers);

  static HideCombinator hideCombinator2(List<String> identifiers) =>
      astFactory.hideCombinator(
          TokenFactory.tokenFromString("hide"), identifierList(identifiers));

  static PrefixedIdentifier identifier(
          SimpleIdentifier prefix, SimpleIdentifier identifier) =>
      astFactory.prefixedIdentifier(
          prefix, TokenFactory.tokenFromType(TokenType.PERIOD), identifier);

  static SimpleIdentifier identifier3(String lexeme) =>
      astFactory.simpleIdentifier(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, lexeme));

  static PrefixedIdentifier identifier4(
          String prefix, SimpleIdentifier identifier) =>
      astFactory.prefixedIdentifier(identifier3(prefix),
          TokenFactory.tokenFromType(TokenType.PERIOD), identifier);

  static PrefixedIdentifier identifier5(String prefix, String identifier) =>
      astFactory.prefixedIdentifier(
          identifier3(prefix),
          TokenFactory.tokenFromType(TokenType.PERIOD),
          identifier3(identifier));

  static List<SimpleIdentifier> identifierList(List<String> identifiers) {
    if (identifiers == null) {
      return null;
    }
    return identifiers
        .map((String identifier) => identifier3(identifier))
        .toList();
  }

  static IfStatement ifStatement(
          Expression condition, Statement thenStatement) =>
      ifStatement2(condition, thenStatement, null);

  static IfStatement ifStatement2(Expression condition, Statement thenStatement,
          Statement elseStatement) =>
      astFactory.ifStatement(
          TokenFactory.tokenFromKeyword(Keyword.IF),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          condition,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          thenStatement,
          elseStatement == null
              ? null
              : TokenFactory.tokenFromKeyword(Keyword.ELSE),
          elseStatement);

  static ImplementsClause implementsClause(List<TypeName> types) =>
      astFactory.implementsClause(
          TokenFactory.tokenFromKeyword(Keyword.IMPLEMENTS), types);

  static ImportDirective importDirective(
          List<Annotation> metadata, String uri, bool isDeferred, String prefix,
          [List<Combinator> combinators]) =>
      astFactory.importDirective(
          null,
          metadata,
          TokenFactory.tokenFromKeyword(Keyword.IMPORT),
          string2(uri),
          null,
          !isDeferred ? null : TokenFactory.tokenFromKeyword(Keyword.DEFERRED),
          prefix == null ? null : TokenFactory.tokenFromKeyword(Keyword.AS),
          prefix == null ? null : identifier3(prefix),
          combinators,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static ImportDirective importDirective2(
          String uri, bool isDeferred, String prefix,
          [List<Combinator> combinators]) =>
      importDirective(null, uri, isDeferred, prefix, combinators);

  static ImportDirective importDirective3(String uri, String prefix,
          [List<Combinator> combinators]) =>
      importDirective(null, uri, false, prefix, combinators);

  static IndexExpression indexExpression(Expression array, Expression index) =>
      astFactory.indexExpressionForTarget(
          array,
          TokenFactory.tokenFromType(TokenType.OPEN_SQUARE_BRACKET),
          index,
          TokenFactory.tokenFromType(TokenType.CLOSE_SQUARE_BRACKET));

  static InstanceCreationExpression instanceCreationExpression(
          Keyword keyword, ConstructorName name,
          [List<Expression> arguments]) =>
      astFactory.instanceCreationExpression(
          keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
          name,
          argumentList(arguments));

  static InstanceCreationExpression instanceCreationExpression2(
          Keyword keyword, TypeName type,
          [List<Expression> arguments]) =>
      instanceCreationExpression3(keyword, type, null, arguments);

  static InstanceCreationExpression instanceCreationExpression3(
          Keyword keyword, TypeName type, String identifier,
          [List<Expression> arguments]) =>
      instanceCreationExpression(
          keyword,
          astFactory.constructorName(
              type,
              identifier == null
                  ? null
                  : TokenFactory.tokenFromType(TokenType.PERIOD),
              identifier == null ? null : identifier3(identifier)),
          arguments);

  static IntegerLiteral integer(int value) => astFactory.integerLiteral(
      TokenFactory.tokenFromTypeAndString(TokenType.INT, value.toString()),
      value);

  static InterpolationExpression interpolationExpression(
          Expression expression) =>
      astFactory.interpolationExpression(
          TokenFactory.tokenFromType(TokenType.STRING_INTERPOLATION_EXPRESSION),
          expression,
          TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static InterpolationExpression interpolationExpression2(String identifier) =>
      astFactory.interpolationExpression(
          TokenFactory.tokenFromType(TokenType.STRING_INTERPOLATION_IDENTIFIER),
          identifier3(identifier),
          null);

  static InterpolationString interpolationString(
          String contents, String value) =>
      astFactory.interpolationString(
          TokenFactory.tokenFromString(contents), value);

  static IsExpression isExpression(
          Expression expression, bool negated, TypeAnnotation type) =>
      astFactory.isExpression(
          expression,
          TokenFactory.tokenFromKeyword(Keyword.IS),
          negated ? TokenFactory.tokenFromType(TokenType.BANG) : null,
          type);

  static Label label(SimpleIdentifier label) =>
      astFactory.label(label, TokenFactory.tokenFromType(TokenType.COLON));

  static Label label2(String label) => AstTestFactory.label(identifier3(label));

  static LabeledStatement labeledStatement(
          List<Label> labels, Statement statement) =>
      astFactory.labeledStatement(labels, statement);

  static LibraryDirective libraryDirective(
          List<Annotation> metadata, LibraryIdentifier libraryName) =>
      astFactory.libraryDirective(
          null,
          metadata,
          TokenFactory.tokenFromKeyword(Keyword.LIBRARY),
          libraryName,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static LibraryDirective libraryDirective2(String libraryName) =>
      libraryDirective(
          new List<Annotation>(), libraryIdentifier2([libraryName]));

  static LibraryIdentifier libraryIdentifier(
          List<SimpleIdentifier> components) =>
      astFactory.libraryIdentifier(components);

  static LibraryIdentifier libraryIdentifier2(List<String> components) {
    return astFactory.libraryIdentifier(identifierList(components));
  }

  static List list(List<Object> elements) {
    return elements;
  }

  static ListLiteral listLiteral([List<Expression> elements]) =>
      listLiteral2(null, null, elements);

  static ListLiteral listLiteral2(
          Keyword keyword, TypeArgumentList typeArguments,
          [List<Expression> elements]) =>
      astFactory.listLiteral(
          keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
          typeArguments,
          TokenFactory.tokenFromType(TokenType.OPEN_SQUARE_BRACKET),
          elements,
          TokenFactory.tokenFromType(TokenType.CLOSE_SQUARE_BRACKET));

  static MapLiteral mapLiteral(Keyword keyword, TypeArgumentList typeArguments,
          [List<MapLiteralEntry> entries]) =>
      astFactory.mapLiteral(
          keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
          typeArguments,
          TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET),
          entries,
          TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static MapLiteral mapLiteral2([List<MapLiteralEntry> entries]) =>
      mapLiteral(null, null, entries);

  static MapLiteralEntry mapLiteralEntry(String key, Expression value) =>
      astFactory.mapLiteralEntry(
          string2(key), TokenFactory.tokenFromType(TokenType.COLON), value);

  static MapLiteralEntry mapLiteralEntry2(Expression key, Expression value) =>
      astFactory.mapLiteralEntry(
          key, TokenFactory.tokenFromType(TokenType.COLON), value);

  static MethodDeclaration methodDeclaration(
          Keyword modifier,
          TypeAnnotation returnType,
          Keyword property,
          Keyword operator,
          SimpleIdentifier name,
          FormalParameterList parameters) =>
      astFactory.methodDeclaration(
          null,
          null,
          TokenFactory.tokenFromKeyword(Keyword.EXTERNAL),
          modifier == null ? null : TokenFactory.tokenFromKeyword(modifier),
          returnType,
          property == null ? null : TokenFactory.tokenFromKeyword(property),
          operator == null ? null : TokenFactory.tokenFromKeyword(operator),
          name,
          null,
          parameters,
          emptyFunctionBody());

  static MethodDeclaration methodDeclaration2(
          Keyword modifier,
          TypeAnnotation returnType,
          Keyword property,
          Keyword operator,
          SimpleIdentifier name,
          FormalParameterList parameters,
          FunctionBody body) =>
      astFactory.methodDeclaration(
          null,
          null,
          null,
          modifier == null ? null : TokenFactory.tokenFromKeyword(modifier),
          returnType,
          property == null ? null : TokenFactory.tokenFromKeyword(property),
          operator == null ? null : TokenFactory.tokenFromKeyword(operator),
          name,
          null,
          parameters,
          body);

  static MethodDeclaration methodDeclaration3(
          Keyword modifier,
          TypeAnnotation returnType,
          Keyword property,
          Keyword operator,
          SimpleIdentifier name,
          TypeParameterList typeParameters,
          FormalParameterList parameters,
          FunctionBody body) =>
      astFactory.methodDeclaration(
          null,
          null,
          null,
          modifier == null ? null : TokenFactory.tokenFromKeyword(modifier),
          returnType,
          property == null ? null : TokenFactory.tokenFromKeyword(property),
          operator == null ? null : TokenFactory.tokenFromKeyword(operator),
          name,
          typeParameters,
          parameters,
          body);

  static MethodDeclaration methodDeclaration4(
          {bool external: false,
          Keyword modifier,
          TypeAnnotation returnType,
          Keyword property,
          bool operator: false,
          String name,
          FormalParameterList parameters,
          FunctionBody body}) =>
      astFactory.methodDeclaration(
          null,
          null,
          external ? TokenFactory.tokenFromKeyword(Keyword.EXTERNAL) : null,
          modifier == null ? null : TokenFactory.tokenFromKeyword(modifier),
          returnType,
          property == null ? null : TokenFactory.tokenFromKeyword(property),
          operator ? TokenFactory.tokenFromKeyword(Keyword.OPERATOR) : null,
          identifier3(name),
          null,
          parameters,
          body);

  static MethodInvocation methodInvocation(Expression target, String methodName,
          [List<Expression> arguments,
          TokenType operator = TokenType.PERIOD]) =>
      astFactory.methodInvocation(
          target,
          target == null ? null : TokenFactory.tokenFromType(operator),
          identifier3(methodName),
          null,
          argumentList(arguments));

  static MethodInvocation methodInvocation2(String methodName,
          [List<Expression> arguments]) =>
      methodInvocation(null, methodName, arguments);

  static MethodInvocation methodInvocation3(
          Expression target, String methodName, TypeArgumentList typeArguments,
          [List<Expression> arguments,
          TokenType operator = TokenType.PERIOD]) =>
      astFactory.methodInvocation(
          target,
          target == null ? null : TokenFactory.tokenFromType(operator),
          identifier3(methodName),
          typeArguments,
          argumentList(arguments));

  static NamedExpression namedExpression(Label label, Expression expression) =>
      astFactory.namedExpression(label, expression);

  static NamedExpression namedExpression2(
          String label, Expression expression) =>
      namedExpression(label2(label), expression);

  static DefaultFormalParameter namedFormalParameter(
          NormalFormalParameter parameter, Expression expression) =>
      astFactory.defaultFormalParameter(
          parameter,
          ParameterKind.NAMED,
          expression == null
              ? null
              : TokenFactory.tokenFromType(TokenType.COLON),
          expression);

  static NativeClause nativeClause(String nativeCode) =>
      astFactory.nativeClause(
          TokenFactory.tokenFromString("native"), string2(nativeCode));

  static NativeFunctionBody nativeFunctionBody(String nativeMethodName) =>
      astFactory.nativeFunctionBody(
          TokenFactory.tokenFromString("native"),
          string2(nativeMethodName),
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static NullLiteral nullLiteral() =>
      astFactory.nullLiteral(TokenFactory.tokenFromKeyword(Keyword.NULL));

  static ParenthesizedExpression parenthesizedExpression(
          Expression expression) =>
      astFactory.parenthesizedExpression(
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          expression,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN));

  static PartDirective partDirective(List<Annotation> metadata, String url) =>
      astFactory.partDirective(
          null,
          metadata,
          TokenFactory.tokenFromKeyword(Keyword.PART),
          string2(url),
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static PartDirective partDirective2(String url) =>
      partDirective(new List<Annotation>(), url);

  static PartOfDirective partOfDirective(LibraryIdentifier libraryName) =>
      partOfDirective2(new List<Annotation>(), libraryName);

  static PartOfDirective partOfDirective2(
          List<Annotation> metadata, LibraryIdentifier libraryName) =>
      astFactory.partOfDirective(
          null,
          metadata,
          TokenFactory.tokenFromKeyword(Keyword.PART),
          TokenFactory.tokenFromString("of"),
          null,
          libraryName,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static DefaultFormalParameter positionalFormalParameter(
          NormalFormalParameter parameter, Expression expression) =>
      astFactory.defaultFormalParameter(
          parameter,
          ParameterKind.POSITIONAL,
          expression == null ? null : TokenFactory.tokenFromType(TokenType.EQ),
          expression);

  static PostfixExpression postfixExpression(
          Expression expression, TokenType operator) =>
      astFactory.postfixExpression(
          expression, TokenFactory.tokenFromType(operator));

  static PrefixExpression prefixExpression(
          TokenType operator, Expression expression) =>
      astFactory.prefixExpression(
          TokenFactory.tokenFromType(operator), expression);

  static PropertyAccess propertyAccess(
          Expression target, SimpleIdentifier propertyName) =>
      astFactory.propertyAccess(
          target, TokenFactory.tokenFromType(TokenType.PERIOD), propertyName);

  static PropertyAccess propertyAccess2(Expression target, String propertyName,
          [TokenType operator = TokenType.PERIOD]) =>
      astFactory.propertyAccess(target, TokenFactory.tokenFromType(operator),
          identifier3(propertyName));

  static RedirectingConstructorInvocation redirectingConstructorInvocation(
          [List<Expression> arguments]) =>
      redirectingConstructorInvocation2(null, arguments);

  static RedirectingConstructorInvocation redirectingConstructorInvocation2(
          String constructorName,
          [List<Expression> arguments]) =>
      astFactory.redirectingConstructorInvocation(
          TokenFactory.tokenFromKeyword(Keyword.THIS),
          constructorName == null
              ? null
              : TokenFactory.tokenFromType(TokenType.PERIOD),
          constructorName == null ? null : identifier3(constructorName),
          argumentList(arguments));

  static RethrowExpression rethrowExpression() => astFactory
      .rethrowExpression(TokenFactory.tokenFromKeyword(Keyword.RETHROW));

  static ReturnStatement returnStatement() => returnStatement2(null);

  static ReturnStatement returnStatement2(Expression expression) =>
      astFactory.returnStatement(TokenFactory.tokenFromKeyword(Keyword.RETURN),
          expression, TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static ScriptTag scriptTag(String scriptTag) =>
      astFactory.scriptTag(TokenFactory.tokenFromString(scriptTag));

  static ShowCombinator showCombinator(List<SimpleIdentifier> identifiers) =>
      astFactory.showCombinator(
          TokenFactory.tokenFromString("show"), identifiers);

  static ShowCombinator showCombinator2(List<String> identifiers) =>
      astFactory.showCombinator(
          TokenFactory.tokenFromString("show"), identifierList(identifiers));

  static SimpleFormalParameter simpleFormalParameter(
          Keyword keyword, String parameterName) =>
      simpleFormalParameter2(keyword, null, parameterName);

  static SimpleFormalParameter simpleFormalParameter2(
          Keyword keyword, TypeAnnotation type, String parameterName) =>
      astFactory.simpleFormalParameter2(
          keyword:
              keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
          type: type,
          identifier:
              parameterName == null ? null : identifier3(parameterName));

  static SimpleFormalParameter simpleFormalParameter3(String parameterName) =>
      simpleFormalParameter2(null, null, parameterName);

  static SimpleFormalParameter simpleFormalParameter4(
          TypeAnnotation type, String parameterName) =>
      simpleFormalParameter2(null, type, parameterName);

  static StringInterpolation string([List<InterpolationElement> elements]) =>
      astFactory.stringInterpolation(elements);

  static SimpleStringLiteral string2(String content) => astFactory
      .simpleStringLiteral(TokenFactory.tokenFromString("'$content'"), content);

  static SuperConstructorInvocation superConstructorInvocation(
          [List<Expression> arguments]) =>
      superConstructorInvocation2(null, arguments);

  static SuperConstructorInvocation superConstructorInvocation2(String name,
          [List<Expression> arguments]) =>
      astFactory.superConstructorInvocation(
          TokenFactory.tokenFromKeyword(Keyword.SUPER),
          name == null ? null : TokenFactory.tokenFromType(TokenType.PERIOD),
          name == null ? null : identifier3(name),
          argumentList(arguments));

  static SuperExpression superExpression() =>
      astFactory.superExpression(TokenFactory.tokenFromKeyword(Keyword.SUPER));

  static SwitchCase switchCase(
          Expression expression, List<Statement> statements) =>
      switchCase2(new List<Label>(), expression, statements);

  static SwitchCase switchCase2(List<Label> labels, Expression expression,
          List<Statement> statements) =>
      astFactory.switchCase(labels, TokenFactory.tokenFromKeyword(Keyword.CASE),
          expression, TokenFactory.tokenFromType(TokenType.COLON), statements);

  static SwitchDefault switchDefault(
          List<Label> labels, List<Statement> statements) =>
      astFactory.switchDefault(
          labels,
          TokenFactory.tokenFromKeyword(Keyword.DEFAULT),
          TokenFactory.tokenFromType(TokenType.COLON),
          statements);

  static SwitchDefault switchDefault2(List<Statement> statements) =>
      switchDefault(new List<Label>(), statements);

  static SwitchStatement switchStatement(
          Expression expression, List<SwitchMember> members) =>
      astFactory.switchStatement(
          TokenFactory.tokenFromKeyword(Keyword.SWITCH),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          expression,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET),
          members,
          TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static SymbolLiteral symbolLiteral(List<String> components) {
    List<Token> identifierList = new List<Token>();
    for (String component in components) {
      identifierList.add(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, component));
    }
    return astFactory.symbolLiteral(
        TokenFactory.tokenFromType(TokenType.HASH), identifierList);
  }

  static BlockFunctionBody syncBlockFunctionBody(
          [List<Statement> statements]) =>
      astFactory.blockFunctionBody(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "sync"),
          null,
          block(statements));

  static BlockFunctionBody syncGeneratorBlockFunctionBody(
          [List<Statement> statements]) =>
      astFactory.blockFunctionBody(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "sync"),
          TokenFactory.tokenFromType(TokenType.STAR),
          block(statements));

  static ThisExpression thisExpression() =>
      astFactory.thisExpression(TokenFactory.tokenFromKeyword(Keyword.THIS));

  static ThrowExpression throwExpression() => throwExpression2(null);

  static ThrowExpression throwExpression2(Expression expression) =>
      astFactory.throwExpression(
          TokenFactory.tokenFromKeyword(Keyword.THROW), expression);

  static TopLevelVariableDeclaration topLevelVariableDeclaration(
          Keyword keyword,
          TypeAnnotation type,
          List<VariableDeclaration> variables) =>
      astFactory.topLevelVariableDeclaration(
          null,
          null,
          variableDeclarationList(keyword, type, variables),
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static TopLevelVariableDeclaration topLevelVariableDeclaration2(
          Keyword keyword, List<VariableDeclaration> variables) =>
      astFactory.topLevelVariableDeclaration(
          null,
          null,
          variableDeclarationList(keyword, null, variables),
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static TryStatement tryStatement(Block body, Block finallyClause) =>
      tryStatement3(body, new List<CatchClause>(), finallyClause);

  static TryStatement tryStatement2(
          Block body, List<CatchClause> catchClauses) =>
      tryStatement3(body, catchClauses, null);

  static TryStatement tryStatement3(
          Block body, List<CatchClause> catchClauses, Block finallyClause) =>
      astFactory.tryStatement(
          TokenFactory.tokenFromKeyword(Keyword.TRY),
          body,
          catchClauses,
          finallyClause == null
              ? null
              : TokenFactory.tokenFromKeyword(Keyword.FINALLY),
          finallyClause);

  static FunctionTypeAlias typeAlias(TypeAnnotation returnType, String name,
          TypeParameterList typeParameters, FormalParameterList parameters) =>
      astFactory.functionTypeAlias(
          null,
          null,
          TokenFactory.tokenFromKeyword(Keyword.TYPEDEF),
          returnType,
          identifier3(name),
          typeParameters,
          parameters,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static TypeArgumentList typeArgumentList(List<TypeAnnotation> types) {
    if (types == null || types.length == 0) {
      return null;
    }
    return astFactory.typeArgumentList(TokenFactory.tokenFromType(TokenType.LT),
        types, TokenFactory.tokenFromType(TokenType.GT));
  }

  /**
   * Create a type name whose name has been resolved to the given [element] and
   * whose type has been resolved to the type of the given element.
   *
   * <b>Note:</b> This method does not correctly handle class elements that have
   * type parameters.
   */
  static TypeName typeName(ClassElement element,
      [List<TypeAnnotation> arguments]) {
    SimpleIdentifier name = identifier3(element.name);
    name.staticElement = element;
    TypeName typeName = typeName3(name, arguments);
    typeName.type = element.type;
    return typeName;
  }

  static TypeName typeName3(Identifier name,
          [List<TypeAnnotation> arguments]) =>
      astFactory.typeName(name, typeArgumentList(arguments));

  static TypeName typeName4(String name, [List<TypeAnnotation> arguments]) =>
      astFactory.typeName(identifier3(name), typeArgumentList(arguments));

  static TypeParameter typeParameter(String name) =>
      astFactory.typeParameter(null, null, identifier3(name), null, null);

  static TypeParameter typeParameter2(String name, TypeAnnotation bound) =>
      astFactory.typeParameter(null, null, identifier3(name),
          TokenFactory.tokenFromKeyword(Keyword.EXTENDS), bound);

  static TypeParameterList typeParameterList([List<String> typeNames]) {
    List<TypeParameter> typeParameters = null;
    if (typeNames != null && !typeNames.isEmpty) {
      typeParameters = new List<TypeParameter>();
      for (String typeName in typeNames) {
        typeParameters.add(typeParameter(typeName));
      }
    }
    return astFactory.typeParameterList(
        TokenFactory.tokenFromType(TokenType.LT),
        typeParameters,
        TokenFactory.tokenFromType(TokenType.GT));
  }

  static VariableDeclaration variableDeclaration(String name) =>
      astFactory.variableDeclaration(identifier3(name), null, null);

  static VariableDeclaration variableDeclaration2(
          String name, Expression initializer) =>
      astFactory.variableDeclaration(identifier3(name),
          TokenFactory.tokenFromType(TokenType.EQ), initializer);

  static VariableDeclarationList variableDeclarationList(Keyword keyword,
          TypeAnnotation type, List<VariableDeclaration> variables) =>
      astFactory.variableDeclarationList(
          null,
          null,
          keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
          type,
          variables);

  static VariableDeclarationList variableDeclarationList2(
          Keyword keyword, List<VariableDeclaration> variables) =>
      variableDeclarationList(keyword, null, variables);

  static VariableDeclarationStatement variableDeclarationStatement(
          Keyword keyword,
          TypeAnnotation type,
          List<VariableDeclaration> variables) =>
      astFactory.variableDeclarationStatement(
          variableDeclarationList(keyword, type, variables),
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static VariableDeclarationStatement variableDeclarationStatement2(
          Keyword keyword, List<VariableDeclaration> variables) =>
      variableDeclarationStatement(keyword, null, variables);

  static WhileStatement whileStatement(Expression condition, Statement body) =>
      astFactory.whileStatement(
          TokenFactory.tokenFromKeyword(Keyword.WHILE),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          condition,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          body);

  static WithClause withClause(List<TypeName> types) =>
      astFactory.withClause(TokenFactory.tokenFromKeyword(Keyword.WITH), types);

  static YieldStatement yieldEachStatement(Expression expression) =>
      astFactory.yieldStatement(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "yield"),
          TokenFactory.tokenFromType(TokenType.STAR),
          expression,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static YieldStatement yieldStatement(Expression expression) =>
      astFactory.yieldStatement(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "yield"),
          null,
          expression,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));
}
