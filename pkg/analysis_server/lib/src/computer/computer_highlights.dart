// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library computer.highlights;

import 'package:analysis_server/plugin/protocol/protocol.dart' hide Element;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/**
 * A computer for [HighlightRegion]s in a Dart [CompilationUnit].
 */
class DartUnitHighlightsComputer {
  final CompilationUnit _unit;

  final List<HighlightRegion> _regions = <HighlightRegion>[];

  DartUnitHighlightsComputer(this._unit);

  /**
   * Returns the computed highlight regions, not `null`.
   */
  List<HighlightRegion> compute() {
    _unit.accept(new _DartUnitHighlightsComputerVisitor(this));
    _addCommentRanges();
    return _regions;
  }

  void _addCommentRanges() {
    Token token = _unit.beginToken;
    while (token != null && token.type != TokenType.EOF) {
      Token commentToken = token.precedingComments;
      while (commentToken != null) {
        HighlightRegionType highlightType = null;
        if (commentToken.type == TokenType.MULTI_LINE_COMMENT) {
          if (commentToken.lexeme.startsWith('/**')) {
            highlightType = HighlightRegionType.COMMENT_DOCUMENTATION;
          } else {
            highlightType = HighlightRegionType.COMMENT_BLOCK;
          }
        }
        if (commentToken.type == TokenType.SINGLE_LINE_COMMENT) {
          highlightType = HighlightRegionType.COMMENT_END_OF_LINE;
        }
        if (highlightType != null) {
          _addRegion_token(commentToken, highlightType);
        }
        commentToken = commentToken.next;
      }
      token = token.next;
    }
  }

  void _addIdentifierRegion(SimpleIdentifier node) {
    if (_addIdentifierRegion_keyword(node)) {
      return;
    }
    if (_addIdentifierRegion_class(node)) {
      return;
    }
    if (_addIdentifierRegion_constructor(node)) {
      return;
    }
    if (_addIdentifierRegion_dynamicType(node)) {
      return;
    }
    if (_addIdentifierRegion_getterSetterDeclaration(node)) {
      return;
    }
    if (_addIdentifierRegion_field(node)) {
      return;
    }
    if (_addIdentifierRegion_function(node)) {
      return;
    }
    if (_addIdentifierRegion_functionTypeAlias(node)) {
      return;
    }
    if (_addIdentifierRegion_importPrefix(node)) {
      return;
    }
    if (_addIdentifierRegion_label(node)) {
      return;
    }
    if (_addIdentifierRegion_localVariable(node)) {
      return;
    }
    if (_addIdentifierRegion_method(node)) {
      return;
    }
    if (_addIdentifierRegion_parameter(node)) {
      return;
    }
    if (_addIdentifierRegion_typeParameter(node)) {
      return;
    }
    _addRegion_node(node, HighlightRegionType.IDENTIFIER_DEFAULT);
  }

  void _addIdentifierRegion_annotation(Annotation node) {
    ArgumentList arguments = node.arguments;
    if (arguments == null) {
      _addRegion_node(node, HighlightRegionType.ANNOTATION);
    } else {
      _addRegion_nodeStart_tokenEnd(
          node, arguments.beginToken, HighlightRegionType.ANNOTATION);
      _addRegion_token(arguments.endToken, HighlightRegionType.ANNOTATION);
    }
  }

