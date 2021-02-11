// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

/// Concrete implementation of [AstFactory] based on the standard AST
/// implementation.
class AstFactoryImpl extends AstFactory {
  @override
  AdjacentStrings adjacentStrings(List<StringLiteral> strings) =>
      AdjacentStringsImpl(strings);

  @override
  Annotation annotation(
          {required Token atSign,
          required Identifier name,
          TypeArgumentList? typeArguments,
          Token? period,
          SimpleIdentifier? constructorName,
          ArgumentList? arguments}) =>
      AnnotationImpl(
          atSign,
          name as IdentifierImpl,
          typeArguments as TypeArgumentListImpl?,
          period,
          constructorName as SimpleIdentifierImpl?,
          arguments as ArgumentListImpl?);

  @override
  ArgumentList argumentList(Token leftParenthesis, List<Expression> arguments,
          Token rightParenthesis) =>
      ArgumentListImpl(leftParenthesis, arguments, rightParenthesis);

  @override
  AsExpression asExpression(
          Expression expression, Token asOperator, TypeAnnotation type) =>
      AsExpressionImpl(
          expression as ExpressionImpl, asOperator, type as TypeAnnotationImpl);

  @override
  AssertInitializer assertInitializer(
          Token assertKeyword,
          Token leftParenthesis,
          Expression condition,
          Token? comma,
          Expression? message,
          Token rightParenthesis) =>
      AssertInitializerImpl(
          assertKeyword,
          leftParenthesis,
          condition as ExpressionImpl,
          comma,
          message as ExpressionImpl?,
          rightParenthesis);

  @override
  AssertStatement assertStatement(
          Token assertKeyword,
          Token leftParenthesis,
          Expression condition,
          Token? comma,
          Expression? message,
          Token rightParenthesis,
          Token semicolon) =>
      AssertStatementImpl(
          assertKeyword,
          leftParenthesis,
          condition as ExpressionImpl,
          comma,
          message as ExpressionImpl?,
          rightParenthesis,
          semicolon);

  @override
  AssignmentExpression assignmentExpression(
          Expression leftHandSide, Token operator, Expression rightHandSide) =>
      AssignmentExpressionImpl(leftHandSide as ExpressionImpl, operator,
          rightHandSide as ExpressionImpl);

  @override
  AwaitExpression awaitExpression(Token awaitKeyword, Expression expression) =>
      AwaitExpressionImpl(awaitKeyword, expression as ExpressionImpl);

  @override
  BinaryExpression binaryExpression(
          Expression leftOperand, Token operator, Expression rightOperand) =>
      BinaryExpressionImpl(leftOperand as ExpressionImpl, operator,
          rightOperand as ExpressionImpl);

  @override
  Block block(
          Token leftBracket, List<Statement> statements, Token rightBracket) =>
      BlockImpl(leftBracket, statements, rightBracket);

  @override
  Comment blockComment(List<Token> tokens) =>
      CommentImpl.createBlockComment(tokens);

  @override
  BlockFunctionBody blockFunctionBody(
          Token? keyword, Token? star, Block block) =>
      BlockFunctionBodyImpl(keyword, star, block as BlockImpl);

  @override
  BooleanLiteral booleanLiteral(Token literal, bool value) =>
      BooleanLiteralImpl(literal, value);

  @override
  BreakStatement breakStatement(
          Token breakKeyword, SimpleIdentifier? label, Token semicolon) =>
      BreakStatementImpl(
          breakKeyword, label as SimpleIdentifierImpl?, semicolon);

  @override
  CascadeExpression cascadeExpression(
          Expression target, List<Expression> cascadeSections) =>
      CascadeExpressionImpl(target as ExpressionImpl, cascadeSections);

  @override
  CatchClause catchClause(
          Token? onKeyword,
          TypeAnnotation? exceptionType,
          Token? catchKeyword,
          Token? leftParenthesis,
          SimpleIdentifier? exceptionParameter,
          Token? comma,
          SimpleIdentifier? stackTraceParameter,
          Token? rightParenthesis,
          Block body) =>
      CatchClauseImpl(
          onKeyword,
          exceptionType as TypeAnnotationImpl?,
          catchKeyword,
          leftParenthesis,
          exceptionParameter as SimpleIdentifierImpl?,
          comma,
          stackTraceParameter as SimpleIdentifierImpl?,
          rightParenthesis,
          body as BlockImpl);

  @override
  ClassDeclaration classDeclaration(
          Comment? comment,
          List<Annotation>? metadata,
          Token? abstractKeyword,
          Token classKeyword,
          SimpleIdentifier name,
          TypeParameterList? typeParameters,
          ExtendsClause? extendsClause,
          WithClause? withClause,
          ImplementsClause? implementsClause,
          Token leftBracket,
          List<ClassMember> members,
          Token rightBracket) =>
      ClassDeclarationImpl(
          comment as CommentImpl?,
          metadata,
          abstractKeyword,
          classKeyword,
          name as SimpleIdentifierImpl,
          typeParameters as TypeParameterListImpl?,
          extendsClause as ExtendsClauseImpl?,
          withClause as WithClauseImpl?,
          implementsClause as ImplementsClauseImpl?,
          leftBracket,
          members,
          rightBracket);

