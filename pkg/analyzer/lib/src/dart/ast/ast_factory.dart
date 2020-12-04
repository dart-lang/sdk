// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';

/// Concrete implementation of [AstFactory] based on the standard AST
/// implementation.
class AstFactoryImpl extends AstFactory {
  @override
  AdjacentStrings adjacentStrings(List<StringLiteral> strings) =>
      AdjacentStringsImpl(strings);

  @override
  Annotation annotation(Token atSign, Identifier name, Token period,
          SimpleIdentifier constructorName, ArgumentList arguments) =>
      AnnotationImpl(atSign, name, period, constructorName, arguments);

  @override
  ArgumentList argumentList(Token leftParenthesis, List<Expression> arguments,
          Token rightParenthesis) =>
      ArgumentListImpl(leftParenthesis, arguments, rightParenthesis);

  @override
  AsExpression asExpression(
          Expression expression, Token asOperator, TypeAnnotation type) =>
      AsExpressionImpl(expression, asOperator, type);

  @override
  AssertInitializer assertInitializer(
          Token assertKeyword,
          Token leftParenthesis,
          Expression condition,
          Token comma,
          Expression message,
          Token rightParenthesis) =>
      AssertInitializerImpl(assertKeyword, leftParenthesis, condition, comma,
          message, rightParenthesis);

  @override
  AssertStatement assertStatement(
          Token assertKeyword,
          Token leftParenthesis,
          Expression condition,
          Token comma,
          Expression message,
          Token rightParenthesis,
          Token semicolon) =>
      AssertStatementImpl(assertKeyword, leftParenthesis, condition, comma,
          message, rightParenthesis, semicolon);

  @override
  AssignmentExpression assignmentExpression(
          Expression leftHandSide, Token operator, Expression rightHandSide) =>
      AssignmentExpressionImpl(leftHandSide, operator, rightHandSide);

  @override
  AwaitExpression awaitExpression(Token awaitKeyword, Expression expression) =>
      AwaitExpressionImpl(awaitKeyword, expression);

  @override
  BinaryExpression binaryExpression(
          Expression leftOperand, Token operator, Expression rightOperand) =>
      BinaryExpressionImpl(leftOperand, operator, rightOperand);

  @override
  Block block(
          Token leftBracket, List<Statement> statements, Token rightBracket) =>
      BlockImpl(leftBracket, statements, rightBracket);

  @override
  Comment blockComment(List<Token> tokens) =>
      CommentImpl.createBlockComment(tokens);

  @override
  BlockFunctionBody blockFunctionBody(Token keyword, Token star, Block block) =>
      BlockFunctionBodyImpl(keyword, star, block);

  @override
  BooleanLiteral booleanLiteral(Token literal, bool value) =>
      BooleanLiteralImpl(literal, value);

  @override
  BreakStatement breakStatement(
          Token breakKeyword, SimpleIdentifier label, Token semicolon) =>
      BreakStatementImpl(breakKeyword, label, semicolon);