  bool _addIdentifierRegion_class(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! ClassElement) {
      return false;
    }
    ClassElement classElement = element;
    // prepare type
    HighlightRegionType type;
    if (classElement.isEnum) {
      type = HighlightRegionType.ENUM;
    } else {
      type = HighlightRegionType.CLASS;
    }
    // add region
    return _addRegion_node(node, type);
  }

  bool _addIdentifierRegion_constructor(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! ConstructorElement) {
      return false;
    }
    return _addRegion_node(node, HighlightRegionType.CONSTRUCTOR);
  }

  bool _addIdentifierRegion_dynamicType(SimpleIdentifier node) {
    // should be variable
    Element element = node.staticElement;
    if (element is! VariableElement) {
      return false;
    }
    // has propagated type
    if (node.propagatedType != null) {
      return false;
    }
    // has dynamic static type
    DartType staticType = node.staticType;
    if (staticType == null || !staticType.isDynamic) {
      return false;
    }
    // OK
    return _addRegion_node(node, HighlightRegionType.DYNAMIC_TYPE);
  }

  bool _addIdentifierRegion_field(SimpleIdentifier node) {
    Element element = node.bestElement;
    if (element is FieldFormalParameterElement) {
      element = (element as FieldFormalParameterElement).field;
    }
    if (element is PropertyAccessorElement) {
      element = (element as PropertyAccessorElement).variable;
    }
    // prepare type
    HighlightRegionType type;
    if (element is FieldElement) {
      Element enclosingElement = element.enclosingElement;
      if (enclosingElement is ClassElement && enclosingElement.isEnum) {
        type = HighlightRegionType.ENUM_CONSTANT;
      } else if (element.isStatic) {
        type = HighlightRegionType.FIELD_STATIC;
      } else {
        type = HighlightRegionType.FIELD;
      }
    } else if (element is TopLevelVariableElement) {
      type = HighlightRegionType.TOP_LEVEL_VARIABLE;
    }
    // add region
    if (type != null) {
      return _addRegion_node(node, type);
    }
    return false;
  }

  bool _addIdentifierRegion_function(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! FunctionElement) {
      return false;
    }
    HighlightRegionType type;
    if (node.inDeclarationContext()) {
      type = HighlightRegionType.FUNCTION_DECLARATION;
    } else {
      type = HighlightRegionType.FUNCTION;
    }
    return _addRegion_node(node, type);
  }

  bool _addIdentifierRegion_functionTypeAlias(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! FunctionTypeAliasElement) {
      return false;
    }
    return _addRegion_node(node, HighlightRegionType.FUNCTION_TYPE_ALIAS);
  }

  bool _addIdentifierRegion_getterSetterDeclaration(SimpleIdentifier node) {
    // should be declaration
    AstNode parent = node.parent;
    if (!(parent is MethodDeclaration || parent is FunctionDeclaration)) {
      return false;
    }
    // should be property accessor
    Element element = node.staticElement;
    if (element is! PropertyAccessorElement) {
      return false;
    }
    // getter or setter
    PropertyAccessorElement propertyAccessorElement =
        element as PropertyAccessorElement;
    if (propertyAccessorElement.isGetter) {
      return _addRegion_node(node, HighlightRegionType.GETTER_DECLARATION);
    } else {
      return _addRegion_node(node, HighlightRegionType.SETTER_DECLARATION);
    }
  }

  bool _addIdentifierRegion_importPrefix(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! PrefixElement) {
      return false;
    }
    return _addRegion_node(node, HighlightRegionType.IMPORT_PREFIX);
  }

  bool _addIdentifierRegion_keyword(SimpleIdentifier node) {
    String name = node.name;
    if (name == "void") {
      return _addRegion_node(node, HighlightRegionType.KEYWORD);
    }
    return false;
  }

  bool _addIdentifierRegion_label(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! LabelElement) {
      return false;
    }
    return _addRegion_node(node, HighlightRegionType.LABEL);
  }

  bool _addIdentifierRegion_localVariable(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! LocalVariableElement) {
      return false;
    }
    // OK
    HighlightRegionType type;
    if (node.inDeclarationContext()) {
      type = HighlightRegionType.LOCAL_VARIABLE_DECLARATION;
    } else {
      type = HighlightRegionType.LOCAL_VARIABLE;
    }
    return _addRegion_node(node, type);
  }

  bool _addIdentifierRegion_method(SimpleIdentifier node) {
    Element element = node.bestElement;
    if (element is! MethodElement) {
      return false;
    }
    MethodElement methodElement = element as MethodElement;
    bool isStatic = methodElement.isStatic;
    // OK
    HighlightRegionType type;
    if (node.inDeclarationContext()) {
      if (isStatic) {
        type = HighlightRegionType.METHOD_DECLARATION_STATIC;
      } else {
        type = HighlightRegionType.METHOD_DECLARATION;
      }
    } else {
      if (isStatic) {
        type = HighlightRegionType.METHOD_STATIC;
      } else {
        type = HighlightRegionType.METHOD;
      }
    }
    return _addRegion_node(node, type);
  }

  bool _addIdentifierRegion_parameter(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! ParameterElement) {
      return false;
    }
    return _addRegion_node(node, HighlightRegionType.PARAMETER);
  }

  bool _addIdentifierRegion_typeParameter(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! TypeParameterElement) {
      return false;
    }
    return _addRegion_node(node, HighlightRegionType.TYPE_PARAMETER);
  }

  void _addRegion(int offset, int length, HighlightRegionType type) {
    _regions.add(new HighlightRegion(type, offset, length));
  }

  bool _addRegion_node(AstNode node, HighlightRegionType type) {
    int offset = node.offset;
    int length = node.length;
    _addRegion(offset, length, type);
    return true;
  }

  void _addRegion_nodeStart_tokenEnd(
      AstNode a, Token b, HighlightRegionType type) {
    int offset = a.offset;
    int end = b.end;
    _addRegion(offset, end - offset, type);
  }

  void _addRegion_token(Token token, HighlightRegionType type) {
    if (token != null) {
      int offset = token.offset;
      int length = token.length;
      _addRegion(offset, length, type);
    }
  }

  void _addRegion_tokenStart_tokenEnd(
      Token a, Token b, HighlightRegionType type) {
    int offset = a.offset;
    int end = b.end;
    _addRegion(offset, end - offset, type);
  }
}