  @override
  ClassTypeAlias classTypeAlias(
          Comment? comment,
          List<Annotation>? metadata,
          Token keyword,
          SimpleIdentifier name,
          TypeParameterList? typeParameters,
          Token equals,
          Token? abstractKeyword,
          TypeName superclass,
          WithClause withClause,
          ImplementsClause? implementsClause,
          Token semicolon) =>
      ClassTypeAliasImpl(
          comment as CommentImpl?,
          metadata,
          keyword,
          name as SimpleIdentifierImpl,
          typeParameters as TypeParameterListImpl?,
          equals,
          abstractKeyword,
          superclass as TypeNameImpl,
          withClause as WithClauseImpl,
          implementsClause as ImplementsClauseImpl?,
          semicolon);

  @override
  CommentReference commentReference(Token? newKeyword, Identifier identifier) =>
      CommentReferenceImpl(newKeyword, identifier as IdentifierImpl);

  @override
  CompilationUnit compilationUnit(
          {required Token beginToken,
          ScriptTag? scriptTag,
          List<Directive>? directives,
          List<CompilationUnitMember>? declarations,
          required Token endToken,
          required FeatureSet featureSet}) =>
      CompilationUnitImpl(beginToken, scriptTag as ScriptTagImpl?, directives,
          declarations, endToken, featureSet);

  @override
  ConditionalExpression conditionalExpression(
          Expression condition,
          Token question,
          Expression thenExpression,
          Token colon,
          Expression elseExpression) =>
      ConditionalExpressionImpl(
          condition as ExpressionImpl,
          question,
          thenExpression as ExpressionImpl,
          colon,
          elseExpression as ExpressionImpl);

  @override
  Configuration configuration(
          Token ifKeyword,
          Token leftParenthesis,
          DottedName name,
          Token? equalToken,
          StringLiteral? value,
          Token rightParenthesis,
          StringLiteral libraryUri) =>
      ConfigurationImpl(
          ifKeyword,
          leftParenthesis,
          name as DottedNameImpl,
          equalToken,
          value as StringLiteralImpl?,
          rightParenthesis,
          libraryUri as StringLiteralImpl);

  @override
  ConstructorDeclaration constructorDeclaration(
          Comment? comment,
          List<Annotation>? metadata,
          Token? externalKeyword,
          Token? constKeyword,
          Token? factoryKeyword,
          Identifier returnType,
          Token? period,
          SimpleIdentifier? name,
          FormalParameterList parameters,
          Token? separator,
          List<ConstructorInitializer>? initializers,
          ConstructorName? redirectedConstructor,
          FunctionBody? body) =>
      ConstructorDeclarationImpl(
          comment as CommentImpl?,
          metadata,
          externalKeyword,
          constKeyword,
          factoryKeyword,
          returnType as IdentifierImpl,
          period,
          name as SimpleIdentifierImpl?,
          parameters as FormalParameterListImpl,
          separator,
          initializers,
          redirectedConstructor as ConstructorNameImpl?,
          body as FunctionBodyImpl?);

  @override
  ConstructorFieldInitializer constructorFieldInitializer(
          Token? thisKeyword,
          Token? period,
          SimpleIdentifier fieldName,
          Token equals,
          Expression expression) =>
      ConstructorFieldInitializerImpl(
          thisKeyword,
          period,
          fieldName as SimpleIdentifierImpl,
          equals,
          expression as ExpressionImpl);

  @override
  ConstructorName constructorName(
          TypeName type, Token? period, SimpleIdentifier? name) =>
      ConstructorNameImpl(
          type as TypeNameImpl, period, name as SimpleIdentifierImpl?);

  @override
  ContinueStatement continueStatement(
          Token continueKeyword, SimpleIdentifier? label, Token semicolon) =>
      ContinueStatementImpl(
          continueKeyword, label as SimpleIdentifierImpl?, semicolon);

  @override
  DeclaredIdentifier declaredIdentifier(
          Comment? comment,
          List<Annotation>? metadata,
          Token? keyword,
          TypeAnnotation? type,
          SimpleIdentifier identifier) =>
      DeclaredIdentifierImpl(comment as CommentImpl?, metadata, keyword,
          type as TypeAnnotationImpl?, identifier as SimpleIdentifierImpl);

  @override
  DefaultFormalParameter defaultFormalParameter(NormalFormalParameter parameter,
          ParameterKind kind, Token? separator, Expression? defaultValue) =>
      DefaultFormalParameterImpl(parameter as NormalFormalParameterImpl, kind,
          separator, defaultValue as ExpressionImpl?);

