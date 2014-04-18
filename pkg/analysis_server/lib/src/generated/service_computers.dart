// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library service.computers;

import 'package:analyzer/src/generated/java_core.dart' show JavaStringBuilder, StringUtils;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/generated/scanner.dart' show Token;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart' show Element;
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

  final OutlineKind kind;

  final String name;

  final int offset;

  final int length;

  final String arguments;

  final String returnType;

  List<Outline> children = Outline.EMPTY_ARRAY;

  OutlineImpl(this.parent, this.kind, this.name, this.offset, this.length, this.arguments, this.returnType);

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
    builder.append(", arguments=");
    builder.append(arguments);
    builder.append(", return=");
    builder.append(returnType);
    builder.append(", children=[");
    builder.append(StringUtils.join(children, ", "));
    builder.append("]]");
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
  void _addRegionForNode(AstNode node, Element element) {
    int offset = node.offset;
    int length = node.length;
    _addRegion(offset, length, element);
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
                _newField(classOutline, classChildren, fieldTypeName, field);
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

  OutlineImpl _newClassOutline(Outline unitOutline, List<Outline> unitChildren, ClassDeclaration classDeclartion) {
    SimpleIdentifier nameNode = classDeclartion.name;
    String name = nameNode.name;
    OutlineImpl outline = new OutlineImpl(unitOutline, OutlineKind.CLASS, name, nameNode.offset, name.length, null, null);
    unitChildren.add(outline);
    return outline;
  }

  void _newClassTypeAlias(Outline unitOutline, List<Outline> unitChildren, ClassTypeAlias alias) {
    SimpleIdentifier nameNode = alias.name;
    unitChildren.add(new OutlineImpl(unitOutline, OutlineKind.CLASS_TYPE_ALIAS, nameNode.name, nameNode.offset, nameNode.length, null, null));
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
    OutlineImpl outline = new OutlineImpl(classOutline, OutlineKind.CONSTRUCTOR, name, offset, length, parameters != null ? parameters.toSource() : "", null);
    children.add(outline);
    _addLocalFunctionOutlines(outline, constructorDeclaration.body);
  }

  void _newField(OutlineImpl classOutline, List<Outline> children, String fieldTypeName, VariableDeclaration field) {
    SimpleIdentifier nameNode = field.name;
    children.add(new OutlineImpl(classOutline, OutlineKind.FIELD, nameNode.name, nameNode.offset, nameNode.length, null, fieldTypeName));
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
    OutlineImpl outline = new OutlineImpl(unitOutline, kind, nameNode.name, nameNode.offset, nameNode.length, parameters != null ? parameters.toSource() : "", returnType != null ? returnType.toSource() : "");
    unitChildren.add(outline);
    _addLocalFunctionOutlines(outline, functionExpression.body);
  }

  void _newFunctionTypeAliasOutline(Outline unitOutline, List<Outline> unitChildren, FunctionTypeAlias alias) {
    TypeName returnType = alias.returnType;
    SimpleIdentifier nameNode = alias.name;
    FormalParameterList parameters = alias.parameters;
    unitChildren.add(new OutlineImpl(unitOutline, OutlineKind.FUNCTION_TYPE_ALIAS, nameNode.name, nameNode.offset, nameNode.length, parameters != null ? parameters.toSource() : "", returnType != null ? returnType.toSource() : ""));
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
    OutlineImpl outline = new OutlineImpl(classOutline, kind, nameNode.name, nameNode.offset, nameNode.length, parameters != null ? parameters.toSource() : "", returnType != null ? returnType.toSource() : "");
    children.add(outline);
    _addLocalFunctionOutlines(outline, methodDeclaration.body);
  }

  OutlineImpl _newUnitOutline() => new OutlineImpl(null, OutlineKind.COMPILATION_UNIT, null, 0, 0, null, null);
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