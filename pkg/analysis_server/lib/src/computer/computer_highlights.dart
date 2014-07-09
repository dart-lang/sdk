// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library computer.highlights;

import 'package:analysis_server/src/constants.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart';


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
  List<Map<String, Object>> compute() {
    _unit.accept(new _DartUnitHighlightsComputerVisitor(this));
    _addCommentRanges();
    return _regions.map((region) => region.toJson()).toList();
  }

  void _addCommentRanges() {
    Token token = _unit.beginToken;
    while (token != null && token.type != TokenType.EOF) {
      Token commentToken = token.precedingComments;
      while (commentToken != null) {
        HighlightType highlightType = null;
        if (commentToken.type == TokenType.MULTI_LINE_COMMENT) {
          if (commentToken.lexeme.startsWith('/**')) {
            highlightType = HighlightType.COMMENT_DOCUMENTATION;
          } else {
            highlightType = HighlightType.COMMENT_BLOCK;
          }
        }
        if (commentToken.type == TokenType.SINGLE_LINE_COMMENT) {
          highlightType = HighlightType.COMMENT_END_OF_LINE;
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
    if (_addIdentifierRegion_localVariable(node)) {
      return;
    }
    if (_addIdentifierRegion_method(node)) {
      return;
    }
    if (_addIdentifierRegion_parameter(node)) {
      return;
    }
    if (_addIdentifierRegion_topLevelVariable(node)) {
      return;
    }
    if (_addIdentifierRegion_typeParameter(node)) {
      return;
    }
    _addRegion_node(node, HighlightType.IDENTIFIER_DEFAULT);
  }

  void _addIdentifierRegion_annotation(Annotation node) {
    ArgumentList arguments = node.arguments;
    if (arguments == null) {
      _addRegion_node(node, HighlightType.ANNOTATION);
    } else {
      _addRegion_nodeStart_tokenEnd(node, arguments.beginToken,
          HighlightType.ANNOTATION);
      _addRegion_token(arguments.endToken, HighlightType.ANNOTATION);
    }
  }

  bool _addIdentifierRegion_class(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! ClassElement) {
      return false;
    }
    return _addRegion_node(node, HighlightType.CLASS);
  }

  bool _addIdentifierRegion_constructor(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! ConstructorElement) {
      return false;
    }
    return _addRegion_node(node, HighlightType.CONSTRUCTOR);
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
    return _addRegion_node(node, HighlightType.DYNAMIC_TYPE);
  }

  bool _addIdentifierRegion_field(SimpleIdentifier node) {
    Element element = node.bestElement;
    if (element is FieldFormalParameterElement) {
      element = (element as FieldFormalParameterElement).field;
    }
    if (element is FieldElement) {
      if ((element as FieldElement).isStatic) {
        return _addRegion_node(node, HighlightType.FIELD_STATIC);
      } else {
        return _addRegion_node(node, HighlightType.FIELD);
      }
    }
    if (element is PropertyAccessorElement) {
      if ((element as PropertyAccessorElement).isStatic) {
        return _addRegion_node(node, HighlightType.FIELD_STATIC);
      } else {
        return _addRegion_node(node, HighlightType.FIELD);
      }
    }
    return false;
  }

  bool _addIdentifierRegion_function(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! FunctionElement) {
      return false;
    }
    HighlightType type;
    if (node.inDeclarationContext()) {
      type = HighlightType.FUNCTION_DECLARATION;
    } else {
      type = HighlightType.FUNCTION;
    }
    return _addRegion_node(node, type);
  }

  bool _addIdentifierRegion_functionTypeAlias(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! FunctionTypeAliasElement) {
      return false;
    }
    return _addRegion_node(node, HighlightType.FUNCTION_TYPE_ALIAS);
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
    PropertyAccessorElement propertyAccessorElement = element as
        PropertyAccessorElement;
    if (propertyAccessorElement.isGetter) {
      return _addRegion_node(node, HighlightType.GETTER_DECLARATION);
    } else {
      return _addRegion_node(node, HighlightType.SETTER_DECLARATION);
    }
  }

  bool _addIdentifierRegion_importPrefix(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! PrefixElement) {
      return false;
    }
    return _addRegion_node(node, HighlightType.IMPORT_PREFIX);
  }

  bool _addIdentifierRegion_keyword(SimpleIdentifier node) {
    String name = node.name;
    if (name == "void") {
      return _addRegion_node(node, HighlightType.KEYWORD);
    }
    return false;
  }

  bool _addIdentifierRegion_localVariable(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! LocalVariableElement) {
      return false;
    }
    // OK
    HighlightType type;
    if (node.inDeclarationContext()) {
      type = HighlightType.LOCAL_VARIABLE_DECLARATION;
    } else {
      type = HighlightType.LOCAL_VARIABLE;
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
    HighlightType type;
    if (node.inDeclarationContext()) {
      if (isStatic) {
        type = HighlightType.METHOD_DECLARATION_STATIC;
      } else {
        type = HighlightType.METHOD_DECLARATION;
      }
    } else {
      if (isStatic) {
        type = HighlightType.METHOD_STATIC;
      } else {
        type = HighlightType.METHOD;
      }
    }
    return _addRegion_node(node, type);
  }

  bool _addIdentifierRegion_parameter(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! ParameterElement) {
      return false;
    }
    return _addRegion_node(node, HighlightType.PARAMETER);
  }

  bool _addIdentifierRegion_topLevelVariable(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! TopLevelVariableElement) {
      return false;
    }
    return _addRegion_node(node, HighlightType.TOP_LEVEL_VARIABLE);
  }

  bool _addIdentifierRegion_typeParameter(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is! TypeParameterElement) {
      return false;
    }
    return _addRegion_node(node, HighlightType.TYPE_PARAMETER);
  }

  void _addRegion(int offset, int length, HighlightType type) {
    _regions.add(new HighlightRegion(offset, length, type));
  }

  bool _addRegion_node(AstNode node, HighlightType type) {
    int offset = node.offset;
    int length = node.length;
    _addRegion(offset, length, type);
    return true;
  }

  void _addRegion_nodeStart_tokenEnd(AstNode a, Token b, HighlightType type) {
    int offset = a.offset;
    int end = b.end;
    _addRegion(offset, end - offset, type);
  }

  void _addRegion_token(Token token, HighlightType type) {
    if (token != null) {
      int offset = token.offset;
      int length = token.length;
      _addRegion(offset, length, type);
    }
  }

  void _addRegion_tokenStart_tokenEnd(Token a, Token b, HighlightType type) {
    int offset = a.offset;
    int end = b.end;
    _addRegion(offset, end - offset, type);
  }
}