  @override
  Comment documentationComment(List<Token> tokens,
          [List<CommentReference>? references]) =>
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
      DoStatementImpl(
          doKeyword,
          body as StatementImpl,
          whileKeyword,
          leftParenthesis,
          condition as ExpressionImpl,
          rightParenthesis,
          semicolon);

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
  EnumConstantDeclaration enumConstantDeclaration(Comment? comment,
          List<Annotation>? metadata, SimpleIdentifier name) =>
      EnumConstantDeclarationImpl(
          comment as CommentImpl?, metadata, name as SimpleIdentifierImpl);

  @override
  EnumDeclaration enumDeclaration(
          Comment? comment,
          List<Annotation>? metadata,
          Token enumKeyword,
          SimpleIdentifier name,
          Token leftBracket,
          List<EnumConstantDeclaration> constants,
          Token rightBracket) =>
      EnumDeclarationImpl(comment as CommentImpl?, metadata, enumKeyword,
          name as SimpleIdentifierImpl, leftBracket, constants, rightBracket);

  @override
  ExportDirective exportDirective(
          Comment? comment,
          List<Annotation>? metadata,
          Token keyword,
          StringLiteral libraryUri,
          List<Configuration>? configurations,
          List<Combinator>? combinators,
          Token semicolon) =>
      ExportDirectiveImpl(
          comment as CommentImpl?,
          metadata,
          keyword,
          libraryUri as StringLiteralImpl,
          configurations,
          combinators,
          semicolon);

  @override
  ExpressionFunctionBody expressionFunctionBody(Token? keyword,
          Token functionDefinition, Expression expression, Token? semicolon) =>
      ExpressionFunctionBodyImpl(
          keyword, functionDefinition, expression as ExpressionImpl, semicolon);

  @override
  ExpressionStatement expressionStatement(
          Expression expression, Token? semicolon) =>
      ExpressionStatementImpl(expression as ExpressionImpl, semicolon);

  @override
  ExtendsClause extendsClause(Token extendsKeyword, TypeName superclass) =>
      ExtendsClauseImpl(extendsKeyword, superclass as TypeNameImpl);

  @override
  ExtensionDeclaration extensionDeclaration(
          {Comment? comment,
          List<Annotation>? metadata,
          required Token extensionKeyword,
          required SimpleIdentifier? name,
          TypeParameterList? typeParameters,
          required Token onKeyword,
          required TypeAnnotation extendedType,
          required Token leftBracket,
          required List<ClassMember> members,
          required Token rightBracket}) =>
      ExtensionDeclarationImpl(
          comment as CommentImpl?,
          metadata,
          extensionKeyword,
          name as SimpleIdentifierImpl?,
          typeParameters as TypeParameterListImpl?,
          onKeyword,
          extendedType as TypeAnnotationImpl,
          leftBracket,
          members,
          rightBracket);

  @override
  ExtensionOverride extensionOverride(
          {required Identifier extensionName,
          TypeArgumentList? typeArguments,
          required ArgumentList argumentList}) =>
      ExtensionOverrideImpl(
          extensionName as IdentifierImpl,
          typeArguments as TypeArgumentListImpl?,
          argumentList as ArgumentListImpl);

  @override
  FieldDeclaration fieldDeclaration2(
          {Comment? comment,
          List<Annotation>? metadata,
          Token? abstractKeyword,
          Token? covariantKeyword,
          Token? externalKeyword,
          Token? staticKeyword,
          required VariableDeclarationList fieldList,
          required Token semicolon}) =>
      FieldDeclarationImpl(
          comment as CommentImpl?,
          metadata,
          abstractKeyword,
          covariantKeyword,
          externalKeyword,
          staticKeyword,
          fieldList as VariableDeclarationListImpl,
          semicolon);

  @override
  FieldFormalParameter fieldFormalParameter2(
          {Comment? comment,
          List<Annotation>? metadata,
          Token? covariantKeyword,
          Token? requiredKeyword,
          Token? keyword,
          TypeAnnotation? type,
          required Token thisKeyword,
          required Token period,
          required SimpleIdentifier identifier,
          TypeParameterList? typeParameters,
          FormalParameterList? parameters,
          Token? question}) =>
      FieldFormalParameterImpl(
          comment as CommentImpl?,
          metadata,
          covariantKeyword,
          requiredKeyword,
          keyword,
          type as TypeAnnotationImpl?,
          thisKeyword,
          period,
          identifier as SimpleIdentifierImpl,
          typeParameters as TypeParameterListImpl?,
          parameters as FormalParameterListImpl?,
          question);

  @override
  ForEachPartsWithDeclaration forEachPartsWithDeclaration(
          {required DeclaredIdentifier loopVariable,
          required Token inKeyword,
          required Expression iterable}) =>
      ForEachPartsWithDeclarationImpl(loopVariable as DeclaredIdentifierImpl,
          inKeyword, iterable as ExpressionImpl);

