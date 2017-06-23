// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:meta/meta.dart';

/**
 * Concrete implementation of [AstFactory] based on the standard AST
 * implementation.
 */
class AstFactoryImpl extends AstFactory {
  @override
  AdjacentStrings adjacentStrings(List<StringLiteral> strings) =>
      new AdjacentStringsImpl(strings);

  @override
  Annotation annotation(Token atSign, Identifier name, Token period,
          SimpleIdentifier constructorName, ArgumentList arguments) =>
      new AnnotationImpl(atSign, name, period, constructorName, arguments);

  @override
  ArgumentList argumentList(Token leftParenthesis, List<Expression> arguments,
          Token rightParenthesis) =>
      new ArgumentListImpl(leftParenthesis, arguments, rightParenthesis);

  @override
  AsExpression asExpression(
          Expression expression, Token asOperator, TypeAnnotation type) =>
      new AsExpressionImpl(expression, asOperator, type);

  @override
  AssertInitializer assertInitializer(
          Token assertKeyword,
          Token leftParenthesis,
          Expression condition,
          Token comma,
          Expression message,
          Token rightParenthesis) =>
      new AssertInitializerImpl(assertKeyword, leftParenthesis, condition,
          comma, message, rightParenthesis);

  @override
  AssertStatement assertStatement(
          Token assertKeyword,
          Token leftParenthesis,
          Expression condition,
          Token comma,
          Expression message,
          Token rightParenthesis,
          Token semicolon) =>
      new AssertStatementImpl(assertKeyword, leftParenthesis, condition, comma,
          message, rightParenthesis, semicolon);

  @override
  AssignmentExpression assignmentExpression(
          Expression leftHandSide, Token operator, Expression rightHandSide) =>
      new AssignmentExpressionImpl(leftHandSide, operator, rightHandSide);

  @override
  AwaitExpression awaitExpression(Token awaitKeyword, Expression expression) =>
      new AwaitExpressionImpl(awaitKeyword, expression);

  @override
  BinaryExpression binaryExpression(
          Expression leftOperand, Token operator, Expression rightOperand) =>
      new BinaryExpressionImpl(leftOperand, operator, rightOperand);
  @override
  Block block(
          Token leftBracket, List<Statement> statements, Token rightBracket) =>
      new BlockImpl(leftBracket, statements, rightBracket);

  @override
  Comment blockComment(List<Token> tokens) =>
      CommentImpl.createBlockComment(tokens);

  @override
  BlockFunctionBody blockFunctionBody(Token keyword, Token star, Block block) =>
      new BlockFunctionBodyImpl(keyword, star, block);

  @override
  BooleanLiteral booleanLiteral(Token literal, bool value) =>
      new BooleanLiteralImpl(literal, value);

  @override
  BreakStatement breakStatement(
          Token breakKeyword, SimpleIdentifier label, Token semicolon) =>
      new BreakStatementImpl(breakKeyword, label, semicolon);

  @override
  CascadeExpression cascadeExpression(
          Expression target, List<Expression> cascadeSections) =>
      new CascadeExpressionImpl(target, cascadeSections);

  @override
  CatchClause catchClause(
          Token onKeyword,
          TypeAnnotation exceptionType,
          Token catchKeyword,
          Token leftParenthesis,
          SimpleIdentifier exceptionParameter,
          Token comma,
          SimpleIdentifier stackTraceParameter,
          Token rightParenthesis,
          Block body) =>
      new CatchClauseImpl(
          onKeyword,
          exceptionType,
          catchKeyword,
          leftParenthesis,
          exceptionParameter,
          comma,
          stackTraceParameter,
          rightParenthesis,
          body);

  @override
  ClassDeclaration classDeclaration(
          Comment comment,
          List<Annotation> metadata,
          Token abstractKeyword,
          Token classKeyword,
          SimpleIdentifier name,
          TypeParameterList typeParameters,
          ExtendsClause extendsClause,
          WithClause withClause,
          ImplementsClause implementsClause,
          Token leftBracket,
          List<ClassMember> members,
          Token rightBracket) =>
      new ClassDeclarationImpl(
          comment,
          metadata,
          abstractKeyword,
          classKeyword,
          name,
          typeParameters,
          extendsClause,
          withClause,
          implementsClause,
          leftBracket,
          members,
          rightBracket);

