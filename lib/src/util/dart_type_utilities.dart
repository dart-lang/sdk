// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

typedef bool AstNodePredicate(AstNode node);

class DartTypeUtilities {
  static bool extendsClass(DartType type, String className, String library) =>
      isClass(type, className, library) ||
      (type is InterfaceType &&
          extendsClass(type.superclass, className, library));

  static Element getCanonicalElement(Element element) =>
      element is PropertyAccessorElement ? element.variable : element;

  static Element getCanonicalElementFromIdentifier(AstNode rawNode) {
    if (rawNode is Expression) {
      final node = rawNode.unParenthesized;
      if (node is Identifier) {
        return getCanonicalElement(node.bestElement);
      } else if (node is PropertyAccess) {
        return getCanonicalElement(node.propertyName.bestElement);
      }
    }
    return null;
  }

  static Iterable<InterfaceType> getImplementedInterfaces(InterfaceType type) {
    void recursiveCall(InterfaceType type, Set<ClassElement> alreadyVisited,
        List<InterfaceType> interfaceTypes) {
      if (type == null || !alreadyVisited.add(type.element)) {
        return;
      }
      interfaceTypes.add(type);
      recursiveCall(type.superclass, alreadyVisited, interfaceTypes);
      for (final interface in type.interfaces) {
        recursiveCall(interface, alreadyVisited, interfaceTypes);
      }
      for (final mixin in type.mixins) {
        recursiveCall(mixin, alreadyVisited, interfaceTypes);
      }
    }

    final interfaceTypes = <InterfaceType>[];
    recursiveCall(type, new Set<ClassElement>(), interfaceTypes);
    return interfaceTypes;
  }

  static Statement getLastStatementInBlock(Block node) {
    if (node.statements.isEmpty) {
      return null;
    }
    final lastStatement = node.statements.last;
    if (lastStatement is Block) {
      return getLastStatementInBlock(lastStatement);
    }
    return lastStatement;
  }

  static bool hasInheritedMethod(MethodDeclaration node) =>
      lookUpInheritedMethod(node) != null;

  static bool implementsAnyInterface(
      DartType type, Iterable<InterfaceTypeDefinition> definitions) {
    if (type is! InterfaceType) {
      return false;
    }
    bool predicate(InterfaceType i) =>
        definitions.any((d) => isInterface(i, d.name, d.library));
    ClassElement element = type.element;
    return predicate(type) ||
        !element.isSynthetic && element.allSupertypes.any(predicate);
  }

  static bool implementsInterface(
      DartType type, String interface, String library) {
    if (type is! InterfaceType) {
      return false;
    }
    bool predicate(InterfaceType i) => isInterface(i, interface, library);
    ClassElement element = type.element;
    return predicate(type) ||
        !element.isSynthetic && element.allSupertypes.any(predicate);
  }

  static bool isClass(DartType type, String className, String library) =>
      type != null &&
      type.name == className &&
      type.element?.library?.name == library;

  static bool isInterface(
          InterfaceType type, String interface, String library) =>
      type.name == interface && type.element.library.name == library;

  static bool isNullLiteral(Expression expression) =>
      expression?.unParenthesized is NullLiteral;

  static PropertyAccessorElement lookUpGetter(MethodDeclaration node) =>
      (node.parent as ClassDeclaration)
          .element
          .lookUpGetter(node.name.name, node.element.library);

  static PropertyAccessorElement lookUpInheritedConcreteGetter(
          MethodDeclaration node) =>
      (node.parent as ClassDeclaration)
          .element
          .lookUpInheritedConcreteGetter(node.name.name, node.element.library);

  static MethodElement lookUpInheritedConcreteMethod(MethodDeclaration node) =>
      (node.parent as ClassDeclaration)
          .element
          .lookUpInheritedConcreteMethod(node.name.name, node.element.library);

  static PropertyAccessorElement lookUpInheritedConcreteSetter(
          MethodDeclaration node) =>
      (node.parent as ClassDeclaration)
          .element
          .lookUpInheritedConcreteSetter(node.name.name, node.element.library);

  static MethodElement lookUpInheritedMethod(MethodDeclaration node) =>
      (node.parent as ClassDeclaration)
          .element
          .lookUpInheritedMethod(node.name.name, node.element.library);

  static PropertyAccessorElement lookUpSetter(MethodDeclaration node) =>
      (node.parent as ClassDeclaration)
          .element
          .lookUpSetter(node.name.name, node.element.library);

  static bool matchesArgumentsWithParameters(
      NodeList<Expression> arguments, NodeList<FormalParameter> parameters) {
    final namedParameters = <String, Element>{};
    final namedArguments = <String, Element>{};
    final positionalParameters = <Element>[];
    final positionalArguments = <Element>[];
    for (final parameter in parameters) {
      if (parameter.kind == ParameterKind.NAMED) {
        namedParameters[parameter.identifier.name] =
            parameter.identifier.bestElement;
      } else {
        positionalParameters.add(parameter.identifier.bestElement);
      }
    }
    for (final argument in arguments) {
      if (argument is NamedExpression) {
        final element = DartTypeUtilities
            .getCanonicalElementFromIdentifier(argument.expression);
        if (element == null) {
          return false;
        }
        namedArguments[argument.name.label.name] = element;
      } else {
        final element =
            DartTypeUtilities.getCanonicalElementFromIdentifier(argument);
        if (element == null) {
          return false;
        }
        positionalArguments.add(element);
      }
    }
    if (positionalParameters.length != positionalArguments.length ||
        namedParameters.keys.length != namedArguments.keys.length) {
      return false;
    }
    for (var i = 0; i < positionalArguments.length; i++) {
      if (positionalArguments[i] != positionalParameters[i]) {
        return false;
      }
    }

    for (final key in namedParameters.keys) {
      if (namedParameters[key] != namedArguments[key]) {
        return false;
      }
    }

    return true;
  }

  /// Builds the list resulting from traversing the node in DFS and does not
  /// include the node itself, it excludes the nodes for which the exclusion
  /// predicate returns true, if not provided, all is included.
  static Iterable<AstNode> traverseNodesInDFS(AstNode node,
      {AstNodePredicate excludeCriteria}) {
    LinkedHashSet<AstNode> nodes = new LinkedHashSet();
    void recursiveCall(node) {
      if (node is AstNode &&
          (excludeCriteria == null || !excludeCriteria(node))) {
        nodes.add(node);
        node.childEntities.forEach(recursiveCall);
      }
    }

    node.childEntities.forEach(recursiveCall);
    return nodes;
  }

  static bool unrelatedTypes(DartType leftType, DartType rightType) {
    if (leftType == null ||
        leftType.isBottom ||
        leftType.isDynamic ||
        rightType == null ||
        rightType.isBottom ||
        rightType.isDynamic) {
      return false;
    }
    if (leftType == rightType ||
        leftType.isMoreSpecificThan(rightType) ||
        rightType.isMoreSpecificThan(leftType)) {
      return false;
    }
    Element leftElement = leftType.element;
    Element rightElement = rightType.element;
    if (leftElement is ClassElement && rightElement is ClassElement) {
      return leftElement.supertype.isObject ||
          leftElement.supertype != rightElement.supertype;
    }
    return false;
  }
}

class InterfaceTypeDefinition {
  final String name;
  final String library;

  InterfaceTypeDefinition(this.name, this.library);

  @override
  int get hashCode {
    return name.hashCode ^ library.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is InterfaceTypeDefinition &&
        name == other.name &&
        library == other.library;
  }
}
