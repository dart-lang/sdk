// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/element/member.dart'; // ignore: implementation_imports
import 'package:meta/meta.dart';

typedef AstNodePredicate = bool Function(AstNode node);

class DartTypeUtilities {
  static EnumLikeClassDescription asEnumLikeClass(ClassElement classElement) {
    // See discussion: https://github.com/dart-lang/linter/issues/2083
    //

    // Must be concrete.
    if (classElement.isAbstract) {
      return null;
    }

    // With only private non-factory constructors.
    for (var cons in classElement.constructors) {
      if (!cons.isPrivate || cons.isFactory) {
        return null;
      }
    }

    var type = classElement.thisType;

    // And 2 or more static const fields whose type is the enclosing class.
    var enumConstantNames = <String>[];
    for (var field in classElement.fields) {
      // Ensure static const.
      if (field.isSynthetic || !field.isConst || !field.isStatic) {
        continue;
      }
      // Check for type equality.
      if (field.type != type) {
        continue;
      }
      enumConstantNames.add(field.name);
    }
    if (enumConstantNames.length < 2) {
      return null;
    }

    // And no subclasses in the defining library.
    var compilationUnit = classElement.library.definingCompilationUnit;
    for (var cls in compilationUnit.types) {
      var classType = cls.thisType;
      do {
        classType = classType.superclass;
        if (classType == type) {
          return null;
        }
      } while (!classType.isDartCoreObject);
    }

    return EnumLikeClassDescription(enumConstantNames);
  }

  /// Return whether the canonical elements of two elements are equal.
  static bool canonicalElementsAreEqual(Element element1, Element element2) =>
      getCanonicalElement(element1) == getCanonicalElement(element2);

  /// Returns whether the canonical elements from two nodes are equal.
  ///
  /// As in, [getCanonicalElementFromIdentifier], the two nodes must be
  /// [Expression]s in order to be compared (otherwise `false` is returned).
  ///
  /// The two nodes must both be a [SimpleIdentifier], [PrefixedIdentifier], or
  /// [PropertyAccess] (otherwise `false` is returned).
  ///
  /// If the two nodes are PrefixedIdentifiers, or PropertyAccess nodes, then
  /// `true` is returned only if their canonical elements are equal, in
  /// addition to their prefixes' and targets' (respectfully) canonical
  /// elements.
  ///
  /// There is an inherent assumption about pure getters. For example:
  ///
  ///     A a1 = ...
  ///     A a2 = ...
  ///     a1.b.c; // statement 1
  ///     a2.b.c; // statement 2
  ///     a1.b.c; // statement 3
  ///
  /// The canonical elements from statements 1 and 2 are different, because a1
  /// is not the same element as a2.  The canonical elements from statements 1
  /// and 3 are considered to be equal, even though `A.b` may have side effects
  /// which alter the returned value.
  static bool canonicalElementsFromIdentifiersAreEqual(
      Expression rawExpression1, Expression rawExpression2) {
    if (rawExpression1 == null || rawExpression2 == null) return false;

    final expression1 = rawExpression1.unParenthesized;
    final expression2 = rawExpression2.unParenthesized;

    if (expression1 is SimpleIdentifier) {
      return expression2 is SimpleIdentifier &&
          canonicalElementsAreEqual(
              expression1.staticElement, expression2.staticElement);
    }

    if (expression1 is PrefixedIdentifier) {
      return expression2 is PrefixedIdentifier &&
          canonicalElementsAreEqual(expression1.prefix.staticElement,
              expression2.prefix.staticElement) &&
          canonicalElementsAreEqual(
              expression1.staticElement, expression2.staticElement);
    }

    if (expression1 is PropertyAccess && expression2 is PropertyAccess) {
      final target1 = expression1.target;
      final target2 = expression2.target;
      return canonicalElementsFromIdentifiersAreEqual(target1, target2) &&
          canonicalElementsAreEqual(expression1.propertyName.staticElement,
              expression2.propertyName.staticElement);
    }

    return false;
  }

  static bool extendsClass(DartType type, String className, String library) =>
      _extendsClass(type, <ClassElement>{}, className, library);

  static Element getCanonicalElement(Element element) {
    if (element is PropertyAccessorElement) {
      final variable = element.variable;
      if (variable is FieldMember) {
        // A field element defined in a parameterized type where the values of
        // the type parameters are known.
        //
        // This concept should be invisible when comparing FieldElements, but a
        // bug in the analyzer causes FieldElements to not evaluate as
        // equivalent to equivalent FieldMembers. See
        // https://github.com/dart-lang/sdk/issues/35343.
        return variable.declaration;
      } else {
        return variable;
      }
    } else {
      return element;
    }
  }

