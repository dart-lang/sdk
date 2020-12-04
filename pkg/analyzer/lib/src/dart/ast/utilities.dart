// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/to_source_visitor.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;

export 'package:analyzer/src/dart/ast/constant_evaluator.dart';

/// A function used to handle exceptions that are thrown by delegates while
/// using an [ExceptionHandlingDelegatingAstVisitor].
typedef ExceptionInDelegateHandler = void Function(
    AstNode node, AstVisitor visitor, dynamic exception, StackTrace stackTrace);

/// An AST visitor that will clone any AST structure that it visits. The cloner
/// will only clone the structure, it will not preserve any resolution results
/// or properties associated with the nodes.
class AstCloner implements AstVisitor<AstNode> {
  /// A flag indicating whether tokens should be cloned while cloning an AST
  /// structure.
  final bool cloneTokens;

  /// Mapping from original tokes to cloned.
  final Map<Token, Token> _clonedTokens = Map<Token, Token>.identity();

  /// The next original token to clone.
  Token _nextToClone;

  /// The last cloned token.
  Token _lastCloned;

  /// The offset of the last cloned token.
  int _lastClonedOffset = -1;

  /// Initialize a newly created AST cloner to optionally clone tokens while
  /// cloning AST nodes if [cloneTokens] is `true`.
  ///
  /// TODO(brianwilkerson) Change this to be a named parameter.
  AstCloner([this.cloneTokens = false]);

  /// Return a clone of the given [node].
  E cloneNode<E extends AstNode>(E node) {
    if (node == null) {
      return null;
    }
    return node.accept(this) as E;
  }

  /// Return a list containing cloned versions of the nodes in the given list of
  /// [nodes].
  List<E> cloneNodeList<E extends AstNode>(List<E> nodes) {
    int count = nodes.length;
    List<E> clonedNodes = <E>[];
    for (int i = 0; i < count; i++) {
      clonedNodes.add((nodes[i]).accept(this) as E);
    }
    return clonedNodes;
  }

  /// Clone the given [token] if tokens are supposed to be cloned.
  Token cloneToken(Token token) {
    if (cloneTokens) {
      if (token == null) {
        return null;
      }
      if (_lastClonedOffset <= token.offset) {
        _cloneTokens(_nextToClone ?? token, token.offset);
      }
      Token clone = _clonedTokens[token];
      assert(clone != null);
      return clone;
    } else {
      return token;
    }
  }

  /// Clone the given [tokens] if tokens are supposed to be cloned.
  List<Token> cloneTokenList(List<Token> tokens) {
    if (cloneTokens) {
      return tokens.map(cloneToken).toList();
    }
    return tokens;
  }

  @override
  AdjacentStrings visitAdjacentStrings(AdjacentStrings node) =>
      astFactory.adjacentStrings(cloneNodeList(node.strings));

  @override
  Annotation visitAnnotation(Annotation node) => astFactory.annotation(
      cloneToken(node.atSign),
      cloneNode(node.name),
      cloneToken(node.period),
      cloneNode(node.constructorName),
      cloneNode(node.arguments));

  @override
  ArgumentList visitArgumentList(ArgumentList node) => astFactory.argumentList(
      cloneToken(node.leftParenthesis),
      cloneNodeList(node.arguments),
      cloneToken(node.rightParenthesis));

  @override
  AsExpression visitAsExpression(AsExpression node) => astFactory.asExpression(
      cloneNode(node.expression),
      cloneToken(node.asOperator),
      cloneNode(node.type));

  @override
  AstNode visitAssertInitializer(AssertInitializer node) =>
      astFactory.assertInitializer(
          cloneToken(node.assertKeyword),
          cloneToken(node.leftParenthesis),
          cloneNode(node.condition),
          cloneToken(node.comma),
          cloneNode(node.message),
          cloneToken(node.rightParenthesis));

  @override
  AstNode visitAssertStatement(AssertStatement node) =>
      astFactory.assertStatement(
          cloneToken(node.assertKeyword),
          cloneToken(node.leftParenthesis),
          cloneNode(node.condition),
          cloneToken(node.comma),
          cloneNode(node.message),
          cloneToken(node.rightParenthesis),
          cloneToken(node.semicolon));

  @override
  AssignmentExpression visitAssignmentExpression(AssignmentExpression node) =>
      astFactory.assignmentExpression(cloneNode(node.leftHandSide),
          cloneToken(node.operator), cloneNode(node.rightHandSide));

  @override
  AwaitExpression visitAwaitExpression(AwaitExpression node) =>
      astFactory.awaitExpression(
          cloneToken(node.awaitKeyword), cloneNode(node.expression));

  @override
  BinaryExpression visitBinaryExpression(BinaryExpression node) =>
      astFactory.binaryExpression(cloneNode(node.leftOperand),
          cloneToken(node.operator), cloneNode(node.rightOperand));

  @override
  Block visitBlock(Block node) => astFactory.block(cloneToken(node.leftBracket),
      cloneNodeList(node.statements), cloneToken(node.rightBracket));

  @override
  BlockFunctionBody visitBlockFunctionBody(BlockFunctionBody node) =>
      astFactory.blockFunctionBody(cloneToken(node.keyword),
          cloneToken(node.star), cloneNode(node.block));

  @override
  BooleanLiteral visitBooleanLiteral(BooleanLiteral node) =>
      astFactory.booleanLiteral(cloneToken(node.literal), node.value);

  @override
  BreakStatement visitBreakStatement(BreakStatement node) =>
      astFactory.breakStatement(cloneToken(node.breakKeyword),
          cloneNode(node.label), cloneToken(node.semicolon));

  @override
  CascadeExpression visitCascadeExpression(CascadeExpression node) =>
      astFactory.cascadeExpression(
          cloneNode(node.target), cloneNodeList(node.cascadeSections));

  @override
  CatchClause visitCatchClause(CatchClause node) => astFactory.catchClause(
      cloneToken(node.onKeyword),
      cloneNode(node.exceptionType),
      cloneToken(node.catchKeyword),
      cloneToken(node.leftParenthesis),
      cloneNode(node.exceptionParameter),
      cloneToken(node.comma),
      cloneNode(node.stackTraceParameter),
      cloneToken(node.rightParenthesis),
      cloneNode(node.body));

  @override
  ClassDeclaration visitClassDeclaration(ClassDeclaration node) {
    ClassDeclaration copy = astFactory.classDeclaration(
        cloneNode(node.documentationComment),
        cloneNodeList(node.metadata),
        cloneToken(node.abstractKeyword),
        cloneToken(node.classKeyword),
        cloneNode(node.name),
        cloneNode(node.typeParameters),
        cloneNode(node.extendsClause),
        cloneNode(node.withClause),
        cloneNode(node.implementsClause),
        cloneToken(node.leftBracket),
        cloneNodeList(node.members),
        cloneToken(node.rightBracket));
    copy.nativeClause = cloneNode(node.nativeClause);
    return copy;
  }

  @override
  ClassTypeAlias visitClassTypeAlias(ClassTypeAlias node) {
    cloneToken(node.abstractKeyword);
    return astFactory.classTypeAlias(
        cloneNode(node.documentationComment),
        cloneNodeList(node.metadata),
        cloneToken(node.typedefKeyword),
        cloneNode(node.name),
        cloneNode(node.typeParameters),
        cloneToken(node.equals),
        cloneToken(node.abstractKeyword),
        cloneNode(node.superclass),
        cloneNode(node.withClause),
        cloneNode(node.implementsClause),
        cloneToken(node.semicolon));
  }

  @override
  Comment visitComment(Comment node) {
    if (node.isDocumentation) {
      return astFactory.documentationComment(
          cloneTokenList(node.tokens), cloneNodeList(node.references));
    } else if (node.isBlock) {
      return astFactory.blockComment(cloneTokenList(node.tokens));
    }
    return astFactory.endOfLineComment(cloneTokenList(node.tokens));
  }

  @override
  CommentReference visitCommentReference(CommentReference node) {
    // Comment references have a token stream
    // separate from the compilation unit's token stream.
    // Clone the tokens in that stream here and add them to _clondedTokens
    // for use when cloning the comment reference.
    Token token = node.beginToken;
    Token lastCloned = Token.eof(-1);
    while (token != null) {
      Token clone = token.copy();
      _clonedTokens[token] = clone;
      lastCloned.setNext(clone);
      lastCloned = clone;
      if (token.isEof) {
        break;
      }
      token = token.next;
    }
    return astFactory.commentReference(
        cloneToken(node.newKeyword), cloneNode(node.identifier));
  }

  @override
  CompilationUnit visitCompilationUnit(CompilationUnit node) {
    CompilationUnit clone = astFactory.compilationUnit(
        beginToken: cloneToken(node.beginToken),
        scriptTag: cloneNode(node.scriptTag),
        directives: cloneNodeList(node.directives),
        declarations: cloneNodeList(node.declarations),
        endToken: cloneToken(node.endToken),
        featureSet: node.featureSet);
    clone.lineInfo = node.lineInfo;
    return clone;
  }

  @override
  ConditionalExpression visitConditionalExpression(
          ConditionalExpression node) =>
      astFactory.conditionalExpression(
          cloneNode(node.condition),
          cloneToken(node.question),
          cloneNode(node.thenExpression),
          cloneToken(node.colon),
          cloneNode(node.elseExpression));

  @override
  Configuration visitConfiguration(Configuration node) =>
      astFactory.configuration(
          cloneToken(node.ifKeyword),
          cloneToken(node.leftParenthesis),
          cloneNode(node.name),
          cloneToken(node.equalToken),
          cloneNode(node.value),
          cloneToken(node.rightParenthesis),
          cloneNode(node.uri));

  @override
  ConstructorDeclaration visitConstructorDeclaration(
          ConstructorDeclaration node) =>
      astFactory.constructorDeclaration(
          cloneNode(node.documentationComment),
          cloneNodeList(node.metadata),
          cloneToken(node.externalKeyword),
          cloneToken(node.constKeyword),
          cloneToken(node.factoryKeyword),
          cloneNode(node.returnType),
          cloneToken(node.period),
          cloneNode(node.name),
          cloneNode(node.parameters),
          cloneToken(node.separator),
          cloneNodeList(node.initializers),
          cloneNode(node.redirectedConstructor),
          cloneNode(node.body));

  @override
  ConstructorFieldInitializer visitConstructorFieldInitializer(
          ConstructorFieldInitializer node) =>
      astFactory.constructorFieldInitializer(
          cloneToken(node.thisKeyword),
          cloneToken(node.period),
          cloneNode(node.fieldName),
          cloneToken(node.equals),
          cloneNode(node.expression));

  @override
  ConstructorName visitConstructorName(ConstructorName node) =>
      astFactory.constructorName(
          cloneNode(node.type), cloneToken(node.period), cloneNode(node.name));

  @override
  ContinueStatement visitContinueStatement(ContinueStatement node) =>
      astFactory.continueStatement(cloneToken(node.continueKeyword),
          cloneNode(node.label), cloneToken(node.semicolon));

  @override
  DeclaredIdentifier visitDeclaredIdentifier(DeclaredIdentifier node) =>
      astFactory.declaredIdentifier(
          cloneNode(node.documentationComment),
          cloneNodeList(node.metadata),
          cloneToken(node.keyword),
          cloneNode(node.type),
          cloneNode(node.identifier));

  @override
  DefaultFormalParameter visitDefaultFormalParameter(
          covariant DefaultFormalParameterImpl node) =>
      astFactory.defaultFormalParameter(cloneNode(node.parameter), node.kind,
          cloneToken(node.separator), cloneNode(node.defaultValue));

  @override
  DoStatement visitDoStatement(DoStatement node) => astFactory.doStatement(
      cloneToken(node.doKeyword),
      cloneNode(node.body),
      cloneToken(node.whileKeyword),
      cloneToken(node.leftParenthesis),
      cloneNode(node.condition),
      cloneToken(node.rightParenthesis),
      cloneToken(node.semicolon));

  @override
  DottedName visitDottedName(DottedName node) =>
      astFactory.dottedName(cloneNodeList(node.components));

  @override
  DoubleLiteral visitDoubleLiteral(DoubleLiteral node) =>
      astFactory.doubleLiteral(cloneToken(node.literal), node.value);

  @override
  EmptyFunctionBody visitEmptyFunctionBody(EmptyFunctionBody node) =>
      astFactory.emptyFunctionBody(cloneToken(node.semicolon));

  @override
  EmptyStatement visitEmptyStatement(EmptyStatement node) =>
      astFactory.emptyStatement(cloneToken(node.semicolon));

  @override
  AstNode visitEnumConstantDeclaration(EnumConstantDeclaration node) =>
      astFactory.enumConstantDeclaration(cloneNode(node.documentationComment),
          cloneNodeList(node.metadata), cloneNode(node.name));

  @override
  EnumDeclaration visitEnumDeclaration(EnumDeclaration node) =>
      astFactory.enumDeclaration(
          cloneNode(node.documentationComment),
          cloneNodeList(node.metadata),
          cloneToken(node.enumKeyword),
          cloneNode(node.name),
          cloneToken(node.leftBracket),
          cloneNodeList(node.constants),
          cloneToken(node.rightBracket));

  @override
  ExportDirective visitExportDirective(ExportDirective node) {
    ExportDirectiveImpl directive = astFactory.exportDirective(
        cloneNode(node.documentationComment),
        cloneNodeList(node.metadata),
        cloneToken(node.keyword),
        cloneNode(node.uri),
        cloneNodeList(node.configurations),
        cloneNodeList(node.combinators),
        cloneToken(node.semicolon));
    directive.selectedUriContent = node.selectedUriContent;
    directive.selectedSource = node.selectedSource;
    directive.uriSource = node.uriSource;
    directive.uriContent = node.uriContent;
    return directive;
  }

  @override
  ExpressionFunctionBody visitExpressionFunctionBody(
          ExpressionFunctionBody node) =>
      astFactory.expressionFunctionBody(
          cloneToken(node.keyword),
          cloneToken(node.functionDefinition),
          cloneNode(node.expression),
          cloneToken(node.semicolon));

  @override
  ExpressionStatement visitExpressionStatement(ExpressionStatement node) =>
      astFactory.expressionStatement(
          cloneNode(node.expression), cloneToken(node.semicolon));

  @override
  ExtendsClause visitExtendsClause(ExtendsClause node) =>
      astFactory.extendsClause(
          cloneToken(node.extendsKeyword), cloneNode(node.superclass));

  @override
  ExtensionDeclaration visitExtensionDeclaration(ExtensionDeclaration node) =>
      astFactory.extensionDeclaration(
          comment: cloneNode(node.documentationComment),
          metadata: cloneNodeList(node.metadata),
          extensionKeyword: cloneToken(node.extensionKeyword),
          name: cloneNode(node.name),
          typeParameters: cloneNode(node.typeParameters),
          onKeyword: cloneToken(node.onKeyword),
          extendedType: cloneNode(node.extendedType),
          leftBracket: cloneToken(node.leftBracket),
          members: cloneNodeList(node.members),
          rightBracket: cloneToken(node.rightBracket));

  @override
  ExtensionOverride visitExtensionOverride(ExtensionOverride node) =>
      astFactory.extensionOverride(
          extensionName: cloneNode(node.extensionName),
          typeArguments: cloneNode(node.typeArguments),
          argumentList: cloneNode(node.argumentList));

  @override
  FieldDeclaration visitFieldDeclaration(FieldDeclaration node) =>
      astFactory.fieldDeclaration2(
          comment: cloneNode(node.documentationComment),
          metadata: cloneNodeList(node.metadata),
          abstractKeyword: cloneToken(node.abstractKeyword),
          covariantKeyword: cloneToken(node.covariantKeyword),
          externalKeyword: cloneToken(node.externalKeyword),
          staticKeyword: cloneToken(node.staticKeyword),
          fieldList: cloneNode(node.fields),
          semicolon: cloneToken(node.semicolon));

  @override
  FieldFormalParameter visitFieldFormalParameter(FieldFormalParameter node) =>
      astFactory.fieldFormalParameter2(
          comment: cloneNode(node.documentationComment),
          metadata: cloneNodeList(node.metadata),
          covariantKeyword: cloneToken(node.covariantKeyword),
          keyword: cloneToken(node.keyword),
          type: cloneNode(node.type),
          thisKeyword: cloneToken(node.thisKeyword),
          period: cloneToken(node.period),
          identifier: cloneNode(node.identifier),
          typeParameters: cloneNode(node.typeParameters),
          parameters: cloneNode(node.parameters),
          question: cloneToken(node.question));

  @override
  ForEachPartsWithDeclaration visitForEachPartsWithDeclaration(
          ForEachPartsWithDeclaration node) =>
      astFactory.forEachPartsWithDeclaration(
          loopVariable: cloneNode(node.loopVariable),
          inKeyword: cloneToken(node.inKeyword),
          iterable: cloneNode(node.iterable));

  @override
  ForEachPartsWithIdentifier visitForEachPartsWithIdentifier(
          ForEachPartsWithIdentifier node) =>
      astFactory.forEachPartsWithIdentifier(
          identifier: cloneNode(node.identifier),
          inKeyword: cloneToken(node.inKeyword),
          iterable: cloneNode(node.iterable));

  @override
  ForElement visitForElement(ForElement node) => astFactory.forElement(
      awaitKeyword: cloneToken(node.awaitKeyword),
      forKeyword: cloneToken(node.forKeyword),
      leftParenthesis: cloneToken(node.leftParenthesis),
      forLoopParts: cloneNode(node.forLoopParts),
      rightParenthesis: cloneToken(node.rightParenthesis),
      body: cloneNode(node.body));

  @override
  FormalParameterList visitFormalParameterList(FormalParameterList node) =>
      astFactory.formalParameterList(
          cloneToken(node.leftParenthesis),
          cloneNodeList(node.parameters),
          cloneToken(node.leftDelimiter),
          cloneToken(node.rightDelimiter),
          cloneToken(node.rightParenthesis));

  @override
  ForPartsWithDeclarations visitForPartsWithDeclarations(
          ForPartsWithDeclarations node) =>
      astFactory.forPartsWithDeclarations(
          variables: cloneNode(node.variables),
          leftSeparator: cloneToken(node.leftSeparator),
          condition: cloneNode(node.condition),
          rightSeparator: cloneToken(node.rightSeparator),
          updaters: cloneNodeList(node.updaters));

  @override
  ForPartsWithExpression visitForPartsWithExpression(
          ForPartsWithExpression node) =>
      astFactory.forPartsWithExpression(
          initialization: cloneNode(node.initialization),
          leftSeparator: cloneToken(node.leftSeparator),
          condition: cloneNode(node.condition),
          rightSeparator: cloneToken(node.rightSeparator),
          updaters: cloneNodeList(node.updaters));

  @override
  ForStatement visitForStatement(ForStatement node) => astFactory.forStatement(
      awaitKeyword: cloneToken(node.awaitKeyword),
      forKeyword: cloneToken(node.forKeyword),
      leftParenthesis: cloneToken(node.leftParenthesis),
      forLoopParts: cloneNode(node.forLoopParts),
      rightParenthesis: cloneToken(node.rightParenthesis),
      body: cloneNode(node.body));