  @override
  ForEachPartsWithIdentifier forEachPartsWithIdentifier(
          {required SimpleIdentifier identifier,
          required Token inKeyword,
          required Expression iterable}) =>
      ForEachPartsWithIdentifierImpl(identifier as SimpleIdentifierImpl,
          inKeyword, iterable as ExpressionImpl);

  @override
  ForElement forElement(
          {Token? awaitKeyword,
          required Token forKeyword,
          required Token leftParenthesis,
          required ForLoopParts forLoopParts,
          required Token rightParenthesis,
          required CollectionElement body}) =>
      ForElementImpl(
          awaitKeyword,
          forKeyword,
          leftParenthesis,
          forLoopParts as ForLoopPartsImpl,
          rightParenthesis,
          body as CollectionElementImpl);

  @override
  FormalParameterList formalParameterList(
          Token leftParenthesis,
          List<FormalParameter> parameters,
          Token? leftDelimiter,
          Token? rightDelimiter,
          Token rightParenthesis) =>
      FormalParameterListImpl(leftParenthesis, parameters, leftDelimiter,
          rightDelimiter, rightParenthesis);

  @override
  ForPartsWithDeclarations forPartsWithDeclarations(
          {required VariableDeclarationList variables,
          required Token leftSeparator,
          Expression? condition,
          required Token rightSeparator,
          List<Expression>? updaters}) =>
      ForPartsWithDeclarationsImpl(
          variables as VariableDeclarationListImpl,
          leftSeparator,
          condition as ExpressionImpl?,
          rightSeparator,
          updaters);

  @override
  ForPartsWithExpression forPartsWithExpression(
          {Expression? initialization,
          required Token leftSeparator,
          Expression? condition,
          required Token rightSeparator,
          List<Expression>? updaters}) =>
      ForPartsWithExpressionImpl(
          initialization as ExpressionImpl?,
          leftSeparator,
          condition as ExpressionImpl?,
          rightSeparator,
          updaters);

  @override
  ForStatement forStatement(
      {Token? awaitKeyword,
      required Token forKeyword,
      required Token leftParenthesis,
      required ForLoopParts forLoopParts,
      required Token rightParenthesis,
      required Statement body}) {
    return ForStatementImpl(
        awaitKeyword,
        forKeyword,
        leftParenthesis,
        forLoopParts as ForLoopPartsImpl,
        rightParenthesis,
        body as StatementImpl);
  }

  @override
  FunctionDeclaration functionDeclaration(
          Comment? comment,
          List<Annotation>? metadata,
          Token? externalKeyword,
          TypeAnnotation? returnType,
          Token? propertyKeyword,
          SimpleIdentifier name,
          FunctionExpression functionExpression) =>
      FunctionDeclarationImpl(
          comment as CommentImpl?,
          metadata,
          externalKeyword,
          returnType as TypeAnnotationImpl?,
          propertyKeyword,
          name as SimpleIdentifierImpl,
          functionExpression as FunctionExpressionImpl);

  @override
  FunctionDeclarationStatement functionDeclarationStatement(
          FunctionDeclaration functionDeclaration) =>
      FunctionDeclarationStatementImpl(
          functionDeclaration as FunctionDeclarationImpl);

  @override
  FunctionExpression functionExpression(TypeParameterList? typeParameters,
          FormalParameterList? parameters, FunctionBody body) =>
      FunctionExpressionImpl(typeParameters as TypeParameterListImpl?,
          parameters as FormalParameterListImpl?, body as FunctionBodyImpl);

  @override
  FunctionExpressionInvocation functionExpressionInvocation(Expression function,
          TypeArgumentList? typeArguments, ArgumentList argumentList) =>
      FunctionExpressionInvocationImpl(
          function as ExpressionImpl,
          typeArguments as TypeArgumentListImpl?,
          argumentList as ArgumentListImpl);

  @override
  FunctionTypeAlias functionTypeAlias(
          Comment? comment,
          List<Annotation>? metadata,
          Token keyword,
          TypeAnnotation? returnType,
          SimpleIdentifier name,
          TypeParameterList? typeParameters,
          FormalParameterList parameters,
          Token semicolon) =>
      FunctionTypeAliasImpl(
          comment as CommentImpl?,
          metadata,
          keyword,
          returnType as TypeAnnotationImpl?,
          name as SimpleIdentifierImpl,
          typeParameters as TypeParameterListImpl?,
          parameters as FormalParameterListImpl,
          semicolon);

