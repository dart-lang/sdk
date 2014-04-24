// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library service.computers;

import 'package:analyzer/src/generated/java_core.dart' show JavaStringBuilder, StringUtils;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/generated/scanner.dart' show Token;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'service_interfaces.dart';

/**
 * A concrete implementation of [SourceRegion].
 */
class SourceRegionImpl implements SourceRegion {
  final int offset;

  final int length;

  SourceRegionImpl(this.offset, this.length);

  @override
  bool containsInclusive(int x) => offset <= x && x <= offset + length;

  @override
  bool operator ==(Object obj) {
    if (identical(obj, this)) {
      return true;
    }
    if (obj is! SourceRegion) {
      return false;
    }
    SourceRegion other = obj as SourceRegion;
    return other.offset == offset && other.length == length;
  }

  @override
  int get hashCode => ObjectUtilities.combineHashCodes(offset, length);

  @override
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("[offset=");
    builder.append(offset);
    builder.append(", length=");
    builder.append(length);
    builder.append("]");
    return builder.toString();
  }
}

/**
 * A concrete implementation of [Outline].
 */
class OutlineImpl implements Outline {
  final Outline parent;

  final SourceRegion sourceRegion;

  final OutlineKind kind;

  final String name;

  final int offset;

  final int length;

  final String parameters;

  final String returnType;

  final bool isAbstract;

  final bool isStatic;

  List<Outline> children = Outline.EMPTY_ARRAY;

  OutlineImpl(this.parent, this.sourceRegion, this.kind, this.name, this.offset, this.length, this.parameters, this.returnType, this.isAbstract, this.isStatic);

  @override
  bool operator ==(Object obj) {
    if (identical(obj, this)) {
      return true;
    }
    if (obj is! OutlineImpl) {
      return false;
    }
    OutlineImpl other = obj as OutlineImpl;
    return (other.parent == parent) && other.offset == offset;
  }

  @override
  int get hashCode => offset;

  @override
  bool get isPrivate => StringUtilities.startsWithChar(name, 0x5F);

  @override
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("[name=");
    builder.append(name);
    builder.append(", kind=");
    builder.append(kind);
    builder.append(", offset=");
    builder.append(offset);
    builder.append(", length=");
    builder.append(length);
    builder.append(", parameters=");
    builder.append(parameters);
    builder.append(", return=");
    builder.append(returnType);
    builder.append(", children=[");
    builder.append(StringUtils.join(children, ", "));
    builder.append("]]");
    return builder.toString();
  }
}

/**
 * A concrete implementation of [HighlightRegion].
 */
class HighlightRegionImpl extends SourceRegionImpl implements HighlightRegion {
  final HighlightType type;

  HighlightRegionImpl(int offset, int length, this.type) : super(offset, length);

  @override
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("[offset=");
    builder.append(offset);
    builder.append(", length=");
    builder.append(length);
    builder.append(", type=");
    builder.append(type);
    builder.append("]");
    return builder.toString();
  }
}

/**
 * A computer for [NavigationRegion]s in a Dart [CompilationUnit].
 */
class DartUnitNavigationComputer {
  final CompilationUnit _unit;

  List<NavigationRegion> _regions = [];

  DartUnitNavigationComputer(this._unit);

  /**
   * Returns the computed [NavigationRegion]s, not `null`.
   */
  List<NavigationRegion> compute() {
    _unit.accept(new RecursiveAstVisitor_DartUnitNavigationComputer_compute(this));
    return new List.from(_regions);
  }

  /**
   * If the given [Element] is not `null`, then creates a corresponding
   * [NavigationRegion].
   */
  void _addRegion(int offset, int length, Element element) {
    NavigationTarget target = _createTarget(element);
    if (target == null) {
      return;
    }
    _regions.add(new NavigationRegionImpl(offset, length, <NavigationTarget> [target]));
  }

