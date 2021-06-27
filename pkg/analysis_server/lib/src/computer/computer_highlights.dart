// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:_fe_analyzer_shared/src/parser/quote.dart'
    show analyzeQuote, Quote, firstQuoteLength, lastQuoteLength;
import 'package:_fe_analyzer_shared/src/scanner/characters.dart' as char;
import 'package:analysis_server/lsp_protocol/protocol_generated.dart'
    show SemanticTokenTypes, SemanticTokenModifiers;
import 'package:analysis_server/src/lsp/constants.dart'
    show CustomSemanticTokenModifiers, CustomSemanticTokenTypes;
import 'package:analysis_server/src/lsp/semantic_tokens/encoder.dart'
    show SemanticTokenInfo;
import 'package:analysis_server/src/lsp/semantic_tokens/mapping.dart'
    show highlightRegionTokenModifiers, highlightRegionTokenTypes;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;

/// A computer for [HighlightRegion]s and LSP [SemanticTokenInfo] in a Dart [CompilationUnit].
class DartUnitHighlightsComputer {
  final CompilationUnit _unit;
  final SourceRange? range;

  final _regions = <HighlightRegion>[];
  final _semanticTokens = <SemanticTokenInfo>[];
  bool _computeRegions = false;
  bool _computeSemanticTokens = false;

  /// Creates a computer for [HighlightRegion]s and LSP [SemanticTokenInfo] in a
  /// Dart [CompilationUnit].
  ///
  /// If [range] is supplied, tokens outside of this range will not be included
  /// in results.
  DartUnitHighlightsComputer(this._unit, {this.range});

  /// Returns the computed highlight regions, not `null`.
  List<HighlightRegion> compute() {
    _reset();
    _computeRegions = true;
    _unit.accept(_DartUnitHighlightsComputerVisitor(this));
    _addCommentRanges();
    return _regions;
  }

  /// Returns the computed semantic tokens, not `null`.
  List<SemanticTokenInfo> computeSemanticTokens() {
    _reset();
    _computeSemanticTokens = true;
    _unit.accept(_DartUnitHighlightsComputerVisitor(this));
    _addCommentRanges();
    return _semanticTokens;
  }