  @override
  FunctionTypedFormalParameter functionTypedFormalParameter2(
          {Comment? comment,
          List<Annotation>? metadata,
          Token? covariantKeyword,
          Token? requiredKeyword,
          TypeAnnotation? returnType,
          required SimpleIdentifier identifier,
          TypeParameterList? typeParameters,
          required FormalParameterList parameters,
          Token? question}) =>
      FunctionTypedFormalParameterImpl(
          comment as CommentImpl?,
          metadata,
          covariantKeyword,
          requiredKeyword,
          returnType as TypeAnnotationImpl?,
          identifier as SimpleIdentifierImpl,
          typeParameters as TypeParameterListImpl?,
          parameters as FormalParameterListImpl,
          question);

  @override
  GenericFunctionType genericFunctionType(
          TypeAnnotation? returnType,
          Token functionKeyword,
          TypeParameterList? typeParameters,
          FormalParameterList parameters,
          {Token? question}) =>
      GenericFunctionTypeImpl(
          returnType as TypeAnnotationImpl?,
          functionKeyword,
          typeParameters as TypeParameterListImpl?,
          parameters as FormalParameterListImpl,
          question: question);

  @override
  GenericTypeAlias genericTypeAlias(
          Comment? comment,
          List<Annotation>? metadata,
          Token typedefKeyword,
          SimpleIdentifier name,
          TypeParameterList? typeParameters,
          Token equals,
          TypeAnnotation type,
          Token semicolon) =>
      GenericTypeAliasImpl(
          comment as CommentImpl?,
          metadata,
          typedefKeyword,
          name as SimpleIdentifierImpl,
          typeParameters as TypeParameterListImpl?,
          equals,
          type as TypeAnnotationImpl,
          semicolon);

  @override
  HideCombinator hideCombinator(
          Token keyword, List<SimpleIdentifier> hiddenNames) =>
      HideCombinatorImpl(keyword, hiddenNames);

  @override
  IfElement ifElement(
          {required Token ifKeyword,
          required Token leftParenthesis,
          required Expression condition,
          required Token rightParenthesis,
          required CollectionElement thenElement,
          Token? elseKeyword,
          CollectionElement? elseElement}) =>
      IfElementImpl(
          ifKeyword,
          leftParenthesis,
          condition as ExpressionImpl,
          rightParenthesis,
          thenElement as CollectionElementImpl,
          elseKeyword,
          elseElement as CollectionElementImpl?);

  @override
  IfStatement ifStatement(
          Token ifKeyword,
          Token leftParenthesis,
          Expression condition,
          Token rightParenthesis,
          Statement thenStatement,
          Token? elseKeyword,
          Statement? elseStatement) =>
      IfStatementImpl(
          ifKeyword,
          leftParenthesis,
          condition as ExpressionImpl,
          rightParenthesis,
          thenStatement as StatementImpl,
          elseKeyword,
          elseStatement as StatementImpl?);

  @override
  ImplementsClause implementsClause(
          Token implementsKeyword, List<TypeName> interfaces) =>
      ImplementsClauseImpl(implementsKeyword, interfaces);

  @override
  ImportDirective importDirective(
          Comment? comment,
          List<Annotation>? metadata,
          Token keyword,
          StringLiteral libraryUri,
          List<Configuration>? configurations,
          Token? deferredKeyword,
          Token? asKeyword,
          SimpleIdentifier? prefix,
          List<Combinator>? combinators,
          Token semicolon) =>
      ImportDirectiveImpl(
          comment as CommentImpl?,
          metadata,
          keyword,
          libraryUri as StringLiteralImpl,
          configurations,
          deferredKeyword,
          asKeyword,
          prefix as SimpleIdentifierImpl?,
          combinators,
          semicolon);

  @override
  IndexExpression indexExpressionForCascade2(
          {required Token period,
          Token? question,
          required Token leftBracket,
          required Expression index,
          required Token rightBracket}) =>
      IndexExpressionImpl.forCascade(
          period, question, leftBracket, index as ExpressionImpl, rightBracket);

  @override
  IndexExpression indexExpressionForTarget2(
          {required Expression target,
          Token? question,
          required Token leftBracket,
          required Expression index,
          required Token rightBracket}) =>
      IndexExpressionImpl.forTarget(target as ExpressionImpl, question,
          leftBracket, index as ExpressionImpl, rightBracket);

  @override
  InstanceCreationExpression instanceCreationExpression(Token? keyword,
          ConstructorName constructorName, ArgumentList argumentList,
          {TypeArgumentList? typeArguments}) =>
      InstanceCreationExpressionImpl(
          keyword,
          constructorName as ConstructorNameImpl,
          argumentList as ArgumentListImpl,
          typeArguments: typeArguments as TypeArgumentListImpl?);

  @override
  IntegerLiteral integerLiteral(Token literal, int? value) =>
      IntegerLiteralImpl(literal, value);

  @override
  InterpolationExpression interpolationExpression(
          Token leftBracket, Expression expression, Token? rightBracket) =>
      InterpolationExpressionImpl(
          leftBracket, expression as ExpressionImpl, rightBracket);

  @override
  InterpolationString interpolationString(Token contents, String value) =>
      InterpolationStringImpl(contents, value);