class HighlightRegion {
  final int offset;
  final int length;
  final HighlightType type;

  HighlightRegion(this.offset, this.length, this.type);

  factory HighlightRegion.fromJson(Map<String, Object> map) {
    HighlightType type = HighlightType.valueOf(map[TYPE]);
    return new HighlightRegion(map[OFFSET], map[LENGTH], type);
  }

  Map<String, Object> toJson() {
    Map<String, Object> json = <String, Object>{};
    json[OFFSET] = offset;
    json[LENGTH] = length;
    json[TYPE] = type.name;
    return json;
  }

  @override
  String toString() => toJson().toString();
}


/**
 * Highlighting kinds constants.
 */
class HighlightType {
  static const HighlightType ANNOTATION = const HighlightType('ANNOTATION');
  static const HighlightType BUILT_IN = const HighlightType('BUILT_IN');
  static const HighlightType CLASS = const HighlightType('CLASS');
  static const HighlightType COMMENT_BLOCK = const HighlightType(
      'COMMENT_BLOCK');
  static const HighlightType COMMENT_DOCUMENTATION = const HighlightType(
      'COMMENT_DOCUMENTATION');
  static const HighlightType COMMENT_END_OF_LINE = const HighlightType(
      'COMMENT_END_OF_LINE');
  static const HighlightType CONSTRUCTOR = const HighlightType('CONSTRUCTOR');
  static const HighlightType DIRECTIVE = const HighlightType('DIRECTIVE');
  static const HighlightType DYNAMIC_TYPE = const HighlightType('DYNAMIC_TYPE');
  static const HighlightType FIELD = const HighlightType('FIELD');
  static const HighlightType FIELD_STATIC = const HighlightType('FIELD_STATIC');
  static const HighlightType FUNCTION_DECLARATION = const HighlightType(
      'FUNCTION_DECLARATION');
  static const HighlightType FUNCTION = const HighlightType('FUNCTION');
  static const HighlightType FUNCTION_TYPE_ALIAS = const HighlightType(
      'FUNCTION_TYPE_ALIAS');
  static const HighlightType GETTER_DECLARATION = const HighlightType(
      'GETTER_DECLARATION');
  static const HighlightType KEYWORD = const HighlightType('KEYWORD');
  static const HighlightType IDENTIFIER_DEFAULT = const HighlightType(
      'IDENTIFIER_DEFAULT');
  static const HighlightType IMPORT_PREFIX = const HighlightType(
      'IMPORT_PREFIX');
  static const HighlightType LITERAL_BOOLEAN = const HighlightType(
      'LITERAL_BOOLEAN');
  static const HighlightType LITERAL_DOUBLE = const HighlightType(
      'LITERAL_DOUBLE');
  static const HighlightType LITERAL_INTEGER = const HighlightType(
      'LITERAL_INTEGER');
  static const HighlightType LITERAL_LIST = const HighlightType('LITERAL_LIST');
  static const HighlightType LITERAL_MAP = const HighlightType('LITERAL_MAP');
  static const HighlightType LITERAL_STRING = const HighlightType(
      'LITERAL_STRING');
  static const HighlightType LOCAL_VARIABLE_DECLARATION = const HighlightType(
      'LOCAL_VARIABLE_DECLARATION');
  static const HighlightType LOCAL_VARIABLE = const HighlightType(
      'LOCAL_VARIABLE');
  static const HighlightType METHOD_DECLARATION = const HighlightType(
      'METHOD_DECLARATION');
  static const HighlightType METHOD_DECLARATION_STATIC = const HighlightType(
      'METHOD_DECLARATION_STATIC');
  static const HighlightType METHOD = const HighlightType('METHOD');
  static const HighlightType METHOD_STATIC = const HighlightType(
      'METHOD_STATIC');
  static const HighlightType PARAMETER = const HighlightType('PARAMETER');
  static const HighlightType SETTER_DECLARATION = const HighlightType(
      'SETTER_DECLARATION');
  static const HighlightType TOP_LEVEL_VARIABLE = const HighlightType(
      'TOP_LEVEL_VARIABLE');
  static const HighlightType TYPE_NAME_DYNAMIC = const HighlightType(
      'TYPE_NAME_DYNAMIC');
  static const HighlightType TYPE_PARAMETER = const HighlightType(
      'TYPE_PARAMETER');

