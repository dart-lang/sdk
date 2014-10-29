// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.testing.ast_factory;

import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';

/**
 * The class `AstFactory` defines utility methods that can be used to create AST nodes. The
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
class AstFactory {
  static AdjacentStrings adjacentStrings(List<StringLiteral> strings) => new AdjacentStrings(list(strings));

  static Annotation annotation(Identifier name) => new Annotation(TokenFactory.tokenFromType(TokenType.AT), name, null, null, null);

  static Annotation annotation2(Identifier name, SimpleIdentifier constructorName, ArgumentList arguments) => new Annotation(TokenFactory.tokenFromType(TokenType.AT), name, TokenFactory.tokenFromType(TokenType.PERIOD), constructorName, arguments);

  static ArgumentList argumentList(List<Expression> arguments) => new ArgumentList(TokenFactory.tokenFromType(TokenType.OPEN_PAREN), list(arguments), TokenFactory.tokenFromType(TokenType.CLOSE_PAREN));

  static AsExpression asExpression(Expression expression, TypeName type) => new AsExpression(expression, TokenFactory.tokenFromKeyword(Keyword.AS), type);

  static AssertStatement assertStatement(Expression condition) => new AssertStatement(TokenFactory.tokenFromKeyword(Keyword.ASSERT), TokenFactory.tokenFromType(TokenType.OPEN_PAREN), condition, TokenFactory.tokenFromType(TokenType.CLOSE_PAREN), TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static AssignmentExpression assignmentExpression(Expression leftHandSide, TokenType operator, Expression rightHandSide) => new AssignmentExpression(leftHandSide, TokenFactory.tokenFromType(operator), rightHandSide);

  static BlockFunctionBody asyncBlockFunctionBody(List<Statement> statements) => new BlockFunctionBody(TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "async"), null, block(statements));

  static ExpressionFunctionBody asyncExpressionFunctionBody(Expression expression) => new ExpressionFunctionBody(TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "async"), TokenFactory.tokenFromType(TokenType.FUNCTION), expression, TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static BlockFunctionBody asyncGeneratorBlockFunctionBody(List<Statement> statements) => new BlockFunctionBody(TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "async"), TokenFactory.tokenFromType(TokenType.STAR), block(statements));

  static AwaitExpression awaitExpression(Expression expression) => new AwaitExpression(TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "await"), expression);

  static BinaryExpression binaryExpression(Expression leftOperand, TokenType operator, Expression rightOperand) => new BinaryExpression(leftOperand, TokenFactory.tokenFromType(operator), rightOperand);

  static Block block(List<Statement> statements) => new Block(TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET), list(statements), TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static BlockFunctionBody blockFunctionBody(Block block) => new BlockFunctionBody(null, null, block);

  static BlockFunctionBody blockFunctionBody2(List<Statement> statements) => new BlockFunctionBody(null, null, block(statements));

  static BooleanLiteral booleanLiteral(bool value) => new BooleanLiteral(value ? TokenFactory.tokenFromKeyword(Keyword.TRUE) : TokenFactory.tokenFromKeyword(Keyword.FALSE), value);

  static BreakStatement breakStatement() => new BreakStatement(TokenFactory.tokenFromKeyword(Keyword.BREAK), null, TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static BreakStatement breakStatement2(String label) => new BreakStatement(TokenFactory.tokenFromKeyword(Keyword.BREAK), identifier3(label), TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static IndexExpression cascadedIndexExpression(Expression index) => new IndexExpression.forCascade(TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD), TokenFactory.tokenFromType(TokenType.OPEN_SQUARE_BRACKET), index, TokenFactory.tokenFromType(TokenType.CLOSE_SQUARE_BRACKET));

  static MethodInvocation cascadedMethodInvocation(String methodName, List<Expression> arguments) => new MethodInvocation(null, TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD), identifier3(methodName), argumentList(arguments));

  static PropertyAccess cascadedPropertyAccess(String propertyName) => new PropertyAccess(null, TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD), identifier3(propertyName));

  static CascadeExpression cascadeExpression(Expression target, List<Expression> cascadeSections) => new CascadeExpression(target, list(cascadeSections));

  static CatchClause catchClause(String exceptionParameter, List<Statement> statements) => catchClause5(null, exceptionParameter, null, statements);

  static CatchClause catchClause2(String exceptionParameter, String stackTraceParameter, List<Statement> statements) => catchClause5(null, exceptionParameter, stackTraceParameter, statements);

  static CatchClause catchClause3(TypeName exceptionType, List<Statement> statements) => catchClause5(exceptionType, null, null, statements);

  static CatchClause catchClause4(TypeName exceptionType, String exceptionParameter, List<Statement> statements) => catchClause5(exceptionType, exceptionParameter, null, statements);

  static CatchClause catchClause5(TypeName exceptionType, String exceptionParameter, String stackTraceParameter, List<Statement> statements) => new CatchClause(exceptionType == null ? null : TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "on"), exceptionType, exceptionParameter == null ? null : TokenFactory.tokenFromKeyword(Keyword.CATCH), exceptionParameter == null ? null : TokenFactory.tokenFromType(TokenType.OPEN_PAREN), exceptionParameter == null ? null : identifier3(exceptionParameter), stackTraceParameter == null ? null : TokenFactory.tokenFromType(TokenType.COMMA), stackTraceParameter == null ? null : identifier3(stackTraceParameter), exceptionParameter == null ? null : TokenFactory.tokenFromType(TokenType.CLOSE_PAREN), block(statements));

  static ClassDeclaration classDeclaration(Keyword abstractKeyword, String name, TypeParameterList typeParameters, ExtendsClause extendsClause, WithClause withClause, ImplementsClause implementsClause, List<ClassMember> members) => new ClassDeclaration(null, null, abstractKeyword == null ? null : TokenFactory.tokenFromKeyword(abstractKeyword), TokenFactory.tokenFromKeyword(Keyword.CLASS), identifier3(name), typeParameters, extendsClause, withClause, implementsClause, TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET), list(members), TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static ClassTypeAlias classTypeAlias(String name, TypeParameterList typeParameters, Keyword abstractKeyword, TypeName superclass, WithClause withClause, ImplementsClause implementsClause) => new ClassTypeAlias(null, null, TokenFactory.tokenFromKeyword(Keyword.CLASS), identifier3(name), typeParameters, TokenFactory.tokenFromType(TokenType.EQ), abstractKeyword == null ? null : TokenFactory.tokenFromKeyword(abstractKeyword), superclass, withClause, implementsClause, TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static CompilationUnit compilationUnit() => compilationUnit8(null, null, null);

  static CompilationUnit compilationUnit2(List<CompilationUnitMember> declarations) => compilationUnit8(null, null, list(declarations));

  static CompilationUnit compilationUnit3(List<Directive> directives) => compilationUnit8(null, list(directives), null);

  static CompilationUnit compilationUnit4(List<Directive> directives, List<CompilationUnitMember> declarations) => compilationUnit8(null, directives, declarations);

  static CompilationUnit compilationUnit5(String scriptTag) => compilationUnit8(scriptTag, null, null);

  static CompilationUnit compilationUnit6(String scriptTag, List<CompilationUnitMember> declarations) => compilationUnit8(scriptTag, null, list(declarations));

  static CompilationUnit compilationUnit7(String scriptTag, List<Directive> directives) => compilationUnit8(scriptTag, list(directives), null);

  static CompilationUnit compilationUnit8(String scriptTag, List<Directive> directives, List<CompilationUnitMember> declarations) => new CompilationUnit(TokenFactory.tokenFromType(TokenType.EOF), scriptTag == null ? null : AstFactory.scriptTag(scriptTag), directives == null ? new List<Directive>() : directives, declarations == null ? new List<CompilationUnitMember>() : declarations, TokenFactory.tokenFromType(TokenType.EOF));

  static ConditionalExpression conditionalExpression(Expression condition, Expression thenExpression, Expression elseExpression) => new ConditionalExpression(condition, TokenFactory.tokenFromType(TokenType.QUESTION), thenExpression, TokenFactory.tokenFromType(TokenType.COLON), elseExpression);

  static ConstructorDeclaration constructorDeclaration(Identifier returnType, String name, FormalParameterList parameters, List<ConstructorInitializer> initializers) => new ConstructorDeclaration(null, null, TokenFactory.tokenFromKeyword(Keyword.EXTERNAL), null, null, returnType, name == null ? null : TokenFactory.tokenFromType(TokenType.PERIOD), name == null ? null : identifier3(name), parameters, initializers == null || initializers.isEmpty ? null : TokenFactory.tokenFromType(TokenType.PERIOD), initializers == null ? new List<ConstructorInitializer>() : initializers, null, emptyFunctionBody());

  static ConstructorDeclaration constructorDeclaration2(Keyword constKeyword, Keyword factoryKeyword, Identifier returnType, String name, FormalParameterList parameters, List<ConstructorInitializer> initializers, FunctionBody body) => new ConstructorDeclaration(null, null, null, constKeyword == null ? null : TokenFactory.tokenFromKeyword(constKeyword), factoryKeyword == null ? null : TokenFactory.tokenFromKeyword(factoryKeyword), returnType, name == null ? null : TokenFactory.tokenFromType(TokenType.PERIOD), name == null ? null : identifier3(name), parameters, initializers == null || initializers.isEmpty ? null : TokenFactory.tokenFromType(TokenType.PERIOD), initializers == null ? new List<ConstructorInitializer>() : initializers, null, body);

  static ConstructorFieldInitializer constructorFieldInitializer(bool prefixedWithThis, String fieldName, Expression expression) => new ConstructorFieldInitializer(prefixedWithThis ? TokenFactory.tokenFromKeyword(Keyword.THIS) : null, prefixedWithThis ? TokenFactory.tokenFromType(TokenType.PERIOD) : null, identifier3(fieldName), TokenFactory.tokenFromType(TokenType.EQ), expression);

  static ConstructorName constructorName(TypeName type, String name) => new ConstructorName(type, name == null ? null : TokenFactory.tokenFromType(TokenType.PERIOD), name == null ? null : identifier3(name));

  static ContinueStatement continueStatement([String label]) {
    SimpleIdentifier labelNode = label == null ? null : identifier3(label);
    return new ContinueStatement(TokenFactory.tokenFromKeyword(Keyword.CONTINUE), labelNode, TokenFactory.tokenFromType(TokenType.SEMICOLON));
  }

  static DeclaredIdentifier declaredIdentifier(Keyword keyword, String identifier) => declaredIdentifier2(keyword, null, identifier);

  static DeclaredIdentifier declaredIdentifier2(Keyword keyword, TypeName type, String identifier) => new DeclaredIdentifier(null, null, keyword == null ? null : TokenFactory.tokenFromKeyword(keyword), type, identifier3(identifier));

  static DeclaredIdentifier declaredIdentifier3(String identifier) => declaredIdentifier2(null, null, identifier);

  static DeclaredIdentifier declaredIdentifier4(TypeName type, String identifier) => declaredIdentifier2(null, type, identifier);

  static DoStatement doStatement(Statement body, Expression condition) => new DoStatement(TokenFactory.tokenFromKeyword(Keyword.DO), body, TokenFactory.tokenFromKeyword(Keyword.WHILE), TokenFactory.tokenFromType(TokenType.OPEN_PAREN), condition, TokenFactory.tokenFromType(TokenType.CLOSE_PAREN), TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static DoubleLiteral doubleLiteral(double value) => new DoubleLiteral(TokenFactory.tokenFromString(value.toString()), value);

  static EmptyFunctionBody emptyFunctionBody() => new EmptyFunctionBody(TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static EmptyStatement emptyStatement() => new EmptyStatement(TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static EnumDeclaration enumDeclaration(SimpleIdentifier name, List<EnumConstantDeclaration> constants) => new EnumDeclaration(null, null, TokenFactory.tokenFromKeyword(Keyword.ENUM), name, TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET), list(constants), TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static EnumDeclaration enumDeclaration2(String name, List<String> constantNames) {
    int count = constantNames.length;
    List<EnumConstantDeclaration> constants = new List<EnumConstantDeclaration>(count);
    for (int i = 0; i < count; i++) {
      constants[i] = new EnumConstantDeclaration(null, null, identifier3(constantNames[i]));
    }
    return enumDeclaration(identifier3(name), constants);
  }

  static ExportDirective exportDirective(List<Annotation> metadata, String uri, List<Combinator> combinators) => new ExportDirective(null, metadata, TokenFactory.tokenFromKeyword(Keyword.EXPORT), string2(uri), list(combinators), TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static ExportDirective exportDirective2(String uri, List<Combinator> combinators) => exportDirective(new List<Annotation>(), uri, combinators);

  static ExpressionFunctionBody expressionFunctionBody(Expression expression) => new ExpressionFunctionBody(null, TokenFactory.tokenFromType(TokenType.FUNCTION), expression, TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static ExpressionStatement expressionStatement(Expression expression) => new ExpressionStatement(expression, TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static ExtendsClause extendsClause(TypeName type) => new ExtendsClause(TokenFactory.tokenFromKeyword(Keyword.EXTENDS), type);

  static FieldDeclaration fieldDeclaration(bool isStatic, Keyword keyword, TypeName type, List<VariableDeclaration> variables) => new FieldDeclaration(null, null, isStatic ? TokenFactory.tokenFromKeyword(Keyword.STATIC) : null, variableDeclarationList(keyword, type, variables), TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static FieldDeclaration fieldDeclaration2(bool isStatic, Keyword keyword, List<VariableDeclaration> variables) => fieldDeclaration(isStatic, keyword, null, variables);

  static FieldFormalParameter fieldFormalParameter(Keyword keyword, TypeName type, String identifier, [FormalParameterList parameterList]) => new FieldFormalParameter(null, null, keyword == null ? null : TokenFactory.tokenFromKeyword(keyword), type, TokenFactory.tokenFromKeyword(Keyword.THIS), TokenFactory.tokenFromType(TokenType.PERIOD), identifier3(identifier), parameterList);

  static FieldFormalParameter fieldFormalParameter2(String identifier) => fieldFormalParameter(null, null, identifier);

  static ForEachStatement forEachStatement(DeclaredIdentifier loopVariable, Expression iterator, Statement body) => new ForEachStatement.con1(null, TokenFactory.tokenFromKeyword(Keyword.FOR), TokenFactory.tokenFromType(TokenType.OPEN_PAREN), loopVariable, TokenFactory.tokenFromKeyword(Keyword.IN), iterator, TokenFactory.tokenFromType(TokenType.CLOSE_PAREN), body);

  static ForEachStatement forEachStatement2(SimpleIdentifier identifier, Expression iterator, Statement body) => new ForEachStatement.con2(null, TokenFactory.tokenFromKeyword(Keyword.FOR), TokenFactory.tokenFromType(TokenType.OPEN_PAREN), identifier, TokenFactory.tokenFromKeyword(Keyword.IN), iterator, TokenFactory.tokenFromType(TokenType.CLOSE_PAREN), body);

  static FormalParameterList formalParameterList(List<FormalParameter> parameters) => new FormalParameterList(TokenFactory.tokenFromType(TokenType.OPEN_PAREN), list(parameters), null, null, TokenFactory.tokenFromType(TokenType.CLOSE_PAREN));

  static ForStatement forStatement(Expression initialization, Expression condition, List<Expression> updaters, Statement body) => new ForStatement(TokenFactory.tokenFromKeyword(Keyword.FOR), TokenFactory.tokenFromType(TokenType.OPEN_PAREN), null, initialization, TokenFactory.tokenFromType(TokenType.SEMICOLON), condition, TokenFactory.tokenFromType(TokenType.SEMICOLON), updaters, TokenFactory.tokenFromType(TokenType.CLOSE_PAREN), body);

  static ForStatement forStatement2(VariableDeclarationList variableList, Expression condition, List<Expression> updaters, Statement body) => new ForStatement(TokenFactory.tokenFromKeyword(Keyword.FOR), TokenFactory.tokenFromType(TokenType.OPEN_PAREN), variableList, null, TokenFactory.tokenFromType(TokenType.SEMICOLON), condition, TokenFactory.tokenFromType(TokenType.SEMICOLON), updaters, TokenFactory.tokenFromType(TokenType.CLOSE_PAREN), body);

  static FunctionDeclaration functionDeclaration(TypeName type, Keyword keyword, String name, FunctionExpression functionExpression) => new FunctionDeclaration(null, null, null, type, keyword == null ? null : TokenFactory.tokenFromKeyword(keyword), identifier3(name), functionExpression);

  static FunctionDeclarationStatement functionDeclarationStatement(TypeName type, Keyword keyword, String name, FunctionExpression functionExpression) => new FunctionDeclarationStatement(functionDeclaration(type, keyword, name, functionExpression));

  static FunctionExpression functionExpression() => new FunctionExpression(formalParameterList([]), blockFunctionBody2([]));

  static FunctionExpression functionExpression2(FormalParameterList parameters, FunctionBody body) => new FunctionExpression(parameters, body);

  static FunctionExpressionInvocation functionExpressionInvocation(Expression function, List<Expression> arguments) => new FunctionExpressionInvocation(function, argumentList(arguments));

  static FunctionTypedFormalParameter functionTypedFormalParameter(TypeName returnType, String identifier, List<FormalParameter> parameters) => new FunctionTypedFormalParameter(null, null, returnType, identifier3(identifier), formalParameterList(parameters));

  static HideCombinator hideCombinator(List<SimpleIdentifier> identifiers) => new HideCombinator(TokenFactory.tokenFromString("hide"), list(identifiers));

  static HideCombinator hideCombinator2(List<String> identifiers) {
    List<SimpleIdentifier> identifierList = new List<SimpleIdentifier>();
    for (String identifier in identifiers) {
      identifierList.add(identifier3(identifier));
    }
    return new HideCombinator(TokenFactory.tokenFromString("hide"), identifierList);
  }

  static PrefixedIdentifier identifier(SimpleIdentifier prefix, SimpleIdentifier identifier) => new PrefixedIdentifier(prefix, TokenFactory.tokenFromType(TokenType.PERIOD), identifier);

  static SimpleIdentifier identifier3(String lexeme) => new SimpleIdentifier(TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, lexeme));

  static PrefixedIdentifier identifier4(String prefix, SimpleIdentifier identifier) => new PrefixedIdentifier(identifier3(prefix), TokenFactory.tokenFromType(TokenType.PERIOD), identifier);

  static PrefixedIdentifier identifier5(String prefix, String identifier) => new PrefixedIdentifier(identifier3(prefix), TokenFactory.tokenFromType(TokenType.PERIOD), identifier3(identifier));

  static IfStatement ifStatement(Expression condition, Statement thenStatement) => ifStatement2(condition, thenStatement, null);

  static IfStatement ifStatement2(Expression condition, Statement thenStatement, Statement elseStatement) => new IfStatement(TokenFactory.tokenFromKeyword(Keyword.IF), TokenFactory.tokenFromType(TokenType.OPEN_PAREN), condition, TokenFactory.tokenFromType(TokenType.CLOSE_PAREN), thenStatement, elseStatement == null ? null : TokenFactory.tokenFromKeyword(Keyword.ELSE), elseStatement);

  static ImplementsClause implementsClause(List<TypeName> types) => new ImplementsClause(TokenFactory.tokenFromKeyword(Keyword.IMPLEMENTS), list(types));

  static ImportDirective importDirective(List<Annotation> metadata, String uri, bool isDeferred, String prefix, List<Combinator> combinators) => new ImportDirective(null, metadata, TokenFactory.tokenFromKeyword(Keyword.IMPORT), string2(uri), !isDeferred ? null : TokenFactory.tokenFromKeyword(Keyword.DEFERRED), prefix == null ? null : TokenFactory.tokenFromKeyword(Keyword.AS), prefix == null ? null : identifier3(prefix), list(combinators), TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static ImportDirective importDirective2(String uri, bool isDeferred, String prefix, List<Combinator> combinators) => importDirective(new List<Annotation>(), uri, isDeferred, prefix, combinators);

  static ImportDirective importDirective3(String uri, String prefix, List<Combinator> combinators) => importDirective(new List<Annotation>(), uri, false, prefix, combinators);

  static IndexExpression indexExpression(Expression array, Expression index) => new IndexExpression.forTarget(array, TokenFactory.tokenFromType(TokenType.OPEN_SQUARE_BRACKET), index, TokenFactory.tokenFromType(TokenType.CLOSE_SQUARE_BRACKET));

  static InstanceCreationExpression instanceCreationExpression(Keyword keyword, ConstructorName name, List<Expression> arguments) => new InstanceCreationExpression(keyword == null ? null : TokenFactory.tokenFromKeyword(keyword), name, argumentList(arguments));

  static InstanceCreationExpression instanceCreationExpression2(Keyword keyword, TypeName type, List<Expression> arguments) => instanceCreationExpression3(keyword, type, null, arguments);

  static InstanceCreationExpression instanceCreationExpression3(Keyword keyword, TypeName type, String identifier, List<Expression> arguments) => instanceCreationExpression(keyword, new ConstructorName(type, identifier == null ? null : TokenFactory.tokenFromType(TokenType.PERIOD), identifier == null ? null : identifier3(identifier)), arguments);

  static IntegerLiteral integer(int value) => new IntegerLiteral(TokenFactory.tokenFromTypeAndString(TokenType.INT, value.toString()), value);

  static InterpolationExpression interpolationExpression(Expression expression) => new InterpolationExpression(TokenFactory.tokenFromType(TokenType.STRING_INTERPOLATION_EXPRESSION), expression, TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static InterpolationExpression interpolationExpression2(String identifier) => new InterpolationExpression(TokenFactory.tokenFromType(TokenType.STRING_INTERPOLATION_IDENTIFIER), identifier3(identifier), null);

  static InterpolationString interpolationString(String contents, String value) => new InterpolationString(TokenFactory.tokenFromString(contents), value);

  static IsExpression isExpression(Expression expression, bool negated, TypeName type) => new IsExpression(expression, TokenFactory.tokenFromKeyword(Keyword.IS), negated ? TokenFactory.tokenFromType(TokenType.BANG) : null, type);

  static Label label(SimpleIdentifier label) => new Label(label, TokenFactory.tokenFromType(TokenType.COLON));

  static Label label2(String label) => AstFactory.label(identifier3(label));

  static LabeledStatement labeledStatement(List<Label> labels, Statement statement) => new LabeledStatement(labels, statement);

  static LibraryDirective libraryDirective(List<Annotation> metadata, LibraryIdentifier libraryName) => new LibraryDirective(null, metadata, TokenFactory.tokenFromKeyword(Keyword.LIBRARY), libraryName, TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static LibraryDirective libraryDirective2(String libraryName) => libraryDirective(new List<Annotation>(), libraryIdentifier2([libraryName]));

  static LibraryIdentifier libraryIdentifier(List<SimpleIdentifier> components) => new LibraryIdentifier(list(components));

  static LibraryIdentifier libraryIdentifier2(List<String> components) {
    List<SimpleIdentifier> componentList = new List<SimpleIdentifier>();
    for (String component in components) {
      componentList.add(identifier3(component));
    }
    return new LibraryIdentifier(componentList);
  }

  static List list(List<Object> elements) {
    List elementList = new List();
    for (Object element in elements) {
      elementList.add(element);
    }
    return elementList;
  }

  static ListLiteral listLiteral(List<Expression> elements) => listLiteral2(null, null, elements);

  static ListLiteral listLiteral2(Keyword keyword, TypeArgumentList typeArguments, List<Expression> elements) => new ListLiteral(keyword == null ? null : TokenFactory.tokenFromKeyword(keyword), typeArguments, TokenFactory.tokenFromType(TokenType.OPEN_SQUARE_BRACKET), list(elements), TokenFactory.tokenFromType(TokenType.CLOSE_SQUARE_BRACKET));

  static MapLiteral mapLiteral(Keyword keyword, TypeArgumentList typeArguments, List<MapLiteralEntry> entries) => new MapLiteral(keyword == null ? null : TokenFactory.tokenFromKeyword(keyword), typeArguments, TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET), list(entries), TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static MapLiteral mapLiteral2(List<MapLiteralEntry> entries) => mapLiteral(null, null, entries);

  static MapLiteralEntry mapLiteralEntry(String key, Expression value) => new MapLiteralEntry(string2(key), TokenFactory.tokenFromType(TokenType.COLON), value);

  static MethodDeclaration methodDeclaration(Keyword modifier, TypeName returnType, Keyword property, Keyword operator, SimpleIdentifier name, FormalParameterList parameters) => new MethodDeclaration(null, null, TokenFactory.tokenFromKeyword(Keyword.EXTERNAL), modifier == null ? null : TokenFactory.tokenFromKeyword(modifier), returnType, property == null ? null : TokenFactory.tokenFromKeyword(property), operator == null ? null : TokenFactory.tokenFromKeyword(operator), name, parameters, emptyFunctionBody());

  static MethodDeclaration methodDeclaration2(Keyword modifier, TypeName returnType, Keyword property, Keyword operator, SimpleIdentifier name, FormalParameterList parameters, FunctionBody body) => new MethodDeclaration(null, null, null, modifier == null ? null : TokenFactory.tokenFromKeyword(modifier), returnType, property == null ? null : TokenFactory.tokenFromKeyword(property), operator == null ? null : TokenFactory.tokenFromKeyword(operator), name, parameters, body);

  static MethodInvocation methodInvocation(Expression target, String methodName, List<Expression> arguments) => new MethodInvocation(target, target == null ? null : TokenFactory.tokenFromType(TokenType.PERIOD), identifier3(methodName), argumentList(arguments));

  static MethodInvocation methodInvocation2(String methodName, List<Expression> arguments) => methodInvocation(null, methodName, arguments);

  static NamedExpression namedExpression(Label label, Expression expression) => new NamedExpression(label, expression);

  static NamedExpression namedExpression2(String label, Expression expression) => namedExpression(label2(label), expression);

  static DefaultFormalParameter namedFormalParameter(NormalFormalParameter parameter, Expression expression) => new DefaultFormalParameter(parameter, ParameterKind.NAMED, expression == null ? null : TokenFactory.tokenFromType(TokenType.COLON), expression);

  static NativeClause nativeClause(String nativeCode) => new NativeClause(TokenFactory.tokenFromString("native"), string2(nativeCode));

  static NativeFunctionBody nativeFunctionBody(String nativeMethodName) => new NativeFunctionBody(TokenFactory.tokenFromString("native"), string2(nativeMethodName), TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static NullLiteral nullLiteral() => new NullLiteral(TokenFactory.tokenFromKeyword(Keyword.NULL));

  static ParenthesizedExpression parenthesizedExpression(Expression expression) => new ParenthesizedExpression(TokenFactory.tokenFromType(TokenType.OPEN_PAREN), expression, TokenFactory.tokenFromType(TokenType.CLOSE_PAREN));

  static PartDirective partDirective(List<Annotation> metadata, String url) => new PartDirective(null, metadata, TokenFactory.tokenFromKeyword(Keyword.PART), string2(url), TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static PartDirective partDirective2(String url) => partDirective(new List<Annotation>(), url);

  static PartOfDirective partOfDirective(LibraryIdentifier libraryName) => partOfDirective2(new List<Annotation>(), libraryName);

  static PartOfDirective partOfDirective2(List<Annotation> metadata, LibraryIdentifier libraryName) => new PartOfDirective(null, metadata, TokenFactory.tokenFromKeyword(Keyword.PART), TokenFactory.tokenFromString("of"), libraryName, TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static DefaultFormalParameter positionalFormalParameter(NormalFormalParameter parameter, Expression expression) => new DefaultFormalParameter(parameter, ParameterKind.POSITIONAL, expression == null ? null : TokenFactory.tokenFromType(TokenType.EQ), expression);

  static PostfixExpression postfixExpression(Expression expression, TokenType operator) => new PostfixExpression(expression, TokenFactory.tokenFromType(operator));

  static PrefixExpression prefixExpression(TokenType operator, Expression expression) => new PrefixExpression(TokenFactory.tokenFromType(operator), expression);

  static PropertyAccess propertyAccess(Expression target, SimpleIdentifier propertyName) => new PropertyAccess(target, TokenFactory.tokenFromType(TokenType.PERIOD), propertyName);

  static PropertyAccess propertyAccess2(Expression target, String propertyName) => new PropertyAccess(target, TokenFactory.tokenFromType(TokenType.PERIOD), identifier3(propertyName));

  static RedirectingConstructorInvocation redirectingConstructorInvocation(List<Expression> arguments) => redirectingConstructorInvocation2(null, arguments);

  static RedirectingConstructorInvocation redirectingConstructorInvocation2(String constructorName, List<Expression> arguments) => new RedirectingConstructorInvocation(TokenFactory.tokenFromKeyword(Keyword.THIS), constructorName == null ? null : TokenFactory.tokenFromType(TokenType.PERIOD), constructorName == null ? null : identifier3(constructorName), argumentList(arguments));

  static RethrowExpression rethrowExpression() => new RethrowExpression(TokenFactory.tokenFromKeyword(Keyword.RETHROW));

  static ReturnStatement returnStatement() => returnStatement2(null);

  static ReturnStatement returnStatement2(Expression expression) => new ReturnStatement(TokenFactory.tokenFromKeyword(Keyword.RETURN), expression, TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static ScriptTag scriptTag(String scriptTag) => new ScriptTag(TokenFactory.tokenFromString(scriptTag));

  static ShowCombinator showCombinator(List<SimpleIdentifier> identifiers) => new ShowCombinator(TokenFactory.tokenFromString("show"), list(identifiers));

  static ShowCombinator showCombinator2(List<String> identifiers) {
    List<SimpleIdentifier> identifierList = new List<SimpleIdentifier>();
    for (String identifier in identifiers) {
      identifierList.add(identifier3(identifier));
    }
    return new ShowCombinator(TokenFactory.tokenFromString("show"), identifierList);
  }

  static SimpleFormalParameter simpleFormalParameter(Keyword keyword, String parameterName) => simpleFormalParameter2(keyword, null, parameterName);

  static SimpleFormalParameter simpleFormalParameter2(Keyword keyword, TypeName type, String parameterName) => new SimpleFormalParameter(null, null, keyword == null ? null : TokenFactory.tokenFromKeyword(keyword), type, identifier3(parameterName));

  static SimpleFormalParameter simpleFormalParameter3(String parameterName) => simpleFormalParameter2(null, null, parameterName);

  static SimpleFormalParameter simpleFormalParameter4(TypeName type, String parameterName) => simpleFormalParameter2(null, type, parameterName);

  static StringInterpolation string(List<InterpolationElement> elements) => new StringInterpolation(list(elements));

  static SimpleStringLiteral string2(String content) => new SimpleStringLiteral(TokenFactory.tokenFromString("'$content'"), content);

  static SuperConstructorInvocation superConstructorInvocation(List<Expression> arguments) => superConstructorInvocation2(null, arguments);

  static SuperConstructorInvocation superConstructorInvocation2(String name, List<Expression> arguments) => new SuperConstructorInvocation(TokenFactory.tokenFromKeyword(Keyword.SUPER), name == null ? null : TokenFactory.tokenFromType(TokenType.PERIOD), name == null ? null : identifier3(name), argumentList(arguments));

  static SuperExpression superExpression() => new SuperExpression(TokenFactory.tokenFromKeyword(Keyword.SUPER));

  static SwitchCase switchCase(Expression expression, List<Statement> statements) => switchCase2(new List<Label>(), expression, statements);

  static SwitchCase switchCase2(List<Label> labels, Expression expression, List<Statement> statements) => new SwitchCase(labels, TokenFactory.tokenFromKeyword(Keyword.CASE), expression, TokenFactory.tokenFromType(TokenType.COLON), list(statements));

  static SwitchDefault switchDefault(List<Label> labels, List<Statement> statements) => new SwitchDefault(labels, TokenFactory.tokenFromKeyword(Keyword.DEFAULT), TokenFactory.tokenFromType(TokenType.COLON), list(statements));

  static SwitchDefault switchDefault2(List<Statement> statements) => switchDefault(new List<Label>(), statements);

  static SwitchStatement switchStatement(Expression expression, List<SwitchMember> members) => new SwitchStatement(TokenFactory.tokenFromKeyword(Keyword.SWITCH), TokenFactory.tokenFromType(TokenType.OPEN_PAREN), expression, TokenFactory.tokenFromType(TokenType.CLOSE_PAREN), TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET), list(members), TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static SymbolLiteral symbolLiteral(List<String> components) {
    List<Token> identifierList = new List<Token>();
    for (String component in components) {
      identifierList.add(TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, component));
    }
    return new SymbolLiteral(TokenFactory.tokenFromType(TokenType.HASH), identifierList);
  }

  static BlockFunctionBody syncBlockFunctionBody(List<Statement> statements) => new BlockFunctionBody(TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "sync"), null, block(statements));

  static BlockFunctionBody syncGeneratorBlockFunctionBody(List<Statement> statements) => new BlockFunctionBody(TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "sync"), TokenFactory.tokenFromType(TokenType.STAR), block(statements));

  static ThisExpression thisExpression() => new ThisExpression(TokenFactory.tokenFromKeyword(Keyword.THIS));

  static ThrowExpression throwExpression() => throwExpression2(null);

  static ThrowExpression throwExpression2(Expression expression) => new ThrowExpression(TokenFactory.tokenFromKeyword(Keyword.THROW), expression);

  static TopLevelVariableDeclaration topLevelVariableDeclaration(Keyword keyword, TypeName type, List<VariableDeclaration> variables) => new TopLevelVariableDeclaration(null, null, variableDeclarationList(keyword, type, variables), TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static TopLevelVariableDeclaration topLevelVariableDeclaration2(Keyword keyword, List<VariableDeclaration> variables) => new TopLevelVariableDeclaration(null, null, variableDeclarationList(keyword, null, variables), TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static TryStatement tryStatement(Block body, Block finallyClause) => tryStatement3(body, new List<CatchClause>(), finallyClause);

  static TryStatement tryStatement2(Block body, List<CatchClause> catchClauses) => tryStatement3(body, list(catchClauses), null);

  static TryStatement tryStatement3(Block body, List<CatchClause> catchClauses, Block finallyClause) => new TryStatement(TokenFactory.tokenFromKeyword(Keyword.TRY), body, catchClauses, finallyClause == null ? null : TokenFactory.tokenFromKeyword(Keyword.FINALLY), finallyClause);

  static FunctionTypeAlias typeAlias(TypeName returnType, String name, TypeParameterList typeParameters, FormalParameterList parameters) => new FunctionTypeAlias(null, null, TokenFactory.tokenFromKeyword(Keyword.TYPEDEF), returnType, identifier3(name), typeParameters, parameters, TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static TypeArgumentList typeArgumentList(List<TypeName> typeNames) => new TypeArgumentList(TokenFactory.tokenFromType(TokenType.LT), list(typeNames), TokenFactory.tokenFromType(TokenType.GT));

  /**
   * Create a type name whose name has been resolved to the given element and whose type has been
   * resolved to the type of the given element.
   *
   * <b>Note:</b> This method does not correctly handle class elements that have type parameters.
   *
   * @param element the element defining the type represented by the type name
   * @return the type name that was created
   */
  static TypeName typeName(ClassElement element, List<TypeName> arguments) {
    SimpleIdentifier name = identifier3(element.name);
    name.staticElement = element;
    TypeName typeName = typeName3(name, arguments);
    typeName.type = element.type;
    return typeName;
  }

  static TypeName typeName3(Identifier name, List<TypeName> arguments) {
    if (arguments.length == 0) {
      return new TypeName(name, null);
    }
    return new TypeName(name, typeArgumentList(arguments));
  }

  static TypeName typeName4(String name, List<TypeName> arguments) {
    if (arguments.length == 0) {
      return new TypeName(identifier3(name), null);
    }
    return new TypeName(identifier3(name), typeArgumentList(arguments));
  }

  static TypeParameter typeParameter(String name) => new TypeParameter(null, null, identifier3(name), null, null);

  static TypeParameter typeParameter2(String name, TypeName bound) => new TypeParameter(null, null, identifier3(name), TokenFactory.tokenFromKeyword(Keyword.EXTENDS), bound);

  static TypeParameterList typeParameterList(List<String> typeNames) {
    List<TypeParameter> typeParameters = new List<TypeParameter>();
    for (String typeName in typeNames) {
      typeParameters.add(typeParameter(typeName));
    }
    return new TypeParameterList(TokenFactory.tokenFromType(TokenType.LT), typeParameters, TokenFactory.tokenFromType(TokenType.GT));
  }

  static VariableDeclaration variableDeclaration(String name) => new VariableDeclaration(null, null, identifier3(name), null, null);

  static VariableDeclaration variableDeclaration2(String name, Expression initializer) => new VariableDeclaration(null, null, identifier3(name), TokenFactory.tokenFromType(TokenType.EQ), initializer);

  static VariableDeclarationList variableDeclarationList(Keyword keyword, TypeName type, List<VariableDeclaration> variables) => new VariableDeclarationList(null, null, keyword == null ? null : TokenFactory.tokenFromKeyword(keyword), type, list(variables));

  static VariableDeclarationList variableDeclarationList2(Keyword keyword, List<VariableDeclaration> variables) => variableDeclarationList(keyword, null, variables);

  static VariableDeclarationStatement variableDeclarationStatement(Keyword keyword, TypeName type, List<VariableDeclaration> variables) => new VariableDeclarationStatement(variableDeclarationList(keyword, type, variables), TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static VariableDeclarationStatement variableDeclarationStatement2(Keyword keyword, List<VariableDeclaration> variables) => variableDeclarationStatement(keyword, null, variables);

  static WhileStatement whileStatement(Expression condition, Statement body) => new WhileStatement(TokenFactory.tokenFromKeyword(Keyword.WHILE), TokenFactory.tokenFromType(TokenType.OPEN_PAREN), condition, TokenFactory.tokenFromType(TokenType.CLOSE_PAREN), body);

  static WithClause withClause(List<TypeName> types) => new WithClause(TokenFactory.tokenFromKeyword(Keyword.WITH), list(types));

  static YieldStatement yieldEachStatement(Expression expression) => new YieldStatement(TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "yield"), TokenFactory.tokenFromType(TokenType.STAR), expression, TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static YieldStatement yieldStatement(Expression expression) => new YieldStatement(TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "yield"), null, expression, TokenFactory.tokenFromType(TokenType.SEMICOLON));
}