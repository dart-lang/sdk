// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.dart.ast.utilities;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/utilities_collection.dart' show TokenMap;
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';

/**
 * A function used to handle exceptions that are thrown by delegates while using
 * an [ExceptionHandlingDelegatingAstVisitor].
 */
typedef void ExceptionInDelegateHandler(
    AstNode node, AstVisitor visitor, dynamic exception, StackTrace stackTrace);

/**
 * An AST visitor that will clone any AST structure that it visits. The cloner
 * will only clone the structure, it will not preserve any resolution results or
 * properties associated with the nodes.
 */
class AstCloner implements AstVisitor<AstNode> {
  /**
   * A flag indicating whether tokens should be cloned while cloning an AST
   * structure.
   */
  final bool cloneTokens;

  /**
   * Mapping from original tokes to cloned.
   */
  final Map<Token, Token> _clonedTokens = new Map<Token, Token>.identity();

  /**
   * The next original token to clone.
   */
  Token _nextToClone;

  /**
   * The last cloned token.
   */
  Token _lastCloned;

  /**
   * The offset of the last cloned token.
   */
  int _lastClonedOffset = -1;

  /**
   * Initialize a newly created AST cloner to optionally clone tokens while
   * cloning AST nodes if [cloneTokens] is `true`.
   *
   * TODO(brianwilkerson) Change this to be a named parameter.
   */
  AstCloner([this.cloneTokens = false]);

  /**
   * Return a clone of the given [node].
   */
  AstNode/*=E*/ cloneNode/*<E extends AstNode>*/(AstNode/*=E*/ node) {
    if (node == null) {
      return null;
    }
    return node.accept(this) as AstNode/*=E*/;
  }

  /**
   * Return a list containing cloned versions of the nodes in the given list of
   * [nodes].
   */
  List<AstNode/*=E*/ > cloneNodeList/*<E extends AstNode>*/(List/*<E>*/ nodes) {
    int count = nodes.length;
    List/*<E>*/ clonedNodes = new List/*<E>*/();
    for (int i = 0; i < count; i++) {
      clonedNodes.add((nodes[i]).accept(this) as AstNode/*=E*/);
    }
    return clonedNodes;
  }

  /**
   * Clone the given [token] if tokens are supposed to be cloned.
   */
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

  /**
   * Clone the given [tokens] if tokens are supposed to be cloned.
   */
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
  CommentReference visitCommentReference(CommentReference node) =>
      astFactory.commentReference(
          cloneToken(node.newKeyword), cloneNode(node.identifier));

  @override
  CompilationUnit visitCompilationUnit(CompilationUnit node) {
    CompilationUnit clone = astFactory.compilationUnit(
        cloneToken(node.beginToken),
        cloneNode(node.scriptTag),
        cloneNodeList(node.directives),
        cloneNodeList(node.declarations),
        cloneToken(node.endToken));
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
          DefaultFormalParameter node) =>
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
  FieldDeclaration visitFieldDeclaration(FieldDeclaration node) =>
      astFactory.fieldDeclaration2(
          comment: cloneNode(node.documentationComment),
          metadata: cloneNodeList(node.metadata),
          covariantKeyword: cloneToken(node.covariantKeyword),
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
          parameters: cloneNode(node.parameters));

  @override
  ForEachStatement visitForEachStatement(ForEachStatement node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (loopVariable == null) {
      return astFactory.forEachStatementWithReference(
          cloneToken(node.awaitKeyword),
          cloneToken(node.forKeyword),
          cloneToken(node.leftParenthesis),
          cloneNode(node.identifier),
          cloneToken(node.inKeyword),
          cloneNode(node.iterable),
          cloneToken(node.rightParenthesis),
          cloneNode(node.body));
    }
    return astFactory.forEachStatementWithDeclaration(
        cloneToken(node.awaitKeyword),
        cloneToken(node.forKeyword),
        cloneToken(node.leftParenthesis),
        cloneNode(loopVariable),
        cloneToken(node.inKeyword),
        cloneNode(node.iterable),
        cloneToken(node.rightParenthesis),
        cloneNode(node.body));
  }

  @override
  FormalParameterList visitFormalParameterList(FormalParameterList node) =>
      astFactory.formalParameterList(
          cloneToken(node.leftParenthesis),
          cloneNodeList(node.parameters),
          cloneToken(node.leftDelimiter),
          cloneToken(node.rightDelimiter),
          cloneToken(node.rightParenthesis));

  @override
  ForStatement visitForStatement(ForStatement node) => astFactory.forStatement(
      cloneToken(node.forKeyword),
      cloneToken(node.leftParenthesis),
      cloneNode(node.variables),
      cloneNode(node.initialization),
      cloneToken(node.leftSeparator),
      cloneNode(node.condition),
      cloneToken(node.rightSeparator),
      cloneNodeList(node.updaters),
      cloneToken(node.rightParenthesis),
      cloneNode(node.body));

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
          parameters: cloneNode(node.parameters));

  @override
  AstNode visitGenericFunctionType(GenericFunctionType node) =>
      astFactory.genericFunctionType(
          cloneNode(node.returnType),
          cloneToken(node.functionKeyword),
          cloneNode(node.typeParameters),
          cloneNode(node.parameters));

  @override
  AstNode visitGenericTypeAlias(GenericTypeAlias node) =>
      astFactory.genericTypeAlias(
          cloneNode(node.documentationComment),
          cloneNodeList(node.metadata),
          cloneToken(node.typedefKeyword),
          cloneNode(node.name),
          cloneNode(node.typeParameters),
          cloneToken(node.equals),
          cloneNode(node.functionType),
          cloneToken(node.semicolon));

  @override
  HideCombinator visitHideCombinator(HideCombinator node) =>
      astFactory.hideCombinator(
          cloneToken(node.keyword), cloneNodeList(node.hiddenNames));

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
      return astFactory.indexExpressionForTarget(
          cloneNode(node.target),
          cloneToken(node.leftBracket),
          cloneNode(node.index),
          cloneToken(node.rightBracket));
    } else {
      return astFactory.indexExpressionForCascade(
          cloneToken(period),
          cloneToken(node.leftBracket),
          cloneNode(node.index),
          cloneToken(node.rightBracket));
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
  MapLiteral visitMapLiteral(MapLiteral node) => astFactory.mapLiteral(
      cloneToken(node.constKeyword),
      cloneNode(node.typeArguments),
      cloneToken(node.leftBracket),
      cloneNodeList(node.entries),
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
          cloneToken(node.semicolon));

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
      astFactory.typeName(cloneNode(node.name), cloneNode(node.typeArguments));

  @override
  TypeParameter visitTypeParameter(TypeParameter node) =>
      astFactory.typeParameter(
          cloneNode(node.documentationComment),
          cloneNodeList(node.metadata),
          cloneNode(node.name),
          cloneToken(node.extendsKeyword),
          cloneNode(node.bound));

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

  /**
   * Clone all token starting from the given [token] up to a token that has
   * offset greater then [stopAfter], and put mapping from originals to clones
   * into [_clonedTokens].
   *
   * We cannot clone tokens as we visit nodes because not every token is a part
   * of a node, E.g. commas in argument lists are not represented in AST. But
   * we need to the sequence of tokens that is identical to the original one.
   */
  void _cloneTokens(Token token, int stopAfter) {
    if (token == null) {
      return;
    }
    Token nonComment(Token token) {
      return token is CommentToken ? token.parent : token;
    }

    token = nonComment(token);
    if (_lastCloned == null) {
      _lastCloned = new Token.eof(-1);
    }
    while (token != null) {
      Token clone = token.copy();
      {
        CommentToken c1 = token.precedingComments;
        CommentToken c2 = clone.precedingComments;
        while (c1 != null && c2 != null) {
          _clonedTokens[c1] = c2;
          if (c1 is DocumentationCommentToken &&
              c2 is DocumentationCommentToken) {
            for (int i = 0; i < c1.references.length; i++) {
              _clonedTokens[c1.references[i]] = c2.references[i];
            }
          }
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

  /**
   * Return a clone of the given [node].
   */
  static AstNode clone(AstNode node) {
    return node.accept(new AstCloner());
  }
}

/**
 * An AstVisitor that compares the structure of two AstNodes to see whether they
 * are equal.
 */
class AstComparator implements AstVisitor<bool> {
  /**
   * The AST node with which the node being visited is to be compared. This is
   * only valid at the beginning of each visit method (until [isEqualNodes] is
   * invoked).
   */
  AstNode _other;

  /**
   * Notify that [first] and second have different length.
   * This implementation returns `false`. Subclasses can override and throw.
   */
  bool failDifferentLength(List first, List second) {
    return false;
  }

  /**
   * Check whether [second] is null. Subclasses can override to throw.
   */
  bool failIfNotNull(Object first, Object second) {
    return second == null;
  }

  /**
   * Notify that [first] is not `null` while [second] one is `null`.
   * This implementation returns `false`. Subclasses can override and throw.
   */
  bool failIsNull(Object first, Object second) {
    return false;
  }

  /**
   * Notify that [first] and [second] have different types.
   * This implementation returns `false`. Subclasses can override and throw.
   */
  bool failRuntimeType(Object first, Object second) {
    return false;
  }

  /**
   * Return `true` if the [first] node and the [second] node have the same
   * structure.
   *
   * *Note:* This method is only visible for testing purposes and should not be
   * used by clients.
   */
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

  /**
   * Return `true` if the [first] token and the [second] token have the same
   * structure.
   *
   * *Note:* This method is only visible for testing purposes and should not be
   * used by clients.
   */
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

  /**
   * Return `true` if the [first] token and the [second] token have the same
   * structure.  Both [first] and [second] are not `null`.
   */
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
    AssertStatement other = _other as AssertStatement;
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
        node.value == other.value;
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
  bool visitDefaultFormalParameter(DefaultFormalParameter node) {
    DefaultFormalParameter other = _other as DefaultFormalParameter;
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
        node.value == other.value;
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
  bool visitFieldDeclaration(FieldDeclaration node) {
    FieldDeclaration other = _other as FieldDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
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
  bool visitForEachStatement(ForEachStatement node) {
    ForEachStatement other = _other as ForEachStatement;
    return isEqualTokens(node.forKeyword, other.forKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.loopVariable, other.loopVariable) &&
        isEqualTokens(node.inKeyword, other.inKeyword) &&
        isEqualNodes(node.iterable, other.iterable) &&
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
  bool visitForStatement(ForStatement node) {
    ForStatement other = _other as ForStatement;
    return isEqualTokens(node.forKeyword, other.forKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.variables, other.variables) &&
        isEqualNodes(node.initialization, other.initialization) &&
        isEqualTokens(node.leftSeparator, other.leftSeparator) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightSeparator, other.rightSeparator) &&
        _isEqualNodeLists(node.updaters, other.updaters) &&
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
        isEqualNodes(node.parameters, other.parameters);
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
        isEqualNodes(node.functionType, other.functionType);
  }

  @override
  bool visitHideCombinator(HideCombinator node) {
    HideCombinator other = _other as HideCombinator;
    return isEqualTokens(node.keyword, other.keyword) &&
        _isEqualNodeLists(node.hiddenNames, other.hiddenNames);
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
        (node.value == other.value);
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
        node.value == other.value;
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
  bool visitMapLiteral(MapLiteral node) {
    MapLiteral other = _other as MapLiteral;
    return isEqualTokens(node.constKeyword, other.constKeyword) &&
        isEqualNodes(node.typeArguments, other.typeArguments) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.entries, other.entries) &&
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
        isEqualTokens(node.propertyKeyword, other.propertyKeyword) &&
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
        (node.value == other.value);
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
        isEqualNodes(node.typeArguments, other.typeArguments);
  }

  @override
  bool visitTypeParameter(TypeParameter node) {
    TypeParameter other = _other as TypeParameter;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualNodes(node.name, other.name) &&
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

  /**
   * Return `true` if the [first] and [second] lists of AST nodes have the same
   * size and corresponding elements are equal.
   */
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

  /**
   * Return `true` if the [first] and [second] lists of tokens have the same
   * length and corresponding elements are equal.
   */
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

  /**
   * Return `true` if the [first] and [second] nodes are equal.
   */
  static bool equalNodes(AstNode first, AstNode second) {
    AstComparator comparator = new AstComparator();
    return comparator.isEqualNodes(first, second);
  }
}

/**
 * Instances of the class [ConstantEvaluator] evaluate constant expressions to
 * produce their compile-time value.
 *
 * According to the Dart Language Specification:
 *
 * > A constant expression is one of the following:
 * >
 * > * A literal number.
 * > * A literal boolean.
 * > * A literal string where any interpolated expression is a compile-time
 * >   constant that evaluates to a numeric, string or boolean value or to
 * >   **null**.
 * > * A literal symbol.
 * > * **null**.
 * > * A qualified reference to a static constant variable.
 * > * An identifier expression that denotes a constant variable, class or type
 * >   alias.
 * > * A constant constructor invocation.
 * > * A constant list literal.
 * > * A constant map literal.
 * > * A simple or qualified identifier denoting a top-level function or a
 * >   static method.
 * > * A parenthesized expression _(e)_ where _e_ is a constant expression.
 * > * <span>
 * >   An expression of the form <i>identical(e<sub>1</sub>, e<sub>2</sub>)</i>
 * >   where <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant
 * >   expressions and <i>identical()</i> is statically bound to the predefined
 * >   dart function <i>identical()</i> discussed above.
 * >   </span>
 * > * <span>
 * >   An expression of one of the forms <i>e<sub>1</sub> == e<sub>2</sub></i>
 * >   or <i>e<sub>1</sub> != e<sub>2</sub></i> where <i>e<sub>1</sub></i> and
 * >   <i>e<sub>2</sub></i> are constant expressions that evaluate to a
 * >   numeric, string or boolean value.
 * >   </span>
 * > * <span>
 * >   An expression of one of the forms <i>!e</i>, <i>e<sub>1</sub> &amp;&amp;
 * >   e<sub>2</sub></i> or <i>e<sub>1</sub> || e<sub>2</sub></i>, where
 * >   <i>e</i>, <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant
 * >   expressions that evaluate to a boolean value.
 * >   </span>
 * > * <span>
 * >   An expression of one of the forms <i>~e</i>, <i>e<sub>1</sub> ^
 * >   e<sub>2</sub></i>, <i>e<sub>1</sub> &amp; e<sub>2</sub></i>,
 * >   <i>e<sub>1</sub> | e<sub>2</sub></i>, <i>e<sub>1</sub> &gt;&gt;
 * >   e<sub>2</sub></i> or <i>e<sub>1</sub> &lt;&lt; e<sub>2</sub></i>, where
 * >   <i>e</i>, <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant
 * >   expressions that evaluate to an integer value or to <b>null</b>.
 * >   </span>
 * > * <span>
 * >   An expression of one of the forms <i>-e</i>, <i>e<sub>1</sub>
 * >   -e<sub>2</sub></i>, <i>e<sub>1</sub> * e<sub>2</sub></i>,
 * >   <i>e<sub>1</sub> / e<sub>2</sub></i>, <i>e<sub>1</sub> ~/
 * >   e<sub>2</sub></i>, <i>e<sub>1</sub> &gt; e<sub>2</sub></i>,
 * >   <i>e<sub>1</sub> &lt; e<sub>2</sub></i>, <i>e<sub>1</sub> &gt;=
 * >   e<sub>2</sub></i>, <i>e<sub>1</sub> &lt;= e<sub>2</sub></i> or
 * >   <i>e<sub>1</sub> % e<sub>2</sub></i>, where <i>e</i>,
 * >   <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant expressions
 * >   that evaluate to a numeric value or to <b>null</b>.
 * >   </span>
 * > * <span>
 * >   An expression of one the form <i>e<sub>1</sub> + e<sub>2</sub></i>,
 * >   <i>e<sub>1</sub> -e<sub>2</sub></i> where <i>e<sub>1</sub> and
 * >   e<sub>2</sub></i> are constant expressions that evaluate to a numeric or
 * >   string value or to <b>null</b>.
 * >   </span>
 * > * <span>
 * >   An expression of the form <i>e<sub>1</sub> ? e<sub>2</sub> :
 * >   e<sub>3</sub></i> where <i>e<sub>1</sub></i>, <i>e<sub>2</sub></i> and
 * >   <i>e<sub>3</sub></i> are constant expressions, and <i>e<sub>1</sub></i>
 * >   evaluates to a boolean value.
 * >   </span>
 *
 * However, this comment is now at least a little bit out of sync with the spec.
 *
 * The values returned by instances of this class are therefore `null` and
 * instances of the classes `Boolean`, `BigInteger`, `Double`, `String`, and
 * `DartObject`.
 *
 * In addition, this class defines several values that can be returned to
 * indicate various conditions encountered during evaluation. These are
 * documented with the static fields that define those values.
 */
class ConstantEvaluator extends GeneralizingAstVisitor<Object> {
  /**
   * The value returned for expressions (or non-expression nodes) that are not
   * compile-time constant expressions.
   */
  static Object NOT_A_CONSTANT = new Object();

  @override
  Object visitAdjacentStrings(AdjacentStrings node) {
    StringBuffer buffer = new StringBuffer();
    for (StringLiteral string in node.strings) {
      Object value = string.accept(this);
      if (identical(value, NOT_A_CONSTANT)) {
        return value;
      }
      buffer.write(value);
    }
    return buffer.toString();
  }

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    Object leftOperand = node.leftOperand.accept(this);
    if (identical(leftOperand, NOT_A_CONSTANT)) {
      return leftOperand;
    }
    Object rightOperand = node.rightOperand.accept(this);
    if (identical(rightOperand, NOT_A_CONSTANT)) {
      return rightOperand;
    }
    while (true) {
      if (node.operator.type == TokenType.AMPERSAND) {
        // integer or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand & rightOperand;
        }
      } else if (node.operator.type == TokenType.AMPERSAND_AMPERSAND) {
        // boolean or {@code null}
        if (leftOperand is bool && rightOperand is bool) {
          return leftOperand && rightOperand;
        }
      } else if (node.operator.type == TokenType.BANG_EQ) {
        // numeric, string, boolean, or {@code null}
        if (leftOperand is bool && rightOperand is bool) {
          return leftOperand != rightOperand;
        } else if (leftOperand is num && rightOperand is num) {
          return leftOperand != rightOperand;
        } else if (leftOperand is String && rightOperand is String) {
          return leftOperand != rightOperand;
        }
      } else if (node.operator.type == TokenType.BAR) {
        // integer or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand | rightOperand;
        }
      } else if (node.operator.type == TokenType.BAR_BAR) {
        // boolean or {@code null}
        if (leftOperand is bool && rightOperand is bool) {
          return leftOperand || rightOperand;
        }
      } else if (node.operator.type == TokenType.CARET) {
        // integer or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand ^ rightOperand;
        }
      } else if (node.operator.type == TokenType.EQ_EQ) {
        // numeric, string, boolean, or {@code null}
        if (leftOperand is bool && rightOperand is bool) {
          return leftOperand == rightOperand;
        } else if (leftOperand is num && rightOperand is num) {
          return leftOperand == rightOperand;
        } else if (leftOperand is String && rightOperand is String) {
          return leftOperand == rightOperand;
        }
      } else if (node.operator.type == TokenType.GT) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand.compareTo(rightOperand) > 0;
        }
      } else if (node.operator.type == TokenType.GT_EQ) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand.compareTo(rightOperand) >= 0;
        }
      } else if (node.operator.type == TokenType.GT_GT) {
        // integer or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand >> rightOperand;
        }
      } else if (node.operator.type == TokenType.LT) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand.compareTo(rightOperand) < 0;
        }
      } else if (node.operator.type == TokenType.LT_EQ) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand.compareTo(rightOperand) <= 0;
        }
      } else if (node.operator.type == TokenType.LT_LT) {
        // integer or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand << rightOperand;
        }
      } else if (node.operator.type == TokenType.MINUS) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand - rightOperand;
        }
      } else if (node.operator.type == TokenType.PERCENT) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand.remainder(rightOperand);
        }
      } else if (node.operator.type == TokenType.PLUS) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand + rightOperand;
        }
        if (leftOperand is String && rightOperand is String) {
          return leftOperand + rightOperand;
        }
      } else if (node.operator.type == TokenType.STAR) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand * rightOperand;
        }
      } else if (node.operator.type == TokenType.SLASH) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand / rightOperand;
        }
      } else if (node.operator.type == TokenType.TILDE_SLASH) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand ~/ rightOperand;
        }
      }
      break;
    }
    // TODO(brianwilkerson) This doesn't handle numeric conversions.
    return visitExpression(node);
  }

  @override
  Object visitBooleanLiteral(BooleanLiteral node) => node.value ? true : false;

  @override
  Object visitDoubleLiteral(DoubleLiteral node) => node.value;

  @override
  Object visitIntegerLiteral(IntegerLiteral node) => node.value;

  @override
  Object visitInterpolationExpression(InterpolationExpression node) {
    Object value = node.expression.accept(this);
    if (value == null || value is bool || value is String || value is num) {
      return value;
    }
    return NOT_A_CONSTANT;
  }

  @override
  Object visitInterpolationString(InterpolationString node) => node.value;

  @override
  Object visitListLiteral(ListLiteral node) {
    List<Object> list = new List<Object>();
    for (Expression element in node.elements) {
      Object value = element.accept(this);
      if (identical(value, NOT_A_CONSTANT)) {
        return value;
      }
      list.add(value);
    }
    return list;
  }

  @override
  Object visitMapLiteral(MapLiteral node) {
    HashMap<String, Object> map = new HashMap<String, Object>();
    for (MapLiteralEntry entry in node.entries) {
      Object key = entry.key.accept(this);
      Object value = entry.value.accept(this);
      if (key is String && !identical(value, NOT_A_CONSTANT)) {
        map[key] = value;
      } else {
        return NOT_A_CONSTANT;
      }
    }
    return map;
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) => visitNode(node);

  @override
  Object visitNode(AstNode node) => NOT_A_CONSTANT;

  @override
  Object visitNullLiteral(NullLiteral node) => null;

  @override
  Object visitParenthesizedExpression(ParenthesizedExpression node) =>
      node.expression.accept(this);

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) =>
      _getConstantValue(null);

  @override
  Object visitPrefixExpression(PrefixExpression node) {
    Object operand = node.operand.accept(this);
    if (identical(operand, NOT_A_CONSTANT)) {
      return operand;
    }
    while (true) {
      if (node.operator.type == TokenType.BANG) {
        if (identical(operand, true)) {
          return false;
        } else if (identical(operand, false)) {
          return true;
        }
      } else if (node.operator.type == TokenType.TILDE) {
        if (operand is int) {
          return ~operand;
        }
      } else if (node.operator.type == TokenType.MINUS) {
        if (operand == null) {
          return null;
        } else if (operand is num) {
          return -operand;
        }
      } else {}
      break;
    }
    return NOT_A_CONSTANT;
  }

  @override
  Object visitPropertyAccess(PropertyAccess node) => _getConstantValue(null);

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) =>
      _getConstantValue(null);

  @override
  Object visitSimpleStringLiteral(SimpleStringLiteral node) => node.value;

  @override
  Object visitStringInterpolation(StringInterpolation node) {
    StringBuffer buffer = new StringBuffer();
    for (InterpolationElement element in node.elements) {
      Object value = element.accept(this);
      if (identical(value, NOT_A_CONSTANT)) {
        return value;
      }
      buffer.write(value);
    }
    return buffer.toString();
  }

  @override
  Object visitSymbolLiteral(SymbolLiteral node) {
    // TODO(brianwilkerson) This isn't optimal because a Symbol is not a String.
    StringBuffer buffer = new StringBuffer();
    for (Token component in node.components) {
      if (buffer.length > 0) {
        buffer.writeCharCode(0x2E);
      }
      buffer.write(component.lexeme);
    }
    return buffer.toString();
  }

  /**
   * Return the constant value of the static constant represented by the given
   * [element].
   */
  Object _getConstantValue(Element element) {
    // TODO(brianwilkerson) Implement this
//    if (element is FieldElement) {
//      FieldElement field = element;
//      if (field.isStatic && field.isConst) {
//        //field.getConstantValue();
//      }
//      //    } else if (element instanceof VariableElement) {
//      //      VariableElement variable = (VariableElement) element;
//      //      if (variable.isStatic() && variable.isConst()) {
//      //        //variable.getConstantValue();
//      //      }
//    }
    return NOT_A_CONSTANT;
  }
}