  void _addCommentRanges() {
    Token? token = _unit.beginToken;
    while (token != null) {
      Token? commentToken = token.precedingComments;
      while (commentToken != null) {
        HighlightRegionType? highlightType;
        if (commentToken.type == TokenType.MULTI_LINE_COMMENT) {
          if (commentToken.lexeme.startsWith('/**')) {
            highlightType = HighlightRegionType.COMMENT_DOCUMENTATION;
          } else {
            highlightType = HighlightRegionType.COMMENT_BLOCK;
          }
        }
        if (commentToken.type == TokenType.SINGLE_LINE_COMMENT) {
          if (commentToken.lexeme.startsWith('///')) {
            highlightType = HighlightRegionType.COMMENT_DOCUMENTATION;
          } else {
            highlightType = HighlightRegionType.COMMENT_END_OF_LINE;
          }
        }
        if (highlightType != null) {
          _addRegion_token(commentToken, highlightType);
        }
        commentToken = commentToken.next;
      }
      if (token.type == TokenType.EOF) {
        // Only exit the loop *after* processing the EOF token as it may
        // have preceeding comments.
        break;
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
    if (_addIdentifierRegion_extension(node)) {
      return;
    }
    if (_addIdentifierRegion_constructor(node)) {
      return;
    }
    if (_addIdentifierRegion_getterSetterDeclaration(node)) {
      return;
    }
    if (_addIdentifierRegion_field(node)) {
      return;
    }
    if (_addIdentifierRegion_dynamicLocal(node)) {
      return;
    }
    if (_addIdentifierRegion_function(node)) {
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
    if (_addIdentifierRegion_typeAlias(node)) {
      return;
    }
    if (_addIdentifierRegion_typeParameter(node)) {
      return;
    }
    if (_addIdentifierRegion_unresolvedInstanceMemberReference(node)) {
      return;
    }
    _addRegion_node(node, HighlightRegionType.IDENTIFIER_DEFAULT);
  }

  void _addIdentifierRegion_annotation(Annotation node) {
    var arguments = node.arguments;
    if (arguments == null) {
      _addRegion_node(node, HighlightRegionType.ANNOTATION);
    } else {
      _addRegion_nodeStart_tokenEnd(
          node, arguments.beginToken, HighlightRegionType.ANNOTATION);
      _addRegion_token(arguments.endToken, HighlightRegionType.ANNOTATION);
    }
  }

  bool _addIdentifierRegion_class(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element is! ClassElement) {
      return false;
    }
    // prepare type
    HighlightRegionType type;
    SemanticTokenTypes? semanticType;
    Set<SemanticTokenModifiers>? semanticModifiers;
    var parent = node.parent;
    var grandParent = parent?.parent;
    if (parent is TypeName &&
        grandParent is ConstructorName &&
        grandParent.parent is InstanceCreationExpression) {
      // new Class()
      type = HighlightRegionType.CONSTRUCTOR;
      semanticType = SemanticTokenTypes.class_;
      semanticModifiers = {CustomSemanticTokenModifiers.constructor};
    } else if (element.isEnum) {
      type = HighlightRegionType.ENUM;
    } else {
      type = HighlightRegionType.CLASS;
    }
    // add region
    return _addRegion_node(
      node,
      type,
      semanticTokenType: semanticType,
      semanticTokenModifiers: semanticModifiers,
    );
  }

  bool _addIdentifierRegion_constructor(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element is! ConstructorElement) {
      return false;
    }
    return _addRegion_node(
      node,
      HighlightRegionType.CONSTRUCTOR,
      // For semantic tokens, constructor names are coloured like methods but
      // have a modifier applied.
      semanticTokenType: SemanticTokenTypes.method,
      semanticTokenModifiers: {CustomSemanticTokenModifiers.constructor},
    );
  }

  bool _addIdentifierRegion_dynamicLocal(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element is LocalVariableElement) {
      var elementType = element.type;
      if (elementType.isDynamic) {
        var type = node.inDeclarationContext()
            ? HighlightRegionType.DYNAMIC_LOCAL_VARIABLE_DECLARATION
            : HighlightRegionType.DYNAMIC_LOCAL_VARIABLE_REFERENCE;
        return _addRegion_node(node, type);
      }
    }
    if (element is ParameterElement) {
      var elementType = element.type;
      if (elementType.isDynamic) {
        var type = node.inDeclarationContext()
            ? HighlightRegionType.DYNAMIC_PARAMETER_DECLARATION
            : HighlightRegionType.DYNAMIC_PARAMETER_REFERENCE;
        return _addRegion_node(node, type);
      }
    }
    return false;
  }

  bool _addIdentifierRegion_extension(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element is! ExtensionElement) {
      return false;
    }

    // TODO(dantup): Right now there is no highlight type for extension, so
    // bail out and do the default thing (which will be to return
    // IDENTIFIER_DEFAULT). Adding EXTENSION requires coordination with
    // IntelliJ + bumping protocol version.
    if (!_computeSemanticTokens) {
      return false;
    }