  final String name;

  const HighlightType(this.name);

  @override
  String toString() => name;

  static HighlightType valueOf(String name) {
    if (ANNOTATION.name == name) return ANNOTATION;
    if (BUILT_IN.name == name) return BUILT_IN;
    if (CLASS.name == name) return CLASS;
    if (COMMENT_BLOCK.name == name) return COMMENT_BLOCK;
    if (COMMENT_DOCUMENTATION.name == name) return COMMENT_DOCUMENTATION;
    if (COMMENT_END_OF_LINE.name == name) return COMMENT_END_OF_LINE;
    if (CONSTRUCTOR.name == name) return CONSTRUCTOR;
    if (DIRECTIVE.name == name) return DIRECTIVE;
    if (DYNAMIC_TYPE.name == name) return DYNAMIC_TYPE;
    if (FIELD.name == name) return FIELD;
    if (FIELD_STATIC.name == name) return FIELD_STATIC;
    if (FUNCTION_DECLARATION.name == name) return FUNCTION_DECLARATION;
    if (FUNCTION.name == name) return FUNCTION;
    if (FUNCTION_TYPE_ALIAS.name == name) return FUNCTION_TYPE_ALIAS;
    if (GETTER_DECLARATION.name == name) return GETTER_DECLARATION;
    if (KEYWORD.name == name) return KEYWORD;
    if (IDENTIFIER_DEFAULT.name == name) return IDENTIFIER_DEFAULT;
    if (IMPORT_PREFIX.name == name) return IMPORT_PREFIX;
    if (LITERAL_BOOLEAN.name == name) return LITERAL_BOOLEAN;
    if (LITERAL_DOUBLE.name == name) return LITERAL_DOUBLE;
    if (LITERAL_INTEGER.name == name) return LITERAL_INTEGER;
    if (LITERAL_LIST.name == name) return LITERAL_LIST;
    if (LITERAL_MAP.name == name) return LITERAL_MAP;
    if (LITERAL_STRING.name == name) return LITERAL_STRING;
    if (LOCAL_VARIABLE_DECLARATION.name == name) return
        LOCAL_VARIABLE_DECLARATION;
    if (LOCAL_VARIABLE.name == name) return LOCAL_VARIABLE;
    if (METHOD_DECLARATION.name == name) return METHOD_DECLARATION;
    if (METHOD_DECLARATION_STATIC.name == name) return
        METHOD_DECLARATION_STATIC;
    if (METHOD.name == name) return METHOD;
    if (METHOD_STATIC.name == name) return METHOD_STATIC;
    if (PARAMETER.name == name) return PARAMETER;
    if (SETTER_DECLARATION.name == name) return SETTER_DECLARATION;
    if (TOP_LEVEL_VARIABLE.name == name) return TOP_LEVEL_VARIABLE;
    if (TYPE_NAME_DYNAMIC.name == name) return TYPE_NAME_DYNAMIC;
    if (TYPE_PARAMETER.name == name) return TYPE_PARAMETER;
    throw new ArgumentError('Unknown HighlightType: $name');
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
    computer._addRegion_token(node.asOperator, HighlightType.BUILT_IN);
    return super.visitAsExpression(node);
  }