/**
 * A recursive AST visitor that is used to run over [Expression]s to determine
 * whether the expression is composed by at least one deferred
 * [PrefixedIdentifier].
 *
 * See [PrefixedIdentifier.isDeferred].
 */
class DeferredLibraryReferenceDetector extends RecursiveAstVisitor<Object> {
  /**
   * A flag indicating whether an identifier from a deferred library has been
   * found.
   */
  bool _result = false;

  /**
   * Return `true` if the visitor found a [PrefixedIdentifier] that returned
   * `true` to the [PrefixedIdentifier.isDeferred] query.
   */
  bool get result => _result;

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (!_result) {
      if (node.isDeferred) {
        _result = true;
      }
    }
    return null;
  }
}

/**
 * An object used to locate the [Element] associated with a given [AstNode].
 */
class ElementLocator {
  /**
   * Return the element associated with the given [node], or `null` if there is
   * no element associated with the node.
   */
  static Element locate(AstNode node) {
    if (node == null) {
      return null;
    }
    ElementLocator_ElementMapper mapper = new ElementLocator_ElementMapper();
    return node.accept(mapper);
  }
}

/**
 * Visitor that maps nodes to elements.
 */
class ElementLocator_ElementMapper extends GeneralizingAstVisitor<Element> {
  @override
  Element visitAnnotation(Annotation node) => node.element;

  @override
  Element visitAssignmentExpression(AssignmentExpression node) =>
      node.bestElement;

  @override
  Element visitBinaryExpression(BinaryExpression node) => node.bestElement;

  @override
  Element visitClassDeclaration(ClassDeclaration node) => node.element;

  @override
  Element visitCompilationUnit(CompilationUnit node) => node.element;

  @override
  Element visitConstructorDeclaration(ConstructorDeclaration node) =>
      node.element;

  @override
  Element visitExportDirective(ExportDirective node) => node.element;

  @override
  Element visitFunctionDeclaration(FunctionDeclaration node) => node.element;

  @override
  Element visitIdentifier(Identifier node) {
    AstNode parent = node.parent;
    if (parent is Annotation) {
      // Type name in Annotation
      if (identical(parent.name, node) && parent.constructorName == null) {
        return parent.element;
      }
    } else if (parent is ConstructorDeclaration) {
      // Extra work to map Constructor Declarations to their associated
      // Constructor Elements
      Identifier returnType = parent.returnType;
      if (identical(returnType, node)) {
        SimpleIdentifier name = parent.name;
        if (name != null) {
          return name.bestElement;
        }
        Element element = node.bestElement;
        if (element is ClassElement) {
          return element.unnamedConstructor;
        }
      }
    } else if (parent is LibraryIdentifier) {
      AstNode grandParent = parent.parent;
      if (grandParent is PartOfDirective) {
        Element element = grandParent.element;
        if (element is LibraryElement) {
          return element.definingCompilationUnit;
        }
      } else if (grandParent is LibraryDirective) {
        return grandParent.element;
      }
    }
    return node.bestElement;
  }

  @override
  Element visitImportDirective(ImportDirective node) => node.element;

  @override
  Element visitIndexExpression(IndexExpression node) => node.bestElement;

  @override
  Element visitInstanceCreationExpression(InstanceCreationExpression node) =>
      node.staticElement;

  @override
  Element visitLibraryDirective(LibraryDirective node) => node.element;

  @override
  Element visitMethodDeclaration(MethodDeclaration node) => node.element;

  @override
  Element visitMethodInvocation(MethodInvocation node) =>
      node.methodName.bestElement;

  @override
  Element visitPartOfDirective(PartOfDirective node) => node.element;

  @override
  Element visitPostfixExpression(PostfixExpression node) => node.bestElement;

  @override
  Element visitPrefixedIdentifier(PrefixedIdentifier node) => node.bestElement;

  @override
  Element visitPrefixExpression(PrefixExpression node) => node.bestElement;

  @override
  Element visitStringLiteral(StringLiteral node) {
    AstNode parent = node.parent;
    if (parent is UriBasedDirective) {
      return parent.uriElement;
    }
    return null;
  }

  @override
  Element visitVariableDeclaration(VariableDeclaration node) => node.element;
}