/**
 * An AST visitor for [DartUnitHighlightsComputer].
 */
class _DartUnitHighlightsComputerVisitor extends RecursiveAstVisitor<Object> {
  final DartUnitHighlightsComputer computer;

  _DartUnitHighlightsComputerVisitor(this.computer);

  @override
  Object visitAnnotation(Annotation node) {
    computer._addIdentifierRegion_annotation(node);
    return super.visitAnnotation(node);
  }

  @override
  Object visitAsExpression(AsExpression node) {
    computer._addRegion_token(node.asOperator, HighlightRegionType.BUILT_IN);
    return super.visitAsExpression(node);
  }

  @override
  Object visitAssertStatement(AssertStatement node) {
    computer._addRegion_token(node.assertKeyword, HighlightRegionType.KEYWORD);
    return super.visitAssertStatement(node);
  }

  @override
  Object visitAwaitExpression(AwaitExpression node) {
    computer._addRegion_token(node.awaitKeyword, HighlightRegionType.BUILT_IN);
    return super.visitAwaitExpression(node);
  }

  @override
  Object visitBlockFunctionBody(BlockFunctionBody node) {
    _addRegions_functionBody(node);
    return super.visitBlockFunctionBody(node);
  }

  @override
  Object visitBooleanLiteral(BooleanLiteral node) {
    computer._addRegion_node(node, HighlightRegionType.KEYWORD);
    computer._addRegion_node(node, HighlightRegionType.LITERAL_BOOLEAN);
    return super.visitBooleanLiteral(node);
  }

  @override
  Object visitBreakStatement(BreakStatement node) {
    computer._addRegion_token(node.breakKeyword, HighlightRegionType.KEYWORD);
    return super.visitBreakStatement(node);
  }