  /**
   * If the given [Element] is not `null`, then creates a corresponding
   * [NavigationRegion].
   */
  void _addRegionForNode(AstNode node, Element element) {
    int offset = node.offset;
    int length = node.length;
    _addRegion(offset, length, element);
  }

  /**
   * If the given [Element] is not `null`, then creates a corresponding
   * [NavigationRegion].
   */
  void _addRegionForToken(Token token, Element element) {
    int offset = token.offset;
    int length = token.length;
    _addRegion(offset, length, element);
  }

  /**
   * Returns the [NavigationTarget] for the given [Element], maybe `null` if
   * `null` was given.
   */
  NavigationTarget _createTarget(Element element) {
    if (element == null) {
      return null;
    }
    if (element is FieldFormalParameterElement) {
      element = (element as FieldFormalParameterElement).field;
    }
    return new NavigationTargetImpl(element.source, _getElementId(element), element.nameOffset, element.displayName.length);
  }

  String _getElementId(Element element) => element.location.encoding;
}

class RecursiveAstVisitor_DartUnitNavigationComputer_compute extends RecursiveAstVisitor<Object> {
  final DartUnitNavigationComputer DartUnitNavigationComputer_this;

  RecursiveAstVisitor_DartUnitNavigationComputer_compute(this.DartUnitNavigationComputer_this) : super();

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    DartUnitNavigationComputer_this._addRegionForToken(node.operator, node.bestElement);
    return super.visitAssignmentExpression(node);
  }

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    DartUnitNavigationComputer_this._addRegionForToken(node.operator, node.bestElement);
    return super.visitBinaryExpression(node);
  }

  @override
  Object visitIndexExpression(IndexExpression node) {
    DartUnitNavigationComputer_this._addRegionForToken(node.rightBracket, node.bestElement);
    return super.visitIndexExpression(node);
  }

  @override
  Object visitPostfixExpression(PostfixExpression node) {
    DartUnitNavigationComputer_this._addRegionForToken(node.operator, node.bestElement);
    return super.visitPostfixExpression(node);
  }

  @override
  Object visitPrefixExpression(PrefixExpression node) {
    DartUnitNavigationComputer_this._addRegionForToken(node.operator, node.bestElement);
    return super.visitPrefixExpression(node);
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    DartUnitNavigationComputer_this._addRegionForNode(node, node.bestElement);
    return super.visitSimpleIdentifier(node);
  }
}

/**
 * A computer for [HighlightRegion]s in a Dart [CompilationUnit].
 */
class DartUnitHighlightsComputer {
  final CompilationUnit _unit;

  List<HighlightRegion> _regions = [];

  DartUnitHighlightsComputer(this._unit);