/**
 * A [DelegatingAstVisitor] that will additionally catch all exceptions from the
 * delegates without stopping the visiting. A function must be provided that
 * will be invoked for each such exception.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ExceptionHandlingDelegatingAstVisitor<T> extends DelegatingAstVisitor<T> {
  /**
   * The function that will be executed for each exception that is thrown by one
   * of the visit methods on the delegate.
   */
  final ExceptionInDelegateHandler handler;

  /**
   * Initialize a newly created visitor to use each of the given delegate
   * visitors to visit the nodes of an AST structure.
   */
  ExceptionHandlingDelegatingAstVisitor(
      Iterable<AstVisitor<T>> delegates, this.handler)
      : super(delegates) {
    if (handler == null) {
      throw new ArgumentError('A handler must be provided');
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

  /**
   * A function that can be used with instances of this class to log and then
   * ignore any exceptions that are thrown by any of the delegates.
   */
  static void logException(AstNode node, AstVisitor visitor, dynamic exception,
      StackTrace stackTrace) {
    StringBuffer buffer = new StringBuffer();
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
    AnalysisEngine.instance.logger.logError(
        buffer.toString(), new CaughtException(exception, stackTrace));
  }
}

/**
 * An object that will clone any AST structure that it visits. The cloner will
 * clone the structure, replacing the specified ASTNode with a new ASTNode,
 * mapping the old token stream to a new token stream, and preserving resolution
 * results.
 */
@deprecated
class IncrementalAstCloner implements AstVisitor<AstNode> {
  /**
   * The node to be replaced during the cloning process.
   */
  final AstNode _oldNode;

  /**
   * The replacement node used during the cloning process.
   */
  final AstNode _newNode;

  /**
   * A mapping of old tokens to new tokens used during the cloning process.
   */
  final TokenMap _tokenMap;

  /**
   * Construct a new instance that will replace the [oldNode] with the [newNode]
   * in the process of cloning an existing AST structure. The [tokenMap] is a
   * mapping of old tokens to new tokens.
   */
  IncrementalAstCloner(this._oldNode, this._newNode, this._tokenMap);

  @override
  AdjacentStrings visitAdjacentStrings(AdjacentStrings node) =>
      astFactory.adjacentStrings(_cloneNodeList(node.strings));

  @override
  Annotation visitAnnotation(Annotation node) {
    Annotation copy = astFactory.annotation(
        _mapToken(node.atSign),
        _cloneNode(node.name),
        _mapToken(node.period),
        _cloneNode(node.constructorName),
        _cloneNode(node.arguments));
    copy.element = node.element;
    return copy;
  }

  @override
  ArgumentList visitArgumentList(ArgumentList node) => astFactory.argumentList(
      _mapToken(node.leftParenthesis),
      _cloneNodeList(node.arguments),
      _mapToken(node.rightParenthesis));

  @override
  AsExpression visitAsExpression(AsExpression node) {
    AsExpression copy = astFactory.asExpression(_cloneNode(node.expression),
        _mapToken(node.asOperator), _cloneNode(node.type));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  AstNode visitAssertInitializer(AssertInitializer node) =>
      astFactory.assertInitializer(
          _mapToken(node.assertKeyword),
          _mapToken(node.leftParenthesis),
          _cloneNode(node.condition),
          _mapToken(node.comma),
          _cloneNode(node.message),
          _mapToken(node.rightParenthesis));

  @override
  AstNode visitAssertStatement(AssertStatement node) =>
      astFactory.assertStatement(
          _mapToken(node.assertKeyword),
          _mapToken(node.leftParenthesis),
          _cloneNode(node.condition),
          _mapToken(node.comma),
          _cloneNode(node.message),
          _mapToken(node.rightParenthesis),
          _mapToken(node.semicolon));

  @override
  AssignmentExpression visitAssignmentExpression(AssignmentExpression node) {
    AssignmentExpression copy = astFactory.assignmentExpression(
        _cloneNode(node.leftHandSide),
        _mapToken(node.operator),
        _cloneNode(node.rightHandSide));
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  AwaitExpression visitAwaitExpression(AwaitExpression node) =>
      astFactory.awaitExpression(
          _mapToken(node.awaitKeyword), _cloneNode(node.expression));

  @override
  BinaryExpression visitBinaryExpression(BinaryExpression node) {
    BinaryExpression copy = astFactory.binaryExpression(
        _cloneNode(node.leftOperand),
        _mapToken(node.operator),
        _cloneNode(node.rightOperand));
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  Block visitBlock(Block node) => astFactory.block(_mapToken(node.leftBracket),
      _cloneNodeList(node.statements), _mapToken(node.rightBracket));

  @override
  BlockFunctionBody visitBlockFunctionBody(BlockFunctionBody node) =>
      astFactory.blockFunctionBody(_mapToken(node.keyword),
          _mapToken(node.star), _cloneNode(node.block));

  @override
  BooleanLiteral visitBooleanLiteral(BooleanLiteral node) {
    BooleanLiteral copy =
        astFactory.booleanLiteral(_mapToken(node.literal), node.value);
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  BreakStatement visitBreakStatement(BreakStatement node) =>
      astFactory.breakStatement(_mapToken(node.breakKeyword),
          _cloneNode(node.label), _mapToken(node.semicolon));

  @override
  CascadeExpression visitCascadeExpression(CascadeExpression node) {
    CascadeExpression copy = astFactory.cascadeExpression(
        _cloneNode(node.target), _cloneNodeList(node.cascadeSections));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  CatchClause visitCatchClause(CatchClause node) => astFactory.catchClause(
      _mapToken(node.onKeyword),
      _cloneNode(node.exceptionType),
      _mapToken(node.catchKeyword),
      _mapToken(node.leftParenthesis),
      _cloneNode(node.exceptionParameter),
      _mapToken(node.comma),
      _cloneNode(node.stackTraceParameter),
      _mapToken(node.rightParenthesis),
      _cloneNode(node.body));

  @override
  ClassDeclaration visitClassDeclaration(ClassDeclaration node) {
    ClassDeclaration copy = astFactory.classDeclaration(
        _cloneNode(node.documentationComment),
        _cloneNodeList(node.metadata),
        _mapToken(node.abstractKeyword),
        _mapToken(node.classKeyword),
        _cloneNode(node.name),
        _cloneNode(node.typeParameters),
        _cloneNode(node.extendsClause),
        _cloneNode(node.withClause),
        _cloneNode(node.implementsClause),
        _mapToken(node.leftBracket),
        _cloneNodeList(node.members),
        _mapToken(node.rightBracket));
    copy.nativeClause = _cloneNode(node.nativeClause);
    return copy;
  }

  @override
  ClassTypeAlias visitClassTypeAlias(ClassTypeAlias node) =>
      astFactory.classTypeAlias(
          _cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata),
          _mapToken(node.typedefKeyword),
          _cloneNode(node.name),
          _cloneNode(node.typeParameters),
          _mapToken(node.equals),
          _mapToken(node.abstractKeyword),
          _cloneNode(node.superclass),
          _cloneNode(node.withClause),
          _cloneNode(node.implementsClause),
          _mapToken(node.semicolon));

  @override
  Comment visitComment(Comment node) {
    if (node.isDocumentation) {
      return astFactory.documentationComment(
          _mapTokens(node.tokens), _cloneNodeList(node.references));
    } else if (node.isBlock) {
      return astFactory.blockComment(_mapTokens(node.tokens));
    }
    return astFactory.endOfLineComment(_mapTokens(node.tokens));
  }

  @override
  CommentReference visitCommentReference(CommentReference node) =>
      astFactory.commentReference(
          _mapToken(node.newKeyword), _cloneNode(node.identifier));

  @override
  CompilationUnit visitCompilationUnit(CompilationUnit node) {
    CompilationUnit copy = astFactory.compilationUnit(
        _mapToken(node.beginToken),
        _cloneNode(node.scriptTag),
        _cloneNodeList(node.directives),
        _cloneNodeList(node.declarations),
        _mapToken(node.endToken));
    copy.lineInfo = node.lineInfo;
    copy.element = node.element;
    return copy;
  }

  @override
  ConditionalExpression visitConditionalExpression(ConditionalExpression node) {
    ConditionalExpression copy = astFactory.conditionalExpression(
        _cloneNode(node.condition),
        _mapToken(node.question),
        _cloneNode(node.thenExpression),
        _mapToken(node.colon),
        _cloneNode(node.elseExpression));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  Configuration visitConfiguration(Configuration node) =>
      astFactory.configuration(
          _mapToken(node.ifKeyword),
          _mapToken(node.leftParenthesis),
          _cloneNode(node.name),
          _mapToken(node.equalToken),
          _cloneNode(node.value),
          _mapToken(node.rightParenthesis),
          _cloneNode(node.uri));

  @override
  ConstructorDeclaration visitConstructorDeclaration(
      ConstructorDeclaration node) {
    ConstructorDeclaration copy = astFactory.constructorDeclaration(
        _cloneNode(node.documentationComment),
        _cloneNodeList(node.metadata),
        _mapToken(node.externalKeyword),
        _mapToken(node.constKeyword),
        _mapToken(node.factoryKeyword),
        _cloneNode(node.returnType),
        _mapToken(node.period),
        _cloneNode(node.name),
        _cloneNode(node.parameters),
        _mapToken(node.separator),
        _cloneNodeList(node.initializers),
        _cloneNode(node.redirectedConstructor),
        _cloneNode(node.body));
    copy.element = node.element;
    return copy;
  }

  @override
  ConstructorFieldInitializer visitConstructorFieldInitializer(
          ConstructorFieldInitializer node) =>
      astFactory.constructorFieldInitializer(
          _mapToken(node.thisKeyword),
          _mapToken(node.period),
          _cloneNode(node.fieldName),
          _mapToken(node.equals),
          _cloneNode(node.expression));

  @override
  ConstructorName visitConstructorName(ConstructorName node) {
    ConstructorName copy = astFactory.constructorName(
        _cloneNode(node.type), _mapToken(node.period), _cloneNode(node.name));
    copy.staticElement = node.staticElement;
    return copy;
  }

  @override
  ContinueStatement visitContinueStatement(ContinueStatement node) =>
      astFactory.continueStatement(_mapToken(node.continueKeyword),
          _cloneNode(node.label), _mapToken(node.semicolon));

  @override
  DeclaredIdentifier visitDeclaredIdentifier(DeclaredIdentifier node) =>
      astFactory.declaredIdentifier(
          _cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata),
          _mapToken(node.keyword),
          _cloneNode(node.type),
          _cloneNode(node.identifier));

  @override
  DefaultFormalParameter visitDefaultFormalParameter(
          DefaultFormalParameter node) =>
      astFactory.defaultFormalParameter(_cloneNode(node.parameter), node.kind,
          _mapToken(node.separator), _cloneNode(node.defaultValue));

  @override
  DoStatement visitDoStatement(DoStatement node) => astFactory.doStatement(
      _mapToken(node.doKeyword),
      _cloneNode(node.body),
      _mapToken(node.whileKeyword),
      _mapToken(node.leftParenthesis),
      _cloneNode(node.condition),
      _mapToken(node.rightParenthesis),
      _mapToken(node.semicolon));

  @override
  DottedName visitDottedName(DottedName node) =>
      astFactory.dottedName(_cloneNodeList(node.components));

  @override
  DoubleLiteral visitDoubleLiteral(DoubleLiteral node) {
    DoubleLiteral copy =
        astFactory.doubleLiteral(_mapToken(node.literal), node.value);
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  EmptyFunctionBody visitEmptyFunctionBody(EmptyFunctionBody node) =>
      astFactory.emptyFunctionBody(_mapToken(node.semicolon));

  @override
  EmptyStatement visitEmptyStatement(EmptyStatement node) =>
      astFactory.emptyStatement(_mapToken(node.semicolon));

  @override
  AstNode visitEnumConstantDeclaration(EnumConstantDeclaration node) =>
      astFactory.enumConstantDeclaration(_cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata), _cloneNode(node.name));

  @override
  AstNode visitEnumDeclaration(EnumDeclaration node) =>
      astFactory.enumDeclaration(
          _cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata),
          _mapToken(node.enumKeyword),
          _cloneNode(node.name),
          _mapToken(node.leftBracket),
          _cloneNodeList(node.constants),
          _mapToken(node.rightBracket));

  @override
  ExportDirective visitExportDirective(ExportDirective node) {
    ExportDirective copy = astFactory.exportDirective(
        _cloneNode(node.documentationComment),
        _cloneNodeList(node.metadata),
        _mapToken(node.keyword),
        _cloneNode(node.uri),
        _cloneNodeList(node.configurations),
        _cloneNodeList(node.combinators),
        _mapToken(node.semicolon));
    copy.element = node.element;
    return copy;
  }

  @override
  ExpressionFunctionBody visitExpressionFunctionBody(
          ExpressionFunctionBody node) =>
      astFactory.expressionFunctionBody(
          _mapToken(node.keyword),
          _mapToken(node.functionDefinition),
          _cloneNode(node.expression),
          _mapToken(node.semicolon));

  @override
  ExpressionStatement visitExpressionStatement(ExpressionStatement node) =>
      astFactory.expressionStatement(
          _cloneNode(node.expression), _mapToken(node.semicolon));

  @override
  ExtendsClause visitExtendsClause(ExtendsClause node) =>
      astFactory.extendsClause(
          _mapToken(node.extendsKeyword), _cloneNode(node.superclass));

  @override
  FieldDeclaration visitFieldDeclaration(FieldDeclaration node) =>
      astFactory.fieldDeclaration2(
          comment: _cloneNode(node.documentationComment),
          metadata: _cloneNodeList(node.metadata),
          covariantKeyword: _mapToken(node.covariantKeyword),
          staticKeyword: _mapToken(node.staticKeyword),
          fieldList: _cloneNode(node.fields),
          semicolon: _mapToken(node.semicolon));

  @override
  FieldFormalParameter visitFieldFormalParameter(FieldFormalParameter node) =>
      astFactory.fieldFormalParameter2(
          comment: _cloneNode(node.documentationComment),
          metadata: _cloneNodeList(node.metadata),
          covariantKeyword: _mapToken(node.covariantKeyword),
          keyword: _mapToken(node.keyword),
          type: _cloneNode(node.type),
          thisKeyword: _mapToken(node.thisKeyword),
          period: _mapToken(node.period),
          identifier: _cloneNode(node.identifier),
          typeParameters: _cloneNode(node.typeParameters),
          parameters: _cloneNode(node.parameters));

  @override
  ForEachStatement visitForEachStatement(ForEachStatement node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (loopVariable == null) {
      return astFactory.forEachStatementWithReference(
          _mapToken(node.awaitKeyword),
          _mapToken(node.forKeyword),
          _mapToken(node.leftParenthesis),
          _cloneNode(node.identifier),
          _mapToken(node.inKeyword),
          _cloneNode(node.iterable),
          _mapToken(node.rightParenthesis),
          _cloneNode(node.body));
    }
    return astFactory.forEachStatementWithDeclaration(
        _mapToken(node.awaitKeyword),
        _mapToken(node.forKeyword),
        _mapToken(node.leftParenthesis),
        _cloneNode(loopVariable),
        _mapToken(node.inKeyword),
        _cloneNode(node.iterable),
        _mapToken(node.rightParenthesis),
        _cloneNode(node.body));
  }

  @override
  FormalParameterList visitFormalParameterList(FormalParameterList node) =>
      astFactory.formalParameterList(
          _mapToken(node.leftParenthesis),
          _cloneNodeList(node.parameters),
          _mapToken(node.leftDelimiter),
          _mapToken(node.rightDelimiter),
          _mapToken(node.rightParenthesis));

  @override
  ForStatement visitForStatement(ForStatement node) => astFactory.forStatement(
      _mapToken(node.forKeyword),
      _mapToken(node.leftParenthesis),
      _cloneNode(node.variables),
      _cloneNode(node.initialization),
      _mapToken(node.leftSeparator),
      _cloneNode(node.condition),
      _mapToken(node.rightSeparator),
      _cloneNodeList(node.updaters),
      _mapToken(node.rightParenthesis),
      _cloneNode(node.body));

  @override
  FunctionDeclaration visitFunctionDeclaration(FunctionDeclaration node) =>
      astFactory.functionDeclaration(
          _cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata),
          _mapToken(node.externalKeyword),
          _cloneNode(node.returnType),
          _mapToken(node.propertyKeyword),
          _cloneNode(node.name),
          _cloneNode(node.functionExpression));

  @override
  FunctionDeclarationStatement visitFunctionDeclarationStatement(
          FunctionDeclarationStatement node) =>
      astFactory
          .functionDeclarationStatement(_cloneNode(node.functionDeclaration));

  @override
  FunctionExpression visitFunctionExpression(FunctionExpression node) {
    FunctionExpression copy = astFactory.functionExpression(
        _cloneNode(node.typeParameters),
        _cloneNode(node.parameters),
        _cloneNode(node.body));
    copy.element = node.element;
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  FunctionExpressionInvocation visitFunctionExpressionInvocation(
      FunctionExpressionInvocation node) {
    FunctionExpressionInvocation copy = astFactory.functionExpressionInvocation(
        _cloneNode(node.function),
        _cloneNode(node.typeArguments),
        _cloneNode(node.argumentList));
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  FunctionTypeAlias visitFunctionTypeAlias(FunctionTypeAlias node) =>
      astFactory.functionTypeAlias(
          _cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata),
          _mapToken(node.typedefKeyword),
          _cloneNode(node.returnType),
          _cloneNode(node.name),
          _cloneNode(node.typeParameters),
          _cloneNode(node.parameters),
          _mapToken(node.semicolon));

  @override
  FunctionTypedFormalParameter visitFunctionTypedFormalParameter(
          FunctionTypedFormalParameter node) =>
      astFactory.functionTypedFormalParameter2(
          comment: _cloneNode(node.documentationComment),
          metadata: _cloneNodeList(node.metadata),
          covariantKeyword: _mapToken(node.covariantKeyword),
          returnType: _cloneNode(node.returnType),
          identifier: _cloneNode(node.identifier),
          typeParameters: _cloneNode(node.typeParameters),
          parameters: _cloneNode(node.parameters));

  @override
  AstNode visitGenericFunctionType(GenericFunctionType node) =>
      astFactory.genericFunctionType(
          _cloneNode(node.returnType),
          _mapToken(node.functionKeyword),
          _cloneNode(node.typeParameters),
          _cloneNode(node.parameters));

  @override
  AstNode visitGenericTypeAlias(GenericTypeAlias node) =>
      astFactory.genericTypeAlias(
          _cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata),
          _mapToken(node.typedefKeyword),
          _cloneNode(node.name),
          _cloneNode(node.typeParameters),
          _mapToken(node.equals),
          _cloneNode(node.functionType),
          _mapToken(node.semicolon));

  @override
  HideCombinator visitHideCombinator(HideCombinator node) =>
      astFactory.hideCombinator(
          _mapToken(node.keyword), _cloneNodeList(node.hiddenNames));

  @override
  IfStatement visitIfStatement(IfStatement node) => astFactory.ifStatement(
      _mapToken(node.ifKeyword),
      _mapToken(node.leftParenthesis),
      _cloneNode(node.condition),
      _mapToken(node.rightParenthesis),
      _cloneNode(node.thenStatement),
      _mapToken(node.elseKeyword),
      _cloneNode(node.elseStatement));

  @override
  ImplementsClause visitImplementsClause(ImplementsClause node) =>
      astFactory.implementsClause(
          _mapToken(node.implementsKeyword), _cloneNodeList(node.interfaces));

  @override
  ImportDirective visitImportDirective(ImportDirective node) {
    ImportDirective copy = astFactory.importDirective(
        _cloneNode(node.documentationComment),
        _cloneNodeList(node.metadata),
        _mapToken(node.keyword),
        _cloneNode(node.uri),
        _cloneNodeList(node.configurations),
        _mapToken(node.deferredKeyword),
        _mapToken(node.asKeyword),
        _cloneNode(node.prefix),
        _cloneNodeList(node.combinators),
        _mapToken(node.semicolon));
    copy.element = node.element;
    return copy;
  }

  @override
  IndexExpression visitIndexExpression(IndexExpression node) {
    Token period = _mapToken(node.period);
    IndexExpression copy;
    if (period == null) {
      copy = astFactory.indexExpressionForTarget(
          _cloneNode(node.target),
          _mapToken(node.leftBracket),
          _cloneNode(node.index),
          _mapToken(node.rightBracket));
    } else {
      copy = astFactory.indexExpressionForCascade(
          period,
          _mapToken(node.leftBracket),
          _cloneNode(node.index),
          _mapToken(node.rightBracket));
    }
    copy.auxiliaryElements = node.auxiliaryElements;
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  InstanceCreationExpression visitInstanceCreationExpression(
      InstanceCreationExpression node) {
    InstanceCreationExpression copy = astFactory.instanceCreationExpression(
        _mapToken(node.keyword),
        _cloneNode(node.constructorName),
        _cloneNode(node.argumentList));
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  IntegerLiteral visitIntegerLiteral(IntegerLiteral node) {
    IntegerLiteral copy =
        astFactory.integerLiteral(_mapToken(node.literal), node.value);
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  InterpolationExpression visitInterpolationExpression(
          InterpolationExpression node) =>
      astFactory.interpolationExpression(_mapToken(node.leftBracket),
          _cloneNode(node.expression), _mapToken(node.rightBracket));

  @override
  InterpolationString visitInterpolationString(InterpolationString node) =>
      astFactory.interpolationString(_mapToken(node.contents), node.value);

  @override
  IsExpression visitIsExpression(IsExpression node) {
    IsExpression copy = astFactory.isExpression(
        _cloneNode(node.expression),
        _mapToken(node.isOperator),
        _mapToken(node.notOperator),
        _cloneNode(node.type));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  Label visitLabel(Label node) =>
      astFactory.label(_cloneNode(node.label), _mapToken(node.colon));

  @override
  LabeledStatement visitLabeledStatement(LabeledStatement node) =>
      astFactory.labeledStatement(
          _cloneNodeList(node.labels), _cloneNode(node.statement));

  @override
  LibraryDirective visitLibraryDirective(LibraryDirective node) {
    LibraryDirective copy = astFactory.libraryDirective(
        _cloneNode(node.documentationComment),
        _cloneNodeList(node.metadata),
        _mapToken(node.libraryKeyword),
        _cloneNode(node.name),
        _mapToken(node.semicolon));
    copy.element = node.element;
    return copy;
  }

  @override
  LibraryIdentifier visitLibraryIdentifier(LibraryIdentifier node) {
    LibraryIdentifier copy =
        astFactory.libraryIdentifier(_cloneNodeList(node.components));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  ListLiteral visitListLiteral(ListLiteral node) {
    ListLiteral copy = astFactory.listLiteral(
        _mapToken(node.constKeyword),
        _cloneNode(node.typeArguments),
        _mapToken(node.leftBracket),
        _cloneNodeList(node.elements),
        _mapToken(node.rightBracket));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  MapLiteral visitMapLiteral(MapLiteral node) {
    MapLiteral copy = astFactory.mapLiteral(
        _mapToken(node.constKeyword),
        _cloneNode(node.typeArguments),
        _mapToken(node.leftBracket),
        _cloneNodeList(node.entries),
        _mapToken(node.rightBracket));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  MapLiteralEntry visitMapLiteralEntry(MapLiteralEntry node) =>
      astFactory.mapLiteralEntry(_cloneNode(node.key),
          _mapToken(node.separator), _cloneNode(node.value));

  @override
  MethodDeclaration visitMethodDeclaration(MethodDeclaration node) =>
      astFactory.methodDeclaration(
          _cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata),
          _mapToken(node.externalKeyword),
          _mapToken(node.modifierKeyword),
          _cloneNode(node.returnType),
          _mapToken(node.propertyKeyword),
          _mapToken(node.operatorKeyword),
          _cloneNode(node.name),
          _cloneNode(node.typeParameters),
          _cloneNode(node.parameters),
          _cloneNode(node.body));

  @override
  MethodInvocation visitMethodInvocation(MethodInvocation node) {
    MethodInvocation copy = astFactory.methodInvocation(
        _cloneNode(node.target),
        _mapToken(node.operator),
        _cloneNode(node.methodName),
        _cloneNode(node.typeArguments),
        _cloneNode(node.argumentList));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  NamedExpression visitNamedExpression(NamedExpression node) {
    NamedExpression copy = astFactory.namedExpression(
        _cloneNode(node.name), _cloneNode(node.expression));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  AstNode visitNativeClause(NativeClause node) => astFactory.nativeClause(
      _mapToken(node.nativeKeyword), _cloneNode(node.name));

  @override
  NativeFunctionBody visitNativeFunctionBody(NativeFunctionBody node) =>
      astFactory.nativeFunctionBody(_mapToken(node.nativeKeyword),
          _cloneNode(node.stringLiteral), _mapToken(node.semicolon));

  @override
  NullLiteral visitNullLiteral(NullLiteral node) {
    NullLiteral copy = astFactory.nullLiteral(_mapToken(node.literal));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  ParenthesizedExpression visitParenthesizedExpression(
      ParenthesizedExpression node) {
    ParenthesizedExpression copy = astFactory.parenthesizedExpression(
        _mapToken(node.leftParenthesis),
        _cloneNode(node.expression),
        _mapToken(node.rightParenthesis));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  PartDirective visitPartDirective(PartDirective node) {
    PartDirective copy = astFactory.partDirective(
        _cloneNode(node.documentationComment),
        _cloneNodeList(node.metadata),
        _mapToken(node.partKeyword),
        _cloneNode(node.uri),
        _mapToken(node.semicolon));
    copy.element = node.element;
    return copy;
  }

  @override
  PartOfDirective visitPartOfDirective(PartOfDirective node) {
    PartOfDirective copy = astFactory.partOfDirective(
        _cloneNode(node.documentationComment),
        _cloneNodeList(node.metadata),
        _mapToken(node.partKeyword),
        _mapToken(node.ofKeyword),
        _cloneNode(node.uri),
        _cloneNode(node.libraryName),
        _mapToken(node.semicolon));
    copy.element = node.element;
    return copy;
  }

  @override
  PostfixExpression visitPostfixExpression(PostfixExpression node) {
    PostfixExpression copy = astFactory.postfixExpression(
        _cloneNode(node.operand), _mapToken(node.operator));
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  PrefixedIdentifier visitPrefixedIdentifier(PrefixedIdentifier node) {
    PrefixedIdentifier copy = astFactory.prefixedIdentifier(
        _cloneNode(node.prefix),
        _mapToken(node.period),
        _cloneNode(node.identifier));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  PrefixExpression visitPrefixExpression(PrefixExpression node) {
    PrefixExpression copy = astFactory.prefixExpression(
        _mapToken(node.operator), _cloneNode(node.operand));
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  PropertyAccess visitPropertyAccess(PropertyAccess node) {
    PropertyAccess copy = astFactory.propertyAccess(_cloneNode(node.target),
        _mapToken(node.operator), _cloneNode(node.propertyName));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  RedirectingConstructorInvocation visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    RedirectingConstructorInvocation copy =
        astFactory.redirectingConstructorInvocation(
            _mapToken(node.thisKeyword),
            _mapToken(node.period),
            _cloneNode(node.constructorName),
            _cloneNode(node.argumentList));
    copy.staticElement = node.staticElement;
    return copy;
  }

  @override
  RethrowExpression visitRethrowExpression(RethrowExpression node) {
    RethrowExpression copy =
        astFactory.rethrowExpression(_mapToken(node.rethrowKeyword));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  ReturnStatement visitReturnStatement(ReturnStatement node) =>
      astFactory.returnStatement(_mapToken(node.returnKeyword),
          _cloneNode(node.expression), _mapToken(node.semicolon));

  @override
  ScriptTag visitScriptTag(ScriptTag node) =>
      astFactory.scriptTag(_mapToken(node.scriptTag));

  @override
  ShowCombinator visitShowCombinator(ShowCombinator node) => astFactory
      .showCombinator(_mapToken(node.keyword), _cloneNodeList(node.shownNames));

  @override
  SimpleFormalParameter visitSimpleFormalParameter(
          SimpleFormalParameter node) =>
      astFactory.simpleFormalParameter2(
          comment: _cloneNode(node.documentationComment),
          metadata: _cloneNodeList(node.metadata),
          covariantKeyword: _mapToken(node.covariantKeyword),
          keyword: _mapToken(node.keyword),
          type: _cloneNode(node.type),
          identifier: _cloneNode(node.identifier));

  @override
  SimpleIdentifier visitSimpleIdentifier(SimpleIdentifier node) {
    Token mappedToken = _mapToken(node.token);
    if (mappedToken == null) {
      // This only happens for SimpleIdentifiers created by the parser as part
      // of scanning documentation comments (the tokens for those identifiers
      // are not in the original token stream and hence do not get copied).
      // This extra check can be removed if the scanner is changed to scan
      // documentation comments for the parser.
      mappedToken = node.token;
    }
    SimpleIdentifier copy = astFactory.simpleIdentifier(mappedToken,
        isDeclaration: node.inDeclarationContext());
    copy.auxiliaryElements = node.auxiliaryElements;
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  SimpleStringLiteral visitSimpleStringLiteral(SimpleStringLiteral node) {
    SimpleStringLiteral copy =
        astFactory.simpleStringLiteral(_mapToken(node.literal), node.value);
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  StringInterpolation visitStringInterpolation(StringInterpolation node) {
    StringInterpolation copy =
        astFactory.stringInterpolation(_cloneNodeList(node.elements));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  SuperConstructorInvocation visitSuperConstructorInvocation(
      SuperConstructorInvocation node) {
    SuperConstructorInvocation copy = astFactory.superConstructorInvocation(
        _mapToken(node.superKeyword),
        _mapToken(node.period),
        _cloneNode(node.constructorName),
        _cloneNode(node.argumentList));
    copy.staticElement = node.staticElement;
    return copy;
  }

  @override
  SuperExpression visitSuperExpression(SuperExpression node) {
    SuperExpression copy =
        astFactory.superExpression(_mapToken(node.superKeyword));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  SwitchCase visitSwitchCase(SwitchCase node) => astFactory.switchCase(
      _cloneNodeList(node.labels),
      _mapToken(node.keyword),
      _cloneNode(node.expression),
      _mapToken(node.colon),
      _cloneNodeList(node.statements));

  @override
  SwitchDefault visitSwitchDefault(SwitchDefault node) =>
      astFactory.switchDefault(
          _cloneNodeList(node.labels),
          _mapToken(node.keyword),
          _mapToken(node.colon),
          _cloneNodeList(node.statements));

  @override
  SwitchStatement visitSwitchStatement(SwitchStatement node) =>
      astFactory.switchStatement(
          _mapToken(node.switchKeyword),
          _mapToken(node.leftParenthesis),
          _cloneNode(node.expression),
          _mapToken(node.rightParenthesis),
          _mapToken(node.leftBracket),
          _cloneNodeList(node.members),
          _mapToken(node.rightBracket));

  @override
  AstNode visitSymbolLiteral(SymbolLiteral node) {
    SymbolLiteral copy = astFactory.symbolLiteral(
        _mapToken(node.poundSign), _mapTokens(node.components));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  ThisExpression visitThisExpression(ThisExpression node) {
    ThisExpression copy =
        astFactory.thisExpression(_mapToken(node.thisKeyword));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  ThrowExpression visitThrowExpression(ThrowExpression node) {
    ThrowExpression copy = astFactory.throwExpression(
        _mapToken(node.throwKeyword), _cloneNode(node.expression));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  TopLevelVariableDeclaration visitTopLevelVariableDeclaration(
          TopLevelVariableDeclaration node) =>
      astFactory.topLevelVariableDeclaration(
          _cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata),
          _cloneNode(node.variables),
          _mapToken(node.semicolon));

  @override
  TryStatement visitTryStatement(TryStatement node) => astFactory.tryStatement(
      _mapToken(node.tryKeyword),
      _cloneNode(node.body),
      _cloneNodeList(node.catchClauses),
      _mapToken(node.finallyKeyword),
      _cloneNode(node.finallyBlock));

  @override
  TypeArgumentList visitTypeArgumentList(TypeArgumentList node) =>
      astFactory.typeArgumentList(_mapToken(node.leftBracket),
          _cloneNodeList(node.arguments), _mapToken(node.rightBracket));

  @override
  TypeName visitTypeName(TypeName node) {
    TypeName copy = astFactory.typeName(
        _cloneNode(node.name), _cloneNode(node.typeArguments));
    copy.type = node.type;
    return copy;
  }

  @override
  TypeParameter visitTypeParameter(TypeParameter node) =>
      astFactory.typeParameter(
          _cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata),
          _cloneNode(node.name),
          _mapToken(node.extendsKeyword),
          _cloneNode(node.bound));

  @override
  TypeParameterList visitTypeParameterList(TypeParameterList node) =>
      astFactory.typeParameterList(_mapToken(node.leftBracket),
          _cloneNodeList(node.typeParameters), _mapToken(node.rightBracket));

  @override
  VariableDeclaration visitVariableDeclaration(VariableDeclaration node) =>
      astFactory.variableDeclaration(_cloneNode(node.name),
          _mapToken(node.equals), _cloneNode(node.initializer));

  @override
  VariableDeclarationList visitVariableDeclarationList(
          VariableDeclarationList node) =>
      astFactory.variableDeclarationList(
          null,
          _cloneNodeList(node.metadata),
          _mapToken(node.keyword),
          _cloneNode(node.type),
          _cloneNodeList(node.variables));

  @override
  VariableDeclarationStatement visitVariableDeclarationStatement(
          VariableDeclarationStatement node) =>
      astFactory.variableDeclarationStatement(
          _cloneNode(node.variables), _mapToken(node.semicolon));

  @override
  WhileStatement visitWhileStatement(WhileStatement node) =>
      astFactory.whileStatement(
          _mapToken(node.whileKeyword),
          _mapToken(node.leftParenthesis),
          _cloneNode(node.condition),
          _mapToken(node.rightParenthesis),
          _cloneNode(node.body));

  @override
  WithClause visitWithClause(WithClause node) => astFactory.withClause(
      _mapToken(node.withKeyword), _cloneNodeList(node.mixinTypes));

  @override
  YieldStatement visitYieldStatement(YieldStatement node) =>
      astFactory.yieldStatement(
          _mapToken(node.yieldKeyword),
          _mapToken(node.star),
          _cloneNode(node.expression),
          _mapToken(node.semicolon));

  AstNode/*=E*/ _cloneNode/*<E extends AstNode>*/(AstNode/*=E*/ node) {
    if (node == null) {
      return null;
    }
    if (identical(node, _oldNode)) {
      return _newNode as AstNode/*=E*/;
    }
    return node.accept(this) as AstNode/*=E*/;
  }

  List/*<E>*/ _cloneNodeList/*<E extends AstNode>*/(NodeList/*<E>*/ nodes) {
    List/*<E>*/ clonedNodes = new List/*<E>*/();
    for (AstNode/*=E*/ node in nodes) {
      clonedNodes.add(_cloneNode(node));
    }
    return clonedNodes;
  }

  Token _mapToken(Token oldToken) {
    if (oldToken == null) {
      return null;
    }
    return _tokenMap.get(oldToken);
  }

  List<Token> _mapTokens(List<Token> oldTokens) {
    List<Token> newTokens = new List<Token>(oldTokens.length);
    for (int index = 0; index < newTokens.length; index++) {
      newTokens[index] = _mapToken(oldTokens[index]);
    }
    return newTokens;
  }
}

/**
 * An object used to locate the [AstNode] associated with a source range, given
 * the AST structure built from the source. More specifically, they will return
 * the [AstNode] with the shortest length whose source range completely
 * encompasses the specified range.
 */
class NodeLocator extends UnifyingAstVisitor<Object> {
  /**
   * The start offset of the range used to identify the node.
   */
  int _startOffset = 0;

  /**
   * The end offset of the range used to identify the node.
   */
  int _endOffset = 0;

  /**
   * The element that was found that corresponds to the given source range, or
   * `null` if there is no such element.
   */
  AstNode _foundNode;

  /**
   * Initialize a newly created locator to locate an [AstNode] by locating the
   * node within an AST structure that corresponds to the given range of
   * characters (between the [startOffset] and [endOffset] in the source.
   */
  NodeLocator(int startOffset, [int endOffset])
      : this._startOffset = startOffset,
        this._endOffset = endOffset ?? startOffset;

  /**
   * Return the node that was found that corresponds to the given source range
   * or `null` if there is no such node.
   */
  AstNode get foundNode => _foundNode;

  /**
   * Search within the given AST [node] for an identifier representing an
   * element in the specified source range. Return the element that was found,
   * or `null` if no element was found.
   */
  AstNode searchWithin(AstNode node) {
    if (node == null) {
      return null;
    }
    try {
      node.accept(this);
    } catch (exception, stackTrace) {
      AnalysisEngine.instance.logger.logInformation(
          "Unable to locate element at offset ($_startOffset - $_endOffset)",
          new CaughtException(exception, stackTrace));
      return null;
    }
    return _foundNode;
  }

  @override
  Object visitNode(AstNode node) {
    // Don't visit a new tree if the result has been already found.
    if (_foundNode != null) {
      return null;
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
    if (end < _startOffset) {
      return null;
    }
    if (start > _endOffset) {
      return null;
    }
    // Check children.
    try {
      node.visitChildren(this);
    } catch (exception, stackTrace) {
      // Ignore the exception and proceed in order to visit the rest of the
      // structure.
      AnalysisEngine.instance.logger.logInformation(
          "Exception caught while traversing an AST structure.",
          new CaughtException(exception, stackTrace));
    }
    // Found a child.
    if (_foundNode != null) {
      return null;
    }
    // Check this node.
    if (start <= _startOffset && _endOffset <= end) {
      _foundNode = node;
    }
    return null;
  }
}

/**
 * An object used to locate the [AstNode] associated with a source range.
 * More specifically, they will return the deepest [AstNode] which completely
 * encompasses the specified range.
 */
class NodeLocator2 extends UnifyingAstVisitor<Object> {
  /**
   * The inclusive start offset of the range used to identify the node.
   */
  int _startOffset = 0;

  /**
   * The inclusive end offset of the range used to identify the node.
   */
  int _endOffset = 0;

  /**
   * The found node or `null` if there is no such node.
   */
  AstNode _foundNode;

  /**
   * Initialize a newly created locator to locate the deepest [AstNode] for
   * which `node.offset <= [startOffset]` and `[endOffset] < node.end`.
   *
   * If [endOffset] is not provided, then it is considered the same as the
   * given [startOffset].
   */
  NodeLocator2(int startOffset, [int endOffset])
      : this._startOffset = startOffset,
        this._endOffset = endOffset ?? startOffset;

  /**
   * Search within the given AST [node] and return the node that was found,
   * or `null` if no node was found.
   */
  AstNode searchWithin(AstNode node) {
    if (node == null) {
      return null;
    }
    try {
      node.accept(this);
    } catch (exception, stackTrace) {
      AnalysisEngine.instance.logger.logInformation(
          "Unable to locate element at offset ($_startOffset - $_endOffset)",
          new CaughtException(exception, stackTrace));
      return null;
    }
    return _foundNode;
  }

  @override
  Object visitNode(AstNode node) {
    // Don't visit a new tree if the result has been already found.
    if (_foundNode != null) {
      return null;
    }
    // Check whether the current node covers the selection.
    Token beginToken = node.beginToken;
    Token endToken = node.endToken;
    // Don't include synthetic tokens.
    while (endToken != beginToken) {
      if (endToken.type == TokenType.EOF || !endToken.isSynthetic) {
        break;
      }
      endToken = endToken.previous;
    }
    int end = endToken.end;
    int start = node.offset;
    if (end <= _startOffset) {
      return null;
    }
    if (start > _endOffset) {
      return null;
    }
    // Check children.
    try {
      node.visitChildren(this);
    } catch (exception, stackTrace) {
      // Ignore the exception and proceed in order to visit the rest of the
      // structure.
      AnalysisEngine.instance.logger.logInformation(
          "Exception caught while traversing an AST structure.",
          new CaughtException(exception, stackTrace));
    }
    // Found a child.
    if (_foundNode != null) {
      return null;
    }
    // Check this node.
    if (start <= _startOffset && _endOffset < end) {
      _foundNode = node;
    }
    return null;
  }
}

/**
 * An object that will replace one child node in an AST node with another node.
 */
class NodeReplacer implements AstVisitor<bool> {
  /**
   * The node being replaced.
   */
  final AstNode _oldNode;

  /**
   * The node that is replacing the old node.
   */
  final AstNode _newNode;

  /**
   * Initialize a newly created node locator to replace the [_oldNode] with the
   * [_newNode].
   */
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
  bool visitForEachStatement(ForEachStatement node) {
    if (identical(node.loopVariable, _oldNode)) {
      node.loopVariable = _newNode as DeclaredIdentifier;
      return true;
    } else if (identical(node.identifier, _oldNode)) {
      node.identifier = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.iterable, _oldNode)) {
      node.iterable = _newNode as Expression;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as Statement;
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
  bool visitForStatement(ForStatement node) {
    if (identical(node.variables, _oldNode)) {
      node.variables = _newNode as VariableDeclarationList;
      return true;
    } else if (identical(node.initialization, _oldNode)) {
      node.initialization = _newNode as Expression;
      return true;
    } else if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as Statement;
      return true;
    } else if (_replaceInList(node.updaters)) {
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
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterList;
      return true;
    } else if (identical(node.functionType, _oldNode)) {
      node.functionType = _newNode as GenericFunctionType;
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
  bool visitMapLiteral(MapLiteral node) {
    if (_replaceInList(node.entries)) {
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
    throw new ArgumentError("The old node is not a child of it's parent");
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

  /**
   * Replace the [oldNode] with the [newNode] in the AST structure containing
   * the old node. Return `true` if the replacement was successful.
   *
   * Throws an [ArgumentError] if either node is `null`, if the old node does
   * not have a parent node, or if the AST structure has been corrupted.
   */
  static bool replace(AstNode oldNode, AstNode newNode) {
    if (oldNode == null || newNode == null) {
      throw new ArgumentError("The old and new nodes must be non-null");
    } else if (identical(oldNode, newNode)) {
      return true;
    }
    AstNode parent = oldNode.parent;
    if (parent == null) {
      throw new ArgumentError("The old node is not a child of another node");
    }
    NodeReplacer replacer = new NodeReplacer(oldNode, newNode);
    return parent.accept(replacer);
  }
}

/**
 * An object that copies resolution information from one AST structure to
 * another as long as the structures of the corresponding children of a pair of
 * nodes are the same.
 */
class ResolutionCopier implements AstVisitor<bool> {
  /**
   * The AST node with which the node being visited is to be compared. This is
   * only valid at the beginning of each visit method (until [isEqualNodes] is
   * invoked).
   */
  AstNode _toNode;

  @override
  bool visitAdjacentStrings(AdjacentStrings node) {
    AdjacentStrings toNode = this._toNode as AdjacentStrings;
    if (_isEqualNodeLists(node.strings, toNode.strings)) {
      toNode.staticType = node.staticType;
      toNode.propagatedType = node.propagatedType;
      return true;
    }
    return false;
  }

  @override
  bool visitAnnotation(Annotation node) {
    Annotation toNode = this._toNode as Annotation;
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
    ArgumentList toNode = this._toNode as ArgumentList;
    return _and(
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodeLists(node.arguments, toNode.arguments),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis));
  }

  @override
  bool visitAsExpression(AsExpression node) {
    AsExpression toNode = this._toNode as AsExpression;
    if (_and(
        _isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.asOperator, toNode.asOperator),
        _isEqualNodes(node.type, toNode.type))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitAssertInitializer(AssertInitializer node) {
    AssertInitializer toNode = this._toNode as AssertInitializer;
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
    AssertStatement toNode = this._toNode as AssertStatement;
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
    AssignmentExpression toNode = this._toNode as AssignmentExpression;
    if (_and(
        _isEqualNodes(node.leftHandSide, toNode.leftHandSide),
        _isEqualTokens(node.operator, toNode.operator),
        _isEqualNodes(node.rightHandSide, toNode.rightHandSide))) {
      toNode.propagatedElement = node.propagatedElement;
      toNode.propagatedType = node.propagatedType;
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitAwaitExpression(AwaitExpression node) {
    AwaitExpression toNode = this._toNode as AwaitExpression;
    if (_and(_isEqualTokens(node.awaitKeyword, toNode.awaitKeyword),
        _isEqualNodes(node.expression, toNode.expression))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitBinaryExpression(BinaryExpression node) {
    BinaryExpression toNode = this._toNode as BinaryExpression;
    if (_and(
        _isEqualNodes(node.leftOperand, toNode.leftOperand),
        _isEqualTokens(node.operator, toNode.operator),
        _isEqualNodes(node.rightOperand, toNode.rightOperand))) {
      toNode.propagatedElement = node.propagatedElement;
      toNode.propagatedType = node.propagatedType;
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitBlock(Block node) {
    Block toNode = this._toNode as Block;
    return _and(
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodeLists(node.statements, toNode.statements),
        _isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  @override
  bool visitBlockFunctionBody(BlockFunctionBody node) {
    BlockFunctionBody toNode = this._toNode as BlockFunctionBody;
    return _isEqualNodes(node.block, toNode.block);
  }

  @override
  bool visitBooleanLiteral(BooleanLiteral node) {
    BooleanLiteral toNode = this._toNode as BooleanLiteral;
    if (_and(_isEqualTokens(node.literal, toNode.literal),
        node.value == toNode.value)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitBreakStatement(BreakStatement node) {
    BreakStatement toNode = this._toNode as BreakStatement;
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
    CascadeExpression toNode = this._toNode as CascadeExpression;
    if (_and(_isEqualNodes(node.target, toNode.target),
        _isEqualNodeLists(node.cascadeSections, toNode.cascadeSections))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitCatchClause(CatchClause node) {
    CatchClause toNode = this._toNode as CatchClause;
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
    ClassDeclaration toNode = this._toNode as ClassDeclaration;
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
    ClassTypeAlias toNode = this._toNode as ClassTypeAlias;
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
    Comment toNode = this._toNode as Comment;
    return _isEqualNodeLists(node.references, toNode.references);
  }

  @override
  bool visitCommentReference(CommentReference node) {
    CommentReference toNode = this._toNode as CommentReference;
    return _and(_isEqualTokens(node.newKeyword, toNode.newKeyword),
        _isEqualNodes(node.identifier, toNode.identifier));
  }

  @override
  bool visitCompilationUnit(CompilationUnit node) {
    CompilationUnit toNode = this._toNode as CompilationUnit;
    if (_and(
        _isEqualTokens(node.beginToken, toNode.beginToken),
        _isEqualNodes(node.scriptTag, toNode.scriptTag),
        _isEqualNodeLists(node.directives, toNode.directives),
        _isEqualNodeLists(node.declarations, toNode.declarations),
        _isEqualTokens(node.endToken, toNode.endToken))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  @override
  bool visitConditionalExpression(ConditionalExpression node) {
    ConditionalExpression toNode = this._toNode as ConditionalExpression;
    if (_and(
        _isEqualNodes(node.condition, toNode.condition),
        _isEqualTokens(node.question, toNode.question),
        _isEqualNodes(node.thenExpression, toNode.thenExpression),
        _isEqualTokens(node.colon, toNode.colon),
        _isEqualNodes(node.elseExpression, toNode.elseExpression))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitConfiguration(Configuration node) {
    Configuration toNode = this._toNode as Configuration;
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
    ConstructorDeclaration toNode = this._toNode as ConstructorDeclaration;
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
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  @override
  bool visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    ConstructorFieldInitializer toNode =
        this._toNode as ConstructorFieldInitializer;
    return _and(
        _isEqualTokens(node.thisKeyword, toNode.thisKeyword),
        _isEqualTokens(node.period, toNode.period),
        _isEqualNodes(node.fieldName, toNode.fieldName),
        _isEqualTokens(node.equals, toNode.equals),
        _isEqualNodes(node.expression, toNode.expression));
  }

  @override
  bool visitConstructorName(ConstructorName node) {
    ConstructorName toNode = this._toNode as ConstructorName;
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
    ContinueStatement toNode = this._toNode as ContinueStatement;
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
    DeclaredIdentifier toNode = this._toNode as DeclaredIdentifier;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.keyword, toNode.keyword),
        _isEqualNodes(node.type, toNode.type),
        _isEqualNodes(node.identifier, toNode.identifier));
  }

  @override
  bool visitDefaultFormalParameter(DefaultFormalParameter node) {
    DefaultFormalParameter toNode = this._toNode as DefaultFormalParameter;
    return _and(
        _isEqualNodes(node.parameter, toNode.parameter),
        node.kind == toNode.kind,
        _isEqualTokens(node.separator, toNode.separator),
        _isEqualNodes(node.defaultValue, toNode.defaultValue));
  }

  @override
  bool visitDoStatement(DoStatement node) {
    DoStatement toNode = this._toNode as DoStatement;
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
    DottedName toNode = this._toNode as DottedName;
    return _isEqualNodeLists(node.components, toNode.components);
  }

  @override
  bool visitDoubleLiteral(DoubleLiteral node) {
    DoubleLiteral toNode = this._toNode as DoubleLiteral;
    if (_and(_isEqualTokens(node.literal, toNode.literal),
        node.value == toNode.value)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitEmptyFunctionBody(EmptyFunctionBody node) {
    EmptyFunctionBody toNode = this._toNode as EmptyFunctionBody;
    return _isEqualTokens(node.semicolon, toNode.semicolon);
  }

  @override
  bool visitEmptyStatement(EmptyStatement node) {
    EmptyStatement toNode = this._toNode as EmptyStatement;
    return _isEqualTokens(node.semicolon, toNode.semicolon);
  }

  @override
  bool visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    EnumConstantDeclaration toNode = this._toNode as EnumConstantDeclaration;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualNodes(node.name, toNode.name));
  }

  @override
  bool visitEnumDeclaration(EnumDeclaration node) {
    EnumDeclaration toNode = this._toNode as EnumDeclaration;
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
    ExportDirective toNode = this._toNode as ExportDirective;
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
    ExpressionFunctionBody toNode = this._toNode as ExpressionFunctionBody;
    return _and(
        _isEqualTokens(node.functionDefinition, toNode.functionDefinition),
        _isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitExpressionStatement(ExpressionStatement node) {
    ExpressionStatement toNode = this._toNode as ExpressionStatement;
    return _and(_isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitExtendsClause(ExtendsClause node) {
    ExtendsClause toNode = this._toNode as ExtendsClause;
    return _and(_isEqualTokens(node.extendsKeyword, toNode.extendsKeyword),
        _isEqualNodes(node.superclass, toNode.superclass));
  }

  @override
  bool visitFieldDeclaration(FieldDeclaration node) {
    FieldDeclaration toNode = this._toNode as FieldDeclaration;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.staticKeyword, toNode.staticKeyword),
        _isEqualNodes(node.fields, toNode.fields),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitFieldFormalParameter(FieldFormalParameter node) {
    FieldFormalParameter toNode = this._toNode as FieldFormalParameter;
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
  bool visitForEachStatement(ForEachStatement node) {
    ForEachStatement toNode = this._toNode as ForEachStatement;
    return _and(
        _isEqualTokens(node.forKeyword, toNode.forKeyword),
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodes(node.loopVariable, toNode.loopVariable),
        _isEqualNodes(node.identifier, toNode.identifier),
        _isEqualTokens(node.inKeyword, toNode.inKeyword),
        _isEqualNodes(node.iterable, toNode.iterable),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis),
        _isEqualNodes(node.body, toNode.body));
  }

  @override
  bool visitFormalParameterList(FormalParameterList node) {
    FormalParameterList toNode = this._toNode as FormalParameterList;
    return _and(
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodeLists(node.parameters, toNode.parameters),
        _isEqualTokens(node.leftDelimiter, toNode.leftDelimiter),
        _isEqualTokens(node.rightDelimiter, toNode.rightDelimiter),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis));
  }

  @override
  bool visitForStatement(ForStatement node) {
    ForStatement toNode = this._toNode as ForStatement;
    return _and(
        _isEqualTokens(node.forKeyword, toNode.forKeyword),
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodes(node.variables, toNode.variables),
        _isEqualNodes(node.initialization, toNode.initialization),
        _isEqualTokens(node.leftSeparator, toNode.leftSeparator),
        _isEqualNodes(node.condition, toNode.condition),
        _isEqualTokens(node.rightSeparator, toNode.rightSeparator),
        _isEqualNodeLists(node.updaters, toNode.updaters),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis),
        _isEqualNodes(node.body, toNode.body));
  }

  @override
  bool visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionDeclaration toNode = this._toNode as FunctionDeclaration;
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
        this._toNode as FunctionDeclarationStatement;
    return _isEqualNodes(node.functionDeclaration, toNode.functionDeclaration);
  }

  @override
  bool visitFunctionExpression(FunctionExpression node) {
    FunctionExpression toNode = this._toNode as FunctionExpression;
    if (_and(_isEqualNodes(node.parameters, toNode.parameters),
        _isEqualNodes(node.body, toNode.body))) {
      toNode.element = node.element;
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    FunctionExpressionInvocation toNode =
        this._toNode as FunctionExpressionInvocation;
    if (_and(
        _isEqualNodes(node.function, toNode.function),
        _isEqualNodes(node.typeArguments, toNode.typeArguments),
        _isEqualNodes(node.argumentList, toNode.argumentList))) {
      toNode.propagatedElement = node.propagatedElement;
      toNode.propagatedInvokeType = node.propagatedInvokeType;
      toNode.propagatedType = node.propagatedType;
      toNode.staticInvokeType = node.staticInvokeType;
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAlias toNode = this._toNode as FunctionTypeAlias;
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
        this._toNode as FunctionTypedFormalParameter;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualNodes(node.returnType, toNode.returnType),
        _isEqualNodes(node.identifier, toNode.identifier),
        _isEqualNodes(node.parameters, toNode.parameters));
  }

  @override
  bool visitGenericFunctionType(GenericFunctionType node) {
    GenericFunctionTypeImpl toNode = this._toNode as GenericFunctionTypeImpl;
    if (_and(
        _isEqualNodes(node.returnType, toNode.returnType),
        _isEqualTokens(node.functionKeyword, toNode.functionKeyword),
        _isEqualNodes(node.typeParameters, toNode.typeParameters),
        _isEqualNodes(node.parameters, toNode.parameters))) {
      toNode.type = node.type;
      return true;
    }
    return false;
  }

  @override
  bool visitGenericTypeAlias(GenericTypeAlias node) {
    GenericTypeAliasImpl toNode = this._toNode as GenericTypeAliasImpl;
    if (_and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.typedefKeyword, toNode.typedefKeyword),
        _isEqualNodes(node.name, toNode.name),
        _isEqualNodes(node.typeParameters, toNode.typeParameters),
        _isEqualTokens(node.equals, toNode.equals),
        _isEqualNodes(node.functionType, toNode.functionType),
        _isEqualTokens(node.semicolon, toNode.semicolon))) {
      return true;
    }
    return false;
  }

  @override
  bool visitHideCombinator(HideCombinator node) {
    HideCombinator toNode = this._toNode as HideCombinator;
    return _and(_isEqualTokens(node.keyword, toNode.keyword),
        _isEqualNodeLists(node.hiddenNames, toNode.hiddenNames));
  }

  @override
  bool visitIfStatement(IfStatement node) {
    IfStatement toNode = this._toNode as IfStatement;
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
    ImplementsClause toNode = this._toNode as ImplementsClause;
    return _and(
        _isEqualTokens(node.implementsKeyword, toNode.implementsKeyword),
        _isEqualNodeLists(node.interfaces, toNode.interfaces));
  }

  @override
  bool visitImportDirective(ImportDirective node) {
    ImportDirective toNode = this._toNode as ImportDirective;
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
    IndexExpression toNode = this._toNode as IndexExpression;
    if (_and(
        _isEqualNodes(node.target, toNode.target),
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodes(node.index, toNode.index),
        _isEqualTokens(node.rightBracket, toNode.rightBracket))) {
      toNode.auxiliaryElements = node.auxiliaryElements;
      toNode.propagatedElement = node.propagatedElement;
      toNode.propagatedType = node.propagatedType;
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitInstanceCreationExpression(InstanceCreationExpression node) {
    InstanceCreationExpression toNode =
        this._toNode as InstanceCreationExpression;
    if (_and(
        _isEqualTokens(node.keyword, toNode.keyword),
        _isEqualNodes(node.constructorName, toNode.constructorName),
        _isEqualNodes(node.argumentList, toNode.argumentList))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitIntegerLiteral(IntegerLiteral node) {
    IntegerLiteral toNode = this._toNode as IntegerLiteral;
    if (_and(_isEqualTokens(node.literal, toNode.literal),
        node.value == toNode.value)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitInterpolationExpression(InterpolationExpression node) {
    InterpolationExpression toNode = this._toNode as InterpolationExpression;
    return _and(
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  @override
  bool visitInterpolationString(InterpolationString node) {
    InterpolationString toNode = this._toNode as InterpolationString;
    return _and(_isEqualTokens(node.contents, toNode.contents),
        node.value == toNode.value);
  }

  @override
  bool visitIsExpression(IsExpression node) {
    IsExpression toNode = this._toNode as IsExpression;
    if (_and(
        _isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.isOperator, toNode.isOperator),
        _isEqualTokens(node.notOperator, toNode.notOperator),
        _isEqualNodes(node.type, toNode.type))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitLabel(Label node) {
    Label toNode = this._toNode as Label;
    return _and(_isEqualNodes(node.label, toNode.label),
        _isEqualTokens(node.colon, toNode.colon));
  }

  @override
  bool visitLabeledStatement(LabeledStatement node) {
    LabeledStatement toNode = this._toNode as LabeledStatement;
    return _and(_isEqualNodeLists(node.labels, toNode.labels),
        _isEqualNodes(node.statement, toNode.statement));
  }

  @override
  bool visitLibraryDirective(LibraryDirective node) {
    LibraryDirective toNode = this._toNode as LibraryDirective;
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
    LibraryIdentifier toNode = this._toNode as LibraryIdentifier;
    if (_isEqualNodeLists(node.components, toNode.components)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitListLiteral(ListLiteral node) {
    ListLiteral toNode = this._toNode as ListLiteral;
    if (_and(
        _isEqualTokens(node.constKeyword, toNode.constKeyword),
        _isEqualNodes(node.typeArguments, toNode.typeArguments),
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodeLists(node.elements, toNode.elements),
        _isEqualTokens(node.rightBracket, toNode.rightBracket))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitMapLiteral(MapLiteral node) {
    MapLiteral toNode = this._toNode as MapLiteral;
    if (_and(
        _isEqualTokens(node.constKeyword, toNode.constKeyword),
        _isEqualNodes(node.typeArguments, toNode.typeArguments),
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodeLists(node.entries, toNode.entries),
        _isEqualTokens(node.rightBracket, toNode.rightBracket))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitMapLiteralEntry(MapLiteralEntry node) {
    MapLiteralEntry toNode = this._toNode as MapLiteralEntry;
    return _and(
        _isEqualNodes(node.key, toNode.key),
        _isEqualTokens(node.separator, toNode.separator),
        _isEqualNodes(node.value, toNode.value));
  }

  @override
  bool visitMethodDeclaration(MethodDeclaration node) {
    MethodDeclaration toNode = this._toNode as MethodDeclaration;
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
    MethodInvocation toNode = this._toNode as MethodInvocation;
    if (_and(
        _isEqualNodes(node.target, toNode.target),
        _isEqualTokens(node.operator, toNode.operator),
        _isEqualNodes(node.typeArguments, toNode.typeArguments),
        _isEqualNodes(node.methodName, toNode.methodName),
        _isEqualNodes(node.argumentList, toNode.argumentList))) {
      toNode.propagatedInvokeType = node.propagatedInvokeType;
      toNode.propagatedType = node.propagatedType;
      toNode.staticInvokeType = node.staticInvokeType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitNamedExpression(NamedExpression node) {
    NamedExpression toNode = this._toNode as NamedExpression;
    if (_and(_isEqualNodes(node.name, toNode.name),
        _isEqualNodes(node.expression, toNode.expression))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitNativeClause(NativeClause node) {
    NativeClause toNode = this._toNode as NativeClause;
    return _and(_isEqualTokens(node.nativeKeyword, toNode.nativeKeyword),
        _isEqualNodes(node.name, toNode.name));
  }

  @override
  bool visitNativeFunctionBody(NativeFunctionBody node) {
    NativeFunctionBody toNode = this._toNode as NativeFunctionBody;
    return _and(
        _isEqualTokens(node.nativeKeyword, toNode.nativeKeyword),
        _isEqualNodes(node.stringLiteral, toNode.stringLiteral),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitNullLiteral(NullLiteral node) {
    NullLiteral toNode = this._toNode as NullLiteral;
    if (_isEqualTokens(node.literal, toNode.literal)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitParenthesizedExpression(ParenthesizedExpression node) {
    ParenthesizedExpression toNode = this._toNode as ParenthesizedExpression;
    if (_and(
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitPartDirective(PartDirective node) {
    PartDirective toNode = this._toNode as PartDirective;
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
    PartOfDirective toNode = this._toNode as PartOfDirective;
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
    PostfixExpression toNode = this._toNode as PostfixExpression;
    if (_and(_isEqualNodes(node.operand, toNode.operand),
        _isEqualTokens(node.operator, toNode.operator))) {
      toNode.propagatedElement = node.propagatedElement;
      toNode.propagatedType = node.propagatedType;
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitPrefixedIdentifier(PrefixedIdentifier node) {
    PrefixedIdentifier toNode = this._toNode as PrefixedIdentifier;
    if (_and(
        _isEqualNodes(node.prefix, toNode.prefix),
        _isEqualTokens(node.period, toNode.period),
        _isEqualNodes(node.identifier, toNode.identifier))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitPrefixExpression(PrefixExpression node) {
    PrefixExpression toNode = this._toNode as PrefixExpression;
    if (_and(_isEqualTokens(node.operator, toNode.operator),
        _isEqualNodes(node.operand, toNode.operand))) {
      toNode.propagatedElement = node.propagatedElement;
      toNode.propagatedType = node.propagatedType;
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitPropertyAccess(PropertyAccess node) {
    PropertyAccess toNode = this._toNode as PropertyAccess;
    if (_and(
        _isEqualNodes(node.target, toNode.target),
        _isEqualTokens(node.operator, toNode.operator),
        _isEqualNodes(node.propertyName, toNode.propertyName))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    RedirectingConstructorInvocation toNode =
        this._toNode as RedirectingConstructorInvocation;
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
    RethrowExpression toNode = this._toNode as RethrowExpression;
    if (_isEqualTokens(node.rethrowKeyword, toNode.rethrowKeyword)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitReturnStatement(ReturnStatement node) {
    ReturnStatement toNode = this._toNode as ReturnStatement;
    return _and(
        _isEqualTokens(node.returnKeyword, toNode.returnKeyword),
        _isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitScriptTag(ScriptTag node) {
    ScriptTag toNode = this._toNode as ScriptTag;
    return _isEqualTokens(node.scriptTag, toNode.scriptTag);
  }

  @override
  bool visitShowCombinator(ShowCombinator node) {
    ShowCombinator toNode = this._toNode as ShowCombinator;
    return _and(_isEqualTokens(node.keyword, toNode.keyword),
        _isEqualNodeLists(node.shownNames, toNode.shownNames));
  }

  @override
  bool visitSimpleFormalParameter(SimpleFormalParameter node) {
    SimpleFormalParameter toNode = this._toNode as SimpleFormalParameter;
    if (_and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualTokens(node.keyword, toNode.keyword),
        _isEqualNodes(node.type, toNode.type),
        _isEqualNodes(node.identifier, toNode.identifier))) {
      (toNode as SimpleFormalParameterImpl).element = node.element;
      return true;
    }
    return false;
  }

  @override
  bool visitSimpleIdentifier(SimpleIdentifier node) {
    SimpleIdentifier toNode = this._toNode as SimpleIdentifier;
    if (_isEqualTokens(node.token, toNode.token)) {
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      toNode.propagatedElement = node.propagatedElement;
      toNode.propagatedType = node.propagatedType;
      toNode.auxiliaryElements = node.auxiliaryElements;
      return true;
    }
    return false;
  }

  @override
  bool visitSimpleStringLiteral(SimpleStringLiteral node) {
    SimpleStringLiteral toNode = this._toNode as SimpleStringLiteral;
    if (_and(_isEqualTokens(node.literal, toNode.literal),
        node.value == toNode.value)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitStringInterpolation(StringInterpolation node) {
    StringInterpolation toNode = this._toNode as StringInterpolation;
    if (_isEqualNodeLists(node.elements, toNode.elements)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    SuperConstructorInvocation toNode =
        this._toNode as SuperConstructorInvocation;
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
    SuperExpression toNode = this._toNode as SuperExpression;
    if (_isEqualTokens(node.superKeyword, toNode.superKeyword)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitSwitchCase(SwitchCase node) {
    SwitchCase toNode = this._toNode as SwitchCase;
    return _and(
        _isEqualNodeLists(node.labels, toNode.labels),
        _isEqualTokens(node.keyword, toNode.keyword),
        _isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.colon, toNode.colon),
        _isEqualNodeLists(node.statements, toNode.statements));
  }

  @override
  bool visitSwitchDefault(SwitchDefault node) {
    SwitchDefault toNode = this._toNode as SwitchDefault;
    return _and(
        _isEqualNodeLists(node.labels, toNode.labels),
        _isEqualTokens(node.keyword, toNode.keyword),
        _isEqualTokens(node.colon, toNode.colon),
        _isEqualNodeLists(node.statements, toNode.statements));
  }

  @override
  bool visitSwitchStatement(SwitchStatement node) {
    SwitchStatement toNode = this._toNode as SwitchStatement;
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
    SymbolLiteral toNode = this._toNode as SymbolLiteral;
    if (_and(_isEqualTokens(node.poundSign, toNode.poundSign),
        _isEqualTokenLists(node.components, toNode.components))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitThisExpression(ThisExpression node) {
    ThisExpression toNode = this._toNode as ThisExpression;
    if (_isEqualTokens(node.thisKeyword, toNode.thisKeyword)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitThrowExpression(ThrowExpression node) {
    ThrowExpression toNode = this._toNode as ThrowExpression;
    if (_and(_isEqualTokens(node.throwKeyword, toNode.throwKeyword),
        _isEqualNodes(node.expression, toNode.expression))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  @override
  bool visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    TopLevelVariableDeclaration toNode =
        this._toNode as TopLevelVariableDeclaration;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualNodes(node.variables, toNode.variables),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitTryStatement(TryStatement node) {
    TryStatement toNode = this._toNode as TryStatement;
    return _and(
        _isEqualTokens(node.tryKeyword, toNode.tryKeyword),
        _isEqualNodes(node.body, toNode.body),
        _isEqualNodeLists(node.catchClauses, toNode.catchClauses),
        _isEqualTokens(node.finallyKeyword, toNode.finallyKeyword),
        _isEqualNodes(node.finallyBlock, toNode.finallyBlock));
  }

  @override
  bool visitTypeArgumentList(TypeArgumentList node) {
    TypeArgumentList toNode = this._toNode as TypeArgumentList;
    return _and(
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodeLists(node.arguments, toNode.arguments),
        _isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  @override
  bool visitTypeName(TypeName node) {
    TypeName toNode = this._toNode as TypeName;
    if (_and(_isEqualNodes(node.name, toNode.name),
        _isEqualNodes(node.typeArguments, toNode.typeArguments))) {
      toNode.type = node.type;
      return true;
    }
    return false;
  }

  @override
  bool visitTypeParameter(TypeParameter node) {
    TypeParameter toNode = this._toNode as TypeParameter;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualNodes(node.name, toNode.name),
        _isEqualTokens(node.extendsKeyword, toNode.extendsKeyword),
        _isEqualNodes(node.bound, toNode.bound));
  }

  @override
  bool visitTypeParameterList(TypeParameterList node) {
    TypeParameterList toNode = this._toNode as TypeParameterList;
    return _and(
        _isEqualTokens(node.leftBracket, toNode.leftBracket),
        _isEqualNodeLists(node.typeParameters, toNode.typeParameters),
        _isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  @override
  bool visitVariableDeclaration(VariableDeclaration node) {
    VariableDeclaration toNode = this._toNode as VariableDeclaration;
    return _and(
        _isEqualNodes(node.documentationComment, toNode.documentationComment),
        _isEqualNodeLists(node.metadata, toNode.metadata),
        _isEqualNodes(node.name, toNode.name),
        _isEqualTokens(node.equals, toNode.equals),
        _isEqualNodes(node.initializer, toNode.initializer));
  }

  @override
  bool visitVariableDeclarationList(VariableDeclarationList node) {
    VariableDeclarationList toNode = this._toNode as VariableDeclarationList;
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
        this._toNode as VariableDeclarationStatement;
    return _and(_isEqualNodes(node.variables, toNode.variables),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  @override
  bool visitWhileStatement(WhileStatement node) {
    WhileStatement toNode = this._toNode as WhileStatement;
    return _and(
        _isEqualTokens(node.whileKeyword, toNode.whileKeyword),
        _isEqualTokens(node.leftParenthesis, toNode.leftParenthesis),
        _isEqualNodes(node.condition, toNode.condition),
        _isEqualTokens(node.rightParenthesis, toNode.rightParenthesis),
        _isEqualNodes(node.body, toNode.body));
  }

  @override
  bool visitWithClause(WithClause node) {
    WithClause toNode = this._toNode as WithClause;
    return _and(_isEqualTokens(node.withKeyword, toNode.withKeyword),
        _isEqualNodeLists(node.mixinTypes, toNode.mixinTypes));
  }

  @override
  bool visitYieldStatement(YieldStatement node) {
    YieldStatement toNode = this._toNode as YieldStatement;
    return _and(
        _isEqualTokens(node.yieldKeyword, toNode.yieldKeyword),
        _isEqualNodes(node.expression, toNode.expression),
        _isEqualTokens(node.semicolon, toNode.semicolon));
  }

  /**
   * Return `true` if all of the parameters are `true`.
   */
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

  /**
   * Return `true` if the [first] and [second] lists of AST nodes have the same
   * size and corresponding elements are equal.
   */
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

  /**
   * Return `true` if the [fromNode] and [toNode] have the same structure. As a
   * side-effect, if the nodes do have the same structure, any resolution data
   * from the first node will be copied to the second node.
   */
  bool _isEqualNodes(AstNode fromNode, AstNode toNode) {
    if (fromNode == null) {
      return toNode == null;
    } else if (toNode == null) {
      return false;
    } else if (fromNode.runtimeType == toNode.runtimeType) {
      this._toNode = toNode;
      return fromNode.accept(this);
    }
    //
    // Check for a simple transformation caused by entering a period.
    //
    if (toNode is PrefixedIdentifier) {
      SimpleIdentifier prefix = toNode.prefix;
      if (fromNode.runtimeType == prefix.runtimeType) {
        this._toNode = prefix;
        return fromNode.accept(this);
      }
    } else if (toNode is PropertyAccess) {
      Expression target = toNode.target;
      if (fromNode.runtimeType == target.runtimeType) {
        this._toNode = target;
        return fromNode.accept(this);
      }
    }
    return false;
  }

  /**
   * Return `true` if the [first] and [second] arrays of tokens have the same
   * length and corresponding elements are equal.
   */
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

  /**
   * Return `true` if the [first] and [second] tokens have the same structure.
   */
  bool _isEqualTokens(Token first, Token second) {
    if (first == null) {
      return second == null;
    } else if (second == null) {
      return false;
    }
    return first.lexeme == second.lexeme;
  }

  /**
   * Copy resolution data from the [fromNode] to the [toNode].
   */
  static void copyResolutionData(AstNode fromNode, AstNode toNode) {
    ResolutionCopier copier = new ResolutionCopier();
    copier._isEqualNodes(fromNode, toNode);
  }
}

/**
 * Traverse the AST from initial child node to successive parents, building a
 * collection of local variable and parameter names visible to the initial child
 * node. In case of name shadowing, the first name seen is the most specific one
 * so names are not redefined.
 *
 * Completion test code coverage is 95%. The two basic blocks that are not
 * executed cannot be executed. They are included for future reference.
 */
class ScopedNameFinder extends GeneralizingAstVisitor<Object> {
  Declaration _declarationNode;

  AstNode _immediateChild;

  Map<String, SimpleIdentifier> _locals =
      new HashMap<String, SimpleIdentifier>();

  final int _position;

  bool _referenceIsWithinLocalFunction = false;

  ScopedNameFinder(this._position);

  Declaration get declaration => _declarationNode;

  Map<String, SimpleIdentifier> get locals => _locals;

  @override
  Object visitBlock(Block node) {
    _checkStatements(node.statements);
    return super.visitBlock(node);
  }

  @override
  Object visitCatchClause(CatchClause node) {
    _addToScope(node.exceptionParameter);
    _addToScope(node.stackTraceParameter);
    return super.visitCatchClause(node);
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    if (!identical(_immediateChild, node.parameters)) {
      _addParameters(node.parameters.parameters);
    }
    _declarationNode = node;
    return null;
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    _declarationNode = node;
    return null;
  }

  @override
  Object visitForEachStatement(ForEachStatement node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (loopVariable != null) {
      _addToScope(loopVariable.identifier);
    }
    return super.visitForEachStatement(node);
  }

  @override
  Object visitForStatement(ForStatement node) {
    if (!identical(_immediateChild, node.variables) && node.variables != null) {
      _addVariables(node.variables.variables);
    }
    return super.visitForStatement(node);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is! FunctionDeclarationStatement) {
      _declarationNode = node;
      return null;
    }
    return super.visitFunctionDeclaration(node);
  }

  @override
  Object visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _referenceIsWithinLocalFunction = true;
    return super.visitFunctionDeclarationStatement(node);
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parameters != null &&
        !identical(_immediateChild, node.parameters)) {
      _addParameters(node.parameters.parameters);
    }
    return super.visitFunctionExpression(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    _declarationNode = node;
    if (node.parameters == null) {
      return null;
    }
    if (!identical(_immediateChild, node.parameters)) {
      _addParameters(node.parameters.parameters);
    }
    return null;
  }

  @override
  Object visitNode(AstNode node) {
    _immediateChild = node;
    AstNode parent = node.parent;
    if (parent != null) {
      parent.accept(this);
    }
    return null;
  }

  @override
  Object visitSwitchMember(SwitchMember node) {
    _checkStatements(node.statements);
    return super.visitSwitchMember(node);
  }

  @override
  Object visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _declarationNode = node;
    return null;
  }

  @override
  Object visitTypeAlias(TypeAlias node) {
    _declarationNode = node;
    return null;
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

  /**
   * Check the given list of [statements] for any that come before the immediate
   * child and that define a name that would be visible to the immediate child.
   */
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

/**
 * A visitor used to write a source representation of a visited AST node (and
 * all of it's children) to a writer.
 *
 * This class has been deprecated. Use the class ToSourceVisitor2 instead.
 */
@deprecated
class ToSourceVisitor implements AstVisitor<Object> {
  /**
   * The writer to which the source is to be written.
   */
  final PrintWriter _writer;

  /**
   * Initialize a newly created visitor to write source code representing the
   * visited nodes to the given [writer].
   */
  ToSourceVisitor(this._writer);

  @override
  Object visitAdjacentStrings(AdjacentStrings node) {
    _visitNodeListWithSeparator(node.strings, " ");
    return null;
  }

  @override
  Object visitAnnotation(Annotation node) {
    _writer.print('@');
    _visitNode(node.name);
    _visitNodeWithPrefix(".", node.constructorName);
    _visitNode(node.arguments);
    return null;
  }

  @override
  Object visitArgumentList(ArgumentList node) {
    _writer.print('(');
    _visitNodeListWithSeparator(node.arguments, ", ");
    _writer.print(')');
    return null;
  }

  @override
  Object visitAsExpression(AsExpression node) {
    _visitNode(node.expression);
    _writer.print(" as ");
    _visitNode(node.type);
    return null;
  }

  @override
  bool visitAssertInitializer(AssertInitializer node) {
    _writer.print("assert (");
    _visitNode(node.condition);
    if (node.message != null) {
      _writer.print(', ');
      _visitNode(node.message);
    }
    _writer.print(")");
    return null;
  }

  @override
  Object visitAssertStatement(AssertStatement node) {
    _writer.print("assert (");
    _visitNode(node.condition);
    if (node.message != null) {
      _writer.print(', ');
      _visitNode(node.message);
    }
    _writer.print(");");
    return null;
  }

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    _visitNode(node.leftHandSide);
    _writer.print(' ');
    _writer.print(node.operator.lexeme);
    _writer.print(' ');
    _visitNode(node.rightHandSide);
    return null;
  }

  @override
  Object visitAwaitExpression(AwaitExpression node) {
    _writer.print("await ");
    _visitNode(node.expression);
    return null;
  }

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    _visitNode(node.leftOperand);
    _writer.print(' ');
    _writer.print(node.operator.lexeme);
    _writer.print(' ');
    _visitNode(node.rightOperand);
    return null;
  }

  @override
  Object visitBlock(Block node) {
    _writer.print('{');
    _visitNodeListWithSeparator(node.statements, " ");
    _writer.print('}');
    return null;
  }

  @override
  Object visitBlockFunctionBody(BlockFunctionBody node) {
    Token keyword = node.keyword;
    if (keyword != null) {
      _writer.print(keyword.lexeme);
      if (node.star != null) {
        _writer.print('*');
      }
      _writer.print(' ');
    }
    _visitNode(node.block);
    return null;
  }

  @override
  Object visitBooleanLiteral(BooleanLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }

  @override
  Object visitBreakStatement(BreakStatement node) {
    _writer.print("break");
    _visitNodeWithPrefix(" ", node.label);
    _writer.print(";");
    return null;
  }

  @override
  Object visitCascadeExpression(CascadeExpression node) {
    _visitNode(node.target);
    _visitNodeList(node.cascadeSections);
    return null;
  }

  @override
  Object visitCatchClause(CatchClause node) {
    _visitNodeWithPrefix("on ", node.exceptionType);
    if (node.catchKeyword != null) {
      if (node.exceptionType != null) {
        _writer.print(' ');
      }
      _writer.print("catch (");
      _visitNode(node.exceptionParameter);
      _visitNodeWithPrefix(", ", node.stackTraceParameter);
      _writer.print(") ");
    } else {
      _writer.print(" ");
    }
    _visitNode(node.body);
    return null;
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitTokenWithSuffix(node.abstractKeyword, " ");
    _writer.print("class ");
    _visitNode(node.name);
    _visitNode(node.typeParameters);
    _visitNodeWithPrefix(" ", node.extendsClause);
    _visitNodeWithPrefix(" ", node.withClause);
    _visitNodeWithPrefix(" ", node.implementsClause);
    _writer.print(" {");
    _visitNodeListWithSeparator(node.members, " ");
    _writer.print("}");
    return null;
  }

  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    if (node.abstractKeyword != null) {
      _writer.print("abstract ");
    }
    _writer.print("class ");
    _visitNode(node.name);
    _visitNode(node.typeParameters);
    _writer.print(" = ");
    _visitNode(node.superclass);
    _visitNodeWithPrefix(" ", node.withClause);
    _visitNodeWithPrefix(" ", node.implementsClause);
    _writer.print(";");
    return null;
  }

  @override
  Object visitComment(Comment node) => null;

  @override
  Object visitCommentReference(CommentReference node) => null;

  @override
  Object visitCompilationUnit(CompilationUnit node) {
    ScriptTag scriptTag = node.scriptTag;
    NodeList<Directive> directives = node.directives;
    _visitNode(scriptTag);
    String prefix = scriptTag == null ? "" : " ";
    _visitNodeListWithSeparatorAndPrefix(prefix, directives, " ");
    prefix = scriptTag == null && directives.isEmpty ? "" : " ";
    _visitNodeListWithSeparatorAndPrefix(prefix, node.declarations, " ");
    return null;
  }

  @override
  Object visitConditionalExpression(ConditionalExpression node) {
    _visitNode(node.condition);
    _writer.print(" ? ");
    _visitNode(node.thenExpression);
    _writer.print(" : ");
    _visitNode(node.elseExpression);
    return null;
  }

  @override
  Object visitConfiguration(Configuration node) {
    _writer.print('if (');
    _visitNode(node.name);
    _visitNodeWithPrefix(" == ", node.value);
    _writer.print(') ');
    _visitNode(node.uri);
    return null;
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitTokenWithSuffix(node.externalKeyword, " ");
    _visitTokenWithSuffix(node.constKeyword, " ");
    _visitTokenWithSuffix(node.factoryKeyword, " ");
    _visitNode(node.returnType);
    _visitNodeWithPrefix(".", node.name);
    _visitNode(node.parameters);
    _visitNodeListWithSeparatorAndPrefix(" : ", node.initializers, ", ");
    _visitNodeWithPrefix(" = ", node.redirectedConstructor);
    _visitFunctionWithPrefix(" ", node.body);
    return null;
  }

  @override
  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _visitTokenWithSuffix(node.thisKeyword, ".");
    _visitNode(node.fieldName);
    _writer.print(" = ");
    _visitNode(node.expression);
    return null;
  }

  @override
  Object visitConstructorName(ConstructorName node) {
    _visitNode(node.type);
    _visitNodeWithPrefix(".", node.name);
    return null;
  }

  @override
  Object visitContinueStatement(ContinueStatement node) {
    _writer.print("continue");
    _visitNodeWithPrefix(" ", node.label);
    _writer.print(";");
    return null;
  }

  @override
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitTokenWithSuffix(node.keyword, " ");
    _visitNodeWithSuffix(node.type, " ");
    _visitNode(node.identifier);
    return null;
  }

  @override
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    _visitNode(node.parameter);
    if (node.separator != null) {
      _writer.print(" ");
      _writer.print(node.separator.lexeme);
      _visitNodeWithPrefix(" ", node.defaultValue);
    }
    return null;
  }

  @override
  Object visitDoStatement(DoStatement node) {
    _writer.print("do ");
    _visitNode(node.body);
    _writer.print(" while (");
    _visitNode(node.condition);
    _writer.print(");");
    return null;
  }

  @override
  Object visitDottedName(DottedName node) {
    _visitNodeListWithSeparator(node.components, ".");
    return null;
  }

  @override
  Object visitDoubleLiteral(DoubleLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }

  @override
  Object visitEmptyFunctionBody(EmptyFunctionBody node) {
    _writer.print(';');
    return null;
  }

  @override
  Object visitEmptyStatement(EmptyStatement node) {
    _writer.print(';');
    return null;
  }

  @override
  Object visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitNode(node.name);
    return null;
  }

  @override
  Object visitEnumDeclaration(EnumDeclaration node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _writer.print("enum ");
    _visitNode(node.name);
    _writer.print(" {");
    _visitNodeListWithSeparator(node.constants, ", ");
    _writer.print("}");
    return null;
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _writer.print("export ");
    _visitNode(node.uri);
    _visitNodeListWithSeparatorAndPrefix(" ", node.combinators, " ");
    _writer.print(';');
    return null;
  }

  @override
  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    Token keyword = node.keyword;
    if (keyword != null) {
      _writer.print(keyword.lexeme);
      _writer.print(' ');
    }
    _writer.print("=> ");
    _visitNode(node.expression);
    if (node.semicolon != null) {
      _writer.print(';');
    }
    return null;
  }

  @override
  Object visitExpressionStatement(ExpressionStatement node) {
    _visitNode(node.expression);
    _writer.print(';');
    return null;
  }

  @override
  Object visitExtendsClause(ExtendsClause node) {
    _writer.print("extends ");
    _visitNode(node.superclass);
    return null;
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitTokenWithSuffix(node.staticKeyword, " ");
    _visitNode(node.fields);
    _writer.print(";");
    return null;
  }

  @override
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, ' ', ' ');
    _visitTokenWithSuffix(node.covariantKeyword, ' ');
    _visitTokenWithSuffix(node.keyword, " ");
    _visitNodeWithSuffix(node.type, " ");
    _writer.print("this.");
    _visitNode(node.identifier);
    _visitNode(node.typeParameters);
    _visitNode(node.parameters);
    return null;
  }

  @override
  Object visitForEachStatement(ForEachStatement node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (node.awaitKeyword != null) {
      _writer.print("await ");
    }
    _writer.print("for (");
    if (loopVariable == null) {
      _visitNode(node.identifier);
    } else {
      _visitNode(loopVariable);
    }
    _writer.print(" in ");
    _visitNode(node.iterable);
    _writer.print(") ");
    _visitNode(node.body);
    return null;
  }

  @override
  Object visitFormalParameterList(FormalParameterList node) {
    String groupEnd = null;
    _writer.print('(');
    NodeList<FormalParameter> parameters = node.parameters;
    int size = parameters.length;
    for (int i = 0; i < size; i++) {
      FormalParameter parameter = parameters[i];
      if (i > 0) {
        _writer.print(", ");
      }
      if (groupEnd == null && parameter is DefaultFormalParameter) {
        if (parameter.kind == ParameterKind.NAMED) {
          groupEnd = "}";
          _writer.print('{');
        } else {
          groupEnd = "]";
          _writer.print('[');
        }
      }
      parameter.accept(this);
    }
    if (groupEnd != null) {
      _writer.print(groupEnd);
    }
    _writer.print(')');
    return null;
  }

  @override
  Object visitForStatement(ForStatement node) {
    Expression initialization = node.initialization;
    _writer.print("for (");
    if (initialization != null) {
      _visitNode(initialization);
    } else {
      _visitNode(node.variables);
    }
    _writer.print(";");
    _visitNodeWithPrefix(" ", node.condition);
    _writer.print(";");
    _visitNodeListWithSeparatorAndPrefix(" ", node.updaters, ", ");
    _writer.print(") ");
    _visitNode(node.body);
    return null;
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitTokenWithSuffix(node.externalKeyword, " ");
    _visitNodeWithSuffix(node.returnType, " ");
    _visitTokenWithSuffix(node.propertyKeyword, " ");
    _visitNode(node.name);
    _visitNode(node.functionExpression);
    return null;
  }

  @override
  Object visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _visitNode(node.functionDeclaration);
    return null;
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    _visitNode(node.typeParameters);
    _visitNode(node.parameters);
    if (node.body is! EmptyFunctionBody) {
      _writer.print(' ');
    }
    _visitNode(node.body);
    return null;
  }

  @override
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _visitNode(node.function);
    _visitNode(node.typeArguments);
    _visitNode(node.argumentList);
    return null;
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _writer.print("typedef ");
    _visitNodeWithSuffix(node.returnType, " ");
    _visitNode(node.name);
    _visitNode(node.typeParameters);
    _visitNode(node.parameters);
    _writer.print(";");
    return null;
  }

  @override
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, ' ', ' ');
    _visitTokenWithSuffix(node.covariantKeyword, ' ');
    _visitNodeWithSuffix(node.returnType, " ");
    _visitNode(node.identifier);
    _visitNode(node.typeParameters);
    _visitNode(node.parameters);
    if (node.question != null) {
      _writer.print('?');
    }
    return null;
  }

  @override
  Object visitGenericFunctionType(GenericFunctionType node) {
    _visitNode(node.returnType);
    _writer.print(' Function');
    _visitNode(node.typeParameters);
    _visitNode(node.parameters);
    return null;
  }

  @override
  Object visitGenericTypeAlias(GenericTypeAlias node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _writer.print("typedef ");
    _visitNode(node.name);
    _visitNode(node.typeParameters);
    _writer.print(" = ");
    _visitNode(node.functionType);
    return null;
  }

  @override
  Object visitHideCombinator(HideCombinator node) {
    _writer.print("hide ");
    _visitNodeListWithSeparator(node.hiddenNames, ", ");
    return null;
  }

  @override
  Object visitIfStatement(IfStatement node) {
    _writer.print("if (");
    _visitNode(node.condition);
    _writer.print(") ");
    _visitNode(node.thenStatement);
    _visitNodeWithPrefix(" else ", node.elseStatement);
    return null;
  }

  @override
  Object visitImplementsClause(ImplementsClause node) {
    _writer.print("implements ");
    _visitNodeListWithSeparator(node.interfaces, ", ");
    return null;
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _writer.print("import ");
    _visitNode(node.uri);
    if (node.deferredKeyword != null) {
      _writer.print(" deferred");
    }
    _visitNodeWithPrefix(" as ", node.prefix);
    _visitNodeListWithSeparatorAndPrefix(" ", node.combinators, " ");
    _writer.print(';');
    return null;
  }

  @override
  Object visitIndexExpression(IndexExpression node) {
    if (node.isCascaded) {
      _writer.print("..");
    } else {
      _visitNode(node.target);
    }
    _writer.print('[');
    _visitNode(node.index);
    _writer.print(']');
    return null;
  }

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    _visitTokenWithSuffix(node.keyword, " ");
    _visitNode(node.constructorName);
    _visitNode(node.argumentList);
    return null;
  }

  @override
  Object visitIntegerLiteral(IntegerLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }

  @override
  Object visitInterpolationExpression(InterpolationExpression node) {
    if (node.rightBracket != null) {
      _writer.print("\${");
      _visitNode(node.expression);
      _writer.print("}");
    } else {
      _writer.print("\$");
      _visitNode(node.expression);
    }
    return null;
  }

  @override
  Object visitInterpolationString(InterpolationString node) {
    _writer.print(node.contents.lexeme);
    return null;
  }

  @override
  Object visitIsExpression(IsExpression node) {
    _visitNode(node.expression);
    if (node.notOperator == null) {
      _writer.print(" is ");
    } else {
      _writer.print(" is! ");
    }
    _visitNode(node.type);
    return null;
  }

  @override
  Object visitLabel(Label node) {
    _visitNode(node.label);
    _writer.print(":");
    return null;
  }

  @override
  Object visitLabeledStatement(LabeledStatement node) {
    _visitNodeListWithSeparatorAndSuffix(node.labels, " ", " ");
    _visitNode(node.statement);
    return null;
  }

  @override
  Object visitLibraryDirective(LibraryDirective node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _writer.print("library ");
    _visitNode(node.name);
    _writer.print(';');
    return null;
  }

  @override
  Object visitLibraryIdentifier(LibraryIdentifier node) {
    _writer.print(node.name);
    return null;
  }

  @override
  Object visitListLiteral(ListLiteral node) {
    if (node.constKeyword != null) {
      _writer.print(node.constKeyword.lexeme);
      _writer.print(' ');
    }
    _visitNodeWithSuffix(node.typeArguments, " ");
    _writer.print("[");
    _visitNodeListWithSeparator(node.elements, ", ");
    _writer.print("]");
    return null;
  }

  @override
  Object visitMapLiteral(MapLiteral node) {
    if (node.constKeyword != null) {
      _writer.print(node.constKeyword.lexeme);
      _writer.print(' ');
    }
    _visitNodeWithSuffix(node.typeArguments, " ");
    _writer.print("{");
    _visitNodeListWithSeparator(node.entries, ", ");
    _writer.print("}");
    return null;
  }

  @override
  Object visitMapLiteralEntry(MapLiteralEntry node) {
    _visitNode(node.key);
    _writer.print(" : ");
    _visitNode(node.value);
    return null;
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitTokenWithSuffix(node.externalKeyword, " ");
    _visitTokenWithSuffix(node.modifierKeyword, " ");
    _visitNodeWithSuffix(node.returnType, " ");
    _visitTokenWithSuffix(node.propertyKeyword, " ");
    _visitTokenWithSuffix(node.operatorKeyword, " ");
    _visitNode(node.name);
    if (!node.isGetter) {
      _visitNode(node.typeParameters);
      _visitNode(node.parameters);
    }
    _visitFunctionWithPrefix(" ", node.body);
    return null;
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    if (node.isCascaded) {
      _writer.print("..");
    } else {
      if (node.target != null) {
        node.target.accept(this);
        _writer.print(node.operator.lexeme);
      }
    }
    _visitNode(node.methodName);
    _visitNode(node.typeArguments);
    _visitNode(node.argumentList);
    return null;
  }

  @override
  Object visitNamedExpression(NamedExpression node) {
    _visitNode(node.name);
    _visitNodeWithPrefix(" ", node.expression);
    return null;
  }

  @override
  Object visitNativeClause(NativeClause node) {
    _writer.print("native ");
    _visitNode(node.name);
    return null;
  }

  @override
  Object visitNativeFunctionBody(NativeFunctionBody node) {
    _writer.print("native ");
    _visitNode(node.stringLiteral);
    _writer.print(';');
    return null;
  }

  @override
  Object visitNullLiteral(NullLiteral node) {
    _writer.print("null");
    return null;
  }

  @override
  Object visitParenthesizedExpression(ParenthesizedExpression node) {
    _writer.print('(');
    _visitNode(node.expression);
    _writer.print(')');
    return null;
  }

  @override
  Object visitPartDirective(PartDirective node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _writer.print("part ");
    _visitNode(node.uri);
    _writer.print(';');
    return null;
  }

  @override
  Object visitPartOfDirective(PartOfDirective node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _writer.print("part of ");
    _visitNode(node.libraryName);
    _writer.print(';');
    return null;
  }

  @override
  Object visitPostfixExpression(PostfixExpression node) {
    _visitNode(node.operand);
    _writer.print(node.operator.lexeme);
    return null;
  }

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    _visitNode(node.prefix);
    _writer.print('.');
    _visitNode(node.identifier);
    return null;
  }

  @override
  Object visitPrefixExpression(PrefixExpression node) {
    _writer.print(node.operator.lexeme);
    _visitNode(node.operand);
    return null;
  }

  @override
  Object visitPropertyAccess(PropertyAccess node) {
    if (node.isCascaded) {
      _writer.print("..");
    } else {
      _visitNode(node.target);
      _writer.print(node.operator.lexeme);
    }
    _visitNode(node.propertyName);
    return null;
  }

  @override
  Object visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _writer.print("this");
    _visitNodeWithPrefix(".", node.constructorName);
    _visitNode(node.argumentList);
    return null;
  }

  @override
  Object visitRethrowExpression(RethrowExpression node) {
    _writer.print("rethrow");
    return null;
  }

  @override
  Object visitReturnStatement(ReturnStatement node) {
    Expression expression = node.expression;
    if (expression == null) {
      _writer.print("return;");
    } else {
      _writer.print("return ");
      expression.accept(this);
      _writer.print(";");
    }
    return null;
  }

  @override
  Object visitScriptTag(ScriptTag node) {
    _writer.print(node.scriptTag.lexeme);
    return null;
  }

  @override
  Object visitShowCombinator(ShowCombinator node) {
    _writer.print("show ");
    _visitNodeListWithSeparator(node.shownNames, ", ");
    return null;
  }

  @override
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, ' ', ' ');
    _visitTokenWithSuffix(node.covariantKeyword, ' ');
    _visitTokenWithSuffix(node.keyword, " ");
    _visitNode(node.type);
    if (node.type != null && node.identifier != null) {
      _writer.print(' ');
    }
    _visitNode(node.identifier);
    return null;
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    _writer.print(node.token.lexeme);
    return null;
  }

  @override
  Object visitSimpleStringLiteral(SimpleStringLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }

  @override
  Object visitStringInterpolation(StringInterpolation node) {
    _visitNodeList(node.elements);
    return null;
  }

  @override
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _writer.print("super");
    _visitNodeWithPrefix(".", node.constructorName);
    _visitNode(node.argumentList);
    return null;
  }

  @override
  Object visitSuperExpression(SuperExpression node) {
    _writer.print("super");
    return null;
  }

  @override
  Object visitSwitchCase(SwitchCase node) {
    _visitNodeListWithSeparatorAndSuffix(node.labels, " ", " ");
    _writer.print("case ");
    _visitNode(node.expression);
    _writer.print(": ");
    _visitNodeListWithSeparator(node.statements, " ");
    return null;
  }

  @override
  Object visitSwitchDefault(SwitchDefault node) {
    _visitNodeListWithSeparatorAndSuffix(node.labels, " ", " ");
    _writer.print("default: ");
    _visitNodeListWithSeparator(node.statements, " ");
    return null;
  }

  @override
  Object visitSwitchStatement(SwitchStatement node) {
    _writer.print("switch (");
    _visitNode(node.expression);
    _writer.print(") {");
    _visitNodeListWithSeparator(node.members, " ");
    _writer.print("}");
    return null;
  }

  @override
  Object visitSymbolLiteral(SymbolLiteral node) {
    _writer.print("#");
    List<Token> components = node.components;
    for (int i = 0; i < components.length; i++) {
      if (i > 0) {
        _writer.print(".");
      }
      _writer.print(components[i].lexeme);
    }
    return null;
  }

  @override
  Object visitThisExpression(ThisExpression node) {
    _writer.print("this");
    return null;
  }

  @override
  Object visitThrowExpression(ThrowExpression node) {
    _writer.print("throw ");
    _visitNode(node.expression);
    return null;
  }

  @override
  Object visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _visitNodeWithSuffix(node.variables, ";");
    return null;
  }

  @override
  Object visitTryStatement(TryStatement node) {
    _writer.print("try ");
    _visitNode(node.body);
    _visitNodeListWithSeparatorAndPrefix(" ", node.catchClauses, " ");
    _visitNodeWithPrefix(" finally ", node.finallyBlock);
    return null;
  }

  @override
  Object visitTypeArgumentList(TypeArgumentList node) {
    _writer.print('<');
    _visitNodeListWithSeparator(node.arguments, ", ");
    _writer.print('>');
    return null;
  }

  @override
  Object visitTypeName(TypeName node) {
    _visitNode(node.name);
    _visitNode(node.typeArguments);
    if (node.question != null) {
      _writer.print('?');
    }
    return null;
  }

  @override
  Object visitTypeParameter(TypeParameter node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitNode(node.name);
    _visitNodeWithPrefix(" extends ", node.bound);
    return null;
  }

  @override
  Object visitTypeParameterList(TypeParameterList node) {
    _writer.print('<');
    _visitNodeListWithSeparator(node.typeParameters, ", ");
    _writer.print('>');
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitNode(node.name);
    _visitNodeWithPrefix(" = ", node.initializer);
    return null;
  }

  @override
  Object visitVariableDeclarationList(VariableDeclarationList node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitTokenWithSuffix(node.keyword, " ");
    _visitNodeWithSuffix(node.type, " ");
    _visitNodeListWithSeparator(node.variables, ", ");
    return null;
  }

  @override
  Object visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _visitNode(node.variables);
    _writer.print(";");
    return null;
  }

  @override
  Object visitWhileStatement(WhileStatement node) {
    _writer.print("while (");
    _visitNode(node.condition);
    _writer.print(") ");
    _visitNode(node.body);
    return null;
  }

  @override
  Object visitWithClause(WithClause node) {
    _writer.print("with ");
    _visitNodeListWithSeparator(node.mixinTypes, ", ");
    return null;
  }

  @override
  Object visitYieldStatement(YieldStatement node) {
    if (node.star != null) {
      _writer.print("yield* ");
    } else {
      _writer.print("yield ");
    }
    _visitNode(node.expression);
    _writer.print(";");
    return null;
  }

  /**
   * Visit the given function [body], printing the [prefix] before if the body
   * is not empty.
   */
  void _visitFunctionWithPrefix(String prefix, FunctionBody body) {
    if (body is! EmptyFunctionBody) {
      _writer.print(prefix);
    }
    _visitNode(body);
  }

  /**
   * Safely visit the given [node].
   */
  void _visitNode(AstNode node) {
    if (node != null) {
      node.accept(this);
    }
  }

  /**
   * Print a list of [nodes] without any separation.
   */
  void _visitNodeList(NodeList<AstNode> nodes) {
    _visitNodeListWithSeparator(nodes, "");
  }

  /**
   * Print a list of [nodes], separated by the given [separator].
   */
  void _visitNodeListWithSeparator(NodeList<AstNode> nodes, String separator) {
    if (nodes != null) {
      int size = nodes.length;
      for (int i = 0; i < size; i++) {
        if (i > 0) {
          _writer.print(separator);
        }
        nodes[i].accept(this);
      }
    }
  }

  /**
   * Print a list of [nodes], prefixed by the given [prefix] if the list is not
   * empty, and separated by the given [separator].
   */
  void _visitNodeListWithSeparatorAndPrefix(
      String prefix, NodeList<AstNode> nodes, String separator) {
    if (nodes != null) {
      int size = nodes.length;
      if (size > 0) {
        _writer.print(prefix);
        for (int i = 0; i < size; i++) {
          if (i > 0) {
            _writer.print(separator);
          }
          nodes[i].accept(this);
        }
      }
    }
  }

  /**
   * Print a list of [nodes], separated by the given [separator], followed by
   * the given [suffix] if the list is not empty.
   */
  void _visitNodeListWithSeparatorAndSuffix(
      NodeList<AstNode> nodes, String separator, String suffix) {
    if (nodes != null) {
      int size = nodes.length;
      if (size > 0) {
        for (int i = 0; i < size; i++) {
          if (i > 0) {
            _writer.print(separator);
          }
          nodes[i].accept(this);
        }
        _writer.print(suffix);
      }
    }
  }

  /**
   * Safely visit the given [node], printing the [prefix] before the node if it
   * is non-`null`.
   */
  void _visitNodeWithPrefix(String prefix, AstNode node) {
    if (node != null) {
      _writer.print(prefix);
      node.accept(this);
    }
  }

  /**
   * Safely visit the given [node], printing the [suffix] after the node if it
   * is non-`null`.
   */
  void _visitNodeWithSuffix(AstNode node, String suffix) {
    if (node != null) {
      node.accept(this);
      _writer.print(suffix);
    }
  }

  /**
   * Safely visit the given [token], printing the [suffix] after the token if it
   * is non-`null`.
   */
  void _visitTokenWithSuffix(Token token, String suffix) {
    if (token != null) {
      _writer.print(token.lexeme);
      _writer.print(suffix);
    }
  }
}

/**
 * A visitor used to write a source representation of a visited AST node (and
 * all of it's children) to a sink.
 */
class ToSourceVisitor2 implements AstVisitor<Object> {
  /**
   * The sink to which the source is to be written.
   */
  @protected
  final StringSink sink;

  /**
   * Initialize a newly created visitor to write source code representing the
   * visited nodes to the given [sink].
   */
  ToSourceVisitor2(this.sink);

  /**
   * Visit the given function [body], printing the [prefix] before if the body
   * is not empty.
   */
  @protected
  void safelyVisitFunctionWithPrefix(String prefix, FunctionBody body) {
    if (body is! EmptyFunctionBody) {
      sink.write(prefix);
    }
    safelyVisitNode(body);
  }

  /**
   * Safely visit the given [node].
   */
  @protected
  void safelyVisitNode(AstNode node) {
    if (node != null) {
      node.accept(this);
    }
  }

  /**
   * Print a list of [nodes] without any separation.
   */
  @protected
  void safelyVisitNodeList(NodeList<AstNode> nodes) {
    safelyVisitNodeListWithSeparator(nodes, "");
  }

  /**
   * Print a list of [nodes], separated by the given [separator].
   */
  @protected
  void safelyVisitNodeListWithSeparator(
      NodeList<AstNode> nodes, String separator) {
    if (nodes != null) {
      int size = nodes.length;
      for (int i = 0; i < size; i++) {
        if (i > 0) {
          sink.write(separator);
        }
        nodes[i].accept(this);
      }
    }
  }

  /**
   * Print a list of [nodes], prefixed by the given [prefix] if the list is not
   * empty, and separated by the given [separator].
   */
  @protected
  void safelyVisitNodeListWithSeparatorAndPrefix(
      String prefix, NodeList<AstNode> nodes, String separator) {
    if (nodes != null) {
      int size = nodes.length;
      if (size > 0) {
        sink.write(prefix);
        for (int i = 0; i < size; i++) {
          if (i > 0) {
            sink.write(separator);
          }
          nodes[i].accept(this);
        }
      }
    }
  }

  /**
   * Print a list of [nodes], separated by the given [separator], followed by
   * the given [suffix] if the list is not empty.
   */
  @protected
  void safelyVisitNodeListWithSeparatorAndSuffix(
      NodeList<AstNode> nodes, String separator, String suffix) {
    if (nodes != null) {
      int size = nodes.length;
      if (size > 0) {
        for (int i = 0; i < size; i++) {
          if (i > 0) {
            sink.write(separator);
          }
          nodes[i].accept(this);
        }
        sink.write(suffix);
      }
    }
  }

  /**
   * Safely visit the given [node], printing the [prefix] before the node if it
   * is non-`null`.
   */
  @protected
  void safelyVisitNodeWithPrefix(String prefix, AstNode node) {
    if (node != null) {
      sink.write(prefix);
      node.accept(this);
    }
  }

  /**
   * Safely visit the given [node], printing the [suffix] after the node if it
   * is non-`null`.
   */
  @protected
  void safelyVisitNodeWithSuffix(AstNode node, String suffix) {
    if (node != null) {
      node.accept(this);
      sink.write(suffix);
    }
  }

  /**
   * Safely visit the given [token], printing the [suffix] after the token if it
   * is non-`null`.
   */
  @protected
  void safelyVisitTokenWithSuffix(Token token, String suffix) {
    if (token != null) {
      sink.write(token.lexeme);
      sink.write(suffix);
    }
  }

  @override
  Object visitAdjacentStrings(AdjacentStrings node) {
    safelyVisitNodeListWithSeparator(node.strings, " ");
    return null;
  }

  @override
  Object visitAnnotation(Annotation node) {
    sink.write('@');
    safelyVisitNode(node.name);
    safelyVisitNodeWithPrefix(".", node.constructorName);
    safelyVisitNode(node.arguments);
    return null;
  }

  @override
  Object visitArgumentList(ArgumentList node) {
    sink.write('(');
    safelyVisitNodeListWithSeparator(node.arguments, ", ");
    sink.write(')');
    return null;
  }

  @override
  Object visitAsExpression(AsExpression node) {
    safelyVisitNode(node.expression);
    sink.write(" as ");
    safelyVisitNode(node.type);
    return null;
  }

  @override
  bool visitAssertInitializer(AssertInitializer node) {
    sink.write("assert (");
    safelyVisitNode(node.condition);
    if (node.message != null) {
      sink.write(', ');
      safelyVisitNode(node.message);
    }
    sink.write(");");
    return null;
  }

  @override
  Object visitAssertStatement(AssertStatement node) {
    sink.write("assert (");
    safelyVisitNode(node.condition);
    if (node.message != null) {
      sink.write(', ');
      safelyVisitNode(node.message);
    }
    sink.write(");");
    return null;
  }

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    safelyVisitNode(node.leftHandSide);
    sink.write(' ');
    sink.write(node.operator.lexeme);
    sink.write(' ');
    safelyVisitNode(node.rightHandSide);
    return null;
  }

  @override
  Object visitAwaitExpression(AwaitExpression node) {
    sink.write("await ");
    safelyVisitNode(node.expression);
    return null;
  }

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    safelyVisitNode(node.leftOperand);
    sink.write(' ');
    sink.write(node.operator.lexeme);
    sink.write(' ');
    safelyVisitNode(node.rightOperand);
    return null;
  }

  @override
  Object visitBlock(Block node) {
    sink.write('{');
    safelyVisitNodeListWithSeparator(node.statements, " ");
    sink.write('}');
    return null;
  }

  @override
  Object visitBlockFunctionBody(BlockFunctionBody node) {
    Token keyword = node.keyword;
    if (keyword != null) {
      sink.write(keyword.lexeme);
      if (node.star != null) {
        sink.write('*');
      }
      sink.write(' ');
    }
    safelyVisitNode(node.block);
    return null;
  }

  @override
  Object visitBooleanLiteral(BooleanLiteral node) {
    sink.write(node.literal.lexeme);
    return null;
  }

  @override
  Object visitBreakStatement(BreakStatement node) {
    sink.write("break");
    safelyVisitNodeWithPrefix(" ", node.label);
    sink.write(";");
    return null;
  }

  @override
  Object visitCascadeExpression(CascadeExpression node) {
    safelyVisitNode(node.target);
    safelyVisitNodeList(node.cascadeSections);
    return null;
  }

  @override
  Object visitCatchClause(CatchClause node) {
    safelyVisitNodeWithPrefix("on ", node.exceptionType);
    if (node.catchKeyword != null) {
      if (node.exceptionType != null) {
        sink.write(' ');
      }
      sink.write("catch (");
      safelyVisitNode(node.exceptionParameter);
      safelyVisitNodeWithPrefix(", ", node.stackTraceParameter);
      sink.write(") ");
    } else {
      sink.write(" ");
    }
    safelyVisitNode(node.body);
    return null;
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitTokenWithSuffix(node.abstractKeyword, " ");
    sink.write("class ");
    safelyVisitNode(node.name);
    safelyVisitNode(node.typeParameters);
    safelyVisitNodeWithPrefix(" ", node.extendsClause);
    safelyVisitNodeWithPrefix(" ", node.withClause);
    safelyVisitNodeWithPrefix(" ", node.implementsClause);
    sink.write(" {");
    safelyVisitNodeListWithSeparator(node.members, " ");
    sink.write("}");
    return null;
  }

  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    if (node.abstractKeyword != null) {
      sink.write("abstract ");
    }
    sink.write("class ");
    safelyVisitNode(node.name);
    safelyVisitNode(node.typeParameters);
    sink.write(" = ");
    safelyVisitNode(node.superclass);
    safelyVisitNodeWithPrefix(" ", node.withClause);
    safelyVisitNodeWithPrefix(" ", node.implementsClause);
    sink.write(";");
    return null;
  }

  @override
  Object visitComment(Comment node) => null;

  @override
  Object visitCommentReference(CommentReference node) => null;

  @override
  Object visitCompilationUnit(CompilationUnit node) {
    ScriptTag scriptTag = node.scriptTag;
    NodeList<Directive> directives = node.directives;
    safelyVisitNode(scriptTag);
    String prefix = scriptTag == null ? "" : " ";
    safelyVisitNodeListWithSeparatorAndPrefix(prefix, directives, " ");
    prefix = scriptTag == null && directives.isEmpty ? "" : " ";
    safelyVisitNodeListWithSeparatorAndPrefix(prefix, node.declarations, " ");
    return null;
  }

  @override
  Object visitConditionalExpression(ConditionalExpression node) {
    safelyVisitNode(node.condition);
    sink.write(" ? ");
    safelyVisitNode(node.thenExpression);
    sink.write(" : ");
    safelyVisitNode(node.elseExpression);
    return null;
  }

  @override
  Object visitConfiguration(Configuration node) {
    sink.write('if (');
    safelyVisitNode(node.name);
    safelyVisitNodeWithPrefix(" == ", node.value);
    sink.write(') ');
    safelyVisitNode(node.uri);
    return null;
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitTokenWithSuffix(node.externalKeyword, " ");
    safelyVisitTokenWithSuffix(node.constKeyword, " ");
    safelyVisitTokenWithSuffix(node.factoryKeyword, " ");
    safelyVisitNode(node.returnType);
    safelyVisitNodeWithPrefix(".", node.name);
    safelyVisitNode(node.parameters);
    safelyVisitNodeListWithSeparatorAndPrefix(" : ", node.initializers, ", ");
    safelyVisitNodeWithPrefix(" = ", node.redirectedConstructor);
    safelyVisitFunctionWithPrefix(" ", node.body);
    return null;
  }

  @override
  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    safelyVisitTokenWithSuffix(node.thisKeyword, ".");
    safelyVisitNode(node.fieldName);
    sink.write(" = ");
    safelyVisitNode(node.expression);
    return null;
  }

  @override
  Object visitConstructorName(ConstructorName node) {
    safelyVisitNode(node.type);
    safelyVisitNodeWithPrefix(".", node.name);
    return null;
  }

  @override
  Object visitContinueStatement(ContinueStatement node) {
    sink.write("continue");
    safelyVisitNodeWithPrefix(" ", node.label);
    sink.write(";");
    return null;
  }

  @override
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitTokenWithSuffix(node.keyword, " ");
    safelyVisitNodeWithSuffix(node.type, " ");
    safelyVisitNode(node.identifier);
    return null;
  }

  @override
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    safelyVisitNode(node.parameter);
    if (node.separator != null) {
      sink.write(" ");
      sink.write(node.separator.lexeme);
      safelyVisitNodeWithPrefix(" ", node.defaultValue);
    }
    return null;
  }

  @override
  Object visitDoStatement(DoStatement node) {
    sink.write("do ");
    safelyVisitNode(node.body);
    sink.write(" while (");
    safelyVisitNode(node.condition);
    sink.write(");");
    return null;
  }

  @override
  Object visitDottedName(DottedName node) {
    safelyVisitNodeListWithSeparator(node.components, ".");
    return null;
  }

  @override
  Object visitDoubleLiteral(DoubleLiteral node) {
    sink.write(node.literal.lexeme);
    return null;
  }

  @override
  Object visitEmptyFunctionBody(EmptyFunctionBody node) {
    sink.write(';');
    return null;
  }

  @override
  Object visitEmptyStatement(EmptyStatement node) {
    sink.write(';');
    return null;
  }

  @override
  Object visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitNode(node.name);
    return null;
  }

  @override
  Object visitEnumDeclaration(EnumDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    sink.write("enum ");
    safelyVisitNode(node.name);
    sink.write(" {");
    safelyVisitNodeListWithSeparator(node.constants, ", ");
    sink.write("}");
    return null;
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    sink.write("export ");
    safelyVisitNode(node.uri);
    safelyVisitNodeListWithSeparatorAndPrefix(" ", node.combinators, " ");
    sink.write(';');
    return null;
  }

  @override
  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    Token keyword = node.keyword;
    if (keyword != null) {
      sink.write(keyword.lexeme);
      sink.write(' ');
    }
    sink.write("=> ");
    safelyVisitNode(node.expression);
    if (node.semicolon != null) {
      sink.write(';');
    }
    return null;
  }

  @override
  Object visitExpressionStatement(ExpressionStatement node) {
    safelyVisitNode(node.expression);
    sink.write(';');
    return null;
  }

  @override
  Object visitExtendsClause(ExtendsClause node) {
    sink.write("extends ");
    safelyVisitNode(node.superclass);
    return null;
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitTokenWithSuffix(node.staticKeyword, " ");
    safelyVisitNode(node.fields);
    sink.write(";");
    return null;
  }

  @override
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, ' ', ' ');
    safelyVisitTokenWithSuffix(node.covariantKeyword, ' ');
    safelyVisitTokenWithSuffix(node.keyword, " ");
    safelyVisitNodeWithSuffix(node.type, " ");
    sink.write("this.");
    safelyVisitNode(node.identifier);
    safelyVisitNode(node.typeParameters);
    safelyVisitNode(node.parameters);
    return null;
  }

  @override
  Object visitForEachStatement(ForEachStatement node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (node.awaitKeyword != null) {
      sink.write("await ");
    }
    sink.write("for (");
    if (loopVariable == null) {
      safelyVisitNode(node.identifier);
    } else {
      safelyVisitNode(loopVariable);
    }
    sink.write(" in ");
    safelyVisitNode(node.iterable);
    sink.write(") ");
    safelyVisitNode(node.body);
    return null;
  }

  @override
  Object visitFormalParameterList(FormalParameterList node) {
    String groupEnd = null;
    sink.write('(');
    NodeList<FormalParameter> parameters = node.parameters;
    int size = parameters.length;
    for (int i = 0; i < size; i++) {
      FormalParameter parameter = parameters[i];
      if (i > 0) {
        sink.write(", ");
      }
      if (groupEnd == null && parameter is DefaultFormalParameter) {
        if (parameter.kind == ParameterKind.NAMED) {
          groupEnd = "}";
          sink.write('{');
        } else {
          groupEnd = "]";
          sink.write('[');
        }
      }
      parameter.accept(this);
    }
    if (groupEnd != null) {
      sink.write(groupEnd);
    }
    sink.write(')');
    return null;
  }

  @override
  Object visitForStatement(ForStatement node) {
    Expression initialization = node.initialization;
    sink.write("for (");
    if (initialization != null) {
      safelyVisitNode(initialization);
    } else {
      safelyVisitNode(node.variables);
    }
    sink.write(";");
    safelyVisitNodeWithPrefix(" ", node.condition);
    sink.write(";");
    safelyVisitNodeListWithSeparatorAndPrefix(" ", node.updaters, ", ");
    sink.write(") ");
    safelyVisitNode(node.body);
    return null;
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitTokenWithSuffix(node.externalKeyword, " ");
    safelyVisitNodeWithSuffix(node.returnType, " ");
    safelyVisitTokenWithSuffix(node.propertyKeyword, " ");
    safelyVisitNode(node.name);
    safelyVisitNode(node.functionExpression);
    return null;
  }

  @override
  Object visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    safelyVisitNode(node.functionDeclaration);
    return null;
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    safelyVisitNode(node.typeParameters);
    safelyVisitNode(node.parameters);
    if (node.body is! EmptyFunctionBody) {
      sink.write(' ');
    }
    safelyVisitNode(node.body);
    return null;
  }

  @override
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    safelyVisitNode(node.function);
    safelyVisitNode(node.typeArguments);
    safelyVisitNode(node.argumentList);
    return null;
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    sink.write("typedef ");
    safelyVisitNodeWithSuffix(node.returnType, " ");
    safelyVisitNode(node.name);
    safelyVisitNode(node.typeParameters);
    safelyVisitNode(node.parameters);
    sink.write(";");
    return null;
  }

  @override
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, ' ', ' ');
    safelyVisitTokenWithSuffix(node.covariantKeyword, ' ');
    safelyVisitNodeWithSuffix(node.returnType, " ");
    safelyVisitNode(node.identifier);
    safelyVisitNode(node.typeParameters);
    safelyVisitNode(node.parameters);
    if (node.question != null) {
      sink.write('?');
    }
    return null;
  }

  @override
  Object visitGenericFunctionType(GenericFunctionType node) {
    safelyVisitNode(node.returnType);
    sink.write(' Function');
    safelyVisitNode(node.typeParameters);
    safelyVisitNode(node.parameters);
    return null;
  }

  @override
  Object visitGenericTypeAlias(GenericTypeAlias node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    sink.write("typedef ");
    safelyVisitNode(node.name);
    safelyVisitNode(node.typeParameters);
    sink.write(" = ");
    safelyVisitNode(node.functionType);
    return null;
  }

  @override
  Object visitHideCombinator(HideCombinator node) {
    sink.write("hide ");
    safelyVisitNodeListWithSeparator(node.hiddenNames, ", ");
    return null;
  }

  @override
  Object visitIfStatement(IfStatement node) {
    sink.write("if (");
    safelyVisitNode(node.condition);
    sink.write(") ");
    safelyVisitNode(node.thenStatement);
    safelyVisitNodeWithPrefix(" else ", node.elseStatement);
    return null;
  }

  @override
  Object visitImplementsClause(ImplementsClause node) {
    sink.write("implements ");
    safelyVisitNodeListWithSeparator(node.interfaces, ", ");
    return null;
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    sink.write("import ");
    safelyVisitNode(node.uri);
    if (node.deferredKeyword != null) {
      sink.write(" deferred");
    }
    safelyVisitNodeWithPrefix(" as ", node.prefix);
    safelyVisitNodeListWithSeparatorAndPrefix(" ", node.combinators, " ");
    sink.write(';');
    return null;
  }

  @override
  Object visitIndexExpression(IndexExpression node) {
    if (node.isCascaded) {
      sink.write("..");
    } else {
      safelyVisitNode(node.target);
    }
    sink.write('[');
    safelyVisitNode(node.index);
    sink.write(']');
    return null;
  }

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    safelyVisitTokenWithSuffix(node.keyword, " ");
    safelyVisitNode(node.constructorName);
    safelyVisitNode(node.argumentList);
    return null;
  }

  @override
  Object visitIntegerLiteral(IntegerLiteral node) {
    sink.write(node.literal.lexeme);
    return null;
  }

  @override
  Object visitInterpolationExpression(InterpolationExpression node) {
    if (node.rightBracket != null) {
      sink.write("\${");
      safelyVisitNode(node.expression);
      sink.write("}");
    } else {
      sink.write("\$");
      safelyVisitNode(node.expression);
    }
    return null;
  }

  @override
  Object visitInterpolationString(InterpolationString node) {
    sink.write(node.contents.lexeme);
    return null;
  }

  @override
  Object visitIsExpression(IsExpression node) {
    safelyVisitNode(node.expression);
    if (node.notOperator == null) {
      sink.write(" is ");
    } else {
      sink.write(" is! ");
    }
    safelyVisitNode(node.type);
    return null;
  }

  @override
  Object visitLabel(Label node) {
    safelyVisitNode(node.label);
    sink.write(":");
    return null;
  }

  @override
  Object visitLabeledStatement(LabeledStatement node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.labels, " ", " ");
    safelyVisitNode(node.statement);
    return null;
  }

  @override
  Object visitLibraryDirective(LibraryDirective node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    sink.write("library ");
    safelyVisitNode(node.name);
    sink.write(';');
    return null;
  }

  @override
  Object visitLibraryIdentifier(LibraryIdentifier node) {
    sink.write(node.name);
    return null;
  }

  @override
  Object visitListLiteral(ListLiteral node) {
    if (node.constKeyword != null) {
      sink.write(node.constKeyword.lexeme);
      sink.write(' ');
    }
    safelyVisitNodeWithSuffix(node.typeArguments, " ");
    sink.write("[");
    safelyVisitNodeListWithSeparator(node.elements, ", ");
    sink.write("]");
    return null;
  }

  @override
  Object visitMapLiteral(MapLiteral node) {
    if (node.constKeyword != null) {
      sink.write(node.constKeyword.lexeme);
      sink.write(' ');
    }
    safelyVisitNodeWithSuffix(node.typeArguments, " ");
    sink.write("{");
    safelyVisitNodeListWithSeparator(node.entries, ", ");
    sink.write("}");
    return null;
  }

  @override
  Object visitMapLiteralEntry(MapLiteralEntry node) {
    safelyVisitNode(node.key);
    sink.write(" : ");
    safelyVisitNode(node.value);
    return null;
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitTokenWithSuffix(node.externalKeyword, " ");
    safelyVisitTokenWithSuffix(node.modifierKeyword, " ");
    safelyVisitNodeWithSuffix(node.returnType, " ");
    safelyVisitTokenWithSuffix(node.propertyKeyword, " ");
    safelyVisitTokenWithSuffix(node.operatorKeyword, " ");
    safelyVisitNode(node.name);
    if (!node.isGetter) {
      safelyVisitNode(node.typeParameters);
      safelyVisitNode(node.parameters);
    }
    safelyVisitFunctionWithPrefix(" ", node.body);
    return null;
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    if (node.isCascaded) {
      sink.write("..");
    } else {
      if (node.target != null) {
        node.target.accept(this);
        sink.write(node.operator.lexeme);
      }
    }
    safelyVisitNode(node.methodName);
    safelyVisitNode(node.typeArguments);
    safelyVisitNode(node.argumentList);
    return null;
  }

  @override
  Object visitNamedExpression(NamedExpression node) {
    safelyVisitNode(node.name);
    safelyVisitNodeWithPrefix(" ", node.expression);
    return null;
  }

  @override
  Object visitNativeClause(NativeClause node) {
    sink.write("native ");
    safelyVisitNode(node.name);
    return null;
  }

  @override
  Object visitNativeFunctionBody(NativeFunctionBody node) {
    sink.write("native ");
    safelyVisitNode(node.stringLiteral);
    sink.write(';');
    return null;
  }

  @override
  Object visitNullLiteral(NullLiteral node) {
    sink.write("null");
    return null;
  }

  @override
  Object visitParenthesizedExpression(ParenthesizedExpression node) {
    sink.write('(');
    safelyVisitNode(node.expression);
    sink.write(')');
    return null;
  }

  @override
  Object visitPartDirective(PartDirective node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    sink.write("part ");
    safelyVisitNode(node.uri);
    sink.write(';');
    return null;
  }

  @override
  Object visitPartOfDirective(PartOfDirective node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    sink.write("part of ");
    safelyVisitNode(node.libraryName);
    sink.write(';');
    return null;
  }

  @override
  Object visitPostfixExpression(PostfixExpression node) {
    safelyVisitNode(node.operand);
    sink.write(node.operator.lexeme);
    return null;
  }

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    safelyVisitNode(node.prefix);
    sink.write('.');
    safelyVisitNode(node.identifier);
    return null;
  }

  @override
  Object visitPrefixExpression(PrefixExpression node) {
    sink.write(node.operator.lexeme);
    safelyVisitNode(node.operand);
    return null;
  }

  @override
  Object visitPropertyAccess(PropertyAccess node) {
    if (node.isCascaded) {
      sink.write("..");
    } else {
      safelyVisitNode(node.target);
      sink.write(node.operator.lexeme);
    }
    safelyVisitNode(node.propertyName);
    return null;
  }

  @override
  Object visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    sink.write("this");
    safelyVisitNodeWithPrefix(".", node.constructorName);
    safelyVisitNode(node.argumentList);
    return null;
  }

  @override
  Object visitRethrowExpression(RethrowExpression node) {
    sink.write("rethrow");
    return null;
  }

  @override
  Object visitReturnStatement(ReturnStatement node) {
    Expression expression = node.expression;
    if (expression == null) {
      sink.write("return;");
    } else {
      sink.write("return ");
      expression.accept(this);
      sink.write(";");
    }
    return null;
  }

  @override
  Object visitScriptTag(ScriptTag node) {
    sink.write(node.scriptTag.lexeme);
    return null;
  }

  @override
  Object visitShowCombinator(ShowCombinator node) {
    sink.write("show ");
    safelyVisitNodeListWithSeparator(node.shownNames, ", ");
    return null;
  }

  @override
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, ' ', ' ');
    safelyVisitTokenWithSuffix(node.covariantKeyword, ' ');
    safelyVisitTokenWithSuffix(node.keyword, " ");
    safelyVisitNode(node.type);
    if (node.type != null && node.identifier != null) {
      sink.write(' ');
    }
    safelyVisitNode(node.identifier);
    return null;
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    sink.write(node.token.lexeme);
    return null;
  }

  @override
  Object visitSimpleStringLiteral(SimpleStringLiteral node) {
    sink.write(node.literal.lexeme);
    return null;
  }

  @override
  Object visitStringInterpolation(StringInterpolation node) {
    safelyVisitNodeList(node.elements);
    return null;
  }

  @override
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    sink.write("super");
    safelyVisitNodeWithPrefix(".", node.constructorName);
    safelyVisitNode(node.argumentList);
    return null;
  }

  @override
  Object visitSuperExpression(SuperExpression node) {
    sink.write("super");
    return null;
  }

  @override
  Object visitSwitchCase(SwitchCase node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.labels, " ", " ");
    sink.write("case ");
    safelyVisitNode(node.expression);
    sink.write(": ");
    safelyVisitNodeListWithSeparator(node.statements, " ");
    return null;
  }

  @override
  Object visitSwitchDefault(SwitchDefault node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.labels, " ", " ");
    sink.write("default: ");
    safelyVisitNodeListWithSeparator(node.statements, " ");
    return null;
  }

  @override
  Object visitSwitchStatement(SwitchStatement node) {
    sink.write("switch (");
    safelyVisitNode(node.expression);
    sink.write(") {");
    safelyVisitNodeListWithSeparator(node.members, " ");
    sink.write("}");
    return null;
  }

  @override
  Object visitSymbolLiteral(SymbolLiteral node) {
    sink.write("#");
    List<Token> components = node.components;
    for (int i = 0; i < components.length; i++) {
      if (i > 0) {
        sink.write(".");
      }
      sink.write(components[i].lexeme);
    }
    return null;
  }

  @override
  Object visitThisExpression(ThisExpression node) {
    sink.write("this");
    return null;
  }

  @override
  Object visitThrowExpression(ThrowExpression node) {
    sink.write("throw ");
    safelyVisitNode(node.expression);
    return null;
  }

  @override
  Object visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    safelyVisitNodeWithSuffix(node.variables, ";");
    return null;
  }

  @override
  Object visitTryStatement(TryStatement node) {
    sink.write("try ");
    safelyVisitNode(node.body);
    safelyVisitNodeListWithSeparatorAndPrefix(" ", node.catchClauses, " ");
    safelyVisitNodeWithPrefix(" finally ", node.finallyBlock);
    return null;
  }

  @override
  Object visitTypeArgumentList(TypeArgumentList node) {
    sink.write('<');
    safelyVisitNodeListWithSeparator(node.arguments, ", ");
    sink.write('>');
    return null;
  }

  @override
  Object visitTypeName(TypeName node) {
    safelyVisitNode(node.name);
    safelyVisitNode(node.typeArguments);
    if (node.question != null) {
      sink.write('?');
    }
    return null;
  }

  @override
  Object visitTypeParameter(TypeParameter node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitNode(node.name);
    safelyVisitNodeWithPrefix(" extends ", node.bound);
    return null;
  }

  @override
  Object visitTypeParameterList(TypeParameterList node) {
    sink.write('<');
    safelyVisitNodeListWithSeparator(node.typeParameters, ", ");
    sink.write('>');
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitNode(node.name);
    safelyVisitNodeWithPrefix(" = ", node.initializer);
    return null;
  }

  @override
  Object visitVariableDeclarationList(VariableDeclarationList node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitTokenWithSuffix(node.keyword, " ");
    safelyVisitNodeWithSuffix(node.type, " ");
    safelyVisitNodeListWithSeparator(node.variables, ", ");
    return null;
  }

  @override
  Object visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    safelyVisitNode(node.variables);
    sink.write(";");
    return null;
  }

  @override
  Object visitWhileStatement(WhileStatement node) {
    sink.write("while (");
    safelyVisitNode(node.condition);
    sink.write(") ");
    safelyVisitNode(node.body);
    return null;
  }

  @override
  Object visitWithClause(WithClause node) {
    sink.write("with ");
    safelyVisitNodeListWithSeparator(node.mixinTypes, ", ");
    return null;
  }

  @override
  Object visitYieldStatement(YieldStatement node) {
    if (node.star != null) {
      sink.write("yield* ");
    } else {
      sink.write("yield ");
    }
    safelyVisitNode(node.expression);
    sink.write(";");
    return null;
  }
}