  @override
  Object visitBooleanLiteral(BooleanLiteral node) {
    computer._addRegion_node(node, HighlightType.LITERAL_BOOLEAN);
    return super.visitBooleanLiteral(node);
  }

  @override
  Object visitCatchClause(CatchClause node) {
    computer._addRegion_token(node.onKeyword, HighlightType.BUILT_IN);
    return super.visitCatchClause(node);
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    computer._addRegion_token(node.abstractKeyword, HighlightType.BUILT_IN);
    return super.visitClassDeclaration(node);
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    computer._addRegion_token(node.externalKeyword, HighlightType.BUILT_IN);
    computer._addRegion_token(node.factoryKeyword, HighlightType.BUILT_IN);
    return super.visitConstructorDeclaration(node);
  }

  @override
  Object visitDoubleLiteral(DoubleLiteral node) {
    computer._addRegion_node(node, HighlightType.LITERAL_DOUBLE);
    return super.visitDoubleLiteral(node);
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    computer._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    return super.visitExportDirective(node);
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    computer._addRegion_token(node.staticKeyword, HighlightType.BUILT_IN);
    return super.visitFieldDeclaration(node);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    computer._addRegion_token(node.externalKeyword, HighlightType.BUILT_IN);
    computer._addRegion_token(node.propertyKeyword, HighlightType.BUILT_IN);
    return super.visitFunctionDeclaration(node);
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    computer._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    return super.visitFunctionTypeAlias(node);
  }

  @override
  Object visitHideCombinator(HideCombinator node) {
    computer._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    return super.visitHideCombinator(node);
  }

  @override
  Object visitImplementsClause(ImplementsClause node) {
    computer._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    return super.visitImplementsClause(node);
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    computer._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    computer._addRegion_token(node.deferredToken, HighlightType.BUILT_IN);
    computer._addRegion_token(node.asToken, HighlightType.BUILT_IN);
    return super.visitImportDirective(node);
  }

  @override
  Object visitIntegerLiteral(IntegerLiteral node) {
    computer._addRegion_node(node, HighlightType.LITERAL_INTEGER);
    return super.visitIntegerLiteral(node);
  }

  @override
  Object visitLibraryDirective(LibraryDirective node) {
    computer._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    return super.visitLibraryDirective(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    computer._addRegion_token(node.externalKeyword, HighlightType.BUILT_IN);
    computer._addRegion_token(node.modifierKeyword, HighlightType.BUILT_IN);
    computer._addRegion_token(node.operatorKeyword, HighlightType.BUILT_IN);
    computer._addRegion_token(node.propertyKeyword, HighlightType.BUILT_IN);
    return super.visitMethodDeclaration(node);
  }

  @override
  Object visitNativeClause(NativeClause node) {
    computer._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    return super.visitNativeClause(node);
  }

  @override
  Object visitNativeFunctionBody(NativeFunctionBody node) {
    computer._addRegion_token(node.nativeToken, HighlightType.BUILT_IN);
    return super.visitNativeFunctionBody(node);
  }

  @override
  Object visitPartDirective(PartDirective node) {
    computer._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    return super.visitPartDirective(node);
  }

  @override
  Object visitPartOfDirective(PartOfDirective node) {
    computer._addRegion_tokenStart_tokenEnd(node.partToken, node.ofToken,
        HighlightType.BUILT_IN);
    return super.visitPartOfDirective(node);
  }

  @override
  Object visitShowCombinator(ShowCombinator node) {
    computer._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    return super.visitShowCombinator(node);
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    computer._addIdentifierRegion(node);
    return super.visitSimpleIdentifier(node);
  }

  @override
  Object visitSimpleStringLiteral(SimpleStringLiteral node) {
    computer._addRegion_node(node, HighlightType.LITERAL_STRING);
    return super.visitSimpleStringLiteral(node);
  }

  @override
  Object visitTypeName(TypeName node) {
    DartType type = node.type;
    if (type != null) {
      if (type.isDynamic && node.name.name == "dynamic") {
        computer._addRegion_node(node, HighlightType.TYPE_NAME_DYNAMIC);
        return null;
      }
    }
    return super.visitTypeName(node);
  }
}