  /**
   * Returns the computed [HighlightRegion]s, not `null`.
   */
  List<HighlightRegion> compute() {
    _unit.accept(new RecursiveAstVisitor_DartUnitHighlightsComputer_compute(this));
    return new List.from(_regions);
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
      _addRegion_nodeStart_tokenEnd(node, arguments.beginToken, HighlightType.ANNOTATION);
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
    PropertyAccessorElement propertyAccessorElement = element as PropertyAccessorElement;
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
    _regions.add(new HighlightRegionImpl(offset, length, type));
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

class RecursiveAstVisitor_DartUnitHighlightsComputer_compute extends RecursiveAstVisitor<Object> {
  final DartUnitHighlightsComputer DartUnitHighlightsComputer_this;

  RecursiveAstVisitor_DartUnitHighlightsComputer_compute(this.DartUnitHighlightsComputer_this) : super();

  @override
  Object visitAnnotation(Annotation node) {
    DartUnitHighlightsComputer_this._addIdentifierRegion_annotation(node);
    return super.visitAnnotation(node);
  }

  @override
  Object visitAsExpression(AsExpression node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.asOperator, HighlightType.BUILT_IN);
    return super.visitAsExpression(node);
  }

  @override
  Object visitBooleanLiteral(BooleanLiteral node) {
    DartUnitHighlightsComputer_this._addRegion_node(node, HighlightType.LITERAL_BOOLEAN);
    return super.visitBooleanLiteral(node);
  }

  @override
  Object visitCatchClause(CatchClause node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.onKeyword, HighlightType.BUILT_IN);
    return super.visitCatchClause(node);
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.abstractKeyword, HighlightType.BUILT_IN);
    return super.visitClassDeclaration(node);
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.externalKeyword, HighlightType.BUILT_IN);
    DartUnitHighlightsComputer_this._addRegion_token(node.factoryKeyword, HighlightType.BUILT_IN);
    return super.visitConstructorDeclaration(node);
  }

  @override
  Object visitDoubleLiteral(DoubleLiteral node) {
    DartUnitHighlightsComputer_this._addRegion_node(node, HighlightType.LITERAL_DOUBLE);
    return super.visitDoubleLiteral(node);
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    return super.visitExportDirective(node);
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.staticKeyword, HighlightType.BUILT_IN);
    return super.visitFieldDeclaration(node);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.externalKeyword, HighlightType.BUILT_IN);
    DartUnitHighlightsComputer_this._addRegion_token(node.propertyKeyword, HighlightType.BUILT_IN);
    return super.visitFunctionDeclaration(node);
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    return super.visitFunctionTypeAlias(node);
  }

  @override
  Object visitHideCombinator(HideCombinator node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    return super.visitHideCombinator(node);
  }

  @override
  Object visitImplementsClause(ImplementsClause node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    return super.visitImplementsClause(node);
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    DartUnitHighlightsComputer_this._addRegion_token(node.deferredToken, HighlightType.BUILT_IN);
    DartUnitHighlightsComputer_this._addRegion_token(node.asToken, HighlightType.BUILT_IN);
    return super.visitImportDirective(node);
  }

  @override
  Object visitIntegerLiteral(IntegerLiteral node) {
    DartUnitHighlightsComputer_this._addRegion_node(node, HighlightType.LITERAL_INTEGER);
    return super.visitIntegerLiteral(node);
  }

  @override
  Object visitLibraryDirective(LibraryDirective node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    return super.visitLibraryDirective(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.externalKeyword, HighlightType.BUILT_IN);
    DartUnitHighlightsComputer_this._addRegion_token(node.modifierKeyword, HighlightType.BUILT_IN);
    DartUnitHighlightsComputer_this._addRegion_token(node.operatorKeyword, HighlightType.BUILT_IN);
    DartUnitHighlightsComputer_this._addRegion_token(node.propertyKeyword, HighlightType.BUILT_IN);
    return super.visitMethodDeclaration(node);
  }

  @override
  Object visitNativeClause(NativeClause node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    return super.visitNativeClause(node);
  }

  @override
  Object visitNativeFunctionBody(NativeFunctionBody node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.nativeToken, HighlightType.BUILT_IN);
    return super.visitNativeFunctionBody(node);
  }

  @override
  Object visitPartDirective(PartDirective node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    return super.visitPartDirective(node);
  }

  @override
  Object visitPartOfDirective(PartOfDirective node) {
    DartUnitHighlightsComputer_this._addRegion_tokenStart_tokenEnd(node.partToken, node.ofToken, HighlightType.BUILT_IN);
    return super.visitPartOfDirective(node);
  }

  @override
  Object visitShowCombinator(ShowCombinator node) {
    DartUnitHighlightsComputer_this._addRegion_token(node.keyword, HighlightType.BUILT_IN);
    return super.visitShowCombinator(node);
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    DartUnitHighlightsComputer_this._addIdentifierRegion(node);
    return super.visitSimpleIdentifier(node);
  }

  @override
  Object visitSimpleStringLiteral(SimpleStringLiteral node) {
    DartUnitHighlightsComputer_this._addRegion_node(node, HighlightType.LITERAL_STRING);
    return super.visitSimpleStringLiteral(node);
  }

  @override
  Object visitTypeName(TypeName node) {
    DartType type = node.type;
    if (type != null) {
      if (type.isDynamic && node.name.name == "dynamic") {
        DartUnitHighlightsComputer_this._addRegion_node(node, HighlightType.TYPE_NAME_DYNAMIC);
        return null;
      }
    }
    return super.visitTypeName(node);
  }
}