  @override
  Object visitCatchClause(CatchClause node) {
    computer._addRegion_token(node.catchKeyword, HighlightRegionType.KEYWORD);
    computer._addRegion_token(node.onKeyword, HighlightRegionType.BUILT_IN);
    return super.visitCatchClause(node);
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    computer._addRegion_token(node.classKeyword, HighlightRegionType.KEYWORD);
    computer._addRegion_token(
        node.abstractKeyword, HighlightRegionType.BUILT_IN);
    return super.visitClassDeclaration(node);
  }

  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    computer._addRegion_token(
        node.abstractKeyword, HighlightRegionType.BUILT_IN);
    return super.visitClassTypeAlias(node);
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    computer._addRegion_token(
        node.externalKeyword, HighlightRegionType.BUILT_IN);
    computer._addRegion_token(
        node.factoryKeyword, HighlightRegionType.BUILT_IN);
    return super.visitConstructorDeclaration(node);
  }

  @override
  Object visitContinueStatement(ContinueStatement node) {
    computer._addRegion_token(
        node.continueKeyword, HighlightRegionType.KEYWORD);
    return super.visitContinueStatement(node);
  }

  @override
  Object visitDoStatement(DoStatement node) {
    computer._addRegion_token(node.doKeyword, HighlightRegionType.KEYWORD);
    computer._addRegion_token(node.whileKeyword, HighlightRegionType.KEYWORD);
    return super.visitDoStatement(node);
  }

  @override
  Object visitDoubleLiteral(DoubleLiteral node) {
    computer._addRegion_node(node, HighlightRegionType.LITERAL_DOUBLE);
    return super.visitDoubleLiteral(node);
  }

  @override
  Object visitEnumDeclaration(EnumDeclaration node) {
    computer._addRegion_token(node.enumKeyword, HighlightRegionType.KEYWORD);
    return super.visitEnumDeclaration(node);
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    computer._addRegion_node(node, HighlightRegionType.DIRECTIVE);
    computer._addRegion_token(node.keyword, HighlightRegionType.BUILT_IN);
    return super.visitExportDirective(node);
  }

  @override
  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _addRegions_functionBody(node);
    return super.visitExpressionFunctionBody(node);
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    computer._addRegion_token(node.staticKeyword, HighlightRegionType.BUILT_IN);
    return super.visitFieldDeclaration(node);
  }

  @override
  Object visitForEachStatement(ForEachStatement node) {
    computer._addRegion_token(node.awaitKeyword, HighlightRegionType.BUILT_IN);
    computer._addRegion_token(node.forKeyword, HighlightRegionType.KEYWORD);
    computer._addRegion_token(node.inKeyword, HighlightRegionType.KEYWORD);
    return super.visitForEachStatement(node);
  }

  @override
  Object visitForStatement(ForStatement node) {
    computer._addRegion_token(node.forKeyword, HighlightRegionType.KEYWORD);
    return super.visitForStatement(node);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    computer._addRegion_token(
        node.externalKeyword, HighlightRegionType.BUILT_IN);
    computer._addRegion_token(
        node.propertyKeyword, HighlightRegionType.BUILT_IN);
    return super.visitFunctionDeclaration(node);
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    computer._addRegion_token(
        node.typedefKeyword, HighlightRegionType.BUILT_IN);
    return super.visitFunctionTypeAlias(node);
  }

  @override
  Object visitGenericFunctionType(GenericFunctionType node) {
    computer._addRegion_token(
        node.functionKeyword, HighlightRegionType.KEYWORD);
    return super.visitGenericFunctionType(node);
  }

  @override
  Object visitGenericTypeAlias(GenericTypeAlias node) {
    computer._addRegion_token(node.typedefKeyword, HighlightRegionType.KEYWORD);
    return super.visitGenericTypeAlias(node);
  }

  @override
  Object visitHideCombinator(HideCombinator node) {
    computer._addRegion_token(node.keyword, HighlightRegionType.BUILT_IN);
    return super.visitHideCombinator(node);
  }

  @override
  Object visitIfStatement(IfStatement node) {
    computer._addRegion_token(node.ifKeyword, HighlightRegionType.KEYWORD);
    return super.visitIfStatement(node);
  }

  @override
  Object visitImplementsClause(ImplementsClause node) {
    computer._addRegion_token(
        node.implementsKeyword, HighlightRegionType.BUILT_IN);
    return super.visitImplementsClause(node);
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    computer._addRegion_node(node, HighlightRegionType.DIRECTIVE);
    computer._addRegion_token(node.keyword, HighlightRegionType.BUILT_IN);
    computer._addRegion_token(
        node.deferredKeyword, HighlightRegionType.BUILT_IN);
    computer._addRegion_token(node.asKeyword, HighlightRegionType.BUILT_IN);
    return super.visitImportDirective(node);
  }

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    computer._addRegion_token(node.keyword, HighlightRegionType.KEYWORD);
    return super.visitInstanceCreationExpression(node);
  }

  @override
  Object visitIntegerLiteral(IntegerLiteral node) {
    computer._addRegion_node(node, HighlightRegionType.LITERAL_INTEGER);
    return super.visitIntegerLiteral(node);
  }

  @override
  Object visitIsExpression(IsExpression node) {
    computer._addRegion_token(node.isOperator, HighlightRegionType.KEYWORD);
    return super.visitIsExpression(node);
  }

  @override
  Object visitLibraryDirective(LibraryDirective node) {
    computer._addRegion_node(node, HighlightRegionType.DIRECTIVE);
    computer._addRegion_token(node.keyword, HighlightRegionType.BUILT_IN);
    return super.visitLibraryDirective(node);
  }

  @override
  Object visitListLiteral(ListLiteral node) {
    computer._addRegion_node(node, HighlightRegionType.LITERAL_LIST);
    computer._addRegion_token(node.constKeyword, HighlightRegionType.KEYWORD);
    return super.visitListLiteral(node);
  }

  @override
  Object visitMapLiteral(MapLiteral node) {
    computer._addRegion_node(node, HighlightRegionType.LITERAL_MAP);
    computer._addRegion_token(node.constKeyword, HighlightRegionType.KEYWORD);
    return super.visitMapLiteral(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    computer._addRegion_token(
        node.externalKeyword, HighlightRegionType.BUILT_IN);
    computer._addRegion_token(
        node.modifierKeyword, HighlightRegionType.BUILT_IN);
    computer._addRegion_token(
        node.operatorKeyword, HighlightRegionType.BUILT_IN);
    computer._addRegion_token(
        node.propertyKeyword, HighlightRegionType.BUILT_IN);
    return super.visitMethodDeclaration(node);
  }

  @override
  Object visitNativeClause(NativeClause node) {
    computer._addRegion_token(node.nativeKeyword, HighlightRegionType.BUILT_IN);
    return super.visitNativeClause(node);
  }

  @override
  Object visitNativeFunctionBody(NativeFunctionBody node) {
    computer._addRegion_token(node.nativeKeyword, HighlightRegionType.BUILT_IN);
    return super.visitNativeFunctionBody(node);
  }

  @override
  Object visitPartDirective(PartDirective node) {
    computer._addRegion_node(node, HighlightRegionType.DIRECTIVE);
    computer._addRegion_token(node.keyword, HighlightRegionType.BUILT_IN);
    return super.visitPartDirective(node);
  }

  @override
  Object visitPartOfDirective(PartOfDirective node) {
    computer._addRegion_node(node, HighlightRegionType.DIRECTIVE);
    computer._addRegion_tokenStart_tokenEnd(
        node.partKeyword, node.ofKeyword, HighlightRegionType.BUILT_IN);
    return super.visitPartOfDirective(node);
  }

  @override
  Object visitRethrowExpression(RethrowExpression node) {
    computer._addRegion_token(node.rethrowKeyword, HighlightRegionType.KEYWORD);
    return super.visitRethrowExpression(node);
  }

  @override
  Object visitReturnStatement(ReturnStatement node) {
    computer._addRegion_token(node.returnKeyword, HighlightRegionType.KEYWORD);
    return super.visitReturnStatement(node);
  }

  @override
  Object visitShowCombinator(ShowCombinator node) {
    computer._addRegion_token(node.keyword, HighlightRegionType.BUILT_IN);
    return super.visitShowCombinator(node);
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    computer._addIdentifierRegion(node);
    return super.visitSimpleIdentifier(node);
  }

  @override
  Object visitSimpleStringLiteral(SimpleStringLiteral node) {
    computer._addRegion_node(node, HighlightRegionType.LITERAL_STRING);
    return super.visitSimpleStringLiteral(node);
  }

  @override
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    computer._addRegion_token(node.superKeyword, HighlightRegionType.KEYWORD);
    return super.visitSuperConstructorInvocation(node);
  }

  @override
  Object visitSwitchCase(SwitchCase node) {
    computer._addRegion_token(node.keyword, HighlightRegionType.KEYWORD);
    return super.visitSwitchCase(node);
  }

  @override
  Object visitSwitchDefault(SwitchDefault node) {
    computer._addRegion_token(node.keyword, HighlightRegionType.KEYWORD);
    return super.visitSwitchDefault(node);
  }

  @override
  Object visitSwitchStatement(SwitchStatement node) {
    computer._addRegion_token(node.switchKeyword, HighlightRegionType.KEYWORD);
    return super.visitSwitchStatement(node);
  }

  @override
  Object visitThisExpression(ThisExpression node) {
    computer._addRegion_token(node.thisKeyword, HighlightRegionType.KEYWORD);
    return super.visitThisExpression(node);
  }

  @override
  Object visitTryStatement(TryStatement node) {
    computer._addRegion_token(node.tryKeyword, HighlightRegionType.KEYWORD);
    computer._addRegion_token(node.finallyKeyword, HighlightRegionType.KEYWORD);
    return super.visitTryStatement(node);
  }

  @override
  Object visitTypeName(TypeName node) {
    DartType type = node.type;
    if (type != null) {
      if (type.isDynamic && node.name.name == "dynamic") {
        computer._addRegion_node(node, HighlightRegionType.TYPE_NAME_DYNAMIC);
        return null;
      }
    }
    return super.visitTypeName(node);
  }

  @override
  Object visitVariableDeclarationList(VariableDeclarationList node) {
    computer._addRegion_token(node.keyword, HighlightRegionType.KEYWORD);
    return super.visitVariableDeclarationList(node);
  }

  @override
  Object visitWhileStatement(WhileStatement node) {
    computer._addRegion_token(node.whileKeyword, HighlightRegionType.KEYWORD);
    return super.visitWhileStatement(node);
  }

  @override
  Object visitWithClause(WithClause node) {
    computer._addRegion_token(node.withKeyword, HighlightRegionType.KEYWORD);
    return super.visitWithClause(node);
  }

  @override
  Object visitYieldStatement(YieldStatement node) {
    Token keyword = node.yieldKeyword;
    Token star = node.star;
    int offset = keyword.offset;
    int end = star != null ? star.end : keyword.end;
    computer._addRegion(offset, end - offset, HighlightRegionType.BUILT_IN);
    return super.visitYieldStatement(node);
  }

  void _addRegions_functionBody(FunctionBody node) {
    Token keyword = node.keyword;
    if (keyword != null) {
      Token star = node.star;
      int offset = keyword.offset;
      int end = star != null ? star.end : keyword.end;
      computer._addRegion(offset, end - offset, HighlightRegionType.BUILT_IN);
    }
  }
}