  static Element getCanonicalElementFromIdentifier(AstNode rawNode) {
    if (rawNode is Expression) {
      final node = rawNode.unParenthesized;
      if (node is Identifier) {
        return getCanonicalElement(node.staticElement);
      } else if (node is PropertyAccess) {
        return getCanonicalElement(node.propertyName.staticElement);
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
    recursiveCall(type, <ClassElement>{}, interfaceTypes);
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
    final interfaceType = type as InterfaceType;
    bool predicate(InterfaceType i) =>
        definitions.any((d) => isInterface(i, d.name, d.library));
    final element = interfaceType.element;
    return predicate(interfaceType) ||
        !element.isSynthetic && element.allSupertypes.any(predicate);
  }

  static bool implementsInterface(
      DartType type, String interface, String library) {
    if (type is! InterfaceType) {
      return false;
    }
    final interfaceType = type as InterfaceType;
    bool predicate(InterfaceType i) => isInterface(i, interface, library);
    final element = interfaceType.element;
    return predicate(interfaceType) ||
        !element.isSynthetic && element.allSupertypes.any(predicate);
  }

  /// todo (pq): unify and  `isInterface` into a shared method: `isInterfaceType`
  static bool isClass(DartType type, String className, String library) =>
      type is InterfaceType &&
      type.element.name == className &&
      type.element.library?.name == library;

  static bool isClassElement(
          ClassElement element, String className, String library) =>
      element.name == className && element.library?.name == library;

  static bool isConstructorElement(ConstructorElement element,
          {@required String uriStr,
          @required String className,
          @required String constructorName}) =>
      element != null &&
      element.library?.name == uriStr &&
      element.enclosingElement.name == className &&
      element.name == constructorName;

  static bool isInterface(
          InterfaceType type, String interface, String library) =>
      type.element.name == interface && type.element.library.name == library;

  static bool isNullLiteral(Expression expression) =>
      expression?.unParenthesized is NullLiteral;

  static PropertyAccessorElement lookUpGetter(MethodDeclaration node) {
    final parent = node.declaredElement.enclosingElement;
    if (parent is ClassElement) {
      return parent.lookUpGetter(node.name.name, node.declaredElement.library);
    }
    if (parent is ExtensionElement) {
      return parent.getGetter(node.name.name);
    }
    return null;
  }

  static PropertyAccessorElement lookUpInheritedConcreteGetter(
      MethodDeclaration node) {
    final parent = node.declaredElement.enclosingElement;
    if (parent is ClassElement) {
      return parent.lookUpInheritedConcreteGetter(
          node.name.name, node.declaredElement.library);
    }
    // Extensions don't inherit.
    return null;
  }

  static MethodElement lookUpInheritedConcreteMethod(MethodDeclaration node) {
    final parent = node.declaredElement.enclosingElement;
    if (parent is ClassElement) {
      return parent.lookUpInheritedConcreteMethod(
          node.name.name, node.declaredElement.library);
    }
    // Extensions don't inherit.
    return null;
  }

  static PropertyAccessorElement lookUpInheritedConcreteSetter(
      MethodDeclaration node) {
    final parent = node.declaredElement.enclosingElement;
    if (parent is ClassElement) {
      return parent.lookUpInheritedConcreteSetter(
          node.name.name, node.declaredElement.library);
    }
    // Extensions don't inherit.
    return null;
  }

  static MethodElement lookUpInheritedMethod(MethodDeclaration node) {
    final parent = node.declaredElement.enclosingElement;
    return parent is ClassElement
        ? parent.lookUpInheritedMethod(
            node.name.name, node.declaredElement.library)
        : null;
  }

  static PropertyAccessorElement lookUpSetter(MethodDeclaration node) {
    final parent = node.declaredElement.enclosingElement;
    if (parent is ClassElement) {
      return parent.lookUpSetter(node.name.name, node.declaredElement.library);
    }
    if (parent is ExtensionElement) {
      return parent.getSetter(node.name.name);
    }
    return null;
  }

  static bool matchesArgumentsWithParameters(
      NodeList<Expression> arguments, NodeList<FormalParameter> parameters) {
    final namedParameters = <String, Element>{};
    final namedArguments = <String, Element>{};
    final positionalParameters = <Element>[];
    final positionalArguments = <Element>[];
    for (final parameter in parameters) {
      if (parameter.isNamed) {
        namedParameters[parameter.identifier.name] =
            parameter.identifier.staticElement;
      } else {
        positionalParameters.add(parameter.identifier.staticElement);
      }
    }
    for (final argument in arguments) {
      if (argument is NamedExpression) {
        final element = DartTypeUtilities.getCanonicalElementFromIdentifier(
            argument.expression);
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

  static bool overridesMethod(MethodDeclaration node) {
    final parent = node.parent;
    if (parent is! ClassOrMixinDeclaration) {
      return false;
    }
    final name = node.declaredElement.name;
    final clazz = parent as ClassOrMixinDeclaration;
    final classElement = clazz.declaredElement;
    final library = classElement.library;
    return classElement.allSupertypes
        .map(node.isGetter
            ? (InterfaceType t) => t.lookUpGetter2
            : node.isSetter
                ? (InterfaceType t) => t.lookUpSetter2
                : (InterfaceType t) => t.lookUpMethod2)
        .any((lookUp) => lookUp(name, library) != null);
  }

  /// Builds the list resulting from traversing the node in DFS and does not
  /// include the node itself, it excludes the nodes for which the exclusion
  /// predicate returns true, if not provided, all is included.
  static Iterable<AstNode> traverseNodesInDFS(AstNode node,
      {AstNodePredicate excludeCriteria}) {
    final nodes = <AstNode>{};
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

  /// Return whether [leftType] and [rightType] are _definitely_ unrelated.
  ///
  /// For the purposes of this function, here are some "relation" rules:
  /// * `dynamic` and `Null` are considered related to any other type.
  /// * Two equal types are considered related, e.g. classes `int` and `int`,
  ///   classes `List<String>` and `List<String>`,
  ///   classes `List<T>` and `List<T>`, and type variables `A` and `A`.
  /// * Two types such that one is a subtype of the other, such as classes
  ///   `List<dynamic>` and `Iterable<dynamic>`, and type variables `A` and `B`
  ///   where `A extends B`.
  /// * Two types, each representing a class:
  ///   * are related if they represent the same class, modulo type arguments,
  ///     and each of their pair-wise type arguments are related, e.g.
  ///     `List<dynamic>` and `List<int>`, and `Future<T>` and `Future<S>` where
  ///     `S extends T`.
  ///   * are unrelated if [leftType]'s supertype is [Object].
  ///   * are related if their supertypes are equal, e.g. `List<dynamic>` and
  ///     `Set<dynamic>`.
  /// * Two types, each representing a type variable, are related if their
  ///   bounds are related.
  /// * Otherwise, the types are related.
  // TODO(srawlins): typedefs and functions in general.
  static bool unrelatedTypes(
      TypeSystem typeSystem, DartType leftType, DartType rightType) {
    // If we don't have enough information, or can't really compare the types,
    // return false as they _might_ be related.
    if (leftType == null ||
        leftType.isBottom ||
        leftType.isDynamic ||
        rightType == null ||
        rightType.isBottom ||
        rightType.isDynamic) {
      return false;
    }
    if (leftType == rightType ||
        typeSystem.isSubtypeOf(leftType, rightType) ||
        typeSystem.isSubtypeOf(rightType, leftType)) {
      return false;
    }
    if (leftType is InterfaceType && rightType is InterfaceType) {
      // In this case, [leftElement] and [rightElement] each represent
      // the same class, like `int`, or `Iterable<String>`.
      var leftElement = leftType.element;
      var rightElement = rightType.element;
      if (leftElement == rightElement) {
        // In this case, [leftElement] and [rightElement] represent the same
        // class, modulo generics, e.g. `List<int>` and `List<dynamic>`. Now we
        // need to check type arguments.
        var leftTypeArguments = leftType.typeArguments;
        var rightTypeArguments = rightType.typeArguments;
        if (leftTypeArguments.length != rightTypeArguments.length) {
          // I cannot think of how we would enter this block, but it guards
          // against RangeError below.
          return false;
        }
        for (var i = 0; i < leftTypeArguments.length; i++) {
          // If any of the pair-wise type arguments are unrelated, then
          // [leftType] and [rightType] are unrelated.
          if (unrelatedTypes(
              typeSystem, leftTypeArguments[i], rightTypeArguments[i])) {
            return true;
          }
        }
        // Otherwise, they might be related.
        return false;
      } else {
        return leftElement.supertype?.isObject == true ||
            leftElement.supertype != rightElement.supertype;
      }
    } else if (leftType is TypeParameterType &&
        rightType is TypeParameterType) {
      return unrelatedTypes(
          typeSystem, leftType.element.bound, rightType.element.bound);
    } else if (leftType is FunctionType) {
      if (_isFunctionTypeUnrelatedToType(leftType, rightType)) {
        return true;
      }
    } else if (rightType is FunctionType) {
      if (_isFunctionTypeUnrelatedToType(rightType, leftType)) {
        return true;
      }
    }
    return false;
  }

  static bool _extendsClass(DartType type, Set<ClassElement> seenTypes,
          String className, String library) =>
      type is InterfaceType &&
      seenTypes.add(type.element) &&
      (isClass(type, className, library) ||
          _extendsClass(type.superclass, seenTypes, className, library));

  static bool _isFunctionTypeUnrelatedToType(
      FunctionType type1, DartType type2) {
    if (type2 is FunctionType) {
      return false;
    }
    final element2 = type2.element;
    if (element2 is ClassElement &&
        element2.lookUpConcreteMethod('call', element2.library) != null) {
      return false;
    }
    return true;
  }
}

class EnumLikeClassDescription {
  List<String> enumConstantNames;
  EnumLikeClassDescription(this.enumConstantNames);
}

class InterfaceTypeDefinition {
  final String name;
  final String library;

  InterfaceTypeDefinition(this.name, this.library);

  @override
  int get hashCode => name.hashCode ^ library.hashCode;

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