  @override
  IsExpression isExpression(Expression expression, Token isOperator,
          Token? notOperator, TypeAnnotation type) =>
      IsExpressionImpl(expression as ExpressionImpl, isOperator, notOperator,
          type as TypeAnnotationImpl);

  @override
  Label label(SimpleIdentifier label, Token colon) =>
      LabelImpl(label as SimpleIdentifierImpl, colon);

  @override
  LabeledStatement labeledStatement(List<Label> labels, Statement statement) =>
      LabeledStatementImpl(labels, statement as StatementImpl);

  @override
  LibraryDirective libraryDirective(
          Comment? comment,
          List<Annotation>? metadata,
          Token libraryKeyword,
          LibraryIdentifier name,
          Token semicolon) =>
      LibraryDirectiveImpl(comment as CommentImpl?, metadata, libraryKeyword,
          name as LibraryIdentifierImpl, semicolon);

  @override
  LibraryIdentifier libraryIdentifier(List<SimpleIdentifier> components) =>
      LibraryIdentifierImpl(components);

  @override
  ListLiteral listLiteral(Token? constKeyword, TypeArgumentList? typeArguments,
      Token leftBracket, List<CollectionElement> elements, Token rightBracket) {
    if (elements is List<Expression>) {
      return ListLiteralImpl(
          constKeyword,
          typeArguments as TypeArgumentListImpl?,
          leftBracket,
          elements,
          rightBracket);
    }
    return ListLiteralImpl.experimental(
        constKeyword,
        typeArguments as TypeArgumentListImpl?,
        leftBracket,
        elements,
        rightBracket);
  }

  @override
  MapLiteralEntry mapLiteralEntry(
          Expression key, Token separator, Expression value) =>
      MapLiteralEntryImpl(
          key as ExpressionImpl, separator, value as ExpressionImpl);

  @override
  MethodDeclaration methodDeclaration(
          Comment? comment,
          List<Annotation>? metadata,
          Token? externalKeyword,
          Token? modifierKeyword,
          TypeAnnotation? returnType,
          Token? propertyKeyword,
          Token? operatorKeyword,
          SimpleIdentifier name,
          TypeParameterList? typeParameters,
          FormalParameterList? parameters,
          FunctionBody body) =>
      MethodDeclarationImpl(
          comment as CommentImpl?,
          metadata,
          externalKeyword,
          modifierKeyword,
          returnType as TypeAnnotationImpl?,
          propertyKeyword,
          operatorKeyword,
          name as SimpleIdentifierImpl,
          typeParameters as TypeParameterListImpl?,
          parameters as FormalParameterListImpl?,
          body as FunctionBodyImpl);

  @override
  MethodInvocation methodInvocation(
          Expression? target,
          Token? operator,
          SimpleIdentifier methodName,
          TypeArgumentList? typeArguments,
          ArgumentList argumentList) =>
      MethodInvocationImpl(
          target as ExpressionImpl?,
          operator,
          methodName as SimpleIdentifierImpl,
          typeArguments as TypeArgumentListImpl?,
          argumentList as ArgumentListImpl);

  @override
  MixinDeclaration mixinDeclaration(
          Comment? comment,
          List<Annotation>? metadata,
          Token mixinKeyword,
          SimpleIdentifier name,
          TypeParameterList? typeParameters,
          OnClause? onClause,
          ImplementsClause? implementsClause,
          Token leftBracket,
          List<ClassMember> members,
          Token rightBracket) =>
      MixinDeclarationImpl(
          comment as CommentImpl?,
          metadata,
          mixinKeyword,
          name as SimpleIdentifierImpl,
          typeParameters as TypeParameterListImpl?,
          onClause as OnClauseImpl?,
          implementsClause as ImplementsClauseImpl?,
          leftBracket,
          members,
          rightBracket);

  @override
  NamedExpression namedExpression(Label name, Expression expression) =>
      NamedExpressionImpl(name as LabelImpl, expression as ExpressionImpl);

  @override
  NativeClause nativeClause(Token nativeKeyword, StringLiteral? name) =>
      NativeClauseImpl(nativeKeyword, name as StringLiteralImpl?);

  @override
  NativeFunctionBody nativeFunctionBody(
          Token nativeKeyword, StringLiteral? stringLiteral, Token semicolon) =>
      NativeFunctionBodyImpl(
          nativeKeyword, stringLiteral as StringLiteralImpl?, semicolon);

  @override
  NodeList<E> nodeList<E extends AstNode>(AstNode owner) =>
      NodeListImpl<E>(owner as AstNodeImpl);

  @override
  NullLiteral nullLiteral(Token literal) => NullLiteralImpl(literal);

  @override
  OnClause onClause(Token onKeyword, List<TypeName> superclassConstraints) =>
      OnClauseImpl(onKeyword, superclassConstraints);