/**
 * A concrete implementation of [NavigationRegion].
 */
class NavigationRegionImpl extends SourceRegionImpl implements NavigationRegion {
  final List<NavigationTarget> targets;

  NavigationRegionImpl(int offset, int length, this.targets) : super(offset, length);

  @override
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append(super.toString());
    builder.append(" -> [");
    builder.append(StringUtils.join(targets, ", "));
    builder.append("]");
    return builder.toString();
  }
}

/**
 * A concrete implementation of [NavigationTarget].
 */
class NavigationTargetImpl implements NavigationTarget {
  final Source source;

  final String elementId;

  final int offset;

  final int length;

  NavigationTargetImpl(this.source, this.elementId, this.offset, this.length);

  @override
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("[offset=");
    builder.append(offset);
    builder.append(", length=");
    builder.append(length);
    builder.append(", source=");
    builder.append(source);
    builder.append(", element=");
    builder.append(elementId);
    builder.append("]");
    return builder.toString();
  }
}

/**
 * A computer for [Outline]s in a Dart [CompilationUnit].
 */
class DartUnitOutlineComputer {
  final CompilationUnit _unit;

  DartUnitOutlineComputer(this._unit);

  /**
   * Returns the computed [Outline]s, not `null`.
   */
  Outline compute() {
    OutlineImpl unitOutline = _newUnitOutline();
    List<Outline> unitChildren = [];
    for (CompilationUnitMember unitMember in _unit.declarations) {
      if (unitMember is ClassDeclaration) {
        ClassDeclaration classDeclartion = unitMember;
        OutlineImpl classOutline = _newClassOutline(unitOutline, unitChildren, classDeclartion);
        List<Outline> classChildren = [];
        for (ClassMember classMember in classDeclartion.members) {
          if (classMember is ConstructorDeclaration) {
            ConstructorDeclaration constructorDeclaration = classMember;
            _newConstructorOutline(classOutline, classChildren, constructorDeclaration);
          }
          if (classMember is FieldDeclaration) {
            FieldDeclaration fieldDeclaration = classMember;
            VariableDeclarationList fields = fieldDeclaration.fields;
            if (fields != null) {
              TypeName fieldType = fields.type;
              String fieldTypeName = fieldType != null ? fieldType.toSource() : "";
              for (VariableDeclaration field in fields.variables) {
                _newField(classOutline, classChildren, fieldTypeName, field, fieldDeclaration.isStatic);
              }
            }
          }
          if (classMember is MethodDeclaration) {
            MethodDeclaration methodDeclaration = classMember;
            _newMethodOutline(classOutline, classChildren, methodDeclaration);
          }
        }
        classOutline.children = new List.from(classChildren);
      }
      if (unitMember is FunctionDeclaration) {
        FunctionDeclaration functionDeclaration = unitMember;
        _newFunctionOutline(unitOutline, unitChildren, functionDeclaration);
      }
      if (unitMember is ClassTypeAlias) {
        ClassTypeAlias alias = unitMember;
        _newClassTypeAlias(unitOutline, unitChildren, alias);
      }
      if (unitMember is FunctionTypeAlias) {
        FunctionTypeAlias alias = unitMember;
        _newFunctionTypeAliasOutline(unitOutline, unitChildren, alias);
      }
    }
    unitOutline.children = new List.from(unitChildren);
    return unitOutline;
  }