    return _addRegion_node(
      node,
      // TODO(dantup): Change this to EXTENSION and add to LSP mapping when
      // we have it, but for now use CLASS (which is probably what we'll map it
      // to for LSP semantic tokens anyway).
      HighlightRegionType.CLASS,
    );
  }

  bool _addIdentifierRegion_field(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element is FieldFormalParameterElement) {
      if (node.parent is FieldFormalParameter) {
        element = element.field;
      }
    }
    // prepare type
    HighlightRegionType? type;
    if (element is FieldElement) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement is ClassElement && enclosingElement.isEnum) {
        type = HighlightRegionType.ENUM_CONSTANT;
      } else if (element.isStatic) {
        type = HighlightRegionType.STATIC_FIELD_DECLARATION;
      } else {
        type = node.inDeclarationContext()
            ? HighlightRegionType.INSTANCE_FIELD_DECLARATION
            : HighlightRegionType.INSTANCE_FIELD_REFERENCE;
      }
    } else if (element is TopLevelVariableElement) {
      type = HighlightRegionType.TOP_LEVEL_VARIABLE_DECLARATION;
    }
    if (element is PropertyAccessorElement) {
      var accessor = element;
      var enclosingElement = element.enclosingElement;
      if (accessor.variable is TopLevelVariableElement) {
        type = accessor.isGetter
            ? HighlightRegionType.TOP_LEVEL_GETTER_REFERENCE
            : HighlightRegionType.TOP_LEVEL_SETTER_REFERENCE;
      } else if (enclosingElement is ClassElement && enclosingElement.isEnum) {
        type = HighlightRegionType.ENUM_CONSTANT;
      } else if (accessor.isStatic) {
        type = accessor.isGetter
            ? HighlightRegionType.STATIC_GETTER_REFERENCE
            : HighlightRegionType.STATIC_SETTER_REFERENCE;
      } else {
        type = accessor.isGetter
            ? HighlightRegionType.INSTANCE_GETTER_REFERENCE
            : HighlightRegionType.INSTANCE_SETTER_REFERENCE;
      }
    }
    // add region
    if (type != null) {
      return _addRegion_node(node, type);
    }
    return false;
  }

  bool _addIdentifierRegion_function(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element is! FunctionElement) {
      return false;
    }
    HighlightRegionType type;
    var isTopLevel = element.enclosingElement is CompilationUnitElement;
    if (node.inDeclarationContext()) {
      type = isTopLevel
          ? HighlightRegionType.TOP_LEVEL_FUNCTION_DECLARATION
          : HighlightRegionType.LOCAL_FUNCTION_DECLARATION;
    } else {
      type = isTopLevel
          ? HighlightRegionType.TOP_LEVEL_FUNCTION_REFERENCE
          : HighlightRegionType.LOCAL_FUNCTION_REFERENCE;
    }
    return _addRegion_node(node, type);
  }

  bool _addIdentifierRegion_getterSetterDeclaration(SimpleIdentifier node) {
    // should be declaration
    var parent = node.parent;
    if (!(parent is MethodDeclaration || parent is FunctionDeclaration)) {
      return false;
    }
    // should be property accessor
    var element = node.writeOrReadElement;
    if (element is! PropertyAccessorElement) {
      return false;
    }
    // getter or setter
    var isTopLevel = element.enclosingElement is CompilationUnitElement;
    HighlightRegionType type;
    if (element.isGetter) {
      if (isTopLevel) {
        type = HighlightRegionType.TOP_LEVEL_GETTER_DECLARATION;
      } else if (element.isStatic) {
        type = HighlightRegionType.STATIC_GETTER_DECLARATION;
      } else {
        type = HighlightRegionType.INSTANCE_GETTER_DECLARATION;
      }
    } else {
      if (isTopLevel) {
        type = HighlightRegionType.TOP_LEVEL_SETTER_DECLARATION;
      } else if (element.isStatic) {
        type = HighlightRegionType.STATIC_SETTER_DECLARATION;
      } else {
        type = HighlightRegionType.INSTANCE_SETTER_DECLARATION;
      }
    }
    return _addRegion_node(node, type);
  }

  bool _addIdentifierRegion_importPrefix(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element is! PrefixElement) {
      return false;
    }
    return _addRegion_node(node, HighlightRegionType.IMPORT_PREFIX);
  }

  bool _addIdentifierRegion_keyword(SimpleIdentifier node) {
    var name = node.name;
    if (name == 'void') {
      return _addRegion_node(
        node,
        HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.void_},
      );
    }
    return false;
  }

  bool _addIdentifierRegion_label(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element is! LabelElement) {
      return false;
    }
    return _addRegion_node(node, HighlightRegionType.LABEL);
  }

  bool _addIdentifierRegion_localVariable(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element is! LocalVariableElement) {
      return false;
    }
    // OK
    var type = node.inDeclarationContext()
        ? HighlightRegionType.LOCAL_VARIABLE_DECLARATION
        : HighlightRegionType.LOCAL_VARIABLE_REFERENCE;
    return _addRegion_node(node, type);
  }

  bool _addIdentifierRegion_method(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element is! MethodElement) {
      return false;
    }
    var isStatic = element.isStatic;
    // OK
    HighlightRegionType type;
    if (node.inDeclarationContext()) {
      if (isStatic) {
        type = HighlightRegionType.STATIC_METHOD_DECLARATION;
      } else {
        type = HighlightRegionType.INSTANCE_METHOD_DECLARATION;
      }
    } else {
      if (isStatic) {
        type = HighlightRegionType.STATIC_METHOD_REFERENCE;
      } else {
        type = HighlightRegionType.INSTANCE_METHOD_REFERENCE;
      }
    }
    return _addRegion_node(node, type);
  }

  bool _addIdentifierRegion_parameter(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element is! ParameterElement) {
      return false;
    }
    var type = node.inDeclarationContext()
        ? HighlightRegionType.PARAMETER_DECLARATION
        : HighlightRegionType.PARAMETER_REFERENCE;
    var modifiers =
        node.parent is Label ? {CustomSemanticTokenModifiers.label} : null;
    return _addRegion_node(node, type, semanticTokenModifiers: modifiers);
  }

  bool _addIdentifierRegion_typeAlias(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element is TypeAliasElement) {
      var type = element.aliasedType is FunctionType
          ? HighlightRegionType.FUNCTION_TYPE_ALIAS
          : HighlightRegionType.TYPE_ALIAS;
      return _addRegion_node(node, type);
    }
    return false;
  }

  bool _addIdentifierRegion_typeParameter(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element is! TypeParameterElement) {
      return false;
    }
    return _addRegion_node(node, HighlightRegionType.TYPE_PARAMETER);
  }

  bool _addIdentifierRegion_unresolvedInstanceMemberReference(
      SimpleIdentifier node) {
    // unresolved
    var element = node.writeOrReadElement;
    if (element != null) {
      return false;
    }
    // invoke / get / set
    var decorate = false;
    var parent = node.parent;
    if (parent is MethodInvocation) {
      var target = parent.realTarget;
      if (parent.methodName == node &&
          target != null &&
          _isDynamicExpression(target)) {
        decorate = true;
      }
    } else if (node.inGetterContext() || node.inSetterContext()) {
      if (parent is PrefixedIdentifier) {
        decorate = parent.identifier == node;
      } else if (parent is PropertyAccess) {
        decorate = parent.propertyName == node;
      }
    }
    if (decorate) {
      _addRegion_node(
          node, HighlightRegionType.UNRESOLVED_INSTANCE_MEMBER_REFERENCE);
      return true;
    }
    return false;
  }

  /// Adds a highlight region/semantic token for the given [offset]/[length].
  ///
  /// If [semanticTokenType] or [semanticTokenModifiers] are not provided, the
  /// values from the default LSP mapping for [type] (also used for plugins)
  /// will be used instead.
  ///
  /// If the computer has a [range] set, tokens that fall outside of that range
  /// will not be recorded.
  void _addRegion(
    int offset,
    int length,
    HighlightRegionType type, {
    SemanticTokenTypes? semanticTokenType,
    Set<SemanticTokenModifiers>? semanticTokenModifiers,
  }) {
    final range = this.range;
    if (range != null) {
      final end = offset + length;
      // Skip token if it ends before the range of starts after the range.
      if (end < range.offset || offset > range.end) {
        return;
      }
    }
    if (_computeRegions) {
      _regions.add(HighlightRegion(type, offset, length));
    }
    if (_computeSemanticTokens) {
      // Use default mappings if an overriden type/modifiers were not supplied.
      semanticTokenType ??= highlightRegionTokenTypes[type];
      semanticTokenModifiers ??= highlightRegionTokenModifiers[type];
      if (semanticTokenType != null) {
        _semanticTokens.add(SemanticTokenInfo(
            offset, length, semanticTokenType, semanticTokenModifiers));
      }
    }
  }

  bool _addRegion_node(
    AstNode node,
    HighlightRegionType type, {
    SemanticTokenTypes? semanticTokenType,
    Set<SemanticTokenModifiers>? semanticTokenModifiers,
  }) {
    var offset = node.offset;
    var length = node.length;
    _addRegion(
      offset,
      length,
      type,
      semanticTokenType: semanticTokenType,
      semanticTokenModifiers: semanticTokenModifiers,
    );
    return true;
  }

  void _addRegion_nodeStart_tokenEnd(
      AstNode a, Token b, HighlightRegionType type) {
    var offset = a.offset;
    var end = b.end;
    _addRegion(offset, end - offset, type);
  }

  void _addRegion_token(
    Token? token,
    HighlightRegionType type, {
    SemanticTokenTypes? semanticTokenType,
    Set<SemanticTokenModifiers>? semanticTokenModifiers,
  }) {
    if (token != null) {
      var offset = token.offset;
      var length = token.length;
      _addRegion(offset, length, type,
          semanticTokenType: semanticTokenType,
          semanticTokenModifiers: semanticTokenModifiers);
    }
  }

  void _addRegion_tokenStart_tokenEnd(
      Token a, Token b, HighlightRegionType type) {
    var offset = a.offset;
    var end = b.end;
    _addRegion(offset, end - offset, type);
  }

  void _reset() {
    _computeRegions = false;
    _computeSemanticTokens = false;
    _regions.clear();
    _semanticTokens.clear();
  }

  static bool _isDynamicExpression(Expression e) {
    var type = e.staticType;
    return type != null && type.isDynamic;
  }
}