  @override
  ParenthesizedExpression parenthesizedExpression(Token leftParenthesis,
          Expression expression, Token rightParenthesis) =>
      ParenthesizedExpressionImpl(
          leftParenthesis, expression as ExpressionImpl, rightParenthesis);

  @override
  PartDirective partDirective(Comment? comment, List<Annotation>? metadata,
          Token partKeyword, StringLiteral partUri, Token semicolon) =>
      PartDirectiveImpl(comment as CommentImpl?, metadata, partKeyword,
          partUri as StringLiteralImpl, semicolon);

  @override
  PartOfDirective partOfDirective(
          Comment? comment,
          List<Annotation>? metadata,
          Token partKeyword,
          Token ofKeyword,
          StringLiteral? uri,
          LibraryIdentifier? libraryName,
          Token semicolon) =>
      PartOfDirectiveImpl(
          comment as CommentImpl?,
          metadata,
          partKeyword,
          ofKeyword,
          uri as StringLiteralImpl?,
          libraryName as LibraryIdentifierImpl?,
          semicolon);

  @override
  PostfixExpression postfixExpression(Expression operand, Token operator) =>
      PostfixExpressionImpl(operand as ExpressionImpl, operator);

  @override
  PrefixedIdentifier prefixedIdentifier(
          SimpleIdentifier prefix, Token period, SimpleIdentifier identifier) =>
      PrefixedIdentifierImpl(prefix as SimpleIdentifierImpl, period,
          identifier as SimpleIdentifierImpl);

  @override
  PrefixExpression prefixExpression(Token operator, Expression operand) =>
      PrefixExpressionImpl(operator, operand as ExpressionImpl);

  @override
  PropertyAccess propertyAccess(
          Expression? target, Token operator, SimpleIdentifier propertyName) =>
      PropertyAccessImpl(target as ExpressionImpl?, operator,
          propertyName as SimpleIdentifierImpl);

  @override
  RedirectingConstructorInvocation redirectingConstructorInvocation(
          Token thisKeyword,
          Token? period,
          SimpleIdentifier? constructorName,
          ArgumentList argumentList) =>
      RedirectingConstructorInvocationImpl(
          thisKeyword,
          period,
          constructorName as SimpleIdentifierImpl?,
          argumentList as ArgumentListImpl);

  @override
  RethrowExpression rethrowExpression(Token rethrowKeyword) =>
      RethrowExpressionImpl(rethrowKeyword);

  @override
  ReturnStatement returnStatement(
          Token returnKeyword, Expression? expression, Token semicolon) =>
      ReturnStatementImpl(
          returnKeyword, expression as ExpressionImpl?, semicolon);

  @override
  ScriptTag scriptTag(Token scriptTag) => ScriptTagImpl(scriptTag);

  @override
  SetOrMapLiteral setOrMapLiteral(
          {Token? constKeyword,
          TypeArgumentList? typeArguments,
          required Token leftBracket,
          required List<CollectionElement> elements,
          required Token rightBracket}) =>
      SetOrMapLiteralImpl(constKeyword, typeArguments as TypeArgumentListImpl?,
          leftBracket, elements, rightBracket);

  @override
  ShowCombinator showCombinator(
          Token keyword, List<SimpleIdentifier> shownNames) =>
      ShowCombinatorImpl(keyword, shownNames);

  @override
  SimpleFormalParameter simpleFormalParameter2(
          {Comment? comment,
          List<Annotation>? metadata,
          Token? covariantKeyword,
          Token? requiredKeyword,
          Token? keyword,
          TypeAnnotation? type,
          required SimpleIdentifier? identifier}) =>
      SimpleFormalParameterImpl(
          comment as CommentImpl?,
          metadata,
          covariantKeyword,
          requiredKeyword,
          keyword,
          type as TypeAnnotationImpl?,
          identifier as SimpleIdentifierImpl?);

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
  SpreadElement spreadElement(
          {required Token spreadOperator, required Expression expression}) =>
      SpreadElementImpl(spreadOperator, expression as ExpressionImpl);

  @override
  StringInterpolation stringInterpolation(
          List<InterpolationElement> elements) =>
      StringInterpolationImpl(elements);

  @override
  SuperConstructorInvocation superConstructorInvocation(
          Token superKeyword,
          Token? period,
          SimpleIdentifier? constructorName,
          ArgumentList argumentList) =>
      SuperConstructorInvocationImpl(
          superKeyword,
          period,
          constructorName as SimpleIdentifierImpl?,
          argumentList as ArgumentListImpl);

  @override
  SuperExpression superExpression(Token superKeyword) =>
      SuperExpressionImpl(superKeyword);

  @override
  SwitchCase switchCase(List<Label> labels, Token keyword,
          Expression expression, Token colon, List<Statement> statements) =>
      SwitchCaseImpl(
          labels, keyword, expression as ExpressionImpl, colon, statements);

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
      SwitchStatementImpl(
          switchKeyword,
          leftParenthesis,
          expression as ExpressionImpl,
          rightParenthesis,
          leftBracket,
          members,
          rightBracket);