  void _addLocalFunctionOutlines(OutlineImpl parenet, FunctionBody body) {
    List<Outline> localOutlines = [];
    body.accept(new RecursiveAstVisitor_DartUnitOutlineComputer_addLocalFunctionOutlines(this, parenet, localOutlines));
    parenet.children = new List.from(localOutlines);
  }

  /**
   * Returns the [AstNode]'s source region.
   */
  SourceRegion _getSourceRegion(AstNode node) {
    int endOffset = node.end;
    // prepare position of the node among its siblings
    int firstOffset;
    List<AstNode> siblings;
    AstNode parent = node.parent;
    // field
    if (parent is VariableDeclarationList) {
      VariableDeclarationList variableList = parent as VariableDeclarationList;
      List<VariableDeclaration> variables = variableList.variables;
      int variableIndex = variables.indexOf(node);
      if (variableIndex == variables.length - 1) {
        endOffset = variableList.parent.end;
      }
      if (variableIndex == 0) {
        node = parent.parent;
        parent = node.parent;
      } else if (variableIndex >= 1) {
        firstOffset = variables[variableIndex - 1].end;
        return new SourceRegionImpl(firstOffset, endOffset - firstOffset);
      }
    }
    // unit or class member
    if (parent is CompilationUnit) {
      firstOffset = 0;
      siblings = (parent as CompilationUnit).declarations;
    } else if (parent is ClassDeclaration) {
      ClassDeclaration classDeclaration = parent as ClassDeclaration;
      firstOffset = classDeclaration.leftBracket.end;
      siblings = classDeclaration.members;
    } else {
      int offset = node.offset;
      return new SourceRegionImpl(offset, endOffset - offset);
    }
    // first child: [endOfParent, endOfNode]
    int index = siblings.indexOf(node);
    if (index == 0) {
      return new SourceRegionImpl(firstOffset, endOffset - firstOffset);
    }
    // not first child: [endOfPreviousSibling, endOfNode]
    int prevSiblingEnd = siblings[index - 1].end;
    return new SourceRegionImpl(prevSiblingEnd, endOffset - prevSiblingEnd);
  }

  OutlineImpl _newClassOutline(Outline unitOutline, List<Outline> unitChildren, ClassDeclaration classDeclaration) {
    SimpleIdentifier nameNode = classDeclaration.name;
    String name = nameNode.name;
    OutlineImpl outline = new OutlineImpl(unitOutline, _getSourceRegion(classDeclaration), OutlineKind.CLASS, name, nameNode.offset, name.length, null, null, classDeclaration.isAbstract, false);
    unitChildren.add(outline);
    return outline;
  }

  void _newClassTypeAlias(Outline unitOutline, List<Outline> unitChildren, ClassTypeAlias alias) {
    SimpleIdentifier nameNode = alias.name;
    unitChildren.add(new OutlineImpl(unitOutline, _getSourceRegion(alias), OutlineKind.CLASS_TYPE_ALIAS, nameNode.name, nameNode.offset, nameNode.length, null, null, alias.isAbstract, false));
  }

  void _newConstructorOutline(OutlineImpl classOutline, List<Outline> children, ConstructorDeclaration constructorDeclaration) {
    Identifier returnType = constructorDeclaration.returnType;
    String name = returnType.name;
    int offset = returnType.offset;
    int length = returnType.length;
    SimpleIdentifier constructorNameNode = constructorDeclaration.name;
    if (constructorNameNode != null) {
      name += ".${constructorNameNode.name}";
      offset = constructorNameNode.offset;
      length = constructorNameNode.length;
    }
    FormalParameterList parameters = constructorDeclaration.parameters;
    OutlineImpl outline = new OutlineImpl(classOutline, _getSourceRegion(constructorDeclaration), OutlineKind.CONSTRUCTOR, name, offset, length, parameters != null ? parameters.toSource() : "", null, false, false);
    children.add(outline);
    _addLocalFunctionOutlines(outline, constructorDeclaration.body);
  }