  @override
  FunctionDeclaration visitFunctionDeclaration(FunctionDeclaration node) =>
      astFactory.functionDeclaration(
          cloneNode(node.documentationComment),
          cloneNodeList(node.metadata),
          cloneToken(node.externalKeyword),
          cloneNode(node.returnType),
          cloneToken(node.propertyKeyword),
          cloneNode(node.name),
          cloneNode(node.functionExpression));

  @override
  FunctionDeclarationStatement visitFunctionDeclarationStatement(
          FunctionDeclarationStatement node) =>
      astFactory
          .functionDeclarationStatement(cloneNode(node.functionDeclaration));

  @override
  FunctionExpression visitFunctionExpression(FunctionExpression node) =>
      astFactory.functionExpression(cloneNode(node.typeParameters),
          cloneNode(node.parameters), cloneNode(node.body));

  @override
  FunctionExpressionInvocation visitFunctionExpressionInvocation(
          FunctionExpressionInvocation node) =>
      astFactory.functionExpressionInvocation(cloneNode(node.function),
          cloneNode(node.typeArguments), cloneNode(node.argumentList));

  @override
  FunctionTypeAlias visitFunctionTypeAlias(FunctionTypeAlias node) =>
      astFactory.functionTypeAlias(
          cloneNode(node.documentationComment),
          cloneNodeList(node.metadata),
          cloneToken(node.typedefKeyword),
          cloneNode(node.returnType),
          cloneNode(node.name),
          cloneNode(node.typeParameters),
          cloneNode(node.parameters),
          cloneToken(node.semicolon));

  @override
  FunctionTypedFormalParameter visitFunctionTypedFormalParameter(
          FunctionTypedFormalParameter node) =>
      astFactory.functionTypedFormalParameter2(
          comment: cloneNode(node.documentationComment),
          metadata: cloneNodeList(node.metadata),
          covariantKeyword: cloneToken(node.covariantKeyword),
          returnType: cloneNode(node.returnType),
          identifier: cloneNode(node.identifier),
          typeParameters: cloneNode(node.typeParameters),
          parameters: cloneNode(node.parameters),
          question: cloneToken(node.question));

  @override
  AstNode visitGenericFunctionType(GenericFunctionType node) =>
      astFactory.genericFunctionType(
          cloneNode(node.returnType),
          cloneToken(node.functionKeyword),
          cloneNode(node.typeParameters),
          cloneNode(node.parameters),
          question: cloneToken(node.question));

  @override
  AstNode visitGenericTypeAlias(GenericTypeAlias node) =>
      astFactory.genericTypeAlias(
          cloneNode(node.documentationComment),
          cloneNodeList(node.metadata),
          cloneToken(node.typedefKeyword),
          cloneNode(node.name),
          cloneNode(node.typeParameters),
          cloneToken(node.equals),
          cloneNode(node.type),
          cloneToken(node.semicolon));

  @override
  HideCombinator visitHideCombinator(HideCombinator node) =>
      astFactory.hideCombinator(
          cloneToken(node.keyword), cloneNodeList(node.hiddenNames));

  @override
  IfElement visitIfElement(IfElement node) => astFactory.ifElement(
      ifKeyword: cloneToken(node.ifKeyword),
      leftParenthesis: cloneToken(node.leftParenthesis),
      condition: cloneNode(node.condition),
      rightParenthesis: cloneToken(node.rightParenthesis),
      thenElement: cloneNode(node.thenElement),
      elseKeyword: cloneToken(node.elseKeyword),
      elseElement: cloneNode(node.elseElement));

  @override
  IfStatement visitIfStatement(IfStatement node) => astFactory.ifStatement(
      cloneToken(node.ifKeyword),
      cloneToken(node.leftParenthesis),
      cloneNode(node.condition),
      cloneToken(node.rightParenthesis),
      cloneNode(node.thenStatement),
      cloneToken(node.elseKeyword),
      cloneNode(node.elseStatement));

  @override
  ImplementsClause visitImplementsClause(ImplementsClause node) =>
      astFactory.implementsClause(
          cloneToken(node.implementsKeyword), cloneNodeList(node.interfaces));

  @override
  ImportDirective visitImportDirective(ImportDirective node) {
    ImportDirectiveImpl directive = astFactory.importDirective(
        cloneNode(node.documentationComment),
        cloneNodeList(node.metadata),
        cloneToken(node.keyword),
        cloneNode(node.uri),
        cloneNodeList(node.configurations),
        cloneToken(node.deferredKeyword),
        cloneToken(node.asKeyword),
        cloneNode(node.prefix),
        cloneNodeList(node.combinators),
        cloneToken(node.semicolon));
    directive.selectedUriContent = node.selectedUriContent;
    directive.selectedSource = node.selectedSource;
    directive.uriSource = node.uriSource;
    directive.uriContent = node.uriContent;
    return directive;
  }

  @override
  IndexExpression visitIndexExpression(IndexExpression node) {
    Token period = node.period;
    if (period == null) {
      return astFactory.indexExpressionForTarget2(
          target: cloneNode(node.target),
          leftBracket: cloneToken(node.leftBracket),
          index: cloneNode(node.index),
          rightBracket: cloneToken(node.rightBracket));
    } else {
      return astFactory.indexExpressionForCascade2(
          period: cloneToken(period),
          leftBracket: cloneToken(node.leftBracket),
          index: cloneNode(node.index),
          rightBracket: cloneToken(node.rightBracket));
    }
  }

  @override
  InstanceCreationExpression visitInstanceCreationExpression(
          InstanceCreationExpression node) =>
      astFactory.instanceCreationExpression(cloneToken(node.keyword),
          cloneNode(node.constructorName), cloneNode(node.argumentList));

  @override
  IntegerLiteral visitIntegerLiteral(IntegerLiteral node) =>
      astFactory.integerLiteral(cloneToken(node.literal), node.value);

  @override
  InterpolationExpression visitInterpolationExpression(
          InterpolationExpression node) =>
      astFactory.interpolationExpression(cloneToken(node.leftBracket),
          cloneNode(node.expression), cloneToken(node.rightBracket));

  @override
  InterpolationString visitInterpolationString(InterpolationString node) =>
      astFactory.interpolationString(cloneToken(node.contents), node.value);

  @override
  IsExpression visitIsExpression(IsExpression node) => astFactory.isExpression(
      cloneNode(node.expression),
      cloneToken(node.isOperator),
      cloneToken(node.notOperator),
      cloneNode(node.type));

  @override
  Label visitLabel(Label node) =>
      astFactory.label(cloneNode(node.label), cloneToken(node.colon));

  @override
  LabeledStatement visitLabeledStatement(LabeledStatement node) => astFactory
      .labeledStatement(cloneNodeList(node.labels), cloneNode(node.statement));

  @override
  LibraryDirective visitLibraryDirective(LibraryDirective node) =>
      astFactory.libraryDirective(
          cloneNode(node.documentationComment),
          cloneNodeList(node.metadata),
          cloneToken(node.libraryKeyword),
          cloneNode(node.name),
          cloneToken(node.semicolon));

  @override
  LibraryIdentifier visitLibraryIdentifier(LibraryIdentifier node) =>
      astFactory.libraryIdentifier(cloneNodeList(node.components));

  @override
  ListLiteral visitListLiteral(ListLiteral node) => astFactory.listLiteral(
      cloneToken(node.constKeyword),
      cloneNode(node.typeArguments),
      cloneToken(node.leftBracket),
      cloneNodeList(node.elements),
      cloneToken(node.rightBracket));

  @override
  MapLiteralEntry visitMapLiteralEntry(MapLiteralEntry node) =>
      astFactory.mapLiteralEntry(cloneNode(node.key),
          cloneToken(node.separator), cloneNode(node.value));

  @override
  MethodDeclaration visitMethodDeclaration(MethodDeclaration node) =>
      astFactory.methodDeclaration(
          cloneNode(node.documentationComment),
          cloneNodeList(node.metadata),
          cloneToken(node.externalKeyword),
          cloneToken(node.modifierKeyword),
          cloneNode(node.returnType),
          cloneToken(node.propertyKeyword),
          cloneToken(node.operatorKeyword),
          cloneNode(node.name),
          cloneNode(node.typeParameters),
          cloneNode(node.parameters),
          cloneNode(node.body));

  @override
  MethodInvocation visitMethodInvocation(MethodInvocation node) =>
      astFactory.methodInvocation(
          cloneNode(node.target),
          cloneToken(node.operator),
          cloneNode(node.methodName),
          cloneNode(node.typeArguments),
          cloneNode(node.argumentList));

  @override
  AstNode visitMixinDeclaration(MixinDeclaration node) =>
      astFactory.mixinDeclaration(
          cloneNode(node.documentationComment),
          cloneNodeList(node.metadata),
          cloneToken(node.mixinKeyword),
          cloneNode(node.name),
          cloneNode(node.typeParameters),
          cloneNode(node.onClause),
          cloneNode(node.implementsClause),
          cloneToken(node.leftBracket),
          cloneNodeList(node.members),
          cloneToken(node.rightBracket));

  @override
  NamedExpression visitNamedExpression(NamedExpression node) => astFactory
      .namedExpression(cloneNode(node.name), cloneNode(node.expression));

  @override
  AstNode visitNativeClause(NativeClause node) => astFactory.nativeClause(
      cloneToken(node.nativeKeyword), cloneNode(node.name));

  @override
  NativeFunctionBody visitNativeFunctionBody(NativeFunctionBody node) =>
      astFactory.nativeFunctionBody(cloneToken(node.nativeKeyword),
          cloneNode(node.stringLiteral), cloneToken(node.semicolon));

  @override
  NullLiteral visitNullLiteral(NullLiteral node) =>
      astFactory.nullLiteral(cloneToken(node.literal));

  @override
  AstNode visitOnClause(OnClause node) => astFactory.onClause(
      cloneToken(node.onKeyword), cloneNodeList(node.superclassConstraints));

  @override
  ParenthesizedExpression visitParenthesizedExpression(
          ParenthesizedExpression node) =>
      astFactory.parenthesizedExpression(cloneToken(node.leftParenthesis),
          cloneNode(node.expression), cloneToken(node.rightParenthesis));

  @override
  PartDirective visitPartDirective(PartDirective node) {
    PartDirective directive = astFactory.partDirective(
        cloneNode(node.documentationComment),
        cloneNodeList(node.metadata),
        cloneToken(node.partKeyword),
        cloneNode(node.uri),
        cloneToken(node.semicolon));
    directive.uriSource = node.uriSource;
    directive.uriContent = node.uriContent;
    return directive;
  }

  @override
  PartOfDirective visitPartOfDirective(PartOfDirective node) =>
      astFactory.partOfDirective(
          cloneNode(node.documentationComment),
          cloneNodeList(node.metadata),
          cloneToken(node.partKeyword),
          cloneToken(node.ofKeyword),
          cloneNode(node.uri),
          cloneNode(node.libraryName),
          cloneToken(node.semicolon));

  @override
  PostfixExpression visitPostfixExpression(PostfixExpression node) => astFactory
      .postfixExpression(cloneNode(node.operand), cloneToken(node.operator));

  @override
  PrefixedIdentifier visitPrefixedIdentifier(PrefixedIdentifier node) =>
      astFactory.prefixedIdentifier(cloneNode(node.prefix),
          cloneToken(node.period), cloneNode(node.identifier));

  @override
  PrefixExpression visitPrefixExpression(PrefixExpression node) => astFactory
      .prefixExpression(cloneToken(node.operator), cloneNode(node.operand));

  @override
  PropertyAccess visitPropertyAccess(PropertyAccess node) =>
      astFactory.propertyAccess(cloneNode(node.target),
          cloneToken(node.operator), cloneNode(node.propertyName));

  @override
  RedirectingConstructorInvocation visitRedirectingConstructorInvocation(
          RedirectingConstructorInvocation node) =>
      astFactory.redirectingConstructorInvocation(
          cloneToken(node.thisKeyword),
          cloneToken(node.period),
          cloneNode(node.constructorName),
          cloneNode(node.argumentList));

  @override
  RethrowExpression visitRethrowExpression(RethrowExpression node) =>
      astFactory.rethrowExpression(cloneToken(node.rethrowKeyword));

  @override
  ReturnStatement visitReturnStatement(ReturnStatement node) =>
      astFactory.returnStatement(cloneToken(node.returnKeyword),
          cloneNode(node.expression), cloneToken(node.semicolon));

  @override
  ScriptTag visitScriptTag(ScriptTag node) =>
      astFactory.scriptTag(cloneToken(node.scriptTag));

  @override
  SetOrMapLiteral visitSetOrMapLiteral(SetOrMapLiteral node) {
    var result = astFactory.setOrMapLiteral(
        constKeyword: cloneToken(node.constKeyword),
        typeArguments: cloneNode(node.typeArguments),
        leftBracket: cloneToken(node.leftBracket),
        elements: cloneNodeList(node.elements),
        rightBracket: cloneToken(node.rightBracket));
    if (node.isMap) {
      (result as SetOrMapLiteralImpl).becomeMap();
    } else if (node.isSet) {
      (result as SetOrMapLiteralImpl).becomeSet();
    }
    return result;
  }

  @override
  ShowCombinator visitShowCombinator(ShowCombinator node) => astFactory
      .showCombinator(cloneToken(node.keyword), cloneNodeList(node.shownNames));

  @override
  SimpleFormalParameter visitSimpleFormalParameter(
          SimpleFormalParameter node) =>
      astFactory.simpleFormalParameter2(
          comment: cloneNode(node.documentationComment),
          metadata: cloneNodeList(node.metadata),
          covariantKeyword: cloneToken(node.covariantKeyword),
          keyword: cloneToken(node.keyword),
          type: cloneNode(node.type),
          identifier: cloneNode(node.identifier));

  @override
  SimpleIdentifier visitSimpleIdentifier(SimpleIdentifier node) =>
      astFactory.simpleIdentifier(cloneToken(node.token),
          isDeclaration: node.inDeclarationContext());

  @override
  SimpleStringLiteral visitSimpleStringLiteral(SimpleStringLiteral node) =>
      astFactory.simpleStringLiteral(cloneToken(node.literal), node.value);

  @override
  SpreadElement visitSpreadElement(SpreadElement node) =>
      astFactory.spreadElement(
          spreadOperator: cloneToken(node.spreadOperator),
          expression: cloneNode(node.expression));

  @override
  StringInterpolation visitStringInterpolation(StringInterpolation node) =>
      astFactory.stringInterpolation(cloneNodeList(node.elements));

  @override
  SuperConstructorInvocation visitSuperConstructorInvocation(
          SuperConstructorInvocation node) =>
      astFactory.superConstructorInvocation(
          cloneToken(node.superKeyword),
          cloneToken(node.period),
          cloneNode(node.constructorName),
          cloneNode(node.argumentList));

  @override
  SuperExpression visitSuperExpression(SuperExpression node) =>
      astFactory.superExpression(cloneToken(node.superKeyword));

  @override
  SwitchCase visitSwitchCase(SwitchCase node) => astFactory.switchCase(
      cloneNodeList(node.labels),
      cloneToken(node.keyword),
      cloneNode(node.expression),
      cloneToken(node.colon),
      cloneNodeList(node.statements));

  @override
  SwitchDefault visitSwitchDefault(SwitchDefault node) =>
      astFactory.switchDefault(
          cloneNodeList(node.labels),
          cloneToken(node.keyword),
          cloneToken(node.colon),
          cloneNodeList(node.statements));

  @override
  SwitchStatement visitSwitchStatement(SwitchStatement node) =>
      astFactory.switchStatement(
          cloneToken(node.switchKeyword),
          cloneToken(node.leftParenthesis),
          cloneNode(node.expression),
          cloneToken(node.rightParenthesis),
          cloneToken(node.leftBracket),
          cloneNodeList(node.members),
          cloneToken(node.rightBracket));

  @override
  SymbolLiteral visitSymbolLiteral(SymbolLiteral node) =>
      astFactory.symbolLiteral(
          cloneToken(node.poundSign), cloneTokenList(node.components));

  @override
  ThisExpression visitThisExpression(ThisExpression node) =>
      astFactory.thisExpression(cloneToken(node.thisKeyword));

  @override
  ThrowExpression visitThrowExpression(ThrowExpression node) =>
      astFactory.throwExpression(
          cloneToken(node.throwKeyword), cloneNode(node.expression));

  @override
  TopLevelVariableDeclaration visitTopLevelVariableDeclaration(
          TopLevelVariableDeclaration node) =>
      astFactory.topLevelVariableDeclaration(
          cloneNode(node.documentationComment),
          cloneNodeList(node.metadata),
          cloneNode(node.variables),
          cloneToken(node.semicolon),
          externalKeyword: cloneToken(node.externalKeyword));

  @override
  TryStatement visitTryStatement(TryStatement node) => astFactory.tryStatement(
      cloneToken(node.tryKeyword),
      cloneNode(node.body),
      cloneNodeList(node.catchClauses),
      cloneToken(node.finallyKeyword),
      cloneNode(node.finallyBlock));

  @override
  TypeArgumentList visitTypeArgumentList(TypeArgumentList node) =>
      astFactory.typeArgumentList(cloneToken(node.leftBracket),
          cloneNodeList(node.arguments), cloneToken(node.rightBracket));

  @override
  TypeName visitTypeName(TypeName node) =>
      astFactory.typeName(cloneNode(node.name), cloneNode(node.typeArguments),
          question: cloneToken(node.question));

  @override
  TypeParameter visitTypeParameter(TypeParameter node) =>
      // TODO (kallentu) : Clean up TypeParameterImpl and AstFactoryImpl casting
      // once variance is added to the interface.
      (astFactory as AstFactoryImpl).typeParameter2(
          comment: cloneNode(node.documentationComment),
          metadata: cloneNodeList(node.metadata),
          name: cloneNode(node.name),
          extendsKeyword: cloneToken(node.extendsKeyword),
          bound: cloneNode(node.bound),
          varianceKeyword:
              cloneToken((node as TypeParameterImpl).varianceKeyword));

  @override
  TypeParameterList visitTypeParameterList(TypeParameterList node) =>
      astFactory.typeParameterList(cloneToken(node.leftBracket),
          cloneNodeList(node.typeParameters), cloneToken(node.rightBracket));

  @override
  VariableDeclaration visitVariableDeclaration(VariableDeclaration node) =>
      astFactory.variableDeclaration(cloneNode(node.name),
          cloneToken(node.equals), cloneNode(node.initializer));

  @override
  VariableDeclarationList visitVariableDeclarationList(
          VariableDeclarationList node) =>
      astFactory.variableDeclarationList(
          cloneNode(node.documentationComment),
          cloneNodeList(node.metadata),
          cloneToken(node.keyword),
          cloneNode(node.type),
          cloneNodeList(node.variables));