  @override
  ClassTypeAlias classTypeAlias(
          Comment comment,
          List<Annotation> metadata,
          Token keyword,
          SimpleIdentifier name,
          TypeParameterList typeParameters,
          Token equals,
          Token abstractKeyword,
          TypeName superclass,
          WithClause withClause,
          ImplementsClause implementsClause,
          Token semicolon) =>
      new ClassTypeAliasImpl(
          comment,
          metadata,
          keyword,
          name,
          typeParameters,
          equals,
          abstractKeyword,
          superclass,
          withClause,
          implementsClause,
          semicolon);

  @override
  CommentReference commentReference(Token newKeyword, Identifier identifier) =>
      new CommentReferenceImpl(newKeyword, identifier);

  @override
  CompilationUnit compilationUnit(
          Token beginToken,
          ScriptTag scriptTag,
          List<Directive> directives,
          List<CompilationUnitMember> declarations,
          Token endToken) =>
      new CompilationUnitImpl(
          beginToken, scriptTag, directives, declarations, endToken);

  @override
  ConditionalExpression conditionalExpression(
          Expression condition,
          Token question,
          Expression thenExpression,
          Token colon,
          Expression elseExpression) =>
      new ConditionalExpressionImpl(
          condition, question, thenExpression, colon, elseExpression);

  @override
  Configuration configuration(
          Token ifKeyword,
          Token leftParenthesis,
          DottedName name,
          Token equalToken,
          StringLiteral value,
          Token rightParenthesis,
          StringLiteral libraryUri) =>
      new ConfigurationImpl(ifKeyword, leftParenthesis, name, equalToken, value,
          rightParenthesis, libraryUri);