  @override
  CascadeExpression cascadeExpression(
          Expression target, List<Expression> cascadeSections) =>
      CascadeExpressionImpl(target, cascadeSections);

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
      CatchClauseImpl(
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
      ClassDeclarationImpl(
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
      ClassTypeAliasImpl(
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
      CommentReferenceImpl(newKeyword, identifier);

  @override
  CompilationUnit compilationUnit(
          {Token beginToken,
          ScriptTag scriptTag,
          List<Directive> directives,
          List<CompilationUnitMember> declarations,
          Token endToken,
          FeatureSet featureSet}) =>
      CompilationUnitImpl(beginToken, scriptTag, directives, declarations,
          endToken, featureSet);

  @override
  ConditionalExpression conditionalExpression(
          Expression condition,
          Token question,
          Expression thenExpression,
          Token colon,
          Expression elseExpression) =>
      ConditionalExpressionImpl(
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
      ConfigurationImpl(ifKeyword, leftParenthesis, name, equalToken, value,
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
      ConstructorDeclarationImpl(
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
      ConstructorFieldInitializerImpl(
          thisKeyword, period, fieldName, equals, expression);

  @override
  ConstructorName constructorName(
          TypeName type, Token period, SimpleIdentifier name) =>
      ConstructorNameImpl(type, period, name);

  @override
  ContinueStatement continueStatement(
          Token continueKeyword, SimpleIdentifier label, Token semicolon) =>
      ContinueStatementImpl(continueKeyword, label, semicolon);

  @override
  DeclaredIdentifier declaredIdentifier(
          Comment comment,
          List<Annotation> metadata,
          Token keyword,
          TypeAnnotation type,
          SimpleIdentifier identifier) =>
      DeclaredIdentifierImpl(comment, metadata, keyword, type, identifier);

  @override
  DefaultFormalParameter defaultFormalParameter(NormalFormalParameter parameter,
          ParameterKind kind, Token separator, Expression defaultValue) =>
      DefaultFormalParameterImpl(parameter, kind, separator, defaultValue);

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
      DoStatementImpl(doKeyword, body, whileKeyword, leftParenthesis, condition,
          rightParenthesis, semicolon);

  @override
  DottedName dottedName(List<SimpleIdentifier> components) =>
      DottedNameImpl(components);

  @override
  DoubleLiteral doubleLiteral(Token literal, double value) =>
      DoubleLiteralImpl(literal, value);

  @override
  EmptyFunctionBody emptyFunctionBody(Token semicolon) =>
      EmptyFunctionBodyImpl(semicolon);

  @override
  EmptyStatement emptyStatement(Token semicolon) =>
      EmptyStatementImpl(semicolon);

  @override
  Comment endOfLineComment(List<Token> tokens) =>
      CommentImpl.createEndOfLineComment(tokens);

  @override
  EnumConstantDeclaration enumConstantDeclaration(
          Comment comment, List<Annotation> metadata, SimpleIdentifier name) =>
      EnumConstantDeclarationImpl(comment, metadata, name);

  @override
  EnumDeclaration enumDeclaration(
          Comment comment,
          List<Annotation> metadata,
          Token enumKeyword,
          SimpleIdentifier name,
          Token leftBracket,
          List<EnumConstantDeclaration> constants,
          Token rightBracket) =>
      EnumDeclarationImpl(comment, metadata, enumKeyword, name, leftBracket,
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
      ExportDirectiveImpl(comment, metadata, keyword, libraryUri,
          configurations, combinators, semicolon);

  @override
  ExpressionFunctionBody expressionFunctionBody(Token keyword,
          Token functionDefinition, Expression expression, Token semicolon) =>
      ExpressionFunctionBodyImpl(
          keyword, functionDefinition, expression, semicolon);

  @override
  ExpressionStatement expressionStatement(
          Expression expression, Token semicolon) =>
      ExpressionStatementImpl(expression, semicolon);

  @override
  ExtendsClause extendsClause(Token extendsKeyword, TypeName superclass) =>
      ExtendsClauseImpl(extendsKeyword, superclass);

  @override
  ExtensionDeclaration extensionDeclaration(
          {Comment comment,
          List<Annotation> metadata,
          Token extensionKeyword,
          @required SimpleIdentifier name,
          TypeParameterList typeParameters,
          Token onKeyword,
          @required TypeAnnotation extendedType,
          Token leftBracket,
          List<ClassMember> members,
          Token rightBracket}) =>
      ExtensionDeclarationImpl(
          comment,
          metadata,
          extensionKeyword,
          name,
          typeParameters,
          onKeyword,
          extendedType,
          leftBracket,
          members,
          rightBracket);

  @override
  ExtensionOverride extensionOverride(
          {@required Identifier extensionName,
          TypeArgumentList typeArguments,
          @required ArgumentList argumentList}) =>
      ExtensionOverrideImpl(extensionName, typeArguments, argumentList);

  @override
  FieldDeclaration fieldDeclaration2(
          {Comment comment,
          List<Annotation> metadata,
          Token abstractKeyword,
          Token covariantKeyword,
          Token externalKeyword,
          Token staticKeyword,
          @required VariableDeclarationList fieldList,
          @required Token semicolon}) =>
      FieldDeclarationImpl(comment, metadata, abstractKeyword, covariantKeyword,
          externalKeyword, staticKeyword, fieldList, semicolon);

  @override
  FieldFormalParameter fieldFormalParameter2(
          {Comment comment,
          List<Annotation> metadata,
          Token covariantKeyword,
          Token requiredKeyword,
          Token keyword,
          TypeAnnotation type,
          @required Token thisKeyword,
          @required Token period,
          @required SimpleIdentifier identifier,
          TypeParameterList typeParameters,
          FormalParameterList parameters,
          Token question}) =>
      FieldFormalParameterImpl(
          comment,
          metadata,
          covariantKeyword,
          requiredKeyword,
          keyword,
          type,
          thisKeyword,
          period,
          identifier,
          typeParameters,
          parameters,
          question);

  @override
  ForEachPartsWithDeclaration forEachPartsWithDeclaration(
          {DeclaredIdentifier loopVariable,
          Token inKeyword,
          Expression iterable}) =>
      ForEachPartsWithDeclarationImpl(loopVariable, inKeyword, iterable);

  @override
  ForEachPartsWithIdentifier forEachPartsWithIdentifier(
          {SimpleIdentifier identifier,
          Token inKeyword,
          Expression iterable}) =>
      ForEachPartsWithIdentifierImpl(identifier, inKeyword, iterable);

  @override
  ForElement forElement(
          {Token awaitKeyword,
          Token forKeyword,
          Token leftParenthesis,
          ForLoopParts forLoopParts,
          Token rightParenthesis,
          CollectionElement body}) =>
      ForElementImpl(awaitKeyword, forKeyword, leftParenthesis, forLoopParts,
          rightParenthesis, body);

  @override
  FormalParameterList formalParameterList(
          Token leftParenthesis,
          List<FormalParameter> parameters,
          Token leftDelimiter,
          Token rightDelimiter,
          Token rightParenthesis) =>
      FormalParameterListImpl(leftParenthesis, parameters, leftDelimiter,
          rightDelimiter, rightParenthesis);

  @override
  ForPartsWithDeclarations forPartsWithDeclarations(
          {VariableDeclarationList variables,
          Token leftSeparator,
          Expression condition,
          Token rightSeparator,
          List<Expression> updaters}) =>
      ForPartsWithDeclarationsImpl(
          variables, leftSeparator, condition, rightSeparator, updaters);

  @override
  ForPartsWithExpression forPartsWithExpression(
          {Expression initialization,
          Token leftSeparator,
          Expression condition,
          Token rightSeparator,
          List<Expression> updaters}) =>
      ForPartsWithExpressionImpl(
          initialization, leftSeparator, condition, rightSeparator, updaters);

  @override
  ForStatement forStatement(
      {Token awaitKeyword,
      Token forKeyword,
      Token leftParenthesis,
      ForLoopParts forLoopParts,
      Token rightParenthesis,
      Statement body}) {
    return ForStatementImpl(awaitKeyword, forKeyword, leftParenthesis,
        forLoopParts, rightParenthesis, body);
  }

  @override
  FunctionDeclaration functionDeclaration(
          Comment comment,
          List<Annotation> metadata,
          Token externalKeyword,
          TypeAnnotation returnType,
          Token propertyKeyword,
          SimpleIdentifier name,
          FunctionExpression functionExpression) =>
      FunctionDeclarationImpl(comment, metadata, externalKeyword, returnType,
          propertyKeyword, name, functionExpression);

  @override
  FunctionDeclarationStatement functionDeclarationStatement(
          FunctionDeclaration functionDeclaration) =>
      FunctionDeclarationStatementImpl(functionDeclaration);

  @override
  FunctionExpression functionExpression(TypeParameterList typeParameters,
          FormalParameterList parameters, FunctionBody body) =>
      FunctionExpressionImpl(typeParameters, parameters, body);

  @override
  FunctionExpressionInvocation functionExpressionInvocation(Expression function,
          TypeArgumentList typeArguments, ArgumentList argumentList) =>
      FunctionExpressionInvocationImpl(function, typeArguments, argumentList);

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
      FunctionTypeAliasImpl(comment, metadata, keyword, returnType, name,
          typeParameters, parameters, semicolon);

  @override
  FunctionTypedFormalParameter functionTypedFormalParameter2(
          {Comment comment,
          List<Annotation> metadata,
          Token covariantKeyword,
          Token requiredKeyword,
          TypeAnnotation returnType,
          @required SimpleIdentifier identifier,
          TypeParameterList typeParameters,
          @required FormalParameterList parameters,
          Token question}) =>
      FunctionTypedFormalParameterImpl(
          comment,
          metadata,
          covariantKeyword,
          requiredKeyword,
          returnType,
          identifier,
          typeParameters,
          parameters,
          question);

  @override
  GenericFunctionType genericFunctionType(
          TypeAnnotation returnType,
          Token functionKeyword,
          TypeParameterList typeParameters,
          FormalParameterList parameters,
          {Token question}) =>
      GenericFunctionTypeImpl(
          returnType, functionKeyword, typeParameters, parameters,
          question: question);

  @override
  GenericTypeAlias genericTypeAlias(
          Comment comment,
          List<Annotation> metadata,
          Token typedefKeyword,
          SimpleIdentifier name,
          TypeParameterList typeParameters,
          Token equals,
          TypeAnnotation type,
          Token semicolon) =>
      GenericTypeAliasImpl(comment, metadata, typedefKeyword, name,
          typeParameters, equals, type, semicolon);

  @override
  HideCombinator hideCombinator(
          Token keyword, List<SimpleIdentifier> hiddenNames) =>
      HideCombinatorImpl(keyword, hiddenNames);

  @override
  IfElement ifElement(
          {Token ifKeyword,
          Token leftParenthesis,
          Expression condition,
          Token rightParenthesis,
          CollectionElement thenElement,
          Token elseKeyword,
          CollectionElement elseElement}) =>
      IfElementImpl(ifKeyword, leftParenthesis, condition, rightParenthesis,
          thenElement, elseKeyword, elseElement);

  @override
  IfStatement ifStatement(
          Token ifKeyword,
          Token leftParenthesis,
          Expression condition,
          Token rightParenthesis,
          Statement thenStatement,
          Token elseKeyword,
          Statement elseStatement) =>
      IfStatementImpl(ifKeyword, leftParenthesis, condition, rightParenthesis,
          thenStatement, elseKeyword, elseStatement);

  @override
  ImplementsClause implementsClause(
          Token implementsKeyword, List<TypeName> interfaces) =>
      ImplementsClauseImpl(implementsKeyword, interfaces);

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
      ImportDirectiveImpl(
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
  IndexExpression indexExpressionForCascade2(
          {@required Token period,
          Token question,
          @required Token leftBracket,
          @required Expression index,
          @required Token rightBracket}) =>
      IndexExpressionImpl.forCascade(
          period, question, leftBracket, index, rightBracket);

  @override
  IndexExpression indexExpressionForTarget2(
          {@required Expression target,
          Token question,
          @required Token leftBracket,
          @required Expression index,
          @required Token rightBracket}) =>
      IndexExpressionImpl.forTarget(
          target, question, leftBracket, index, rightBracket);

  @override
  InstanceCreationExpression instanceCreationExpression(Token keyword,
          ConstructorName constructorName, ArgumentList argumentList,
          {TypeArgumentList typeArguments}) =>
      InstanceCreationExpressionImpl(keyword, constructorName, argumentList,
          typeArguments: typeArguments);

  @override
  IntegerLiteral integerLiteral(Token literal, int value) =>
      IntegerLiteralImpl(literal, value);

  @override
  InterpolationExpression interpolationExpression(
          Token leftBracket, Expression expression, Token rightBracket) =>
      InterpolationExpressionImpl(leftBracket, expression, rightBracket);

  @override
  InterpolationString interpolationString(Token contents, String value) =>
      InterpolationStringImpl(contents, value);

  @override
  IsExpression isExpression(Expression expression, Token isOperator,
          Token notOperator, TypeAnnotation type) =>
      IsExpressionImpl(expression, isOperator, notOperator, type);

  @override
  Label label(SimpleIdentifier label, Token colon) => LabelImpl(label, colon);

  @override
  LabeledStatement labeledStatement(List<Label> labels, Statement statement) =>
      LabeledStatementImpl(labels, statement);

  @override
  LibraryDirective libraryDirective(Comment comment, List<Annotation> metadata,
          Token libraryKeyword, LibraryIdentifier name, Token semicolon) =>
      LibraryDirectiveImpl(comment, metadata, libraryKeyword, name, semicolon);

  @override
  LibraryIdentifier libraryIdentifier(List<SimpleIdentifier> components) =>
      LibraryIdentifierImpl(components);

  @override
  ListLiteral listLiteral(Token constKeyword, TypeArgumentList typeArguments,
      Token leftBracket, List<CollectionElement> elements, Token rightBracket) {
    if (elements == null || elements is List<Expression>) {
      return ListLiteralImpl(
          constKeyword, typeArguments, leftBracket, elements, rightBracket);
    }
    return ListLiteralImpl.experimental(
        constKeyword, typeArguments, leftBracket, elements, rightBracket);
  }

  @override
  MapLiteralEntry mapLiteralEntry(
          Expression key, Token separator, Expression value) =>
      MapLiteralEntryImpl(key, separator, value);

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
      MethodDeclarationImpl(
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
      MethodInvocationImpl(
          target, operator, methodName, typeArguments, argumentList);

  @override
  MixinDeclaration mixinDeclaration(
          Comment comment,
          List<Annotation> metadata,
          Token mixinKeyword,
          SimpleIdentifier name,
          TypeParameterList typeParameters,
          OnClause onClause,
          ImplementsClause implementsClause,
          Token leftBracket,
          List<ClassMember> members,
          Token rightBracket) =>
      MixinDeclarationImpl(
          comment,
          metadata,
          mixinKeyword,
          name,
          typeParameters,
          onClause,
          implementsClause,
          leftBracket,
          members,
          rightBracket);

  @override
  NamedExpression namedExpression(Label name, Expression expression) =>
      NamedExpressionImpl(name, expression);

  @override
  NativeClause nativeClause(Token nativeKeyword, StringLiteral name) =>
      NativeClauseImpl(nativeKeyword, name);

  @override
  NativeFunctionBody nativeFunctionBody(
          Token nativeKeyword, StringLiteral stringLiteral, Token semicolon) =>
      NativeFunctionBodyImpl(nativeKeyword, stringLiteral, semicolon);

  @override
  NodeList<E> nodeList<E extends AstNode>(AstNode owner, [List<E> elements]) =>
      NodeListImpl<E>(owner as AstNodeImpl, elements);

  @override
  NullLiteral nullLiteral(Token literal) => NullLiteralImpl(literal);

  @override
  OnClause onClause(Token onKeyword, List<TypeName> superclassConstraints) =>
      OnClauseImpl(onKeyword, superclassConstraints);

  @override
  ParenthesizedExpression parenthesizedExpression(Token leftParenthesis,
          Expression expression, Token rightParenthesis) =>
      ParenthesizedExpressionImpl(
          leftParenthesis, expression, rightParenthesis);

  @override
  PartDirective partDirective(Comment comment, List<Annotation> metadata,
          Token partKeyword, StringLiteral partUri, Token semicolon) =>
      PartDirectiveImpl(comment, metadata, partKeyword, partUri, semicolon);

  @override
  PartOfDirective partOfDirective(
          Comment comment,
          List<Annotation> metadata,
          Token partKeyword,
          Token ofKeyword,
          StringLiteral uri,
          LibraryIdentifier libraryName,
          Token semicolon) =>
      PartOfDirectiveImpl(comment, metadata, partKeyword, ofKeyword, uri,
          libraryName, semicolon);

  @override
  PostfixExpression postfixExpression(Expression operand, Token operator) =>
      PostfixExpressionImpl(operand, operator);

  @override
  PrefixedIdentifier prefixedIdentifier(
          SimpleIdentifier prefix, Token period, SimpleIdentifier identifier) =>
      PrefixedIdentifierImpl(prefix, period, identifier);

  @override
  PrefixExpression prefixExpression(Token operator, Expression operand) =>
      PrefixExpressionImpl(operator, operand);

  @override
  PropertyAccess propertyAccess(
          Expression target, Token operator, SimpleIdentifier propertyName) =>
      PropertyAccessImpl(target, operator, propertyName);

  @override
  RedirectingConstructorInvocation redirectingConstructorInvocation(
          Token thisKeyword,
          Token period,
          SimpleIdentifier constructorName,
          ArgumentList argumentList) =>
      RedirectingConstructorInvocationImpl(
          thisKeyword, period, constructorName, argumentList);

  @override
  RethrowExpression rethrowExpression(Token rethrowKeyword) =>
      RethrowExpressionImpl(rethrowKeyword);

  @override
  ReturnStatement returnStatement(
          Token returnKeyword, Expression expression, Token semicolon) =>
      ReturnStatementImpl(returnKeyword, expression, semicolon);

  @override
  ScriptTag scriptTag(Token scriptTag) => ScriptTagImpl(scriptTag);

  @override
  SetOrMapLiteral setOrMapLiteral(
          {Token constKeyword,
          TypeArgumentList typeArguments,
          Token leftBracket,
          List<CollectionElement> elements,
          Token rightBracket}) =>
      SetOrMapLiteralImpl(
          constKeyword, typeArguments, leftBracket, elements, rightBracket);

  @override
  ShowCombinator showCombinator(
          Token keyword, List<SimpleIdentifier> shownNames) =>
      ShowCombinatorImpl(keyword, shownNames);

  @override
  SimpleFormalParameter simpleFormalParameter2(
          {Comment comment,
          List<Annotation> metadata,
          Token covariantKeyword,
          Token requiredKeyword,
          Token keyword,
          TypeAnnotation type,
          @required SimpleIdentifier identifier}) =>
      SimpleFormalParameterImpl(comment, metadata, covariantKeyword,
          requiredKeyword, keyword, type, identifier);

  @override
  SimpleIdentifier simpleIdentifier(Token token, {bool isDeclaration = false}) {
    if (isDeclaration) {
      return DeclaredSimpleIdentifier(token);
    }
    return SimpleIdentifierImpl(token);
  }

  @override
  SimpleStringLiteral simpleStringLiteral(Token literal, String value) =>
      SimpleStringLiteralImpl(literal, value);

  @override
  SpreadElement spreadElement({Token spreadOperator, Expression expression}) =>
      SpreadElementImpl(spreadOperator, expression);

  @override
  StringInterpolation stringInterpolation(
          List<InterpolationElement> elements) =>
      StringInterpolationImpl(elements);

  @override
  SuperConstructorInvocation superConstructorInvocation(
          Token superKeyword,
          Token period,
          SimpleIdentifier constructorName,
          ArgumentList argumentList) =>
      SuperConstructorInvocationImpl(
          superKeyword, period, constructorName, argumentList);

  @override
  SuperExpression superExpression(Token superKeyword) =>
      SuperExpressionImpl(superKeyword);

  @override
  SwitchCase switchCase(List<Label> labels, Token keyword,
          Expression expression, Token colon, List<Statement> statements) =>
      SwitchCaseImpl(labels, keyword, expression, colon, statements);

  @override
  SwitchDefault switchDefault(List<Label> labels, Token keyword, Token colon,
          List<Statement> statements) =>
      SwitchDefaultImpl(labels, keyword, colon, statements);

  @override
  SwitchStatement switchStatement(
          Token switchKeyword,
          Token leftParenthesis,
          Expression expression,
          Token rightParenthesis,
          Token leftBracket,
          List<SwitchMember> members,
          Token rightBracket) =>
      SwitchStatementImpl(switchKeyword, leftParenthesis, expression,
          rightParenthesis, leftBracket, members, rightBracket);

  @override
  SymbolLiteral symbolLiteral(Token poundSign, List<Token> components) =>
      SymbolLiteralImpl(poundSign, components);

  @override
  ThisExpression thisExpression(Token thisKeyword) =>
      ThisExpressionImpl(thisKeyword);

  @override
  ThrowExpression throwExpression(Token throwKeyword, Expression expression) =>
      ThrowExpressionImpl(throwKeyword, expression);

  @override
  TopLevelVariableDeclaration topLevelVariableDeclaration(
          Comment comment,
          List<Annotation> metadata,
          VariableDeclarationList variableList,
          Token semicolon,
          {Token externalKeyword}) =>
      TopLevelVariableDeclarationImpl(
          comment, metadata, externalKeyword, variableList, semicolon);

  @override
  TryStatement tryStatement(
          Token tryKeyword,
          Block body,
          List<CatchClause> catchClauses,
          Token finallyKeyword,
          Block finallyBlock) =>
      TryStatementImpl(
          tryKeyword, body, catchClauses, finallyKeyword, finallyBlock);

  @override
  TypeArgumentList typeArgumentList(Token leftBracket,
          List<TypeAnnotation> arguments, Token rightBracket) =>
      TypeArgumentListImpl(leftBracket, arguments, rightBracket);

  @override
  TypeName typeName(Identifier name, TypeArgumentList typeArguments,
          {Token question}) =>
      TypeNameImpl(name, typeArguments, question: question);

  @override
  TypeParameter typeParameter(Comment comment, List<Annotation> metadata,
          SimpleIdentifier name, Token extendsKeyword, TypeAnnotation bound) =>
      TypeParameterImpl(comment, metadata, name, extendsKeyword, bound);

  TypeParameter typeParameter2(
          {Comment comment,
          List<Annotation> metadata,
          SimpleIdentifier name,
          Token extendsKeyword,
          TypeAnnotation bound,
          Token varianceKeyword}) =>
      TypeParameterImpl(comment, metadata, name, extendsKeyword, bound)
        ..varianceKeyword = varianceKeyword;

  @override
  TypeParameterList typeParameterList(Token leftBracket,
          List<TypeParameter> typeParameters, Token rightBracket) =>
      TypeParameterListImpl(leftBracket, typeParameters, rightBracket);

  @override
  VariableDeclaration variableDeclaration(
          SimpleIdentifier name, Token equals, Expression initializer) =>
      VariableDeclarationImpl(name, equals, initializer);

  @override
  VariableDeclarationList variableDeclarationList(
          Comment comment,
          List<Annotation> metadata,
          Token keyword,
          TypeAnnotation type,
          List<VariableDeclaration> variables) =>
      VariableDeclarationListImpl(
          comment, metadata, null, keyword, type, variables);

  @override
  VariableDeclarationList variableDeclarationList2(
      {Comment comment,
      List<Annotation> metadata,
      Token lateKeyword,
      Token keyword,
      TypeAnnotation type,
      List<VariableDeclaration> variables}) {
    return VariableDeclarationListImpl(
        comment, metadata, lateKeyword, keyword, type, variables);
  }

  @override
  VariableDeclarationStatement variableDeclarationStatement(
          VariableDeclarationList variableList, Token semicolon) =>
      VariableDeclarationStatementImpl(variableList, semicolon);

  @override
  WhileStatement whileStatement(Token whileKeyword, Token leftParenthesis,
          Expression condition, Token rightParenthesis, Statement body) =>
      WhileStatementImpl(
          whileKeyword, leftParenthesis, condition, rightParenthesis, body);

  @override
  WithClause withClause(Token withKeyword, List<TypeName> mixinTypes) =>
      WithClauseImpl(withKeyword, mixinTypes);

  @override
  YieldStatement yieldStatement(Token yieldKeyword, Token star,
          Expression expression, Token semicolon) =>
      YieldStatementImpl(yieldKeyword, star, expression, semicolon);
}