  @override
  VariableDeclarationStatement visitVariableDeclarationStatement(
          VariableDeclarationStatement node) =>
      astFactory.variableDeclarationStatement(
          cloneNode(node.variables), cloneToken(node.semicolon));

  @override
  WhileStatement visitWhileStatement(WhileStatement node) =>
      astFactory.whileStatement(
          cloneToken(node.whileKeyword),
          cloneToken(node.leftParenthesis),
          cloneNode(node.condition),
          cloneToken(node.rightParenthesis),
          cloneNode(node.body));

  @override
  WithClause visitWithClause(WithClause node) => astFactory.withClause(
      cloneToken(node.withKeyword), cloneNodeList(node.mixinTypes));

  @override
  YieldStatement visitYieldStatement(YieldStatement node) =>
      astFactory.yieldStatement(
          cloneToken(node.yieldKeyword),
          cloneToken(node.star),
          cloneNode(node.expression),
          cloneToken(node.semicolon));

  /// Clone all token starting from the given [token] up to a token that has
  /// offset greater then [stopAfter], and put mapping from originals to clones
  /// into [_clonedTokens].
  ///
  /// We cannot clone tokens as we visit nodes because not every token is a part
  /// of a node, E.g. commas in argument lists are not represented in AST. But
  /// we need to the sequence of tokens that is identical to the original one.
  void _cloneTokens(Token token, int stopAfter) {
    if (token == null) {
      return;
    }
    Token nonComment(Token token) {
      return token is CommentToken ? token.parent : token;
    }

    token = nonComment(token);
    _lastCloned ??= Token.eof(-1);
    while (token != null) {
      Token clone = token.copy();
      {
        CommentToken c1 = token.precedingComments;
        CommentToken c2 = clone.precedingComments;
        while (c1 != null && c2 != null) {
          _clonedTokens[c1] = c2;
          c1 = c1.next;
          c2 = c2.next;
        }
      }
      _clonedTokens[token] = clone;
      _lastCloned.setNext(clone);
      _lastCloned = clone;
      if (token.type == TokenType.EOF) {
        break;
      }
      if (token.offset > stopAfter) {
        _nextToClone = token.next;
        _lastClonedOffset = token.offset;
        break;
      }
      token = token.next;
    }
  }

  /// Return a clone of the given [node].
  static AstNode clone(AstNode node) {
    return node.accept(AstCloner());
  }
}

/// An AstVisitor that compares the structure of two AstNodes to see whether
/// they are equal.
class AstComparator implements AstVisitor<bool> {
  /// The AST node with which the node being visited is to be compared. This is
  /// only valid at the beginning of each visit method (until [isEqualNodes] is
  /// invoked).
  AstNode _other;

  /// Notify that [first] and second have different length.
  /// This implementation returns `false`. Subclasses can override and throw.
  bool failDifferentLength(List first, List second) {
    return false;
  }

  /// Check whether the values of the [first] and [second] nodes are [equal].
  /// Subclasses can override to throw.
  bool failIfNotEqual(
      AstNode first, Object firstValue, AstNode second, Object secondValue) {
    return firstValue == secondValue;
  }

  /// Check whether [second] is null. Subclasses can override to throw.
  bool failIfNotNull(Object first, Object second) {
    return second == null;
  }

  /// Notify that [first] is not `null` while [second] one is `null`.
  /// This implementation returns `false`. Subclasses can override and throw.
  bool failIsNull(Object first, Object second) {
    return false;
  }

  /// Notify that [first] and [second] have different types.
  /// This implementation returns `false`. Subclasses can override and throw.
  bool failRuntimeType(Object first, Object second) {
    return false;
  }

  /// Return `true` if the [first] node and the [second] node have the same
  /// structure.
  ///
  /// *Note:* This method is only visible for testing purposes and should not be
  /// used by clients.
  bool isEqualNodes(AstNode first, AstNode second) {
    if (first == null) {
      return failIfNotNull(first, second);
    } else if (second == null) {
      return failIsNull(first, second);
    } else if (first.runtimeType != second.runtimeType) {
      return failRuntimeType(first, second);
    }
    _other = second;
    return first.accept(this);
  }

  /// Return `true` if the [first] token and the [second] token have the same
  /// structure.
  ///
  /// *Note:* This method is only visible for testing purposes and should not be
  /// used by clients.
  bool isEqualTokens(Token first, Token second) {
    if (first == null) {
      return failIfNotNull(first, second);
    } else if (second == null) {
      return failIsNull(first, second);
    } else if (identical(first, second)) {
      return true;
    }
    return isEqualTokensNotNull(first, second);
  }

  /// Return `true` if the [first] token and the [second] token have the same
  /// structure.  Both [first] and [second] are not `null`.
  bool isEqualTokensNotNull(Token first, Token second) =>
      first.offset == second.offset &&
      first.length == second.length &&
      first.lexeme == second.lexeme;

  @override
  bool visitAdjacentStrings(AdjacentStrings node) {
    AdjacentStrings other = _other as AdjacentStrings;
    return _isEqualNodeLists(node.strings, other.strings);
  }