  @override
  ConstructorDeclaration constructorDeclaration(
          Comment comment,
          List<Annotation> metadata,
          Token externalKeyword,
          Token constKeyword,
          Token factoryKeyword,
          Identifier returnType,
          Token period,
          SimpleIdentifier name,
          FormalParameterList parameters,
          Token separator,
          List<ConstructorInitializer> initializers,
          ConstructorName redirectedConstructor,
          FunctionBody body) =>
      new ConstructorDeclarationImpl(
          comment,
          metadata,
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

  @override
  ConstructorFieldInitializer constructorFieldInitializer(
          Token thisKeyword,
          Token period,
          SimpleIdentifier fieldName,
          Token equals,
          Expression expression) =>
      new ConstructorFieldInitializerImpl(
          thisKeyword, period, fieldName, equals, expression);

  @override
  ConstructorName constructorName(
          TypeName type, Token period, SimpleIdentifier name) =>
      new ConstructorNameImpl(type, period, name);

  @override
  ContinueStatement continueStatement(
          Token continueKeyword, SimpleIdentifier label, Token semicolon) =>
      new ContinueStatementImpl(continueKeyword, label, semicolon);

  @override
  DeclaredIdentifier declaredIdentifier(
          Comment comment,
          List<Annotation> metadata,
          Token keyword,
          TypeAnnotation type,
          SimpleIdentifier identifier) =>
      new DeclaredIdentifierImpl(comment, metadata, keyword, type, identifier);

  @override
  DefaultFormalParameter defaultFormalParameter(NormalFormalParameter parameter,
          ParameterKind kind, Token separator, Expression defaultValue) =>
      new DefaultFormalParameterImpl(parameter, kind, separator, defaultValue);

  @override
  Comment documentationComment(List<Token> tokens,
          [List<CommentReference> references]) =>
      CommentImpl.createDocumentationCommentWithReferences(
          tokens, references ?? <CommentReference>[]);

  @override
  DoStatement doStatement(
          Token doKeyword,
          Statement body,
          Token whileKeyword,
          Token leftParenthesis,
          Expression condition,
          Token rightParenthesis,
          Token semicolon) =>
      new DoStatementImpl(doKeyword, body, whileKeyword, leftParenthesis,
          condition, rightParenthesis, semicolon);

  @override
  DottedName dottedName(List<SimpleIdentifier> components) =>
      new DottedNameImpl(components);

  @override
  DoubleLiteral doubleLiteral(Token literal, double value) =>
      new DoubleLiteralImpl(literal, value);

  @override
  EmptyFunctionBody emptyFunctionBody(Token semicolon) =>
      new EmptyFunctionBodyImpl(semicolon);

  @override
  EmptyStatement emptyStatement(Token semicolon) =>
      new EmptyStatementImpl(semicolon);

  @override
  Comment endOfLineComment(List<Token> tokens) =>
      CommentImpl.createEndOfLineComment(tokens);

  @override
  EnumConstantDeclaration enumConstantDeclaration(
          Comment comment, List<Annotation> metadata, SimpleIdentifier name) =>
      new EnumConstantDeclarationImpl(comment, metadata, name);

  @override
  EnumDeclaration enumDeclaration(
          Comment comment,
          List<Annotation> metadata,
          Token enumKeyword,
          SimpleIdentifier name,
          Token leftBracket,
          List<EnumConstantDeclaration> constants,
          Token rightBracket) =>
      new EnumDeclarationImpl(comment, metadata, enumKeyword, name, leftBracket,
          constants, rightBracket);

  @override
  ExportDirective exportDirective(
          Comment comment,
          List<Annotation> metadata,
          Token keyword,
          StringLiteral libraryUri,
          List<Configuration> configurations,
          List<Combinator> combinators,
          Token semicolon) =>
      new ExportDirectiveImpl(comment, metadata, keyword, libraryUri,
          configurations, combinators, semicolon);
  @override
  ExpressionFunctionBody expressionFunctionBody(Token keyword,
          Token functionDefinition, Expression expression, Token semicolon) =>
      new ExpressionFunctionBodyImpl(
          keyword, functionDefinition, expression, semicolon);

  @override
  ExpressionStatement expressionStatement(
          Expression expression, Token semicolon) =>
      new ExpressionStatementImpl(expression, semicolon);

  @override
  ExtendsClause extendsClause(Token extendsKeyword, TypeName superclass) =>
      new ExtendsClauseImpl(extendsKeyword, superclass);

  @override
  FieldDeclaration fieldDeclaration(
          Comment comment,
          List<Annotation> metadata,
          Token staticKeyword,
          VariableDeclarationList fieldList,
          Token semicolon) =>
      new FieldDeclarationImpl(
          comment, metadata, null, staticKeyword, fieldList, semicolon);

  @override
  FieldDeclaration fieldDeclaration2(
          {Comment comment,
          List<Annotation> metadata,
          Token covariantKeyword,
          Token staticKeyword,
          @required VariableDeclarationList fieldList,
          @required Token semicolon}) =>
      new FieldDeclarationImpl(comment, metadata, covariantKeyword,
          staticKeyword, fieldList, semicolon);

  @override
  FieldFormalParameter fieldFormalParameter(
          Comment comment,
          List<Annotation> metadata,
          Token keyword,
          TypeAnnotation type,
          Token thisKeyword,
          Token period,
          SimpleIdentifier identifier,
          TypeParameterList typeParameters,
          FormalParameterList parameters) =>
      new FieldFormalParameterImpl(comment, metadata, null, keyword, type,
          thisKeyword, period, identifier, typeParameters, parameters);

  @override
  FieldFormalParameter fieldFormalParameter2(
          {Comment comment,
          List<Annotation> metadata,
          Token covariantKeyword,
          Token keyword,
          TypeAnnotation type,
          @required Token thisKeyword,
          @required Token period,
          @required SimpleIdentifier identifier,
          TypeParameterList typeParameters,
          FormalParameterList parameters}) =>
      new FieldFormalParameterImpl(comment, metadata, covariantKeyword, keyword,
          type, thisKeyword, period, identifier, typeParameters, parameters);

  @override
  ForEachStatement forEachStatementWithDeclaration(
          Token awaitKeyword,
          Token forKeyword,
          Token leftParenthesis,
          DeclaredIdentifier loopVariable,
          Token inKeyword,
          Expression iterator,
          Token rightParenthesis,
          Statement body) =>
      new ForEachStatementImpl.withDeclaration(
          awaitKeyword,
          forKeyword,
          leftParenthesis,
          loopVariable,
          inKeyword,
          iterator,
          rightParenthesis,
          body);

  @override
  ForEachStatement forEachStatementWithReference(
          Token awaitKeyword,
          Token forKeyword,
          Token leftParenthesis,
          SimpleIdentifier identifier,
          Token inKeyword,
          Expression iterator,
          Token rightParenthesis,
          Statement body) =>
      new ForEachStatementImpl.withReference(
          awaitKeyword,
          forKeyword,
          leftParenthesis,
          identifier,
          inKeyword,
          iterator,
          rightParenthesis,
          body);

  @override
  FormalParameterList formalParameterList(
          Token leftParenthesis,
          List<FormalParameter> parameters,
          Token leftDelimiter,
          Token rightDelimiter,
          Token rightParenthesis) =>
      new FormalParameterListImpl(leftParenthesis, parameters, leftDelimiter,
          rightDelimiter, rightParenthesis);

  @override
  ForStatement forStatement(
          Token forKeyword,
          Token leftParenthesis,
          VariableDeclarationList variableList,
          Expression initialization,
          Token leftSeparator,
          Expression condition,
          Token rightSeparator,
          List<Expression> updaters,
          Token rightParenthesis,
          Statement body) =>
      new ForStatementImpl(
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

  @override
  FunctionDeclaration functionDeclaration(
          Comment comment,
          List<Annotation> metadata,
          Token externalKeyword,
          TypeAnnotation returnType,
          Token propertyKeyword,
          SimpleIdentifier name,
          FunctionExpression functionExpression) =>
      new FunctionDeclarationImpl(comment, metadata, externalKeyword,
          returnType, propertyKeyword, name, functionExpression);

  @override
  FunctionDeclarationStatement functionDeclarationStatement(
          FunctionDeclaration functionDeclaration) =>
      new FunctionDeclarationStatementImpl(functionDeclaration);

  @override
  FunctionExpression functionExpression(TypeParameterList typeParameters,
          FormalParameterList parameters, FunctionBody body) =>
      new FunctionExpressionImpl(typeParameters, parameters, body);

  @override
  FunctionExpressionInvocation functionExpressionInvocation(Expression function,
          TypeArgumentList typeArguments, ArgumentList argumentList) =>
      new FunctionExpressionInvocationImpl(
          function, typeArguments, argumentList);

  @override
  FunctionTypeAlias functionTypeAlias(
          Comment comment,
          List<Annotation> metadata,
          Token keyword,
          TypeAnnotation returnType,
          SimpleIdentifier name,
          TypeParameterList typeParameters,
          FormalParameterList parameters,
          Token semicolon) =>
      new FunctionTypeAliasImpl(comment, metadata, keyword, returnType, name,
          typeParameters, parameters, semicolon);

  @override
  FunctionTypedFormalParameter functionTypedFormalParameter(
          Comment comment,
          List<Annotation> metadata,
          TypeAnnotation returnType,
          SimpleIdentifier identifier,
          TypeParameterList typeParameters,
          FormalParameterList parameters,
          {Token question: null}) =>
      new FunctionTypedFormalParameterImpl(comment, metadata, null, returnType,
          identifier, typeParameters, parameters, question);

  @override
  FunctionTypedFormalParameter functionTypedFormalParameter2(
          {Comment comment,
          List<Annotation> metadata,
          Token covariantKeyword,
          TypeAnnotation returnType,
          @required SimpleIdentifier identifier,
          TypeParameterList typeParameters,
          @required FormalParameterList parameters,
          Token question}) =>
      new FunctionTypedFormalParameterImpl(comment, metadata, covariantKeyword,
          returnType, identifier, typeParameters, parameters, question);

  @override
  GenericFunctionType genericFunctionType(
          TypeAnnotation returnType,
          Token functionKeyword,
          TypeParameterList typeParameters,
          FormalParameterList parameters) =>
      new GenericFunctionTypeImpl(
          returnType, functionKeyword, typeParameters, parameters);

  @override
  GenericTypeAlias genericTypeAlias(
          Comment comment,
          List<Annotation> metadata,
          Token typedefKeyword,
          SimpleIdentifier name,
          TypeParameterList typeParameters,
          Token equals,
          GenericFunctionType functionType,
          Token semicolon) =>
      new GenericTypeAliasImpl(comment, metadata, typedefKeyword, name,
          typeParameters, equals, functionType, semicolon);

  @override
  HideCombinator hideCombinator(
          Token keyword, List<SimpleIdentifier> hiddenNames) =>
      new HideCombinatorImpl(keyword, hiddenNames);

  @override
  IfStatement ifStatement(
          Token ifKeyword,
          Token leftParenthesis,
          Expression condition,
          Token rightParenthesis,
          Statement thenStatement,
          Token elseKeyword,
          Statement elseStatement) =>
      new IfStatementImpl(ifKeyword, leftParenthesis, condition,
          rightParenthesis, thenStatement, elseKeyword, elseStatement);

  @override
  ImplementsClause implementsClause(
          Token implementsKeyword, List<TypeName> interfaces) =>
      new ImplementsClauseImpl(implementsKeyword, interfaces);

  @override
  ImportDirective importDirective(
          Comment comment,
          List<Annotation> metadata,
          Token keyword,
          StringLiteral libraryUri,
          List<Configuration> configurations,
          Token deferredKeyword,
          Token asKeyword,
          SimpleIdentifier prefix,
          List<Combinator> combinators,
          Token semicolon) =>
      new ImportDirectiveImpl(
          comment,
          metadata,
          keyword,
          libraryUri,
          configurations,
          deferredKeyword,
          asKeyword,
          prefix,
          combinators,
          semicolon);

  @override
  IndexExpression indexExpressionForCascade(Token period, Token leftBracket,
          Expression index, Token rightBracket) =>
      new IndexExpressionImpl.forCascade(
          period, leftBracket, index, rightBracket);

  @override
  IndexExpression indexExpressionForTarget(Expression target, Token leftBracket,
          Expression index, Token rightBracket) =>
      new IndexExpressionImpl.forTarget(
          target, leftBracket, index, rightBracket);

  @override
  InstanceCreationExpression instanceCreationExpression(Token keyword,
          ConstructorName constructorName, ArgumentList argumentList) =>
      new InstanceCreationExpressionImpl(
          keyword, constructorName, argumentList);

  @override
  IntegerLiteral integerLiteral(Token literal, int value) =>
      new IntegerLiteralImpl(literal, value);

  @override
  InterpolationExpression interpolationExpression(
          Token leftBracket, Expression expression, Token rightBracket) =>
      new InterpolationExpressionImpl(leftBracket, expression, rightBracket);

  @override
  InterpolationString interpolationString(Token contents, String value) =>
      new InterpolationStringImpl(contents, value);

  @override
  IsExpression isExpression(Expression expression, Token isOperator,
          Token notOperator, TypeAnnotation type) =>
      new IsExpressionImpl(expression, isOperator, notOperator, type);

  @override
  Label label(SimpleIdentifier label, Token colon) =>
      new LabelImpl(label, colon);

  @override
  LabeledStatement labeledStatement(List<Label> labels, Statement statement) =>
      new LabeledStatementImpl(labels, statement);

  @override
  LibraryDirective libraryDirective(Comment comment, List<Annotation> metadata,
          Token libraryKeyword, LibraryIdentifier name, Token semicolon) =>
      new LibraryDirectiveImpl(
          comment, metadata, libraryKeyword, name, semicolon);

  @override
  LibraryIdentifier libraryIdentifier(List<SimpleIdentifier> components) =>
      new LibraryIdentifierImpl(components);

  @override
  ListLiteral listLiteral(Token constKeyword, TypeArgumentList typeArguments,
          Token leftBracket, List<Expression> elements, Token rightBracket) =>
      new ListLiteralImpl(
          constKeyword, typeArguments, leftBracket, elements, rightBracket);

  @override
  MapLiteral mapLiteral(
          Token constKeyword,
          TypeArgumentList typeArguments,
          Token leftBracket,
          List<MapLiteralEntry> entries,
          Token rightBracket) =>
      new MapLiteralImpl(
          constKeyword, typeArguments, leftBracket, entries, rightBracket);

  @override
  MapLiteralEntry mapLiteralEntry(
          Expression key, Token separator, Expression value) =>
      new MapLiteralEntryImpl(key, separator, value);

  @override
  MethodDeclaration methodDeclaration(
          Comment comment,
          List<Annotation> metadata,
          Token externalKeyword,
          Token modifierKeyword,
          TypeAnnotation returnType,
          Token propertyKeyword,
          Token operatorKeyword,
          SimpleIdentifier name,
          TypeParameterList typeParameters,
          FormalParameterList parameters,
          FunctionBody body) =>
      new MethodDeclarationImpl(
          comment,
          metadata,
          externalKeyword,
          modifierKeyword,
          returnType,
          propertyKeyword,
          operatorKeyword,
          name,
          typeParameters,
          parameters,
          body);

  @override
  MethodInvocation methodInvocation(
          Expression target,
          Token operator,
          SimpleIdentifier methodName,
          TypeArgumentList typeArguments,
          ArgumentList argumentList) =>
      new MethodInvocationImpl(
          target, operator, methodName, typeArguments, argumentList);

  @override
  NamedExpression namedExpression(Label name, Expression expression) =>
      new NamedExpressionImpl(name, expression);

  @override
  NativeClause nativeClause(Token nativeKeyword, StringLiteral name) =>
      new NativeClauseImpl(nativeKeyword, name);

  @override
  NativeFunctionBody nativeFunctionBody(
          Token nativeKeyword, StringLiteral stringLiteral, Token semicolon) =>
      new NativeFunctionBodyImpl(nativeKeyword, stringLiteral, semicolon);

  @override
  NodeList<E> nodeList<E extends AstNode>(AstNode owner, [List<E> elements]) =>
      new NodeListImpl<E>(owner as AstNodeImpl, elements);

  @override
  NullLiteral nullLiteral(Token literal) => new NullLiteralImpl(literal);

  @override
  ParenthesizedExpression parenthesizedExpression(Token leftParenthesis,
          Expression expression, Token rightParenthesis) =>
      new ParenthesizedExpressionImpl(
          leftParenthesis, expression, rightParenthesis);

  @override
  PartDirective partDirective(Comment comment, List<Annotation> metadata,
          Token partKeyword, StringLiteral partUri, Token semicolon) =>
      new PartDirectiveImpl(comment, metadata, partKeyword, partUri, semicolon);

  @override
  PartOfDirective partOfDirective(
          Comment comment,
          List<Annotation> metadata,
          Token partKeyword,
          Token ofKeyword,
          StringLiteral uri,
          LibraryIdentifier libraryName,
          Token semicolon) =>
      new PartOfDirectiveImpl(comment, metadata, partKeyword, ofKeyword, uri,
          libraryName, semicolon);

  @override
  PostfixExpression postfixExpression(Expression operand, Token operator) =>
      new PostfixExpressionImpl(operand, operator);

  @override
  PrefixedIdentifier prefixedIdentifier(
          SimpleIdentifier prefix, Token period, SimpleIdentifier identifier) =>
      new PrefixedIdentifierImpl(prefix, period, identifier);

  @override
  PrefixExpression prefixExpression(Token operator, Expression operand) =>
      new PrefixExpressionImpl(operator, operand);

  @override
  PropertyAccess propertyAccess(
          Expression target, Token operator, SimpleIdentifier propertyName) =>
      new PropertyAccessImpl(target, operator, propertyName);

  @override
  RedirectingConstructorInvocation redirectingConstructorInvocation(
          Token thisKeyword,
          Token period,
          SimpleIdentifier constructorName,
          ArgumentList argumentList) =>
      new RedirectingConstructorInvocationImpl(
          thisKeyword, period, constructorName, argumentList);

  @override
  RethrowExpression rethrowExpression(Token rethrowKeyword) =>
      new RethrowExpressionImpl(rethrowKeyword);

  @override
  ReturnStatement returnStatement(
          Token returnKeyword, Expression expression, Token semicolon) =>
      new ReturnStatementImpl(returnKeyword, expression, semicolon);

  @override
  ScriptTag scriptTag(Token scriptTag) => new ScriptTagImpl(scriptTag);

  @override
  ShowCombinator showCombinator(
          Token keyword, List<SimpleIdentifier> shownNames) =>
      new ShowCombinatorImpl(keyword, shownNames);

  @override
  SimpleFormalParameter simpleFormalParameter(
          Comment comment,
          List<Annotation> metadata,
          Token keyword,
          TypeAnnotation type,
          SimpleIdentifier identifier) =>
      new SimpleFormalParameterImpl(
          comment, metadata, null, keyword, type, identifier);

  @override
  SimpleFormalParameter simpleFormalParameter2(
          {Comment comment,
          List<Annotation> metadata,
          Token covariantKeyword,
          Token keyword,
          TypeAnnotation type,
          @required SimpleIdentifier identifier}) =>
      new SimpleFormalParameterImpl(
          comment, metadata, covariantKeyword, keyword, type, identifier);

  @override
  SimpleIdentifier simpleIdentifier(Token token, {bool isDeclaration: false}) {
    if (isDeclaration) {
      return new DeclaredSimpleIdentifier(token);
    }
    return new SimpleIdentifierImpl(token);
  }

  @override
  SimpleStringLiteral simpleStringLiteral(Token literal, String value) =>
      new SimpleStringLiteralImpl(literal, value);

  @override
  StringInterpolation stringInterpolation(
          List<InterpolationElement> elements) =>
      new StringInterpolationImpl(elements);

  @override
  SuperConstructorInvocation superConstructorInvocation(
          Token superKeyword,
          Token period,
          SimpleIdentifier constructorName,
          ArgumentList argumentList) =>
      new SuperConstructorInvocationImpl(
          superKeyword, period, constructorName, argumentList);

  @override
  SuperExpression superExpression(Token superKeyword) =>
      new SuperExpressionImpl(superKeyword);
  @override
  SwitchCase switchCase(List<Label> labels, Token keyword,
          Expression expression, Token colon, List<Statement> statements) =>
      new SwitchCaseImpl(labels, keyword, expression, colon, statements);

  @override
  SwitchDefault switchDefault(List<Label> labels, Token keyword, Token colon,
          List<Statement> statements) =>
      new SwitchDefaultImpl(labels, keyword, colon, statements);

  @override
  SwitchStatement switchStatement(
          Token switchKeyword,
          Token leftParenthesis,
          Expression expression,
          Token rightParenthesis,
          Token leftBracket,
          List<SwitchMember> members,
          Token rightBracket) =>
      new SwitchStatementImpl(switchKeyword, leftParenthesis, expression,
          rightParenthesis, leftBracket, members, rightBracket);

  @override
  SymbolLiteral symbolLiteral(Token poundSign, List<Token> components) =>
      new SymbolLiteralImpl(poundSign, components);

  @override
  ThisExpression thisExpression(Token thisKeyword) =>
      new ThisExpressionImpl(thisKeyword);

  @override
  ThrowExpression throwExpression(Token throwKeyword, Expression expression) =>
      new ThrowExpressionImpl(throwKeyword, expression);

  @override
  TopLevelVariableDeclaration topLevelVariableDeclaration(
          Comment comment,
          List<Annotation> metadata,
          VariableDeclarationList variableList,
          Token semicolon) =>
      new TopLevelVariableDeclarationImpl(
          comment, metadata, variableList, semicolon);

  @override
  TryStatement tryStatement(
          Token tryKeyword,
          Block body,
          List<CatchClause> catchClauses,
          Token finallyKeyword,
          Block finallyBlock) =>
      new TryStatementImpl(
          tryKeyword, body, catchClauses, finallyKeyword, finallyBlock);

  @override
  TypeArgumentList typeArgumentList(Token leftBracket,
          List<TypeAnnotation> arguments, Token rightBracket) =>
      new TypeArgumentListImpl(leftBracket, arguments, rightBracket);

  @override
  TypeName typeName(Identifier name, TypeArgumentList typeArguments,
          {Token question: null}) =>
      new TypeNameImpl(name, typeArguments, question);

  @override
  TypeParameter typeParameter(Comment comment, List<Annotation> metadata,
          SimpleIdentifier name, Token extendsKeyword, TypeAnnotation bound) =>
      new TypeParameterImpl(comment, metadata, name, extendsKeyword, bound);

  @override
  TypeParameterList typeParameterList(Token leftBracket,
          List<TypeParameter> typeParameters, Token rightBracket) =>
      new TypeParameterListImpl(leftBracket, typeParameters, rightBracket);

  @override
  VariableDeclaration variableDeclaration(
          SimpleIdentifier name, Token equals, Expression initializer) =>
      new VariableDeclarationImpl(name, equals, initializer);

  @override
  VariableDeclarationList variableDeclarationList(
          Comment comment,
          List<Annotation> metadata,
          Token keyword,
          TypeAnnotation type,
          List<VariableDeclaration> variables) =>
      new VariableDeclarationListImpl(
          comment, metadata, keyword, type, variables);

  @override
  VariableDeclarationStatement variableDeclarationStatement(
          VariableDeclarationList variableList, Token semicolon) =>
      new VariableDeclarationStatementImpl(variableList, semicolon);

  @override
  WhileStatement whileStatement(Token whileKeyword, Token leftParenthesis,
          Expression condition, Token rightParenthesis, Statement body) =>
      new WhileStatementImpl(
          whileKeyword, leftParenthesis, condition, rightParenthesis, body);

  @override
  WithClause withClause(Token withKeyword, List<TypeName> mixinTypes) =>
      new WithClauseImpl(withKeyword, mixinTypes);

  @override
  YieldStatement yieldStatement(Token yieldKeyword, Token star,
          Expression expression, Token semicolon) =>
      new YieldStatementImpl(yieldKeyword, star, expression, semicolon);
}