/// An AST visitor for [DartUnitHighlightsComputer].
class _DartUnitHighlightsComputerVisitor extends RecursiveAstVisitor<void> {
  final DartUnitHighlightsComputer computer;

  _DartUnitHighlightsComputerVisitor(this.computer);

  @override
  void visitAnnotation(Annotation node) {
    computer._addIdentifierRegion_annotation(node);
    super.visitAnnotation(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    computer._addRegion_token(node.asOperator, HighlightRegionType.BUILT_IN);
    super.visitAsExpression(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    computer._addRegion_token(node.assertKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitAssertStatement(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    computer._addRegion_token(node.awaitKeyword, HighlightRegionType.BUILT_IN,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitAwaitExpression(node);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _addRegions_functionBody(node);
    super.visitBlockFunctionBody(node);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    computer._addRegion_node(node, HighlightRegionType.KEYWORD);
    computer._addRegion_node(node, HighlightRegionType.LITERAL_BOOLEAN);
    super.visitBooleanLiteral(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    computer._addRegion_token(node.breakKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitBreakStatement(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    computer._addRegion_token(node.catchKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    computer._addRegion_token(node.onKeyword, HighlightRegionType.BUILT_IN,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitCatchClause(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    computer._addRegion_token(node.classKeyword, HighlightRegionType.KEYWORD);
    computer._addRegion_token(
        node.abstractKeyword, HighlightRegionType.BUILT_IN);
    super.visitClassDeclaration(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    computer._addRegion_token(
        node.abstractKeyword, HighlightRegionType.BUILT_IN);
    super.visitClassTypeAlias(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    computer._addRegion_token(
        node.externalKeyword, HighlightRegionType.BUILT_IN);
    computer._addRegion_token(
        node.factoryKeyword, HighlightRegionType.BUILT_IN);
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    computer._addRegion_token(node.continueKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitContinueStatement(node);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    computer._addRegion_token(
        node.requiredKeyword, HighlightRegionType.KEYWORD);
    super.visitDefaultFormalParameter(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    computer._addRegion_token(node.doKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    computer._addRegion_token(node.whileKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitDoStatement(node);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    computer._addRegion_node(node, HighlightRegionType.LITERAL_DOUBLE);
    super.visitDoubleLiteral(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    computer._addRegion_token(node.enumKeyword, HighlightRegionType.KEYWORD);
    super.visitEnumDeclaration(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    computer._addRegion_node(node, HighlightRegionType.DIRECTIVE);
    computer._addRegion_token(node.keyword, HighlightRegionType.BUILT_IN);
    _addRegions_configurations(node.configurations);
    super.visitExportDirective(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _addRegions_functionBody(node);
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    computer._addRegion_token(node.extendsKeyword, HighlightRegionType.KEYWORD);
    super.visitExtendsClause(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    computer._addRegion_token(
        node.extensionKeyword, HighlightRegionType.KEYWORD);
    computer._addRegion_token(node.onKeyword, HighlightRegionType.BUILT_IN);
    super.visitExtensionDeclaration(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    computer._addRegion_token(
        node.abstractKeyword, HighlightRegionType.BUILT_IN);
    computer._addRegion_token(
        node.externalKeyword, HighlightRegionType.BUILT_IN);
    computer._addRegion_token(node.staticKeyword, HighlightRegionType.BUILT_IN);
    super.visitFieldDeclaration(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    computer._addRegion_token(
        node.requiredKeyword, HighlightRegionType.KEYWORD);
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    computer._addRegion_token(node.inKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    computer._addRegion_token(node.inKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitForEachPartsWithIdentifier(node);
  }

  @override
  void visitForElement(ForElement node) {
    computer._addRegion_token(node.awaitKeyword, HighlightRegionType.BUILT_IN,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    computer._addRegion_token(node.forKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitForElement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    computer._addRegion_token(node.awaitKeyword, HighlightRegionType.BUILT_IN,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    computer._addRegion_token(node.forKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitForStatement(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    computer._addRegion_token(
        node.externalKeyword, HighlightRegionType.BUILT_IN);
    computer._addRegion_token(
        node.propertyKeyword, HighlightRegionType.BUILT_IN);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    computer._addRegion_token(
        node.typedefKeyword, HighlightRegionType.BUILT_IN);
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    computer._addRegion_token(
        node.requiredKeyword, HighlightRegionType.KEYWORD);
    super.visitFunctionTypedFormalParameter(node);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    computer._addRegion_token(
        node.functionKeyword, HighlightRegionType.BUILT_IN);
    super.visitGenericFunctionType(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    computer._addRegion_token(
        node.typedefKeyword, HighlightRegionType.BUILT_IN);
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    computer._addRegion_token(node.keyword, HighlightRegionType.BUILT_IN);
    super.visitHideCombinator(node);
  }

  @override
  void visitIfElement(IfElement node) {
    computer._addRegion_token(node.ifKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    computer._addRegion_token(node.elseKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitIfElement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    computer._addRegion_token(node.ifKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    computer._addRegion_token(node.elseKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitIfStatement(node);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    computer._addRegion_token(
        node.implementsKeyword, HighlightRegionType.BUILT_IN);
    super.visitImplementsClause(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    computer._addRegion_node(node, HighlightRegionType.DIRECTIVE);
    computer._addRegion_token(node.keyword, HighlightRegionType.BUILT_IN);
    computer._addRegion_token(
        node.deferredKeyword, HighlightRegionType.BUILT_IN);
    computer._addRegion_token(node.asKeyword, HighlightRegionType.BUILT_IN);
    _addRegions_configurations(node.configurations);
    super.visitImportDirective(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.keyword != null) {
      computer._addRegion_token(node.keyword, HighlightRegionType.KEYWORD);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    computer._addRegion_node(node, HighlightRegionType.LITERAL_INTEGER);
    super.visitIntegerLiteral(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    if (computer._computeSemanticTokens) {
      // Interpolation expressions may include uncolored code, but clients may
      // be providing their own basic coloring for strings that would leak
      // into those uncolored parts so we mark them up to allow the client to
      // reset the coloring if required.
      //
      // Using the String token type with a modifier would work for VS Code but
      // would cause other editors that don't know about the modifier (and also
      // do not have their own local coloring) to color the tokens as a string,
      // which is exactly what we'd like to avoid).

      computer._addRegion_node(
        node,
        // The HighlightRegionType here is not used because of the
        // computer._computeSemanticTokens check above.
        HighlightRegionType.LITERAL_STRING,
        semanticTokenType: CustomSemanticTokenTypes.source,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.interpolation},
      );
    }
    super.visitInterpolationExpression(node);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    computer._addRegion_node(node, HighlightRegionType.LITERAL_STRING);
    super.visitInterpolationString(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    computer._addRegion_token(node.isOperator, HighlightRegionType.KEYWORD);
    super.visitIsExpression(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    computer._addRegion_node(node, HighlightRegionType.DIRECTIVE);
    computer._addRegion_token(node.keyword, HighlightRegionType.BUILT_IN);
    super.visitLibraryDirective(node);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    computer._addRegion_node(node, HighlightRegionType.LIBRARY_NAME);
    null;
  }

  @override
  void visitListLiteral(ListLiteral node) {
    computer._addRegion_node(node, HighlightRegionType.LITERAL_LIST);
    computer._addRegion_token(node.constKeyword, HighlightRegionType.KEYWORD);
    super.visitListLiteral(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    computer._addRegion_token(
        node.externalKeyword, HighlightRegionType.BUILT_IN);
    computer._addRegion_token(
        node.modifierKeyword, HighlightRegionType.BUILT_IN);
    computer._addRegion_token(
        node.operatorKeyword, HighlightRegionType.BUILT_IN);
    computer._addRegion_token(
        node.propertyKeyword, HighlightRegionType.BUILT_IN);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    computer._addRegion_token(node.mixinKeyword, HighlightRegionType.BUILT_IN);
    super.visitMixinDeclaration(node);
  }

  @override
  void visitNativeClause(NativeClause node) {
    computer._addRegion_token(node.nativeKeyword, HighlightRegionType.BUILT_IN);
    super.visitNativeClause(node);
  }

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {
    computer._addRegion_token(node.nativeKeyword, HighlightRegionType.BUILT_IN);
    super.visitNativeFunctionBody(node);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    computer._addRegion_token(node.literal, HighlightRegionType.KEYWORD);
    super.visitNullLiteral(node);
  }

  @override
  void visitOnClause(OnClause node) {
    computer._addRegion_token(node.onKeyword, HighlightRegionType.BUILT_IN);
    super.visitOnClause(node);
  }

  @override
  void visitPartDirective(PartDirective node) {
    computer._addRegion_node(node, HighlightRegionType.DIRECTIVE);
    computer._addRegion_token(node.keyword, HighlightRegionType.BUILT_IN);
    super.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    computer._addRegion_node(node, HighlightRegionType.DIRECTIVE);
    computer._addRegion_tokenStart_tokenEnd(
        node.partKeyword, node.ofKeyword, HighlightRegionType.BUILT_IN);
    super.visitPartOfDirective(node);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    computer._addRegion_token(node.rethrowKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitRethrowExpression(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    computer._addRegion_token(node.returnKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitReturnStatement(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.isMap) {
      computer._addRegion_node(node, HighlightRegionType.LITERAL_MAP);
      // TODO(brianwilkerson) Add a highlight region for set literals. This
      //  would be a breaking change, but would be consistent with list and map
      //  literals.
//    } else if (node.isSet) {
//    computer._addRegion_node(node, HighlightRegionType.LITERAL_SET);
    }
    computer._addRegion_token(node.constKeyword, HighlightRegionType.KEYWORD);
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    computer._addRegion_token(node.keyword, HighlightRegionType.BUILT_IN);
    super.visitShowCombinator(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    computer._addRegion_token(
        node.requiredKeyword, HighlightRegionType.KEYWORD);
    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    computer._addIdentifierRegion(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    computer._addRegion_node(node, HighlightRegionType.LITERAL_STRING);
    if (computer._computeSemanticTokens) {
      _addRegions_stringEscapes(node);
    }
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    computer._addRegion_token(node.superKeyword, HighlightRegionType.KEYWORD);
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    computer._addRegion_token(node.keyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    computer._addRegion_token(node.keyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitSwitchDefault(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    computer._addRegion_token(node.switchKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitSwitchStatement(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    computer._addRegion_token(node.thisKeyword, HighlightRegionType.KEYWORD);
    super.visitThisExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    computer._addRegion_token(node.throwKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitThrowExpression(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    computer._addRegion_token(
        node.externalKeyword, HighlightRegionType.BUILT_IN);
    super.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    computer._addRegion_token(node.tryKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    computer._addRegion_token(node.finallyKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitTryStatement(node);
  }

  @override
  void visitTypeName(TypeName node) {
    var type = node.type;
    if (type != null) {
      if (type.isDynamic && node.name.name == 'dynamic') {
        computer._addRegion_node(node, HighlightRegionType.TYPE_NAME_DYNAMIC);
        return null;
      }
    }
    super.visitTypeName(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    computer._addRegion_token(node.lateKeyword, HighlightRegionType.KEYWORD);
    computer._addRegion_token(node.keyword, HighlightRegionType.KEYWORD);
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    computer._addRegion_token(node.whileKeyword, HighlightRegionType.KEYWORD,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitWhileStatement(node);
  }

  @override
  void visitWithClause(WithClause node) {
    computer._addRegion_token(node.withKeyword, HighlightRegionType.KEYWORD);
    super.visitWithClause(node);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    var keyword = node.yieldKeyword;
    var star = node.star;
    var offset = keyword.offset;
    var end = star != null ? star.end : keyword.end;
    computer._addRegion(offset, end - offset, HighlightRegionType.BUILT_IN,
        semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    super.visitYieldStatement(node);
  }

  void _addRegions_configurations(List<Configuration> configurations) {
    for (final configuration in configurations) {
      computer._addRegion_token(
          configuration.ifKeyword, HighlightRegionType.BUILT_IN,
          semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    }
  }

  void _addRegions_functionBody(FunctionBody node) {
    var keyword = node.keyword;
    if (keyword != null) {
      var star = node.star;
      var offset = keyword.offset;
      var end = star != null ? star.end : keyword.end;
      computer._addRegion(offset, end - offset, HighlightRegionType.BUILT_IN,
          semanticTokenModifiers: {CustomSemanticTokenModifiers.control});
    }
  }

  void _addRegions_stringEscapes(SimpleStringLiteral node) {
    final string = node.literal.lexeme;
    final quote = analyzeQuote(string);
    final startIndex = firstQuoteLength(string, quote);
    final endIndex = string.length - lastQuoteLength(quote);
    switch (quote) {
      case Quote.Single:
      case Quote.Double:
      case Quote.MultiLineSingle:
      case Quote.MultiLineDouble:
        _findEscapes(node, startIndex: startIndex, endIndex: endIndex,
            listener: (offset, end) {
          final length = end - offset;
          computer._addRegion(node.offset + offset, length,
              HighlightRegionType.VALID_STRING_ESCAPE);
        });
        break;
      case Quote.RawSingle:
      case Quote.RawDouble:
      case Quote.RawMultiLineSingle:
      case Quote.RawMultiLineDouble:
        // Raw strings don't have escape characters.
        break;
    }
  }

  /// Finds escaped regions within a string between [startIndex] and [endIndex],
  /// calling [listener] for each found region.
  void _findEscapes(
    SimpleStringLiteral node, {
    required int startIndex,
    required int endIndex,
    required void Function(int offset, int end) listener,
  }) {
    final string = node.literal.lexeme;
    final codeUnits = string.codeUnits;
    final length = string.length;

    bool isBackslash(int i) => i <= length && codeUnits[i] == char.$BACKSLASH;
    bool isHexEscape(int i) => i <= length && codeUnits[i] == char.$x;
    bool isUnicodeHexEscape(int i) => i <= length && codeUnits[i] == char.$u;
    bool isOpenBrace(int i) =>
        i <= length && codeUnits[i] == char.$OPEN_CURLY_BRACKET;
    bool isCloseBrace(int i) =>
        i <= length && codeUnits[i] == char.$CLOSE_CURLY_BRACKET;
    int? numHexDigits(int i, {required int min, required int max}) {
      var numHexDigits = 0;
      for (var j = i; j < math.min(i + max, length); j++) {
        if (!char.isHexDigit(codeUnits[j])) {
          break;
        }
        numHexDigits++;
      }
      return numHexDigits >= min ? numHexDigits : null;
    }

    for (var i = startIndex; i < endIndex;) {
      if (isBackslash(i)) {
        final backslashOffset = i++;
        // All escaped characters are a single character except for:
        // `\uXXXX` or `\u{XX?X?X?X?X?}` for Unicode hex escape.
        // `\xXX` for hex escape.
        if (isHexEscape(i)) {
          // Expect exactly 2 hex digits.
          final numDigits = numHexDigits(i + 1, min: 2, max: 2);
          if (numDigits != null) {
            i += 1 + numDigits;
            listener(backslashOffset, i);
          }
        } else if (isUnicodeHexEscape(i) && isOpenBrace(i + 1)) {
          // Expect 1-6 hex digits followed by '}'.
          final numDigits = numHexDigits(i + 2, min: 1, max: 6);
          if (numDigits != null && isCloseBrace(i + 2 + numDigits)) {
            i += 2 + numDigits + 1;
            listener(backslashOffset, i);
          }
        } else if (isUnicodeHexEscape(i)) {
          // Expect exactly 4 hex digits.
          final numDigits = numHexDigits(i + 1, min: 4, max: 4);
          if (numDigits != null) {
            i += 1 + numDigits;
            listener(backslashOffset, i);
          }
        } else {
          i++;
          // Single-character escape.
          listener(backslashOffset, i);
        }
      } else {
        i++;
      }
    }
  }
}