  @override
  bool visitAnnotation(Annotation node) {
    Annotation other = _other as Annotation;
    return isEqualTokens(node.atSign, other.atSign) &&
        isEqualNodes(node.name, other.name) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.constructorName, other.constructorName) &&
        isEqualNodes(node.arguments, other.arguments);
  }

  @override
  bool visitArgumentList(ArgumentList node) {
    ArgumentList other = _other as ArgumentList;
    return isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        _isEqualNodeLists(node.arguments, other.arguments) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis);
  }

  @override
  bool visitAsExpression(AsExpression node) {
    AsExpression other = _other as AsExpression;
    return isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.asOperator, other.asOperator) &&
        isEqualNodes(node.type, other.type);
  }

  @override
  bool visitAssertInitializer(AssertInitializer node) {
    AssertInitializer other = _other as AssertInitializer;
    return isEqualTokens(node.assertKeyword, other.assertKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.comma, other.comma) &&
        isEqualNodes(node.message, other.message) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis);
  }

  @override
  bool visitAssertStatement(AssertStatement node) {
    AssertStatement other = _other as AssertStatement;
    return isEqualTokens(node.assertKeyword, other.assertKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.comma, other.comma) &&
        isEqualNodes(node.message, other.message) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitAssignmentExpression(AssignmentExpression node) {
    AssignmentExpression other = _other as AssignmentExpression;
    return isEqualNodes(node.leftHandSide, other.leftHandSide) &&
        isEqualTokens(node.operator, other.operator) &&
        isEqualNodes(node.rightHandSide, other.rightHandSide);
  }

  @override
  bool visitAwaitExpression(AwaitExpression node) {
    AwaitExpression other = _other as AwaitExpression;
    return isEqualTokens(node.awaitKeyword, other.awaitKeyword) &&
        isEqualNodes(node.expression, other.expression);
  }

  @override
  bool visitBinaryExpression(BinaryExpression node) {
    BinaryExpression other = _other as BinaryExpression;
    return isEqualNodes(node.leftOperand, other.leftOperand) &&
        isEqualTokens(node.operator, other.operator) &&
        isEqualNodes(node.rightOperand, other.rightOperand);
  }

  @override
  bool visitBlock(Block node) {
    Block other = _other as Block;
    return isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.statements, other.statements) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitBlockFunctionBody(BlockFunctionBody node) {
    BlockFunctionBody other = _other as BlockFunctionBody;
    return isEqualNodes(node.block, other.block);
  }

  @override
  bool visitBooleanLiteral(BooleanLiteral node) {
    BooleanLiteral other = _other as BooleanLiteral;
    return isEqualTokens(node.literal, other.literal) &&
        failIfNotEqual(node, node.value, other, other.value);
  }

  @override
  bool visitBreakStatement(BreakStatement node) {
    BreakStatement other = _other as BreakStatement;
    return isEqualTokens(node.breakKeyword, other.breakKeyword) &&
        isEqualNodes(node.label, other.label) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitCascadeExpression(CascadeExpression node) {
    CascadeExpression other = _other as CascadeExpression;
    return isEqualNodes(node.target, other.target) &&
        _isEqualNodeLists(node.cascadeSections, other.cascadeSections);
  }

  @override
  bool visitCatchClause(CatchClause node) {
    CatchClause other = _other as CatchClause;
    return isEqualTokens(node.onKeyword, other.onKeyword) &&
        isEqualNodes(node.exceptionType, other.exceptionType) &&
        isEqualTokens(node.catchKeyword, other.catchKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.exceptionParameter, other.exceptionParameter) &&
        isEqualTokens(node.comma, other.comma) &&
        isEqualNodes(node.stackTraceParameter, other.stackTraceParameter) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitClassDeclaration(ClassDeclaration node) {
    ClassDeclaration other = _other as ClassDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.abstractKeyword, other.abstractKeyword) &&
        isEqualTokens(node.classKeyword, other.classKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeParameters, other.typeParameters) &&
        isEqualNodes(node.extendsClause, other.extendsClause) &&
        isEqualNodes(node.withClause, other.withClause) &&
        isEqualNodes(node.implementsClause, other.implementsClause) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.members, other.members) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitClassTypeAlias(ClassTypeAlias node) {
    ClassTypeAlias other = _other as ClassTypeAlias;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.typedefKeyword, other.typedefKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeParameters, other.typeParameters) &&
        isEqualTokens(node.equals, other.equals) &&
        isEqualTokens(node.abstractKeyword, other.abstractKeyword) &&
        isEqualNodes(node.superclass, other.superclass) &&
        isEqualNodes(node.withClause, other.withClause) &&
        isEqualNodes(node.implementsClause, other.implementsClause) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitComment(Comment node) {
    Comment other = _other as Comment;
    return _isEqualNodeLists(node.references, other.references);
  }

  @override
  bool visitCommentReference(CommentReference node) {
    CommentReference other = _other as CommentReference;
    return isEqualTokens(node.newKeyword, other.newKeyword) &&
        isEqualNodes(node.identifier, other.identifier);
  }

  @override
  bool visitCompilationUnit(CompilationUnit node) {
    CompilationUnit other = _other as CompilationUnit;
    return isEqualTokens(node.beginToken, other.beginToken) &&
        isEqualNodes(node.scriptTag, other.scriptTag) &&
        _isEqualNodeLists(node.directives, other.directives) &&
        _isEqualNodeLists(node.declarations, other.declarations) &&
        isEqualTokens(node.endToken, other.endToken);
  }

  @override
  bool visitConditionalExpression(ConditionalExpression node) {
    ConditionalExpression other = _other as ConditionalExpression;
    return isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.question, other.question) &&
        isEqualNodes(node.thenExpression, other.thenExpression) &&
        isEqualTokens(node.colon, other.colon) &&
        isEqualNodes(node.elseExpression, other.elseExpression);
  }

  @override
  bool visitConfiguration(Configuration node) {
    Configuration other = _other as Configuration;
    return isEqualTokens(node.ifKeyword, other.ifKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.name, other.name) &&
        isEqualTokens(node.equalToken, other.equalToken) &&
        isEqualNodes(node.value, other.value) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.uri, other.uri);
  }

  @override
  bool visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorDeclaration other = _other as ConstructorDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.externalKeyword, other.externalKeyword) &&
        isEqualTokens(node.constKeyword, other.constKeyword) &&
        isEqualTokens(node.factoryKeyword, other.factoryKeyword) &&
        isEqualNodes(node.returnType, other.returnType) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.parameters, other.parameters) &&
        isEqualTokens(node.separator, other.separator) &&
        _isEqualNodeLists(node.initializers, other.initializers) &&
        isEqualNodes(node.redirectedConstructor, other.redirectedConstructor) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    ConstructorFieldInitializer other = _other as ConstructorFieldInitializer;
    return isEqualTokens(node.thisKeyword, other.thisKeyword) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.fieldName, other.fieldName) &&
        isEqualTokens(node.equals, other.equals) &&
        isEqualNodes(node.expression, other.expression);
  }

  @override
  bool visitConstructorName(ConstructorName node) {
    ConstructorName other = _other as ConstructorName;
    return isEqualNodes(node.type, other.type) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.name, other.name);
  }

  @override
  bool visitContinueStatement(ContinueStatement node) {
    ContinueStatement other = _other as ContinueStatement;
    return isEqualTokens(node.continueKeyword, other.continueKeyword) &&
        isEqualNodes(node.label, other.label) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitDeclaredIdentifier(DeclaredIdentifier node) {
    DeclaredIdentifier other = _other as DeclaredIdentifier;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.type, other.type) &&
        isEqualNodes(node.identifier, other.identifier);
  }

  @override
  bool visitDefaultFormalParameter(covariant DefaultFormalParameterImpl node) {
    var other = _other as DefaultFormalParameterImpl;
    return isEqualNodes(node.parameter, other.parameter) &&
        node.kind == other.kind &&
        isEqualTokens(node.separator, other.separator) &&
        isEqualNodes(node.defaultValue, other.defaultValue);
  }

  @override
  bool visitDoStatement(DoStatement node) {
    DoStatement other = _other as DoStatement;
    return isEqualTokens(node.doKeyword, other.doKeyword) &&
        isEqualNodes(node.body, other.body) &&
        isEqualTokens(node.whileKeyword, other.whileKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitDottedName(DottedName node) {
    DottedName other = _other as DottedName;
    return _isEqualNodeLists(node.components, other.components);
  }

  @override
  bool visitDoubleLiteral(DoubleLiteral node) {
    DoubleLiteral other = _other as DoubleLiteral;
    return isEqualTokens(node.literal, other.literal) &&
        failIfNotEqual(node, node.value, other, other.value);
  }

  @override
  bool visitEmptyFunctionBody(EmptyFunctionBody node) {
    EmptyFunctionBody other = _other as EmptyFunctionBody;
    return isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitEmptyStatement(EmptyStatement node) {
    EmptyStatement other = _other as EmptyStatement;
    return isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    EnumConstantDeclaration other = _other as EnumConstantDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualNodes(node.name, other.name);
  }

  @override
  bool visitEnumDeclaration(EnumDeclaration node) {
    EnumDeclaration other = _other as EnumDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.enumKeyword, other.enumKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.constants, other.constants) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitExportDirective(ExportDirective node) {
    ExportDirective other = _other as ExportDirective;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.uri, other.uri) &&
        _isEqualNodeLists(node.combinators, other.combinators) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitExpressionFunctionBody(ExpressionFunctionBody node) {
    ExpressionFunctionBody other = _other as ExpressionFunctionBody;
    return isEqualTokens(node.functionDefinition, other.functionDefinition) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitExpressionStatement(ExpressionStatement node) {
    ExpressionStatement other = _other as ExpressionStatement;
    return isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitExtendsClause(ExtendsClause node) {
    ExtendsClause other = _other as ExtendsClause;
    return isEqualTokens(node.extendsKeyword, other.extendsKeyword) &&
        isEqualNodes(node.superclass, other.superclass);
  }

  @override
  bool visitExtensionDeclaration(ExtensionDeclaration node) {
    ExtensionDeclaration other = _other as ExtensionDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.extensionKeyword, other.extensionKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeParameters, other.typeParameters) &&
        isEqualTokens(node.onKeyword, other.onKeyword) &&
        isEqualNodes(node.extendedType, other.extendedType) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.members, other.members) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitExtensionOverride(ExtensionOverride node) {
    ExtensionOverride other = _other as ExtensionOverride;
    return isEqualNodes(node.extensionName, other.extensionName) &&
        isEqualNodes(node.typeArguments, other.typeArguments) &&
        isEqualNodes(node.argumentList, other.argumentList);
  }

  @override
  bool visitFieldDeclaration(FieldDeclaration node) {
    FieldDeclaration other = _other as FieldDeclaration;
    return isEqualTokens(node.abstractKeyword, other.abstractKeyword) &&
        isEqualTokens(node.covariantKeyword, other.covariantKeyword) &&
        isEqualNodes(node.documentationComment, other.documentationComment) &&
        isEqualTokens(node.externalKeyword, other.externalKeyword) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.staticKeyword, other.staticKeyword) &&
        isEqualNodes(node.fields, other.fields) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitFieldFormalParameter(FieldFormalParameter node) {
    FieldFormalParameter other = _other as FieldFormalParameter;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.type, other.type) &&
        isEqualTokens(node.thisKeyword, other.thisKeyword) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.identifier, other.identifier);
  }

  @override
  bool visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    ForEachPartsWithDeclaration other = _other as ForEachPartsWithDeclaration;
    return isEqualNodes(node.loopVariable, other.loopVariable) &&
        isEqualTokens(node.inKeyword, other.inKeyword) &&
        isEqualNodes(node.iterable, other.iterable);
  }

  @override
  bool visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    ForEachPartsWithIdentifier other = _other as ForEachPartsWithIdentifier;
    return isEqualNodes(node.identifier, other.identifier) &&
        isEqualTokens(node.inKeyword, other.inKeyword) &&
        isEqualNodes(node.iterable, other.iterable);
  }

  @override
  bool visitForElement(ForElement node) {
    ForElement other = _other as ForElement;
    return isEqualTokens(node.awaitKeyword, other.awaitKeyword) &&
        isEqualTokens(node.forKeyword, other.forKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.forLoopParts, other.forLoopParts) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitFormalParameterList(FormalParameterList node) {
    FormalParameterList other = _other as FormalParameterList;
    return isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        _isEqualNodeLists(node.parameters, other.parameters) &&
        isEqualTokens(node.leftDelimiter, other.leftDelimiter) &&
        isEqualTokens(node.rightDelimiter, other.rightDelimiter) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis);
  }

  @override
  bool visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    ForPartsWithDeclarations other = _other as ForPartsWithDeclarations;
    return isEqualNodes(node.variables, other.variables) &&
        isEqualTokens(node.leftSeparator, other.leftSeparator) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightSeparator, other.rightSeparator) &&
        _isEqualNodeLists(node.updaters, other.updaters);
  }

  @override
  bool visitForPartsWithExpression(ForPartsWithExpression node) {
    ForPartsWithExpression other = _other as ForPartsWithExpression;
    return isEqualNodes(node.initialization, other.initialization) &&
        isEqualTokens(node.leftSeparator, other.leftSeparator) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightSeparator, other.rightSeparator) &&
        _isEqualNodeLists(node.updaters, other.updaters);
  }

  @override
  bool visitForStatement(ForStatement node) {
    ForStatement other = _other as ForStatement;
    return isEqualTokens(node.forKeyword, other.forKeyword) &&
        isEqualTokens(node.awaitKeyword, other.awaitKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.forLoopParts, other.forLoopParts) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionDeclaration other = _other as FunctionDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.externalKeyword, other.externalKeyword) &&
        isEqualNodes(node.returnType, other.returnType) &&
        isEqualTokens(node.propertyKeyword, other.propertyKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.functionExpression, other.functionExpression);
  }

  @override
  bool visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    FunctionDeclarationStatement other = _other as FunctionDeclarationStatement;
    return isEqualNodes(node.functionDeclaration, other.functionDeclaration);
  }

  @override
  bool visitFunctionExpression(FunctionExpression node) {
    FunctionExpression other = _other as FunctionExpression;
    return isEqualNodes(node.parameters, other.parameters) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    FunctionExpressionInvocation other = _other as FunctionExpressionInvocation;
    return isEqualNodes(node.function, other.function) &&
        isEqualNodes(node.argumentList, other.argumentList);
  }

  @override
  bool visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAlias other = _other as FunctionTypeAlias;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.typedefKeyword, other.typedefKeyword) &&
        isEqualNodes(node.returnType, other.returnType) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeParameters, other.typeParameters) &&
        isEqualNodes(node.parameters, other.parameters) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    FunctionTypedFormalParameter other = _other as FunctionTypedFormalParameter;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualNodes(node.returnType, other.returnType) &&
        isEqualNodes(node.identifier, other.identifier) &&
        isEqualNodes(node.parameters, other.parameters);
  }

  @override
  bool visitGenericFunctionType(GenericFunctionType node) {
    GenericFunctionType other = _other as GenericFunctionType;
    return isEqualNodes(node.returnType, other.returnType) &&
        isEqualTokens(node.functionKeyword, other.functionKeyword) &&
        isEqualNodes(node.typeParameters, other.typeParameters) &&
        isEqualNodes(node.parameters, other.parameters) &&
        isEqualTokens(node.question, other.question);
  }

  @override
  bool visitGenericTypeAlias(GenericTypeAlias node) {
    GenericTypeAlias other = _other as GenericTypeAlias;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.typedefKeyword, other.typedefKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeParameters, other.typeParameters) &&
        isEqualTokens(node.equals, other.equals) &&
        isEqualNodes(node.type, other.type);
  }

  @override
  bool visitHideCombinator(HideCombinator node) {
    HideCombinator other = _other as HideCombinator;
    return isEqualTokens(node.keyword, other.keyword) &&
        _isEqualNodeLists(node.hiddenNames, other.hiddenNames);
  }

  @override
  bool visitIfElement(IfElement node) {
    IfElement other = _other as IfElement;
    return isEqualTokens(node.ifKeyword, other.ifKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.thenElement, other.thenElement) &&
        isEqualTokens(node.elseKeyword, other.elseKeyword) &&
        isEqualNodes(node.elseElement, other.elseElement);
  }

  @override
  bool visitIfStatement(IfStatement node) {
    IfStatement other = _other as IfStatement;
    return isEqualTokens(node.ifKeyword, other.ifKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.thenStatement, other.thenStatement) &&
        isEqualTokens(node.elseKeyword, other.elseKeyword) &&
        isEqualNodes(node.elseStatement, other.elseStatement);
  }

  @override
  bool visitImplementsClause(ImplementsClause node) {
    ImplementsClause other = _other as ImplementsClause;
    return isEqualTokens(node.implementsKeyword, other.implementsKeyword) &&
        _isEqualNodeLists(node.interfaces, other.interfaces);
  }

  @override
  bool visitImportDirective(ImportDirective node) {
    ImportDirective other = _other as ImportDirective;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.uri, other.uri) &&
        _isEqualNodeLists(node.configurations, other.configurations) &&
        isEqualTokens(node.deferredKeyword, other.deferredKeyword) &&
        isEqualTokens(node.asKeyword, other.asKeyword) &&
        isEqualNodes(node.prefix, other.prefix) &&
        _isEqualNodeLists(node.combinators, other.combinators) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitIndexExpression(IndexExpression node) {
    IndexExpression other = _other as IndexExpression;
    return isEqualNodes(node.target, other.target) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        isEqualNodes(node.index, other.index) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitInstanceCreationExpression(InstanceCreationExpression node) {
    InstanceCreationExpression other = _other as InstanceCreationExpression;
    return isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.constructorName, other.constructorName) &&
        isEqualNodes(node.argumentList, other.argumentList);
  }

  @override
  bool visitIntegerLiteral(IntegerLiteral node) {
    IntegerLiteral other = _other as IntegerLiteral;
    return isEqualTokens(node.literal, other.literal) &&
        failIfNotEqual(node, node.value, other, other.value);
  }

  @override
  bool visitInterpolationExpression(InterpolationExpression node) {
    InterpolationExpression other = _other as InterpolationExpression;
    return isEqualTokens(node.leftBracket, other.leftBracket) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitInterpolationString(InterpolationString node) {
    InterpolationString other = _other as InterpolationString;
    return isEqualTokens(node.contents, other.contents) &&
        failIfNotEqual(node, node.value, other, other.value);
  }

  @override
  bool visitIsExpression(IsExpression node) {
    IsExpression other = _other as IsExpression;
    return isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.isOperator, other.isOperator) &&
        isEqualTokens(node.notOperator, other.notOperator) &&
        isEqualNodes(node.type, other.type);
  }

  @override
  bool visitLabel(Label node) {
    Label other = _other as Label;
    return isEqualNodes(node.label, other.label) &&
        isEqualTokens(node.colon, other.colon);
  }

  @override
  bool visitLabeledStatement(LabeledStatement node) {
    LabeledStatement other = _other as LabeledStatement;
    return _isEqualNodeLists(node.labels, other.labels) &&
        isEqualNodes(node.statement, other.statement);
  }

  @override
  bool visitLibraryDirective(LibraryDirective node) {
    LibraryDirective other = _other as LibraryDirective;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.libraryKeyword, other.libraryKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitLibraryIdentifier(LibraryIdentifier node) {
    LibraryIdentifier other = _other as LibraryIdentifier;
    return _isEqualNodeLists(node.components, other.components);
  }

  @override
  bool visitListLiteral(ListLiteral node) {
    ListLiteral other = _other as ListLiteral;
    return isEqualTokens(node.constKeyword, other.constKeyword) &&
        isEqualNodes(node.typeArguments, other.typeArguments) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.elements, other.elements) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitMapLiteralEntry(MapLiteralEntry node) {
    MapLiteralEntry other = _other as MapLiteralEntry;
    return isEqualNodes(node.key, other.key) &&
        isEqualTokens(node.separator, other.separator) &&
        isEqualNodes(node.value, other.value);
  }

  @override
  bool visitMethodDeclaration(MethodDeclaration node) {
    MethodDeclaration other = _other as MethodDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.externalKeyword, other.externalKeyword) &&
        isEqualTokens(node.modifierKeyword, other.modifierKeyword) &&
        isEqualNodes(node.returnType, other.returnType) &&
        isEqualTokens(node.propertyKeyword, other.propertyKeyword) &&
        isEqualTokens(node.operatorKeyword, other.operatorKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.parameters, other.parameters) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitMethodInvocation(MethodInvocation node) {
    MethodInvocation other = _other as MethodInvocation;
    return isEqualNodes(node.target, other.target) &&
        isEqualTokens(node.operator, other.operator) &&
        isEqualNodes(node.methodName, other.methodName) &&
        isEqualNodes(node.argumentList, other.argumentList);
  }

  @override
  bool visitMixinDeclaration(MixinDeclaration node) {
    MixinDeclaration other = _other as MixinDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.mixinKeyword, other.mixinKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeParameters, other.typeParameters) &&
        isEqualNodes(node.onClause, other.onClause) &&
        isEqualNodes(node.implementsClause, other.implementsClause) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.members, other.members) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitNamedExpression(NamedExpression node) {
    NamedExpression other = _other as NamedExpression;
    return isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.expression, other.expression);
  }

  @override
  bool visitNativeClause(NativeClause node) {
    NativeClause other = _other as NativeClause;
    return isEqualTokens(node.nativeKeyword, other.nativeKeyword) &&
        isEqualNodes(node.name, other.name);
  }

  @override
  bool visitNativeFunctionBody(NativeFunctionBody node) {
    NativeFunctionBody other = _other as NativeFunctionBody;
    return isEqualTokens(node.nativeKeyword, other.nativeKeyword) &&
        isEqualNodes(node.stringLiteral, other.stringLiteral) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitNullLiteral(NullLiteral node) {
    NullLiteral other = _other as NullLiteral;
    return isEqualTokens(node.literal, other.literal);
  }

  @override
  bool visitOnClause(OnClause node) {
    OnClause other = _other as OnClause;
    return isEqualTokens(node.onKeyword, other.onKeyword) &&
        _isEqualNodeLists(
            node.superclassConstraints, other.superclassConstraints);
  }

  @override
  bool visitParenthesizedExpression(ParenthesizedExpression node) {
    ParenthesizedExpression other = _other as ParenthesizedExpression;
    return isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis);
  }

  @override
  bool visitPartDirective(PartDirective node) {
    PartDirective other = _other as PartDirective;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.partKeyword, other.partKeyword) &&
        isEqualNodes(node.uri, other.uri) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitPartOfDirective(PartOfDirective node) {
    PartOfDirective other = _other as PartOfDirective;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.partKeyword, other.partKeyword) &&
        isEqualTokens(node.ofKeyword, other.ofKeyword) &&
        isEqualNodes(node.libraryName, other.libraryName) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitPostfixExpression(PostfixExpression node) {
    PostfixExpression other = _other as PostfixExpression;
    return isEqualNodes(node.operand, other.operand) &&
        isEqualTokens(node.operator, other.operator);
  }

  @override
  bool visitPrefixedIdentifier(PrefixedIdentifier node) {
    PrefixedIdentifier other = _other as PrefixedIdentifier;
    return isEqualNodes(node.prefix, other.prefix) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.identifier, other.identifier);
  }

  @override
  bool visitPrefixExpression(PrefixExpression node) {
    PrefixExpression other = _other as PrefixExpression;
    return isEqualTokens(node.operator, other.operator) &&
        isEqualNodes(node.operand, other.operand);
  }

  @override
  bool visitPropertyAccess(PropertyAccess node) {
    PropertyAccess other = _other as PropertyAccess;
    return isEqualNodes(node.target, other.target) &&
        isEqualTokens(node.operator, other.operator) &&
        isEqualNodes(node.propertyName, other.propertyName);
  }

  @override
  bool visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    RedirectingConstructorInvocation other =
        _other as RedirectingConstructorInvocation;
    return isEqualTokens(node.thisKeyword, other.thisKeyword) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.constructorName, other.constructorName) &&
        isEqualNodes(node.argumentList, other.argumentList);
  }

  @override
  bool visitRethrowExpression(RethrowExpression node) {
    RethrowExpression other = _other as RethrowExpression;
    return isEqualTokens(node.rethrowKeyword, other.rethrowKeyword);
  }

  @override
  bool visitReturnStatement(ReturnStatement node) {
    ReturnStatement other = _other as ReturnStatement;
    return isEqualTokens(node.returnKeyword, other.returnKeyword) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitScriptTag(ScriptTag node) {
    ScriptTag other = _other as ScriptTag;
    return isEqualTokens(node.scriptTag, other.scriptTag);
  }

  @override
  bool visitSetOrMapLiteral(SetOrMapLiteral node) {
    SetOrMapLiteral other = _other as SetOrMapLiteral;
    return isEqualTokens(node.constKeyword, other.constKeyword) &&
        isEqualNodes(node.typeArguments, other.typeArguments) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.elements, other.elements) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitShowCombinator(ShowCombinator node) {
    ShowCombinator other = _other as ShowCombinator;
    return isEqualTokens(node.keyword, other.keyword) &&
        _isEqualNodeLists(node.shownNames, other.shownNames);
  }

  @override
  bool visitSimpleFormalParameter(SimpleFormalParameter node) {
    SimpleFormalParameter other = _other as SimpleFormalParameter;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.type, other.type) &&
        isEqualNodes(node.identifier, other.identifier);
  }

  @override
  bool visitSimpleIdentifier(SimpleIdentifier node) {
    SimpleIdentifier other = _other as SimpleIdentifier;
    return isEqualTokens(node.token, other.token);
  }

  @override
  bool visitSimpleStringLiteral(SimpleStringLiteral node) {
    SimpleStringLiteral other = _other as SimpleStringLiteral;
    return isEqualTokens(node.literal, other.literal) &&
        failIfNotEqual(node, node.value, other, other.value);
  }

  @override
  bool visitSpreadElement(SpreadElement node) {
    SpreadElement other = _other as SpreadElement;
    return isEqualTokens(node.spreadOperator, other.spreadOperator) &&
        isEqualNodes(node.expression, other.expression);
  }

  @override
  bool visitStringInterpolation(StringInterpolation node) {
    StringInterpolation other = _other as StringInterpolation;
    return _isEqualNodeLists(node.elements, other.elements);
  }

  @override
  bool visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    SuperConstructorInvocation other = _other as SuperConstructorInvocation;
    return isEqualTokens(node.superKeyword, other.superKeyword) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.constructorName, other.constructorName) &&
        isEqualNodes(node.argumentList, other.argumentList);
  }

  @override
  bool visitSuperExpression(SuperExpression node) {
    SuperExpression other = _other as SuperExpression;
    return isEqualTokens(node.superKeyword, other.superKeyword);
  }

  @override
  bool visitSwitchCase(SwitchCase node) {
    SwitchCase other = _other as SwitchCase;
    return _isEqualNodeLists(node.labels, other.labels) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.colon, other.colon) &&
        _isEqualNodeLists(node.statements, other.statements);
  }

  @override
  bool visitSwitchDefault(SwitchDefault node) {
    SwitchDefault other = _other as SwitchDefault;
    return _isEqualNodeLists(node.labels, other.labels) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualTokens(node.colon, other.colon) &&
        _isEqualNodeLists(node.statements, other.statements);
  }

  @override
  bool visitSwitchStatement(SwitchStatement node) {
    SwitchStatement other = _other as SwitchStatement;
    return isEqualTokens(node.switchKeyword, other.switchKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.members, other.members) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitSymbolLiteral(SymbolLiteral node) {
    SymbolLiteral other = _other as SymbolLiteral;
    return isEqualTokens(node.poundSign, other.poundSign) &&
        _isEqualTokenLists(node.components, other.components);
  }

  @override
  bool visitThisExpression(ThisExpression node) {
    ThisExpression other = _other as ThisExpression;
    return isEqualTokens(node.thisKeyword, other.thisKeyword);
  }

  @override
  bool visitThrowExpression(ThrowExpression node) {
    ThrowExpression other = _other as ThrowExpression;
    return isEqualTokens(node.throwKeyword, other.throwKeyword) &&
        isEqualNodes(node.expression, other.expression);
  }

  @override
  bool visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    TopLevelVariableDeclaration other = _other as TopLevelVariableDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.externalKeyword, other.externalKeyword) &&
        isEqualNodes(node.variables, other.variables) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitTryStatement(TryStatement node) {
    TryStatement other = _other as TryStatement;
    return isEqualTokens(node.tryKeyword, other.tryKeyword) &&
        isEqualNodes(node.body, other.body) &&
        _isEqualNodeLists(node.catchClauses, other.catchClauses) &&
        isEqualTokens(node.finallyKeyword, other.finallyKeyword) &&
        isEqualNodes(node.finallyBlock, other.finallyBlock);
  }

  @override
  bool visitTypeArgumentList(TypeArgumentList node) {
    TypeArgumentList other = _other as TypeArgumentList;
    return isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.arguments, other.arguments) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitTypeName(TypeName node) {
    TypeName other = _other as TypeName;
    return isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeArguments, other.typeArguments) &&
        isEqualTokens(node.question, other.question);
  }

  @override
  bool visitTypeParameter(TypeParameter node) {
    TypeParameter other = _other as TypeParameter;
    // TODO (kallentu) : Clean up TypeParameterImpl casting once variance is
    // added to the interface.
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualNodes(node.name, other.name) &&
        isEqualTokens((node as TypeParameterImpl).varianceKeyword,
            (other as TypeParameterImpl).varianceKeyword) &&
        isEqualTokens(node.extendsKeyword, other.extendsKeyword) &&
        isEqualNodes(node.bound, other.bound);
  }

  @override
  bool visitTypeParameterList(TypeParameterList node) {
    TypeParameterList other = _other as TypeParameterList;
    return isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.typeParameters, other.typeParameters) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitVariableDeclaration(VariableDeclaration node) {
    VariableDeclaration other = _other as VariableDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualNodes(node.name, other.name) &&
        isEqualTokens(node.equals, other.equals) &&
        isEqualNodes(node.initializer, other.initializer);
  }

  @override
  bool visitVariableDeclarationList(VariableDeclarationList node) {
    VariableDeclarationList other = _other as VariableDeclarationList;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.type, other.type) &&
        _isEqualNodeLists(node.variables, other.variables);
  }

  @override
  bool visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    VariableDeclarationStatement other = _other as VariableDeclarationStatement;
    return isEqualNodes(node.variables, other.variables) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitWhileStatement(WhileStatement node) {
    WhileStatement other = _other as WhileStatement;
    return isEqualTokens(node.whileKeyword, other.whileKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitWithClause(WithClause node) {
    WithClause other = _other as WithClause;
    return isEqualTokens(node.withKeyword, other.withKeyword) &&
        _isEqualNodeLists(node.mixinTypes, other.mixinTypes);
  }

  @override
  bool visitYieldStatement(YieldStatement node) {
    YieldStatement other = _other as YieldStatement;
    return isEqualTokens(node.yieldKeyword, other.yieldKeyword) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  /// Return `true` if the [first] and [second] lists of AST nodes have the same
  /// size and corresponding elements are equal.
  bool _isEqualNodeLists(NodeList first, NodeList second) {
    if (first == null) {
      return failIfNotNull(first, second);
    } else if (second == null) {
      return failIsNull(first, second);
    }
    int size = first.length;
    if (second.length != size) {
      return failDifferentLength(first, second);
    }
    for (int i = 0; i < size; i++) {
      if (!isEqualNodes(first[i], second[i])) {
        return false;
      }
    }
    return true;
  }

  /// Return `true` if the [first] and [second] lists of tokens have the same
  /// length and corresponding elements are equal.
  bool _isEqualTokenLists(List<Token> first, List<Token> second) {
    int length = first.length;
    if (second.length != length) {
      return failDifferentLength(first, second);
    }
    for (int i = 0; i < length; i++) {
      if (!isEqualTokens(first[i], second[i])) {
        return false;
      }
    }
    return true;
  }

  /// Return `true` if the [first] and [second] nodes are equal.
  static bool equalNodes(AstNode first, AstNode second) {
    AstComparator comparator = AstComparator();
    return comparator.isEqualNodes(first, second);
  }
}

/// A recursive AST visitor that is used to run over [Expression]s to determine
/// whether the expression is composed by at least one deferred
/// [PrefixedIdentifier].
///
/// See [PrefixedIdentifier.isDeferred].
class DeferredLibraryReferenceDetector extends RecursiveAstVisitor<void> {
  /// A flag indicating whether an identifier from a deferred library has been
  /// found.
  bool _result = false;

  /// Return `true` if the visitor found a [PrefixedIdentifier] that returned
  /// `true` to the [PrefixedIdentifier.isDeferred] query.
  bool get result => _result;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (!_result) {
      if (node.isDeferred) {
        _result = true;
      }
    }
  }
}

/// A [DelegatingAstVisitor] that will additionally catch all exceptions from
/// the delegates without stopping the visiting. A function must be provided
/// that will be invoked for each such exception.
///
/// Clients may not extend, implement or mix-in this class.
class ExceptionHandlingDelegatingAstVisitor<T> extends DelegatingAstVisitor<T> {
  /// The function that will be executed for each exception that is thrown by
  /// one of the visit methods on the delegate.
  final ExceptionInDelegateHandler handler;

  /// Initialize a newly created visitor to use each of the given delegate
  /// visitors to visit the nodes of an AST structure.
  ExceptionHandlingDelegatingAstVisitor(
      Iterable<AstVisitor<T>> delegates, this.handler)
      : super(delegates) {
    if (handler == null) {
      throw ArgumentError('A handler must be provided');
    }
  }

  @override
  T visitNode(AstNode node) {
    delegates.forEach((delegate) {
      try {
        node.accept(delegate);
      } catch (exception, stackTrace) {
        handler(node, delegate, exception, stackTrace);
      }
    });
    node.visitChildren(this);
    return null;
  }

  /// A function that can be used with instances of this class to log and then
  /// ignore any exceptions that are thrown by any of the delegates.
  static void logException(
      AstNode node, Object visitor, dynamic exception, StackTrace stackTrace) {
    StringBuffer buffer = StringBuffer();
    buffer.write('Exception while using a ${visitor.runtimeType} to visit a ');
    AstNode currentNode = node;
    bool first = true;
    while (currentNode != null) {
      if (first) {
        first = false;
      } else {
        buffer.write(' in ');
      }
      buffer.write(currentNode.runtimeType);
      currentNode = currentNode.parent;
    }
    // TODO(39284): should this exception be silent?
    AnalysisEngine.instance.instrumentationService.logException(
        SilentException(buffer.toString(), exception, stackTrace));
  }
}

/// An object used to locate the [AstNode] associated with a source range, given
/// the AST structure built from the source. More specifically, they will return
/// the [AstNode] with the shortest length whose source range completely
/// encompasses the specified range.
class NodeLocator extends UnifyingAstVisitor<void> {
  /// The start offset of the range used to identify the node.
  final int _startOffset;

  /// The end offset of the range used to identify the node.
  final int _endOffset;

  /// The element that was found that corresponds to the given source range, or
  /// `null` if there is no such element.
  AstNode _foundNode;

  /// Initialize a newly created locator to locate an [AstNode] by locating the
  /// node within an AST structure that corresponds to the given range of
  /// characters (between the [startOffset] and [endOffset] in the source.
  NodeLocator(int startOffset, [int endOffset])
      : _startOffset = startOffset,
        _endOffset = endOffset ?? startOffset;

  /// Return the node that was found that corresponds to the given source range
  /// or `null` if there is no such node.
  AstNode get foundNode => _foundNode;

  /// Search within the given AST [node] for an identifier representing an
  /// element in the specified source range. Return the element that was found,
  /// or `null` if no element was found.
  AstNode searchWithin(AstNode node) {
    if (node == null) {
      return null;
    }
    try {
      node.accept(this);
    } catch (exception, stackTrace) {
      // TODO(39284): should this exception be silent?
      AnalysisEngine.instance.instrumentationService.logException(
          SilentException(
              "Unable to locate element at offset ($_startOffset - $_endOffset)",
              exception,
              stackTrace));
      return null;
    }
    return _foundNode;
  }

  @override
  void visitNode(AstNode node) {
    // Don't visit a new tree if the result has been already found.
    if (_foundNode != null) {
      return;
    }
    // Check whether the current node covers the selection.
    Token beginToken = node.beginToken;
    Token endToken = node.endToken;
    // Don't include synthetic tokens.
    while (endToken != beginToken) {
      // Fasta scanner reports unterminated string literal errors
      // and generates a synthetic string token with non-zero length.
      // Because of this, check for length > 0 rather than !isSynthetic.
      if (endToken.type == TokenType.EOF || endToken.length > 0) {
        break;
      }
      endToken = endToken.previous;
    }
    int end = endToken.end;
    int start = node.offset;
    if (end < _startOffset || start > _endOffset) {
      return;
    }
    // Check children.
    try {
      node.visitChildren(this);
    } catch (exception, stackTrace) {
      // Ignore the exception and proceed in order to visit the rest of the
      // structure.
      // TODO(39284): should this exception be silent?
      AnalysisEngine.instance.instrumentationService.logException(
          SilentException("Exception caught while traversing an AST structure.",
              exception, stackTrace));
    }
    // Found a child.
    if (_foundNode != null) {
      return;
    }
    // Check this node.
    if (start <= _startOffset && _endOffset <= end) {
      _foundNode = node;
    }
  }
}

/// An object used to locate the [AstNode] associated with a source range.
/// More specifically, they will return the deepest [AstNode] which completely
/// encompasses the specified range.
class NodeLocator2 extends UnifyingAstVisitor<void> {
  /// The inclusive start offset of the range used to identify the node.
  final int _startOffset;

  /// The inclusive end offset of the range used to identify the node.
  final int _endOffset;

  /// The found node or `null` if there is no such node.
  AstNode _foundNode;

  /// Initialize a newly created locator to locate the deepest [AstNode] for
  /// which `node.offset <= [startOffset]` and `[endOffset] < node.end`.
  ///
  /// If [endOffset] is not provided, then it is considered the same as the
  /// given [startOffset].
  NodeLocator2(int startOffset, [int endOffset])
      : _startOffset = startOffset,
        _endOffset = endOffset ?? startOffset;

  /// Search within the given AST [node] and return the node that was found,
  /// or `null` if no node was found.
  AstNode searchWithin(AstNode node) {
    if (node == null) {
      return null;
    }
    try {
      node.accept(this);
    } catch (exception, stackTrace) {
      // TODO(39284): should this exception be silent?
      AnalysisEngine.instance.instrumentationService
          .logException(SilentException(
              'Unable to locate element at offset '
              '($_startOffset - $_endOffset)',
              exception,
              stackTrace));
      return null;
    }
    return _foundNode;
  }

  @override
  void visitNode(AstNode node) {
    // Don't visit a new tree if the result has been already found.
    if (_foundNode != null) {
      return;
    }
    // Check whether the current node covers the selection.
    Token beginToken = node.beginToken;
    Token endToken = node.endToken;
    // Don't include synthetic tokens.
    while (endToken != beginToken) {
      // Fasta scanner reports unterminated string literal errors
      // and generates a synthetic string token with non-zero length.
      // Because of this, check for length > 0 rather than !isSynthetic.
      if (endToken.type == TokenType.EOF || endToken.length > 0) {
        break;
      }
      endToken = endToken.previous;
    }
    int end = endToken.end;
    int start = node.offset;
    if (end <= _startOffset || start > _endOffset) {
      return;
    }
    // Check children.
    try {
      node.visitChildren(this);
    } catch (exception, stackTrace) {
      // Ignore the exception and proceed in order to visit the rest of the
      // structure.
      // TODO(39284): should this exception be silent?
      AnalysisEngine.instance.instrumentationService.logException(
          SilentException("Exception caught while traversing an AST structure.",
              exception, stackTrace));
    }
    // Found a child.
    if (_foundNode != null) {
      return;
    }
    // Check this node.
    if (start <= _startOffset && _endOffset < end) {
      _foundNode = node;
    }
  }
}

/// An object that will replace one child node in an AST node with another node.
class NodeReplacer implements AstVisitor<bool> {
  /// The node being replaced.
  final AstNode _oldNode;

  /// The node that is replacing the old node.
  final AstNode _newNode;

  /// Initialize a newly created node locator to replace the [_oldNode] with the
  /// [_newNode].
  NodeReplacer(this._oldNode, this._newNode);

  @override
  bool visitAdjacentStrings(AdjacentStrings node) {
    if (_replaceInList(node.strings)) {
      return true;
    }
    return visitNode(node);
  }

  bool visitAnnotatedNode(AnnotatedNode node) {
    if (identical(node.documentationComment, _oldNode)) {
      node.documentationComment = _newNode as Comment;
      return true;
    } else if (_replaceInList(node.metadata)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAnnotation(Annotation node) {
    if (identical(node.arguments, _oldNode)) {
      node.arguments = _newNode as ArgumentList;
      return true;
    } else if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as Identifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitArgumentList(ArgumentList node) {
    if (_replaceInList(node.arguments)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAsExpression(AsExpression node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    } else if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotation;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAssertInitializer(AssertInitializer node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    }
    if (identical(node.message, _oldNode)) {
      node.message = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAssertStatement(AssertStatement node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    }
    if (identical(node.message, _oldNode)) {
      node.message = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAssignmentExpression(AssignmentExpression node) {
    if (identical(node.leftHandSide, _oldNode)) {
      node.leftHandSide = _newNode as Expression;
      return true;
    } else if (identical(node.rightHandSide, _oldNode)) {
      node.rightHandSide = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAwaitExpression(AwaitExpression node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitBinaryExpression(BinaryExpression node) {
    if (identical(node.leftOperand, _oldNode)) {
      node.leftOperand = _newNode as Expression;
      return true;
    } else if (identical(node.rightOperand, _oldNode)) {
      node.rightOperand = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitBlock(Block node) {
    if (_replaceInList(node.statements)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitBlockFunctionBody(BlockFunctionBody node) {
    if (identical(node.block, _oldNode)) {
      node.block = _newNode as Block;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitBooleanLiteral(BooleanLiteral node) => visitNode(node);

  @override
  bool visitBreakStatement(BreakStatement node) {
    if (identical(node.label, _oldNode)) {
      node.label = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitCascadeExpression(CascadeExpression node) {
    if (identical(node.target, _oldNode)) {
      node.target = _newNode as Expression;
      return true;
    } else if (_replaceInList(node.cascadeSections)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitCatchClause(CatchClause node) {
    if (identical(node.exceptionType, _oldNode)) {
      node.exceptionType = _newNode as TypeAnnotation;
      return true;
    } else if (identical(node.exceptionParameter, _oldNode)) {
      node.exceptionParameter = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.stackTraceParameter, _oldNode)) {
      node.stackTraceParameter = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitClassDeclaration(ClassDeclaration node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterList;
      return true;
    } else if (identical(node.extendsClause, _oldNode)) {
      node.extendsClause = _newNode as ExtendsClause;
      return true;
    } else if (identical(node.withClause, _oldNode)) {
      node.withClause = _newNode as WithClause;
      return true;
    } else if (identical(node.implementsClause, _oldNode)) {
      node.implementsClause = _newNode as ImplementsClause;
      return true;
    } else if (identical(node.nativeClause, _oldNode)) {
      node.nativeClause = _newNode as NativeClause;
      return true;
    } else if (_replaceInList(node.members)) {
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitClassTypeAlias(ClassTypeAlias node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterList;
      return true;
    } else if (identical(node.superclass, _oldNode)) {
      node.superclass = _newNode as TypeName;
      return true;
    } else if (identical(node.withClause, _oldNode)) {
      node.withClause = _newNode as WithClause;
      return true;
    } else if (identical(node.implementsClause, _oldNode)) {
      node.implementsClause = _newNode as ImplementsClause;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitComment(Comment node) {
    if (_replaceInList(node.references)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitCommentReference(CommentReference node) {
    if (identical(node.identifier, _oldNode)) {
      node.identifier = _newNode as Identifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitCompilationUnit(CompilationUnit node) {
    if (identical(node.scriptTag, _oldNode)) {
      node.scriptTag = _newNode as ScriptTag;
      return true;
    } else if (_replaceInList(node.directives)) {
      return true;
    } else if (_replaceInList(node.declarations)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConditionalExpression(ConditionalExpression node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    } else if (identical(node.thenExpression, _oldNode)) {
      node.thenExpression = _newNode as Expression;
      return true;
    } else if (identical(node.elseExpression, _oldNode)) {
      node.elseExpression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConfiguration(Configuration node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as DottedName;
      return true;
    } else if (identical(node.value, _oldNode)) {
      node.value = _newNode as StringLiteral;
      return true;
    } else if (identical(node.uri, _oldNode)) {
      node.uri = _newNode as StringLiteral;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConstructorDeclaration(ConstructorDeclaration node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as Identifier;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    } else if (identical(node.redirectedConstructor, _oldNode)) {
      node.redirectedConstructor = _newNode as ConstructorName;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as FunctionBody;
      return true;
    } else if (_replaceInList(node.initializers)) {
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    if (identical(node.fieldName, _oldNode)) {
      node.fieldName = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConstructorName(ConstructorName node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeName;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitContinueStatement(ContinueStatement node) {
    if (identical(node.label, _oldNode)) {
      node.label = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitDeclaredIdentifier(DeclaredIdentifier node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotation;
      return true;
    } else if (identical(node.identifier, _oldNode)) {
      node.identifier = _newNode as SimpleIdentifier;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitDefaultFormalParameter(DefaultFormalParameter node) {
    if (identical(node.parameter, _oldNode)) {
      node.parameter = _newNode as NormalFormalParameter;
      return true;
    } else if (identical(node.defaultValue, _oldNode)) {
      node.defaultValue = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitDoStatement(DoStatement node) {
    if (identical(node.body, _oldNode)) {
      node.body = _newNode as Statement;
      return true;
    } else if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitDottedName(DottedName node) {
    if (_replaceInList(node.components)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitDoubleLiteral(DoubleLiteral node) => visitNode(node);

  @override
  bool visitEmptyFunctionBody(EmptyFunctionBody node) => visitNode(node);

  @override
  bool visitEmptyStatement(EmptyStatement node) => visitNode(node);

  @override
  bool visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitEnumDeclaration(EnumDeclaration node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (_replaceInList(node.constants)) {
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitExportDirective(ExportDirective node) =>
      visitNamespaceDirective(node);

  @override
  bool visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitExpressionStatement(ExpressionStatement node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitExtendsClause(ExtendsClause node) {
    if (identical(node.superclass, _oldNode)) {
      node.superclass = _newNode as TypeName;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitExtensionDeclaration(ExtensionDeclaration node) {
    if (identical(node.documentationComment, _oldNode)) {
      node.documentationComment = _newNode as Comment;
      return true;
    } else if (_replaceInList(node.metadata)) {
      return true;
    } else if (identical(node.name, _oldNode)) {
      (node as ExtensionDeclarationImpl).name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      (node as ExtensionDeclarationImpl).typeParameters =
          _newNode as TypeParameterList;
      return true;
    } else if (identical(node.extendedType, _oldNode)) {
      (node as ExtensionDeclarationImpl).extendedType =
          _newNode as TypeAnnotation;
      return true;
    } else if (_replaceInList(node.members)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitExtensionOverride(ExtensionOverride node) {
    if (identical(node.extensionName, _oldNode)) {
      (node as ExtensionOverrideImpl).extensionName = _newNode as Identifier;
      return true;
    } else if (identical(node.typeArguments, _oldNode)) {
      (node as ExtensionOverrideImpl).typeArguments =
          _newNode as TypeArgumentList;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      (node as ExtensionOverrideImpl).argumentList = _newNode as ArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFieldDeclaration(FieldDeclaration node) {
    if (identical(node.fields, _oldNode)) {
      node.fields = _newNode as VariableDeclarationList;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitFieldFormalParameter(FieldFormalParameter node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotation;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    }
    return visitNormalFormalParameter(node);
  }

  @override
  bool visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    if (identical(node.loopVariable, _oldNode)) {
      (node as ForEachPartsWithDeclarationImpl).loopVariable =
          _newNode as DeclaredIdentifier;
      return true;
    } else if (identical(node.iterable, _oldNode)) {
      (node as ForEachPartsWithDeclarationImpl).iterable =
          _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    if (identical(node.identifier, _oldNode)) {
      (node as ForEachPartsWithIdentifierImpl).identifier =
          _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.iterable, _oldNode)) {
      (node as ForEachPartsWithIdentifierImpl).iterable =
          _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitForElement(ForElement node) {
    if (identical(node.forLoopParts, _oldNode)) {
      (node as ForElementImpl).forLoopParts = _newNode as ForLoopParts;
      return true;
    } else if (identical(node.body, _oldNode)) {
      (node as ForElementImpl).body = _newNode as CollectionElement;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFormalParameterList(FormalParameterList node) {
    if (_replaceInList(node.parameters)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    if (identical(node.variables, _oldNode)) {
      (node as ForPartsWithDeclarationsImpl).variables =
          _newNode as VariableDeclarationList;
      return true;
    } else if (identical(node.condition, _oldNode)) {
      (node as ForPartsWithDeclarationsImpl).condition = _newNode as Expression;
      return true;
    } else if (_replaceInList(node.updaters)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitForPartsWithExpression(ForPartsWithExpression node) {
    if (identical(node.initialization, _oldNode)) {
      (node as ForPartsWithExpressionImpl).initialization =
          _newNode as Expression;
      return true;
    } else if (identical(node.condition, _oldNode)) {
      (node as ForPartsWithExpressionImpl).condition = _newNode as Expression;
      return true;
    } else if (_replaceInList(node.updaters)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitForStatement(ForStatement node) {
    if (identical(node.forLoopParts, _oldNode)) {
      (node as ForStatementImpl).forLoopParts = _newNode as ForLoopParts;
      return true;
    } else if (identical(node.body, _oldNode)) {
      (node as ForStatementImpl).body = _newNode as Statement;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionDeclaration(FunctionDeclaration node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeAnnotation;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.functionExpression, _oldNode)) {
      node.functionExpression = _newNode as FunctionExpression;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    if (identical(node.functionDeclaration, _oldNode)) {
      node.functionDeclaration = _newNode as FunctionDeclaration;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionExpression(FunctionExpression node) {
    if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as FunctionBody;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (identical(node.function, _oldNode)) {
      node.function = _newNode as Expression;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeAnnotation;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterList;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeAnnotation;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    }
    return visitNormalFormalParameter(node);
  }

  @override
  bool visitGenericFunctionType(GenericFunctionType node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeAnnotation;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterList;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    }
    return null;
  }

  @override
  bool visitGenericTypeAlias(GenericTypeAlias node) {
    var nodeImpl = node as GenericTypeAliasImpl;
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      nodeImpl.typeParameters = _newNode as TypeParameterList;
      return true;
    } else if (identical(node.type, _oldNode)) {
      nodeImpl.type = _newNode as TypeAnnotation;
      return true;
    } else if (_replaceInList(node.metadata)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitHideCombinator(HideCombinator node) {
    if (_replaceInList(node.hiddenNames)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitIfElement(IfElement node) {
    if (identical(node.condition, _oldNode)) {
      (node as IfElementImpl).condition = _newNode as Expression;
      return true;
    } else if (identical(node.thenElement, _oldNode)) {
      (node as IfElementImpl).thenElement = _newNode as CollectionElement;
      return true;
    } else if (identical(node.elseElement, _oldNode)) {
      (node as IfElementImpl).elseElement = _newNode as CollectionElement;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitIfStatement(IfStatement node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    } else if (identical(node.thenStatement, _oldNode)) {
      node.thenStatement = _newNode as Statement;
      return true;
    } else if (identical(node.elseStatement, _oldNode)) {
      node.elseStatement = _newNode as Statement;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitImplementsClause(ImplementsClause node) {
    if (_replaceInList(node.interfaces)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitImportDirective(ImportDirective node) {
    if (identical(node.prefix, _oldNode)) {
      node.prefix = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNamespaceDirective(node);
  }

  @override
  bool visitIndexExpression(IndexExpression node) {
    if (identical(node.target, _oldNode)) {
      node.target = _newNode as Expression;
      return true;
    } else if (identical(node.index, _oldNode)) {
      node.index = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as ConstructorName;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitIntegerLiteral(IntegerLiteral node) => visitNode(node);

  @override
  bool visitInterpolationExpression(InterpolationExpression node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitInterpolationString(InterpolationString node) => visitNode(node);

  @override
  bool visitIsExpression(IsExpression node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    } else if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotation;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitLabel(Label node) {
    if (identical(node.label, _oldNode)) {
      node.label = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitLabeledStatement(LabeledStatement node) {
    if (identical(node.statement, _oldNode)) {
      node.statement = _newNode as Statement;
      return true;
    } else if (_replaceInList(node.labels)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitLibraryDirective(LibraryDirective node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as LibraryIdentifier;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitLibraryIdentifier(LibraryIdentifier node) {
    if (_replaceInList(node.components)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitListLiteral(ListLiteral node) {
    if (_replaceInList(node.elements)) {
      return true;
    }
    return visitTypedLiteral(node);
  }

  @override
  bool visitMapLiteralEntry(MapLiteralEntry node) {
    if (identical(node.key, _oldNode)) {
      node.key = _newNode as Expression;
      return true;
    } else if (identical(node.value, _oldNode)) {
      node.value = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitMethodDeclaration(MethodDeclaration node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeAnnotation;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as FunctionBody;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitMethodInvocation(MethodInvocation node) {
    if (identical(node.target, _oldNode)) {
      node.target = _newNode as Expression;
      return true;
    } else if (identical(node.methodName, _oldNode)) {
      node.methodName = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitMixinDeclaration(MixinDeclaration node) {
    if (identical(node.documentationComment, _oldNode)) {
      node.documentationComment = _newNode as Comment;
      return true;
    } else if (_replaceInList(node.metadata)) {
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      (node as MixinDeclarationImpl).typeParameters =
          _newNode as TypeParameterList;
      return true;
    } else if (identical(node.onClause, _oldNode)) {
      (node as MixinDeclarationImpl).onClause = _newNode as OnClause;
      return true;
    } else if (identical(node.implementsClause, _oldNode)) {
      (node as MixinDeclarationImpl).implementsClause =
          _newNode as ImplementsClause;
      return true;
    } else if (_replaceInList(node.members)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitNamedExpression(NamedExpression node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as Label;
      return true;
    } else if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  bool visitNamespaceDirective(NamespaceDirective node) {
    if (_replaceInList(node.combinators)) {
      return true;
    }
    return visitUriBasedDirective(node);
  }

  @override
  bool visitNativeClause(NativeClause node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as StringLiteral;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitNativeFunctionBody(NativeFunctionBody node) {
    if (identical(node.stringLiteral, _oldNode)) {
      node.stringLiteral = _newNode as StringLiteral;
      return true;
    }
    return visitNode(node);
  }

  bool visitNode(AstNode node) {
    throw ArgumentError("The old node is not a child of it's parent");
  }

  bool visitNormalFormalParameter(NormalFormalParameter node) {
    if (identical(node.documentationComment, _oldNode)) {
      node.documentationComment = _newNode as Comment;
      return true;
    } else if (identical(node.identifier, _oldNode)) {
      node.identifier = _newNode as SimpleIdentifier;
      return true;
    } else if (_replaceInList(node.metadata)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitNullLiteral(NullLiteral node) => visitNode(node);

  @override
  bool visitOnClause(OnClause node) {
    if (_replaceInList(node.superclassConstraints)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitParenthesizedExpression(ParenthesizedExpression node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPartDirective(PartDirective node) => visitUriBasedDirective(node);

  @override
  bool visitPartOfDirective(PartOfDirective node) {
    if (identical(node.libraryName, _oldNode)) {
      node.libraryName = _newNode as LibraryIdentifier;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitPostfixExpression(PostfixExpression node) {
    if (identical(node.operand, _oldNode)) {
      node.operand = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (identical(node.prefix, _oldNode)) {
      node.prefix = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.identifier, _oldNode)) {
      node.identifier = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPrefixExpression(PrefixExpression node) {
    if (identical(node.operand, _oldNode)) {
      node.operand = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPropertyAccess(PropertyAccess node) {
    if (identical(node.target, _oldNode)) {
      node.target = _newNode as Expression;
      return true;
    } else if (identical(node.propertyName, _oldNode)) {
      node.propertyName = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitRethrowExpression(RethrowExpression node) => visitNode(node);

  @override
  bool visitReturnStatement(ReturnStatement node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitScriptTag(ScriptTag scriptTag) => visitNode(scriptTag);

  @override
  bool visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (_replaceInList(node.elements)) {
      return true;
    }
    return visitTypedLiteral(node);
  }

  @override
  bool visitShowCombinator(ShowCombinator node) {
    if (_replaceInList(node.shownNames)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotation;
      return true;
    }
    return visitNormalFormalParameter(node);
  }

  @override
  bool visitSimpleIdentifier(SimpleIdentifier node) => visitNode(node);

  @override
  bool visitSimpleStringLiteral(SimpleStringLiteral node) => visitNode(node);

  @override
  bool visitSpreadElement(SpreadElement node) {
    if (identical(node.expression, _oldNode)) {
      (node as SpreadElementImpl).expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitStringInterpolation(StringInterpolation node) {
    if (_replaceInList(node.elements)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSuperExpression(SuperExpression node) => visitNode(node);

  @override
  bool visitSwitchCase(SwitchCase node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitSwitchMember(node);
  }

  @override
  bool visitSwitchDefault(SwitchDefault node) => visitSwitchMember(node);

  bool visitSwitchMember(SwitchMember node) {
    if (_replaceInList(node.labels)) {
      return true;
    } else if (_replaceInList(node.statements)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSwitchStatement(SwitchStatement node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    } else if (_replaceInList(node.members)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSymbolLiteral(SymbolLiteral node) => visitNode(node);

  @override
  bool visitThisExpression(ThisExpression node) => visitNode(node);

  @override
  bool visitThrowExpression(ThrowExpression node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (identical(node.variables, _oldNode)) {
      node.variables = _newNode as VariableDeclarationList;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitTryStatement(TryStatement node) {
    if (identical(node.body, _oldNode)) {
      node.body = _newNode as Block;
      return true;
    } else if (identical(node.finallyBlock, _oldNode)) {
      node.finallyBlock = _newNode as Block;
      return true;
    } else if (_replaceInList(node.catchClauses)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTypeArgumentList(TypeArgumentList node) {
    if (_replaceInList(node.arguments)) {
      return true;
    }
    return visitNode(node);
  }

  bool visitTypedLiteral(TypedLiteral node) {
    if (identical(node.typeArguments, _oldNode)) {
      node.typeArguments = _newNode as TypeArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTypeName(TypeName node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as Identifier;
      return true;
    } else if (identical(node.typeArguments, _oldNode)) {
      node.typeArguments = _newNode as TypeArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTypeParameter(TypeParameter node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.bound, _oldNode)) {
      node.bound = _newNode as TypeAnnotation;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTypeParameterList(TypeParameterList node) {
    if (_replaceInList(node.typeParameters)) {
      return true;
    }
    return visitNode(node);
  }

  bool visitUriBasedDirective(UriBasedDirective node) {
    if (identical(node.uri, _oldNode)) {
      node.uri = _newNode as StringLiteral;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitVariableDeclaration(VariableDeclaration node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.initializer, _oldNode)) {
      node.initializer = _newNode as Expression;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitVariableDeclarationList(VariableDeclarationList node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotation;
      return true;
    } else if (_replaceInList(node.variables)) {
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    if (identical(node.variables, _oldNode)) {
      node.variables = _newNode as VariableDeclarationList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitWhileStatement(WhileStatement node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as Statement;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitWithClause(WithClause node) {
    if (_replaceInList(node.mixinTypes)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitYieldStatement(YieldStatement node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  bool _replaceInList(NodeList list) {
    int count = list.length;
    for (int i = 0; i < count; i++) {
      if (identical(_oldNode, list[i])) {
        list[i] = _newNode;
        return true;
      }
    }
    return false;
  }

  /// Replace the [oldNode] with the [newNode] in the AST structure containing
  /// the old node. Return `true` if the replacement was successful.
  ///
  /// Throws an [ArgumentError] if either node is `null`, if the old node does
  /// not have a parent node, or if the AST structure has been corrupted.
  static bool replace(AstNode oldNode, AstNode newNode) {
    if (oldNode == null || newNode == null) {
      throw ArgumentError("The old and new nodes must be non-null");
    } else if (identical(oldNode, newNode)) {
      return true;
    }
    AstNode parent = oldNode.parent;
    if (parent == null) {
      throw ArgumentError("The old node is not a child of another node");
    }
    NodeReplacer replacer = NodeReplacer(oldNode, newNode);
    return parent.accept(replacer);
  }
}

/// An object that copies resolution information from one AST structure to
/// another as long as the structures of the corresponding children of a pair of
/// nodes are the same.
class ResolutionCopier implements AstVisitor<bool> {
  /// The AST node with which the node being visited is to be compared. This is
  /// only valid at the beginning of each visit method (until [isEqualNodes] is
  /// invoked).
  AstNode _toNode;

  @override
  bool visitAdjacentStrings(AdjacentStrings node) {
    AdjacentStrings toNode = _toNode as AdjacentStrings;
    if (_isEqualNodeLists(node.strings, toNode.strings)) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitAnnotation(Annotation node) {
    Annotation toNode = _toNode as Annotation;
    if (_and(
        _isEqualTokens(node.atSign, toNode.atSign),
        _isEqualNodes(node.name, toNode.name),
        _isEqualTokens(node.period, toNode.period),
        _isEqualNodes(node.constructorName, toNode.constructorName),
        _isEqualNodes(node.arguments, toNode.arguments))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  @override
  bool visitArgumentList(ArgumentList node) {
    ArgumentList toNode = _toNode as ArgumentList;
    return _and(
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodeLists(node.arguments, toNode.arguments),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis));
  }

  @override
  bool visitAsExpression(AsExpression node) {
    AsExpression toNode = _toNode as AsExpression;
    if (_and(
        _isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.asOperator, toNode.asOperator),
        _isEqualNodes(node.type, toNode.type))) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitAssertInitializer(AssertInitializer node) {
    AssertInitializer toNode = _toNode as AssertInitializer;
    return _and(
        _isEqualTokens(node.assertKeyword, toNode.assertKeyword),
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodes(node.condition, toNode.condition),
        _isEqualTokens(node.comma, toNode.comma),
        _isEqualNodes(node.message, toNode.message),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis));
  }

  @override
  bool visitAssertStatement(AssertStatement node) {
    AssertStatement toNode = _toNode as AssertStatement;
    return _and(
        _isEqualTokens(node.assertKeyword, toNode.assertKeyword),
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodes(node.condition, toNode.condition),
        _isEqualTokens(node.comma, toNode.comma),
        _isEqualNodes(node.message, toNode.message),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitAssignmentExpression(AssignmentExpression node) {
    AssignmentExpression toNode = _toNode as AssignmentExpression;
    if (_and(
        _isEqualNodes(node.leftHandSide, toNode.leftHandSide),
        _isEqualTokens(node.operator, toNode.operator),
        _isEqualNodes(node.rightHandSide, toNode.rightHandSide))) {
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitAwaitExpression(AwaitExpression node) {
    AwaitExpression toNode = _toNode as AwaitExpression;
    if (_and(_isEqualTokens(node.awaitKeyword, toNode.awaitKeyword),
        _isEqualNodes(node.expression, toNode.expression))) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitBinaryExpression(BinaryExpression node) {
    BinaryExpression toNode = _toNode as BinaryExpression;
    if (_and(
        _isEqualNodes(node.leftOperand, toNode.leftOperand),
        _isEqualTokens(node.operator, toNode.operator),
        _isEqualNodes(node.rightOperand, toNode.rightOperand))) {
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitBlock(Block node) {
    Block toNode = _toNode as Block;
    return _and(
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodeLists(node.statements, toNode.statements),
        _isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  @override
  bool visitBlockFunctionBody(BlockFunctionBody node) {
    BlockFunctionBody toNode = _toNode as BlockFunctionBody;
    return _isEqualNodes(node.block, toNode.block);
  }

  @override
  bool visitBooleanLiteral(BooleanLiteral node) {
    BooleanLiteral toNode = _toNode as BooleanLiteral;
    if (_and(_isEqualTokens(node.literal, toNode.literal),
        node.value == toNode.value)) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitBreakStatement(BreakStatement node) {
    BreakStatement toNode = _toNode as BreakStatement;
    if (_and(
        _isEqualTokens(node.breakKeyword, toNode.breakKeyword),
        _isEqualNodes(node.label, toNode.label),
        _isEqualTokens(node.semicolon, toNode.semicolon))) {
      // TODO(paulberry): map node.target to toNode.target.
      return true;
    }
    return false;
  }

  @override
  bool visitCascadeExpression(CascadeExpression node) {
    CascadeExpression toNode = _toNode as CascadeExpression;
    if (_and(_isEqualNodes(node.target, toNode.target),
        _isEqualNodeLists(node.cascadeSections, toNode.cascadeSections))) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitCatchClause(CatchClause node) {
    CatchClause toNode = _toNode as CatchClause;
    return _and(
        _isEqualTokens(node.onKeyword, toNode.onKeyword),
        _isEqualNodes(node.exceptionType, toNode.exceptionType),
        _isEqualTokens(node.catchKeyword, toNode.catchKeyword),
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodes(node.exceptionParameter, toNode.exceptionParameter),
        _isEqualTokens(node.comma, toNode.comma),
        _isEqualNodes(node.stackTraceParameter, toNode.stackTraceParameter),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis),
        _isEqualNodes(node.body, toNode.body));
  }

  @override
  bool visitClassDeclaration(ClassDeclaration node) {
    ClassDeclaration toNode = _toNode as ClassDeclaration;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.abstractKeyword, toNode.abstractKeyword),
        _isEqualTokens(node.classKeyword, toNode.classKeyword),
        _isEqualNodes(node.name, toNode.name),
        _isEqualNodes(node.typeParameters, toNode.typeParameters),
        _isEqualNodes(node.extendsClause, toNode.extendsClause),
        _isEqualNodes(node.withClause, toNode.withClause),
        _isEqualNodes(node.implementsClause, toNode.implementsClause),
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodeLists(node.members, toNode.members),
        _isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  @override
  bool visitClassTypeAlias(ClassTypeAlias node) {
    ClassTypeAlias toNode = _toNode as ClassTypeAlias;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.typedefKeyword, toNode.typedefKeyword),
        _isEqualNodes(node.name, toNode.name),
        _isEqualNodes(node.typeParameters, toNode.typeParameters),
        _isEqualTokens(node.equals, toNode.equals),
        _isEqualTokens(node.abstractKeyword, toNode.abstractKeyword),
        _isEqualNodes(node.superclass, toNode.superclass),
        _isEqualNodes(node.withClause, toNode.withClause),
        _isEqualNodes(node.implementsClause, toNode.implementsClause),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitComment(Comment node) {
    Comment toNode = _toNode as Comment;
    return _isEqualNodeLists(node.references, toNode.references);
  }

  @override
  bool visitCommentReference(CommentReference node) {
    CommentReference toNode = _toNode as CommentReference;
    return _and(_isEqualTokens(node.newKeyword, toNode.newKeyword),
        _isEqualNodes(node.identifier, toNode.identifier));
  }

  @override
  bool visitCompilationUnit(CompilationUnit node) {
    CompilationUnit toNode = _toNode as CompilationUnit;
    if (_and(
        _isEqualTokens(node.beginToken, toNode.beginToken),
        _isEqualNodes(node.scriptTag, toNode.scriptTag),
        _isEqualNodeLists(node.directives, toNode.directives),
        _isEqualNodeLists(node.declarations, toNode.declarations),
        _isEqualTokens(node.endToken, toNode.endToken))) {
      toNode.element = node.declaredElement;
      return true;
    }
    return false;
  }

  @override
  bool visitConditionalExpression(ConditionalExpression node) {
    ConditionalExpression toNode = _toNode as ConditionalExpression;
    if (_and(
        _isEqualNodes(node.condition, toNode.condition),
        _isEqualTokens(node.question, toNode.question),
        _isEqualNodes(node.thenExpression, toNode.thenExpression),
        _isEqualTokens(node.colon, toNode.colon),
        _isEqualNodes(node.elseExpression, toNode.elseExpression))) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitConfiguration(Configuration node) {
    Configuration toNode = _toNode as Configuration;
    if (_and(
        _isEqualTokens(node.ifKeyword, toNode.ifKeyword),
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodes(node.name, toNode.name),
        _isEqualTokens(node.equalToken, toNode.equalToken),
        _isEqualNodes(node.value, toNode.value),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis),
        _isEqualNodes(node.uri, toNode.uri))) {
      return true;
    }
    return false;
  }

  @override
  bool visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorDeclarationImpl toNode = _toNode as ConstructorDeclaration;
    if (_and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.externalKeyword, toNode.externalKeyword),
        _isEqualTokens(node.constKeyword, toNode.constKeyword),
        _isEqualTokens(node.factoryKeyword, toNode.factoryKeyword),
        _isEqualNodes(node.returnType, toNode.returnType),
        _isEqualTokens(node.period, toNode.period),
        _isEqualNodes(node.name, toNode.name),
        _isEqualNodes(node.parameters, toNode.parameters),
        _isEqualTokens(node.separator, toNode.separator),
        _isEqualNodeLists(node.initializers, toNode.initializers),
        _isEqualNodes(node.redirectedConstructor, toNode.redirectedConstructor),
        _isEqualNodes(node.body, toNode.body))) {
      toNode.declaredElement = node.declaredElement;
      return true;
    }
    return false;
  }

  @override
  bool visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    ConstructorFieldInitializer toNode = _toNode as ConstructorFieldInitializer;
    return _and(
        _isEqualTokens(node.thisKeyword, toNode.thisKeyword),
        _isEqualTokens(node.period, toNode.period),
        _isEqualNodes(node.fieldName, toNode.fieldName),
        _isEqualTokens(node.equals, toNode.equals),
        _isEqualNodes(node.expression, toNode.expression));
  }

  @override
  bool visitConstructorName(ConstructorName node) {
    ConstructorName toNode = _toNode as ConstructorName;
    if (_and(
        _isEqualNodes(node.type, toNode.type),
        _isEqualTokens(node.period, toNode.period),
        _isEqualNodes(node.name, toNode.name))) {
      toNode.staticElement = node.staticElement;
      return true;
    }
    return false;
  }

  @override
  bool visitContinueStatement(ContinueStatement node) {
    ContinueStatement toNode = _toNode as ContinueStatement;
    if (_and(
        _isEqualTokens(node.continueKeyword, toNode.continueKeyword),
        _isEqualNodes(node.label, toNode.label),
        _isEqualTokens(node.semicolon, toNode.semicolon))) {
      // TODO(paulberry): map node.target to toNode.target.
      return true;
    }
    return false;
  }

  @override
  bool visitDeclaredIdentifier(DeclaredIdentifier node) {
    DeclaredIdentifier toNode = _toNode as DeclaredIdentifier;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.keyword, toNode.keyword),
        _isEqualNodes(node.type, toNode.type),
        _isEqualNodes(node.identifier, toNode.identifier));
  }

  @override
  bool visitDefaultFormalParameter(covariant DefaultFormalParameterImpl node) {
    var toNode = _toNode as DefaultFormalParameterImpl;
    return _and(
        _isEqualNodes(node.parameter, toNode.parameter),
        node.kind == toNode.kind,
        _isEqualTokens(node.separator, toNode.separator),
        _isEqualNodes(node.defaultValue, toNode.defaultValue));
  }

  @override
  bool visitDoStatement(DoStatement node) {
    DoStatement toNode = _toNode as DoStatement;
    return _and(
        _isEqualTokens(node.doKeyword, toNode.doKeyword),
        _isEqualNodes(node.body, toNode.body),
        _isEqualTokens(node.whileKeyword, toNode.whileKeyword),
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodes(node.condition, toNode.condition),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitDottedName(DottedName node) {
    DottedName toNode = _toNode as DottedName;
    return _isEqualNodeLists(node.components, toNode.components);
  }

  @override
  bool visitDoubleLiteral(DoubleLiteral node) {
    DoubleLiteral toNode = _toNode as DoubleLiteral;
    if (_and(_isEqualTokens(node.literal, toNode.literal),
        node.value == toNode.value)) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitEmptyFunctionBody(EmptyFunctionBody node) {
    EmptyFunctionBody toNode = _toNode as EmptyFunctionBody;
    return _isEqualTokens(node.semicolon, toNode.semicolon);
  }

  @override
  bool visitEmptyStatement(EmptyStatement node) {
    EmptyStatement toNode = _toNode as EmptyStatement;
    return _isEqualTokens(node.semicolon, toNode.semicolon);
  }

  @override
  bool visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    EnumConstantDeclaration toNode = _toNode as EnumConstantDeclaration;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualNodes(node.name, toNode.name));
  }

  @override
  bool visitEnumDeclaration(EnumDeclaration node) {
    EnumDeclaration toNode = _toNode as EnumDeclaration;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.enumKeyword, toNode.enumKeyword),
        _isEqualNodes(node.name, toNode.name),
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodeLists(node.constants, toNode.constants),
        _isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  @override
  bool visitExportDirective(ExportDirective node) {
    ExportDirective toNode = _toNode as ExportDirective;
    if (_and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.keyword, toNode.keyword),
        _isEqualNodes(node.uri, toNode.uri),
        _isEqualNodeLists(node.combinators, toNode.combinators),
        _isEqualTokens(node.semicolon, toNode.semicolon))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  @override
  bool visitExpressionFunctionBody(ExpressionFunctionBody node) {
    ExpressionFunctionBody toNode = _toNode as ExpressionFunctionBody;
    return _and(
        _isEqualTokens(node.functionDefinition, toNode.functionDefinition),
        _isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitExpressionStatement(ExpressionStatement node) {
    ExpressionStatement toNode = _toNode as ExpressionStatement;
    return _and(_isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitExtendsClause(ExtendsClause node) {
    ExtendsClause toNode = _toNode as ExtendsClause;
    return _and(_isEqualTokens(node.extendsKeyword, toNode.extendsKeyword),
        _isEqualNodes(node.superclass, toNode.superclass));
  }

  @override
  bool visitExtensionDeclaration(ExtensionDeclaration node) {
    ExtensionDeclaration toNode = _toNode as ExtensionDeclaration;
    if (_and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.extensionKeyword, toNode.extensionKeyword),
        _isEqualNodes(node.name, toNode.name),
        _isEqualNodes(node.typeParameters, toNode.typeParameters),
        _isEqualTokens(node.onKeyword, toNode.onKeyword),
        _isEqualNodes(node.extendedType, toNode.extendedType),
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodeLists(node.members, toNode.members),
        _isEqualTokens(node.rightBracket, toNode.rightBracket))) {
      return true;
    }
    return false;
  }

  @override
  bool visitExtensionOverride(ExtensionOverride node) {
    ExtensionOverride toNode = _toNode as ExtensionOverride;
    return _and(
        _isEqualNodes(node.extensionName, toNode.extensionName),
        _isEqualNodes(node.typeArguments, toNode.typeArguments),
        _isEqualNodes(node.argumentList, toNode.argumentList));
  }

  @override
  bool visitFieldDeclaration(FieldDeclaration node) {
    FieldDeclaration toNode = _toNode as FieldDeclaration;
    return _and(
        _isEqualTokens(node.abstractKeyword, toNode.abstractKeyword),
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualTokens(node.externalKeyword, toNode.externalKeyword),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.staticKeyword, toNode.staticKeyword),
        _isEqualNodes(node.fields, toNode.fields),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitFieldFormalParameter(FieldFormalParameter node) {
    FieldFormalParameter toNode = _toNode as FieldFormalParameter;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.keyword, toNode.keyword),
        _isEqualNodes(node.type, toNode.type),
        _isEqualTokens(node.thisKeyword, toNode.thisKeyword),
        _isEqualTokens(node.period, toNode.period),
        _isEqualNodes(node.identifier, toNode.identifier));
  }

  @override
  bool visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    ForEachPartsWithDeclaration toNode = _toNode as ForEachPartsWithDeclaration;
    return _and(
        _isEqualNodes(node.loopVariable, toNode.loopVariable),
        _isEqualTokens(node.inKeyword, toNode.inKeyword),
        _isEqualNodes(node.iterable, toNode.iterable));
  }

  @override
  bool visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    ForEachPartsWithIdentifier toNode = _toNode as ForEachPartsWithIdentifier;
    return _and(
        _isEqualNodes(node.identifier, toNode.identifier),
        _isEqualTokens(node.inKeyword, toNode.inKeyword),
        _isEqualNodes(node.iterable, toNode.iterable));
  }

  @override
  bool visitForElement(ForElement node) {
    ForElement toNode = _toNode as ForElement;
    return _and(
        _isEqualTokens(node.awaitKeyword, toNode.awaitKeyword),
        _isEqualTokens(node.forKeyword, toNode.forKeyword),
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodes(node.forLoopParts, toNode.forLoopParts),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis),
        _isEqualNodes(node.body, toNode.body));
  }

  @override
  bool visitFormalParameterList(FormalParameterList node) {
    FormalParameterList toNode = _toNode as FormalParameterList;
    return _and(
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodeLists(node.parameters, toNode.parameters),
        _isEqualTokens(node.leftDelimiter, toNode.leftDelimiter),
        _isEqualTokens(node.rightDelimiter, toNode.rightDelimiter),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis));
  }

  @override
  bool visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    ForPartsWithDeclarations toNode = _toNode as ForPartsWithDeclarations;
    return _and(
        _isEqualNodes(node.variables, toNode.variables),
        _isEqualTokens(node.leftSeparator, toNode.leftSeparator),
        _isEqualNodes(node.condition, toNode.condition),
        _isEqualTokens(node.rightSeparator, toNode.rightSeparator),
        _isEqualNodeLists(node.updaters, toNode.updaters));
  }

  @override
  bool visitForPartsWithExpression(ForPartsWithExpression node) {
    ForPartsWithExpression toNode = _toNode as ForPartsWithExpression;
    return _and(
        _isEqualNodes(node.initialization, toNode.initialization),
        _isEqualTokens(node.leftSeparator, toNode.leftSeparator),
        _isEqualNodes(node.condition, toNode.condition),
        _isEqualTokens(node.rightSeparator, toNode.rightSeparator),
        _isEqualNodeLists(node.updaters, toNode.updaters));
  }

  @override
  bool visitForStatement(ForStatement node) {
    ForStatement toNode = _toNode as ForStatement;
    return _and(
        _isEqualTokens(node.awaitKeyword, toNode.awaitKeyword),
        _isEqualTokens(node.forKeyword, toNode.forKeyword),
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodes(node.forLoopParts, toNode.forLoopParts),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis),
        _isEqualNodes(node.body, toNode.body));
  }

  @override
  bool visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionDeclaration toNode = _toNode as FunctionDeclaration;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.externalKeyword, toNode.externalKeyword),
        _isEqualNodes(node.returnType, toNode.returnType),
        _isEqualTokens(node.propertyKeyword, toNode.propertyKeyword),
        _isEqualNodes(node.name, toNode.name),
        _isEqualNodes(node.functionExpression, toNode.functionExpression));
  }

  @override
  bool visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    FunctionDeclarationStatement toNode =
        _toNode as FunctionDeclarationStatement;
    return _isEqualNodes(node.functionDeclaration, toNode.functionDeclaration);
  }

  @override
  bool visitFunctionExpression(FunctionExpression node) {
    FunctionExpressionImpl toNode = _toNode as FunctionExpression;
    if (_and(_isEqualNodes(node.parameters, toNode.parameters),
        _isEqualNodes(node.body, toNode.body))) {
      toNode.declaredElement = node.declaredElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    FunctionExpressionInvocation toNode =
        _toNode as FunctionExpressionInvocation;
    if (_and(
        _isEqualNodes(node.function, toNode.function),
        _isEqualNodes(node.typeArguments, toNode.typeArguments),
        _isEqualNodes(node.argumentList, toNode.argumentList))) {
      toNode.staticInvokeType = node.staticInvokeType;
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAlias toNode = _toNode as FunctionTypeAlias;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.typedefKeyword, toNode.typedefKeyword),
        _isEqualNodes(node.returnType, toNode.returnType),
        _isEqualNodes(node.name, toNode.name),
        _isEqualNodes(node.typeParameters, toNode.typeParameters),
        _isEqualNodes(node.parameters, toNode.parameters),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    FunctionTypedFormalParameter toNode =
        _toNode as FunctionTypedFormalParameter;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualNodes(node.returnType, toNode.returnType),
        _isEqualNodes(node.identifier, toNode.identifier),
        _isEqualNodes(node.parameters, toNode.parameters));
  }

  @override
  bool visitGenericFunctionType(GenericFunctionType node) {
    GenericFunctionTypeImpl toNode = _toNode as GenericFunctionTypeImpl;
    if (_and(
        _isEqualNodes(node.returnType, toNode.returnType),
        _isEqualTokens(node.functionKeyword, toNode.functionKeyword),
        _isEqualNodes(node.typeParameters, toNode.typeParameters),
        _isEqualNodes(node.parameters, toNode.parameters),
        _isEqualTokens(node.question, toNode.question))) {
      toNode.type = node.type;
      return true;
    }
    return false;
  }

  @override
  bool visitGenericTypeAlias(GenericTypeAlias node) {
    GenericTypeAliasImpl toNode = _toNode as GenericTypeAliasImpl;
    if (_and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.typedefKeyword, toNode.typedefKeyword),
        _isEqualNodes(node.name, toNode.name),
        _isEqualNodes(node.typeParameters, toNode.typeParameters),
        _isEqualTokens(node.equals, toNode.equals),
        _isEqualNodes(node.type, toNode.type),
        _isEqualTokens(node.semicolon, toNode.semicolon))) {
      return true;
    }
    return false;
  }

  @override
  bool visitHideCombinator(HideCombinator node) {
    HideCombinator toNode = _toNode as HideCombinator;
    return _and(_isEqualTokens(node.keyword, toNode.keyword),
        _isEqualNodeLists(node.hiddenNames, toNode.hiddenNames));
  }

  @override
  bool visitIfElement(IfElement node) {
    IfElement toNode = _toNode as IfElement;
    return _and(
        _isEqualTokens(node.ifKeyword, toNode.ifKeyword),
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodes(node.condition, toNode.condition),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis),
        _isEqualNodes(node.thenElement, toNode.thenElement),
        _isEqualTokens(node.elseKeyword, toNode.elseKeyword),
        _isEqualNodes(node.elseElement, toNode.elseElement));
  }

  @override
  bool visitIfStatement(IfStatement node) {
    IfStatement toNode = _toNode as IfStatement;
    return _and(
        _isEqualTokens(node.ifKeyword, toNode.ifKeyword),
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodes(node.condition, toNode.condition),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis),
        _isEqualNodes(node.thenStatement, toNode.thenStatement),
        _isEqualTokens(node.elseKeyword, toNode.elseKeyword),
        _isEqualNodes(node.elseStatement, toNode.elseStatement));
  }

  @override
  bool visitImplementsClause(ImplementsClause node) {
    ImplementsClause toNode = _toNode as ImplementsClause;
    return _and(
        _isEqualTokens(node.implementsKeyword, toNode.implementsKeyword),
        _isEqualNodeLists(node.interfaces, toNode.interfaces));
  }

  @override
  bool visitImportDirective(ImportDirective node) {
    ImportDirective toNode = _toNode as ImportDirective;
    if (_and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.keyword, toNode.keyword),
        _isEqualNodes(node.uri, toNode.uri),
        _isEqualTokens(node.asKeyword, toNode.asKeyword),
        _isEqualNodes(node.prefix, toNode.prefix),
        _isEqualNodeLists(node.combinators, toNode.combinators),
        _isEqualTokens(node.semicolon, toNode.semicolon))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  @override
  bool visitIndexExpression(IndexExpression node) {
    IndexExpression toNode = _toNode as IndexExpression;
    if (_and(
        _isEqualNodes(node.target, toNode.target),
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodes(node.index, toNode.index),
        _isEqualTokens(node.rightBracket, toNode.rightBracket))) {
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitInstanceCreationExpression(InstanceCreationExpression node) {
    InstanceCreationExpression toNode = _toNode as InstanceCreationExpression;
    if (_and(
        _isEqualTokens(node.keyword, toNode.keyword),
        _isEqualNodes(node.constructorName, toNode.constructorName),
        _isEqualNodes(node.argumentList, toNode.argumentList))) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitIntegerLiteral(IntegerLiteral node) {
    IntegerLiteral toNode = _toNode as IntegerLiteral;
    if (_and(_isEqualTokens(node.literal, toNode.literal),
        node.value == toNode.value)) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitInterpolationExpression(InterpolationExpression node) {
    InterpolationExpression toNode = _toNode as InterpolationExpression;
    return _and(
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  @override
  bool visitInterpolationString(InterpolationString node) {
    InterpolationString toNode = _toNode as InterpolationString;
    return _and(_isEqualTokens(node.contents, toNode.contents),
        node.value == toNode.value);
  }

  @override
  bool visitIsExpression(IsExpression node) {
    IsExpression toNode = _toNode as IsExpression;
    if (_and(
        _isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.isOperator, toNode.isOperator),
        _isEqualTokens(node.notOperator, toNode.notOperator),
        _isEqualNodes(node.type, toNode.type))) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitLabel(Label node) {
    Label toNode = _toNode as Label;
    return _and(_isEqualNodes(node.label, toNode.label),
        _isEqualTokens(node.colon, toNode.colon));
  }

  @override
  bool visitLabeledStatement(LabeledStatement node) {
    LabeledStatement toNode = _toNode as LabeledStatement;
    return _and(_isEqualNodeLists(node.labels, toNode.labels),
        _isEqualNodes(node.statement, toNode.statement));
  }

  @override
  bool visitLibraryDirective(LibraryDirective node) {
    LibraryDirective toNode = _toNode as LibraryDirective;
    if (_and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.libraryKeyword, toNode.libraryKeyword),
        _isEqualNodes(node.name, toNode.name),
        _isEqualTokens(node.semicolon, toNode.semicolon))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  @override
  bool visitLibraryIdentifier(LibraryIdentifier node) {
    LibraryIdentifier toNode = _toNode as LibraryIdentifier;
    if (_isEqualNodeLists(node.components, toNode.components)) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitListLiteral(ListLiteral node) {
    ListLiteral toNode = _toNode as ListLiteral;
    if (_and(
        _isEqualTokens(node.constKeyword, toNode.constKeyword),
        _isEqualNodes(node.typeArguments, toNode.typeArguments),
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodeLists(node.elements, toNode.elements),
        _isEqualTokens(node.rightBracket, toNode.rightBracket))) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitMapLiteralEntry(MapLiteralEntry node) {
    MapLiteralEntry toNode = _toNode as MapLiteralEntry;
    return _and(
        _isEqualNodes(node.key, toNode.key),
        _isEqualTokens(node.separator, toNode.separator),
        _isEqualNodes(node.value, toNode.value));
  }

  @override
  bool visitMethodDeclaration(MethodDeclaration node) {
    MethodDeclaration toNode = _toNode as MethodDeclaration;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.externalKeyword, toNode.externalKeyword),
        _isEqualTokens(node.modifierKeyword, toNode.modifierKeyword),
        _isEqualNodes(node.returnType, toNode.returnType),
        _isEqualTokens(node.propertyKeyword, toNode.propertyKeyword),
        _isEqualTokens(node.propertyKeyword, toNode.propertyKeyword),
        _isEqualNodes(node.name, toNode.name),
        _isEqualNodes(node.parameters, toNode.parameters),
        _isEqualNodes(node.body, toNode.body));
  }

  @override
  bool visitMethodInvocation(MethodInvocation node) {
    MethodInvocation toNode = _toNode as MethodInvocation;
    if (_and(
        _isEqualNodes(node.target, toNode.target),
        _isEqualTokens(node.operator, toNode.operator),
        _isEqualNodes(node.typeArguments, toNode.typeArguments),
        _isEqualNodes(node.methodName, toNode.methodName),
        _isEqualNodes(node.argumentList, toNode.argumentList))) {
      toNode.staticInvokeType = node.staticInvokeType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitMixinDeclaration(MixinDeclaration node) {
    MixinDeclaration toNode = _toNode as MixinDeclaration;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.mixinKeyword, toNode.mixinKeyword),
        _isEqualNodes(node.name, toNode.name),
        _isEqualNodes(node.typeParameters, toNode.typeParameters),
        _isEqualNodes(node.onClause, toNode.onClause),
        _isEqualNodes(node.implementsClause, toNode.implementsClause),
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodeLists(node.members, toNode.members),
        _isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  @override
  bool visitNamedExpression(NamedExpression node) {
    NamedExpression toNode = _toNode as NamedExpression;
    if (_and(_isEqualNodes(node.name, toNode.name),
        _isEqualNodes(node.expression, toNode.expression))) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitNativeClause(NativeClause node) {
    NativeClause toNode = _toNode as NativeClause;
    return _and(_isEqualTokens(node.nativeKeyword, toNode.nativeKeyword),
        _isEqualNodes(node.name, toNode.name));
  }

  @override
  bool visitNativeFunctionBody(NativeFunctionBody node) {
    NativeFunctionBody toNode = _toNode as NativeFunctionBody;
    return _and(
        _isEqualTokens(node.nativeKeyword, toNode.nativeKeyword),
        _isEqualNodes(node.stringLiteral, toNode.stringLiteral),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitNullLiteral(NullLiteral node) {
    NullLiteral toNode = _toNode as NullLiteral;
    if (_isEqualTokens(node.literal, toNode.literal)) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitOnClause(OnClause node) {
    OnClause toNode = _toNode as OnClause;
    return _and(
        _isEqualTokens(node.onKeyword, toNode.onKeyword),
        _isEqualNodeLists(
            node.superclassConstraints, toNode.superclassConstraints));
  }

  @override
  bool visitParenthesizedExpression(ParenthesizedExpression node) {
    ParenthesizedExpression toNode = _toNode as ParenthesizedExpression;
    if (_and(
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis))) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitPartDirective(PartDirective node) {
    PartDirective toNode = _toNode as PartDirective;
    if (_and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.partKeyword, toNode.partKeyword),
        _isEqualNodes(node.uri, toNode.uri),
        _isEqualTokens(node.semicolon, toNode.semicolon))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  @override
  bool visitPartOfDirective(PartOfDirective node) {
    PartOfDirective toNode = _toNode as PartOfDirective;
    if (_and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.partKeyword, toNode.partKeyword),
        _isEqualTokens(node.ofKeyword, toNode.ofKeyword),
        _isEqualNodes(node.libraryName, toNode.libraryName),
        _isEqualTokens(node.semicolon, toNode.semicolon))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  @override
  bool visitPostfixExpression(PostfixExpression node) {
    PostfixExpression toNode = _toNode as PostfixExpression;
    if (_and(_isEqualNodes(node.operand, toNode.operand),
        _isEqualTokens(node.operator, toNode.operator))) {
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitPrefixedIdentifier(PrefixedIdentifier node) {
    PrefixedIdentifier toNode = _toNode as PrefixedIdentifier;
    if (_and(
        _isEqualNodes(node.prefix, toNode.prefix),
        _isEqualTokens(node.period, toNode.period),
        _isEqualNodes(node.identifier, toNode.identifier))) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitPrefixExpression(PrefixExpression node) {
    PrefixExpression toNode = _toNode as PrefixExpression;
    if (_and(_isEqualTokens(node.operator, toNode.operator),
        _isEqualNodes(node.operand, toNode.operand))) {
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitPropertyAccess(PropertyAccess node) {
    PropertyAccess toNode = _toNode as PropertyAccess;
    if (_and(
        _isEqualNodes(node.target, toNode.target),
        _isEqualTokens(node.operator, toNode.operator),
        _isEqualNodes(node.propertyName, toNode.propertyName))) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    RedirectingConstructorInvocation toNode =
        _toNode as RedirectingConstructorInvocation;
    if (_and(
        _isEqualTokens(node.thisKeyword, toNode.thisKeyword),
        _isEqualTokens(node.period, toNode.period),
        _isEqualNodes(node.constructorName, toNode.constructorName),
        _isEqualNodes(node.argumentList, toNode.argumentList))) {
      toNode.staticElement = node.staticElement;
      return true;
    }
    return false;
  }

  @override
  bool visitRethrowExpression(RethrowExpression node) {
    RethrowExpression toNode = _toNode as RethrowExpression;
    if (_isEqualTokens(node.rethrowKeyword, toNode.rethrowKeyword)) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitReturnStatement(ReturnStatement node) {
    ReturnStatement toNode = _toNode as ReturnStatement;
    return _and(
        _isEqualTokens(node.returnKeyword, toNode.returnKeyword),
        _isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitScriptTag(ScriptTag node) {
    ScriptTag toNode = _toNode as ScriptTag;
    return _isEqualTokens(node.scriptTag, toNode.scriptTag);
  }

  @override
  bool visitSetOrMapLiteral(SetOrMapLiteral node) {
    SetOrMapLiteral toNode = _toNode as SetOrMapLiteral;
    if (_and(
        _isEqualTokens(node.constKeyword, toNode.constKeyword),
        _isEqualNodes(node.typeArguments, toNode.typeArguments),
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodeLists(node.elements, toNode.elements),
        _isEqualTokens(node.rightBracket, toNode.rightBracket))) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitShowCombinator(ShowCombinator node) {
    ShowCombinator toNode = _toNode as ShowCombinator;
    return _and(_isEqualTokens(node.keyword, toNode.keyword),
        _isEqualNodeLists(node.shownNames, toNode.shownNames));
  }

  @override
  bool visitSimpleFormalParameter(SimpleFormalParameter node) {
    SimpleFormalParameter toNode = _toNode as SimpleFormalParameter;
    if (_and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.keyword, toNode.keyword),
        _isEqualNodes(node.type, toNode.type),
        _isEqualNodes(node.identifier, toNode.identifier))) {
      (toNode as SimpleFormalParameterImpl).declaredElement =
          node.declaredElement;
      return true;
    }
    return false;
  }

  @override
  bool visitSimpleIdentifier(SimpleIdentifier node) {
    SimpleIdentifier toNode = _toNode as SimpleIdentifier;
    if (_isEqualTokens(node.token, toNode.token)) {
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      (toNode as SimpleIdentifierImpl).tearOffTypeArgumentTypes =
          node.tearOffTypeArgumentTypes;
      return true;
    }
    return false;
  }

  @override
  bool visitSimpleStringLiteral(SimpleStringLiteral node) {
    SimpleStringLiteral toNode = _toNode as SimpleStringLiteral;
    if (_and(_isEqualTokens(node.literal, toNode.literal),
        node.value == toNode.value)) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitSpreadElement(SpreadElement node) {
    SpreadElement toNode = _toNode as SpreadElement;
    return _and(_isEqualTokens(node.spreadOperator, toNode.spreadOperator),
        _isEqualNodes(node.expression, toNode.expression));
  }

  @override
  bool visitStringInterpolation(StringInterpolation node) {
    StringInterpolation toNode = _toNode as StringInterpolation;
    if (_isEqualNodeLists(node.elements, toNode.elements)) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    SuperConstructorInvocation toNode = _toNode as SuperConstructorInvocation;
    if (_and(
        _isEqualTokens(node.superKeyword, toNode.superKeyword),
        _isEqualTokens(node.period, toNode.period),
        _isEqualNodes(node.constructorName, toNode.constructorName),
        _isEqualNodes(node.argumentList, toNode.argumentList))) {
      toNode.staticElement = node.staticElement;
      return true;
    }
    return false;
  }

  @override
  bool visitSuperExpression(SuperExpression node) {
    SuperExpression toNode = _toNode as SuperExpression;
    if (_isEqualTokens(node.superKeyword, toNode.superKeyword)) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitSwitchCase(SwitchCase node) {
    SwitchCase toNode = _toNode as SwitchCase;
    return _and(
        _isEqualNodeLists(node.labels, toNode.labels),
        _isEqualTokens(node.keyword, toNode.keyword),
        _isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.colon, toNode.colon),
        _isEqualNodeLists(node.statements, toNode.statements));
  }

  @override
  bool visitSwitchDefault(SwitchDefault node) {
    SwitchDefault toNode = _toNode as SwitchDefault;
    return _and(
        _isEqualNodeLists(node.labels, toNode.labels),
        _isEqualTokens(node.keyword, toNode.keyword),
        _isEqualTokens(node.colon, toNode.colon),
        _isEqualNodeLists(node.statements, toNode.statements));
  }

  @override
  bool visitSwitchStatement(SwitchStatement node) {
    SwitchStatement toNode = _toNode as SwitchStatement;
    return _and(
        _isEqualTokens(node.switchKeyword, toNode.switchKeyword),
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis),
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodeLists(node.members, toNode.members),
        _isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  @override
  bool visitSymbolLiteral(SymbolLiteral node) {
    SymbolLiteral toNode = _toNode as SymbolLiteral;
    if (_and(_isEqualTokens(node.poundSign, toNode.poundSign),
        _isEqualTokenLists(node.components, toNode.components))) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitThisExpression(ThisExpression node) {
    ThisExpression toNode = _toNode as ThisExpression;
    if (_isEqualTokens(node.thisKeyword, toNode.thisKeyword)) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitThrowExpression(ThrowExpression node) {
    ThrowExpression toNode = _toNode as ThrowExpression;
    if (_and(_isEqualTokens(node.throwKeyword, toNode.throwKeyword),
        _isEqualNodes(node.expression, toNode.expression))) {
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    TopLevelVariableDeclaration toNode = _toNode as TopLevelVariableDeclaration;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.externalKeyword, toNode.externalKeyword),
        _isEqualNodes(node.variables, toNode.variables),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitTryStatement(TryStatement node) {
    TryStatement toNode = _toNode as TryStatement;
    return _and(
        _isEqualTokens(node.tryKeyword, toNode.tryKeyword),
        _isEqualNodes(node.body, toNode.body),
        _isEqualNodeLists(node.catchClauses, toNode.catchClauses),
        _isEqualTokens(node.finallyKeyword, toNode.finallyKeyword),
        _isEqualNodes(node.finallyBlock, toNode.finallyBlock));
  }

  @override
  bool visitTypeArgumentList(TypeArgumentList node) {
    TypeArgumentList toNode = _toNode as TypeArgumentList;
    return _and(
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodeLists(node.arguments, toNode.arguments),
        _isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  @override
  bool visitTypeName(TypeName node) {
    TypeName toNode = _toNode as TypeName;
    if (_and(
        _isEqualNodes(node.name, toNode.name),
        _isEqualNodes(node.typeArguments, toNode.typeArguments),
        _isEqualTokens(node.question, toNode.question))) {
      toNode.type = node.type;
      return true;
    }
    return false;
  }

  @override
  bool visitTypeParameter(TypeParameter node) {
    TypeParameter toNode = _toNode as TypeParameter;
    // TODO (kallentu) : Clean up TypeParameterImpl casting once variance is
    // added to the interface.
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualNodes(node.name, toNode.name),
        _isEqualTokens((node as TypeParameterImpl).varianceKeyword,
            (toNode as TypeParameterImpl).varianceKeyword),
        _isEqualTokens(node.extendsKeyword, toNode.extendsKeyword),
        _isEqualNodes(node.bound, toNode.bound));
  }

  @override
  bool visitTypeParameterList(TypeParameterList node) {
    TypeParameterList toNode = _toNode as TypeParameterList;
    return _and(
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodeLists(node.typeParameters, toNode.typeParameters),
        _isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  @override
  bool visitVariableDeclaration(VariableDeclaration node) {
    VariableDeclaration toNode = _toNode as VariableDeclaration;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualNodes(node.name, toNode.name),
        _isEqualTokens(node.equals, toNode.equals),
        _isEqualNodes(node.initializer, toNode.initializer));
  }

  @override
  bool visitVariableDeclarationList(VariableDeclarationList node) {
    VariableDeclarationList toNode = _toNode as VariableDeclarationList;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.keyword, toNode.keyword),
        _isEqualNodes(node.type, toNode.type),
        _isEqualNodeLists(node.variables, toNode.variables));
  }

  @override
  bool visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    VariableDeclarationStatement toNode =
        _toNode as VariableDeclarationStatement;
    return _and(_isEqualNodes(node.variables, toNode.variables),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitWhileStatement(WhileStatement node) {
    WhileStatement toNode = _toNode as WhileStatement;
    return _and(
        _isEqualTokens(node.whileKeyword, toNode.whileKeyword),
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodes(node.condition, toNode.condition),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis),
        _isEqualNodes(node.body, toNode.body));
  }

  @override
  bool visitWithClause(WithClause node) {
    WithClause toNode = _toNode as WithClause;
    return _and(_isEqualTokens(node.withKeyword, toNode.withKeyword),
        _isEqualNodeLists(node.mixinTypes, toNode.mixinTypes));
  }

  @override
  bool visitYieldStatement(YieldStatement node) {
    YieldStatement toNode = _toNode as YieldStatement;
    return _and(
        _isEqualTokens(node.yieldKeyword, toNode.yieldKeyword),
        _isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  /// Return `true` if all of the parameters are `true`.
  bool _and(bool b1, bool b2,
      [bool b3 = true,
      bool b4 = true,
      bool b5 = true,
      bool b6 = true,
      bool b7 = true,
      bool b8 = true,
      bool b9 = true,
      bool b10 = true,
      bool b11 = true,
      bool b12 = true,
      bool b13 = true]) {
    // TODO(brianwilkerson) Inline this method.
    return b1 &&
        b2 &&
        b3 &&
        b4 &&
        b5 &&
        b6 &&
        b7 &&
        b8 &&
        b9 &&
        b10 &&
        b11 &&
        b12 &&
        b13;
  }

  /// Return `true` if the [first] and [second] lists of AST nodes have the same
  /// size and corresponding elements are equal.
  bool _isEqualNodeLists(NodeList first, NodeList second) {
    if (first == null) {
      return second == null;
    } else if (second == null) {
      return false;
    }
    int size = first.length;
    if (second.length != size) {
      return false;
    }
    bool equal = true;
    for (int i = 0; i < size; i++) {
      if (!_isEqualNodes(first[i], second[i])) {
        equal = false;
      }
    }
    return equal;
  }

  /// Return `true` if the [fromNode] and [toNode] have the same structure. As a
  /// side-effect, if the nodes do have the same structure, any resolution data
  /// from the first node will be copied to the second node.
  bool _isEqualNodes(AstNode fromNode, AstNode toNode) {
    if (fromNode == null) {
      return toNode == null;
    } else if (toNode == null) {
      return false;
    } else if (fromNode.runtimeType == toNode.runtimeType) {
      _toNode = toNode;
      return fromNode.accept(this);
    }
    //
    // Check for a simple transformation caused by entering a period.
    //
    if (toNode is PrefixedIdentifier) {
      SimpleIdentifier prefix = toNode.prefix;
      if (fromNode.runtimeType == prefix.runtimeType) {
        _toNode = prefix;
        return fromNode.accept(this);
      }
    } else if (toNode is PropertyAccess) {
      Expression target = toNode.target;
      if (fromNode.runtimeType == target.runtimeType) {
        _toNode = target;
        return fromNode.accept(this);
      }
    }
    return false;
  }

  /// Return `true` if the [first] and [second] arrays of tokens have the same
  /// length and corresponding elements are equal.
  bool _isEqualTokenLists(List<Token> first, List<Token> second) {
    int length = first.length;
    if (second.length != length) {
      return false;
    }
    for (int i = 0; i < length; i++) {
      if (!_isEqualTokens(first[i], second[i])) {
        return false;
      }
    }
    return true;
  }

  /// Return `true` if the [first] and [second] tokens have the same structure.
  bool _isEqualTokens(Token first, Token second) {
    if (first == null) {
      return second == null;
    } else if (second == null) {
      return false;
    }
    return first.lexeme == second.lexeme;
  }

  /// Copy resolution data from the [fromNode] to the [toNode].
  static void copyResolutionData(AstNode fromNode, AstNode toNode) {
    ResolutionCopier copier = ResolutionCopier();
    copier._isEqualNodes(fromNode, toNode);
  }
}

/// Traverse the AST from initial child node to successive parents, building a
/// collection of local variable and parameter names visible to the initial
/// child node. In case of name shadowing, the first name seen is the most
/// specific one so names are not redefined.
///
/// Completion test code coverage is 95%. The two basic blocks that are not
/// executed cannot be executed. They are included for future reference.
class ScopedNameFinder extends GeneralizingAstVisitor<void> {
  Declaration _declarationNode;

  AstNode _immediateChild;

  final Map<String, SimpleIdentifier> _locals =
      HashMap<String, SimpleIdentifier>();

  final int _position;

  bool _referenceIsWithinLocalFunction = false;

  ScopedNameFinder(this._position);

  Declaration get declaration => _declarationNode;

  Map<String, SimpleIdentifier> get locals => _locals;

  @override
  void visitBlock(Block node) {
    _checkStatements(node.statements);
    super.visitBlock(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _addToScope(node.exceptionParameter);
    _addToScope(node.stackTraceParameter);
    super.visitCatchClause(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (!identical(_immediateChild, node.parameters)) {
      _addParameters(node.parameters.parameters);
    }
    _declarationNode = node;
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _declarationNode = node;
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _addToScope(node.loopVariable.identifier);
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _addVariables(node.variables.variables);
    super.visitForPartsWithDeclarations(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is! FunctionDeclarationStatement) {
      _declarationNode = node;
    } else {
      super.visitFunctionDeclaration(node);
    }
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _referenceIsWithinLocalFunction = true;
    super.visitFunctionDeclarationStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parameters != null &&
        !identical(_immediateChild, node.parameters)) {
      _addParameters(node.parameters.parameters);
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _declarationNode = node;
    if (node.parameters != null &&
        !identical(_immediateChild, node.parameters)) {
      _addParameters(node.parameters.parameters);
    }
  }

  @override
  void visitNode(AstNode node) {
    _immediateChild = node;
    AstNode parent = node.parent;
    if (parent != null) {
      parent.accept(this);
    }
  }

  @override
  void visitSwitchMember(SwitchMember node) {
    _checkStatements(node.statements);
    super.visitSwitchMember(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _declarationNode = node;
  }

  @override
  void visitTypeAlias(TypeAlias node) {
    _declarationNode = node;
  }

  void _addParameters(NodeList<FormalParameter> vars) {
    for (FormalParameter var2 in vars) {
      _addToScope(var2.identifier);
    }
  }

  void _addToScope(SimpleIdentifier identifier) {
    if (identifier != null && _isInRange(identifier)) {
      String name = identifier.name;
      if (!_locals.containsKey(name)) {
        _locals[name] = identifier;
      }
    }
  }

  void _addVariables(NodeList<VariableDeclaration> variables) {
    for (VariableDeclaration variable in variables) {
      _addToScope(variable.name);
    }
  }

  /// Check the given list of [statements] for any that come before the
  /// immediate child and that define a name that would be visible to the
  /// immediate child.
  void _checkStatements(List<Statement> statements) {
    for (Statement statement in statements) {
      if (identical(statement, _immediateChild)) {
        return;
      }
      if (statement is VariableDeclarationStatement) {
        _addVariables(statement.variables.variables);
      } else if (statement is FunctionDeclarationStatement &&
          !_referenceIsWithinLocalFunction) {
        _addToScope(statement.functionDeclaration.name);
      }
    }
  }

  bool _isInRange(AstNode node) {
    if (_position < 0) {
      // if source position is not set then all nodes are in range
      return true;
      // not reached
    }
    return node.end < _position;
  }
}

/// A visitor used to write a source representation of a visited AST node (and
/// all of it's children) to a sink.
@Deprecated('Use ToSourceVisitor')
class ToSourceVisitor2 extends ToSourceVisitor {
  ToSourceVisitor2(StringSink sink) : super(sink);
}