  void _newField(OutlineImpl classOutline, List<Outline> children, String fieldTypeName, VariableDeclaration field, bool isStatic) {
    SimpleIdentifier nameNode = field.name;
    children.add(new OutlineImpl(classOutline, _getSourceRegion(field), OutlineKind.FIELD, nameNode.name, nameNode.offset, nameNode.length, null, fieldTypeName, false, isStatic));
  }

  void _newFunctionOutline(Outline unitOutline, List<Outline> unitChildren, FunctionDeclaration functionDeclaration) {
    TypeName returnType = functionDeclaration.returnType;
    SimpleIdentifier nameNode = functionDeclaration.name;
    FunctionExpression functionExpression = functionDeclaration.functionExpression;
    FormalParameterList parameters = functionExpression.parameters;
    OutlineKind kind;
    if (functionDeclaration.isGetter) {
      kind = OutlineKind.GETTER;
    } else if (functionDeclaration.isSetter) {
      kind = OutlineKind.SETTER;
    } else {
      kind = OutlineKind.FUNCTION;
    }
    OutlineImpl outline = new OutlineImpl(unitOutline, _getSourceRegion(functionDeclaration), kind, nameNode.name, nameNode.offset, nameNode.length, parameters != null ? parameters.toSource() : "", returnType != null ? returnType.toSource() : "", false, false);
    unitChildren.add(outline);
    _addLocalFunctionOutlines(outline, functionExpression.body);
  }

  void _newFunctionTypeAliasOutline(Outline unitOutline, List<Outline> unitChildren, FunctionTypeAlias alias) {
    TypeName returnType = alias.returnType;
    SimpleIdentifier nameNode = alias.name;
    FormalParameterList parameters = alias.parameters;
    unitChildren.add(new OutlineImpl(unitOutline, _getSourceRegion(alias), OutlineKind.FUNCTION_TYPE_ALIAS, nameNode.name, nameNode.offset, nameNode.length, parameters != null ? parameters.toSource() : "", returnType != null ? returnType.toSource() : "", false, false));
  }

  void _newMethodOutline(OutlineImpl classOutline, List<Outline> children, MethodDeclaration methodDeclaration) {
    TypeName returnType = methodDeclaration.returnType;
    SimpleIdentifier nameNode = methodDeclaration.name;
    FormalParameterList parameters = methodDeclaration.parameters;
    OutlineKind kind;
    if (methodDeclaration.isGetter) {
      kind = OutlineKind.GETTER;
    } else if (methodDeclaration.isSetter) {
      kind = OutlineKind.SETTER;
    } else {
      kind = OutlineKind.METHOD;
    }
    OutlineImpl outline = new OutlineImpl(classOutline, _getSourceRegion(methodDeclaration), kind, nameNode.name, nameNode.offset, nameNode.length, parameters != null ? parameters.toSource() : "", returnType != null ? returnType.toSource() : "", methodDeclaration.isAbstract, methodDeclaration.isStatic);
    children.add(outline);
    _addLocalFunctionOutlines(outline, methodDeclaration.body);
  }

  OutlineImpl _newUnitOutline() => new OutlineImpl(null, new SourceRegionImpl(_unit.offset, _unit.length), OutlineKind.COMPILATION_UNIT, null, 0, 0, null, null, false, false);
}

class RecursiveAstVisitor_DartUnitOutlineComputer_addLocalFunctionOutlines extends RecursiveAstVisitor<Object> {
  final DartUnitOutlineComputer DartUnitOutlineComputer_this;

  OutlineImpl parenet;

  List<Outline> localOutlines;

  RecursiveAstVisitor_DartUnitOutlineComputer_addLocalFunctionOutlines(this.DartUnitOutlineComputer_this, this.parenet, this.localOutlines) : super();

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    DartUnitOutlineComputer_this._newFunctionOutline(parenet, localOutlines, node);
    return null;
  }
}