  @override
  SymbolLiteral symbolLiteral(Token poundSign, List<Token> components) =>
      SymbolLiteralImpl(poundSign, components);

  @override
  ThisExpression thisExpression(Token thisKeyword) =>
      ThisExpressionImpl(thisKeyword);

  @override
  ThrowExpression throwExpression(Token throwKeyword, Expression expression) =>
      ThrowExpressionImpl(throwKeyword, expression as ExpressionImpl);

  @override
  TopLevelVariableDeclaration topLevelVariableDeclaration(
          Comment? comment,
          List<Annotation>? metadata,
          VariableDeclarationList variableList,
          Token semicolon,
          {Token? externalKeyword}) =>
      TopLevelVariableDeclarationImpl(
          comment as CommentImpl?,
          metadata,
          externalKeyword,
          variableList as VariableDeclarationListImpl,
          semicolon);

  @override
  TryStatement tryStatement(
          Token tryKeyword,
          Block body,
          List<CatchClause> catchClauses,
          Token? finallyKeyword,
          Block? finallyBlock) =>
      TryStatementImpl(tryKeyword, body as BlockImpl, catchClauses,
          finallyKeyword, finallyBlock as BlockImpl?);

  @override
  TypeArgumentList typeArgumentList(Token leftBracket,
          List<TypeAnnotation> arguments, Token rightBracket) =>
      TypeArgumentListImpl(leftBracket, arguments, rightBracket);

  @override
  TypeName typeName(Identifier name, TypeArgumentList? typeArguments,
          {Token? question}) =>
      TypeNameImpl(
          name as IdentifierImpl, typeArguments as TypeArgumentListImpl?,
          question: question);

  @override
  TypeParameter typeParameter(
          Comment? comment,
          List<Annotation>? metadata,
          SimpleIdentifier name,
          Token? extendsKeyword,
          TypeAnnotation? bound) =>
      TypeParameterImpl(
          comment as CommentImpl?,
          metadata,
          name as SimpleIdentifierImpl,
          extendsKeyword,
          bound as TypeAnnotationImpl?);

  TypeParameter typeParameter2(
          {Comment? comment,
          List<Annotation>? metadata,
          required SimpleIdentifier name,
          Token? extendsKeyword,
          TypeAnnotation? bound,
          Token? varianceKeyword}) =>
      TypeParameterImpl(
          comment as CommentImpl?,
          metadata,
          name as SimpleIdentifierImpl,
          extendsKeyword,
          bound as TypeAnnotationImpl?)
        ..varianceKeyword = varianceKeyword;

  @override
  TypeParameterList typeParameterList(Token leftBracket,
          List<TypeParameter> typeParameters, Token rightBracket) =>
      TypeParameterListImpl(leftBracket, typeParameters, rightBracket);

  @override
  VariableDeclaration variableDeclaration(
          SimpleIdentifier name, Token? equals, Expression? initializer) =>
      VariableDeclarationImpl(
          name as SimpleIdentifierImpl, equals, initializer as ExpressionImpl?);

  @override
  VariableDeclarationList variableDeclarationList(
          Comment? comment,
          List<Annotation>? metadata,
          Token? keyword,
          TypeAnnotation? type,
          List<VariableDeclaration> variables) =>
      VariableDeclarationListImpl(comment as CommentImpl?, metadata, null,
          keyword, type as TypeAnnotationImpl?, variables);

  @override
  VariableDeclarationList variableDeclarationList2(
      {Comment? comment,
      List<Annotation>? metadata,
      Token? lateKeyword,
      Token? keyword,
      TypeAnnotation? type,
      required List<VariableDeclaration> variables}) {
    return VariableDeclarationListImpl(comment as CommentImpl?, metadata,
        lateKeyword, keyword, type as TypeAnnotationImpl?, variables);
  }

  @override
  VariableDeclarationStatement variableDeclarationStatement(
          VariableDeclarationList variableList, Token semicolon) =>
      VariableDeclarationStatementImpl(
          variableList as VariableDeclarationListImpl, semicolon);

  @override
  WhileStatement whileStatement(Token whileKeyword, Token leftParenthesis,
          Expression condition, Token rightParenthesis, Statement body) =>
      WhileStatementImpl(whileKeyword, leftParenthesis,
          condition as ExpressionImpl, rightParenthesis, body as StatementImpl);

  @override
  WithClause withClause(Token withKeyword, List<TypeName> mixinTypes) =>
      WithClauseImpl(withKeyword, mixinTypes);

  @override
  YieldStatement yieldStatement(Token yieldKeyword, Token? star,
          Expression expression, Token semicolon) =>
      YieldStatementImpl(
          yieldKeyword, star, expression as ExpressionImpl, semicolon);
}
